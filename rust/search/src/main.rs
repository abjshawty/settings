//! `search` — turn a query into a search-engine URL and open it in the browser.
//!
//! The tool is entirely table-driven: every supported site is one [`Engine`]
//! row in [`ENGINES`]. From that single table we derive the selection flags
//! (`--<key>` / `--<alias>`), the `--help` and `--list` listings, and
//! `--set-default` — so adding a site means adding one row and nothing else.
//!
//! Flow: parse the args into an optional engine override plus a free-text
//! query, build the URL by percent-encoding the query into the engine's
//! `template`, then hand that URL to PowerShell's `b` (Open-DefaultBrowser) to
//! launch it. The chosen default engine is persisted in a small config file.

use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::{Command, ExitCode};

/// One searchable site.
///
/// Adding a new engine is intentionally a one-liner: append an entry to
/// [`ENGINES`] and it automatically gains its selection flags, its `--help`
/// and `--list` entries, and `--set-default` support.
struct Engine {
    /// Canonical name. Doubles as the primary selection flag, `--<key>`.
    key: &'static str,
    /// Extra short flags that also select this engine (e.g. `gh` for GitHub).
    /// Keys and aliases must be unique across the table (enforced by a test).
    aliases: &'static [&'static str],
    /// Human-readable grouping shown in `--help` / `--list` (e.g. "developer").
    category: &'static str,
    /// URL containing a single `{q}` placeholder, replaced by the
    /// percent-encoded query when the URL is built.
    template: &'static str,
}

/// Every supported engine. Table order is preserved in `--help` and `--list`,
/// where entries are grouped by `category`. Query-param names differ by site
/// (`q`, `search`, `search_query`), and the AI engines open a chat/answer
/// seeded with the query (and may require login); if a site changes its param,
/// only its `template` needs updating.
const ENGINES: &[Engine] = &[
    Engine {
        key: "google",
        aliases: &["g"],
        category: "general web",
        template: "https://www.google.com/search?q={q}",
    },
    Engine {
        key: "brave",
        aliases: &["br"],
        category: "general web",
        template: "https://search.brave.com/search?q={q}",
    },
    Engine {
        key: "duckduckgo",
        aliases: &["dg"],
        category: "general web",
        template: "https://duckduckgo.com/?q={q}",
    },
    Engine {
        key: "ecosia",
        aliases: &["ec"],
        category: "general web",
        template: "https://www.ecosia.org/search?q={q}",
    },
    Engine {
        key: "perplexity",
        aliases: &["px", "pplx"],
        category: "AI assistants",
        template: "https://www.perplexity.ai/search?q={q}",
    },
    Engine {
        key: "chatgpt",
        aliases: &["gpt"],
        category: "AI assistants",
        template: "https://chatgpt.com/?q={q}",
    },
    Engine {
        key: "claude",
        aliases: &["cl"],
        category: "AI assistants",
        template: "https://claude.ai/new?q={q}",
    },
    Engine {
        key: "github",
        aliases: &["gh"],
        category: "developer",
        template: "https://github.com/search?q={q}&type=repositories",
    },
    Engine {
        key: "gitlab",
        aliases: &["gl"],
        category: "developer",
        template: "https://gitlab.com/search?search={q}",
    },
    Engine {
        key: "dockerhub",
        aliases: &["dh", "docker"],
        category: "developer",
        template: "https://hub.docker.com/search?q={q}",
    },
    Engine {
        key: "npm",
        aliases: &["np"],
        category: "developer",
        template: "https://www.npmjs.com/search?q={q}",
    },
    Engine {
        key: "youtube",
        aliases: &["yt"],
        category: "community & reference",
        template: "https://www.youtube.com/results?search_query={q}",
    },
    Engine {
        key: "reddit",
        aliases: &["rd"],
        category: "community & reference",
        template: "https://www.reddit.com/search/?q={q}",
    },
    Engine {
        key: "wikipedia",
        aliases: &["wiki", "wp"],
        category: "community & reference",
        template: "https://en.wikipedia.org/w/index.php?search={q}",
    },
];

/// Engine used by a naked `search <query>` until the user overrides it.
const INITIAL_DEFAULT: &str = "google";

/// Parse the command line, then either run a sub-action (help / list /
/// set-default) or build a query URL and open it.
///
/// Argument grammar, scanned left to right:
/// - the special flags below (`--help`, `--list`, `--dry-run`, `--set-default`);
/// - `--` ends flag parsing — everything after it is treated as query text;
/// - any other `-…`/`--…` token selects an engine by key or alias for this run;
/// - everything else is collected as the free-text query.
fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();

    // Engine chosen by a flag this run; `None` means use the saved default.
    let mut chosen: Option<&Engine> = None;
    let mut query_parts: Vec<String> = Vec::new();
    let mut dry_run = false;
    // Set by `--`: once true, remaining args are query text, not flags.
    let mut flags_done = false;

    let mut i = 0;
    while i < args.len() {
        let arg = &args[i];

        if flags_done || !arg.starts_with('-') {
            query_parts.push(arg.clone());
            i += 1;
            continue;
        }

        match arg.as_str() {
            "--" => flags_done = true,
            "-h" | "--help" => {
                print_help();
                return ExitCode::SUCCESS;
            }
            "-n" | "--dry-run" => dry_run = true,
            "--list" => {
                print_list();
                return ExitCode::SUCCESS;
            }
            "--set-default" => {
                let Some(value) = args.get(i + 1) else {
                    eprintln!("error: --set-default needs an engine name");
                    return ExitCode::FAILURE;
                };
                return set_default(value);
            }
            other if other.starts_with("--set-default=") => {
                let value = &other["--set-default=".len()..];
                return set_default(value);
            }
            // Anything else is treated as an engine selector: strip the
            // leading dashes and look it up by key or alias.
            other => {
                let name = other.trim_start_matches('-');
                match find_engine(name) {
                    Some(engine) => chosen = Some(engine),
                    None => {
                        eprintln!("error: unknown flag or engine '{other}'");
                        eprintln!("run `search --help` to see available engines");
                        return ExitCode::FAILURE;
                    }
                }
            }
        }
        i += 1;
    }

    // No query: report the current default and where to look, rather than
    // opening a browser on nothing.
    if query_parts.is_empty() {
        println!("default engine: {}", current_default().key);
        println!("run `search <query>` to search, `search --help` for usage,");
        println!("or `search --list` to see every engine.");
        return ExitCode::SUCCESS;
    }

    let engine = chosen.unwrap_or_else(current_default);
    let query = query_parts.join(" ");
    let url = build_url(engine, &query);

    if dry_run {
        println!("{url}");
        return ExitCode::SUCCESS;
    }

    open_in_browser(&url)
}

/// Build the final URL by substituting the percent-encoded query into the
/// engine's template.
fn build_url(engine: &Engine, query: &str) -> String {
    engine.template.replace("{q}", &percent_encode(query))
}

/// Percent-encode per RFC 3986: keep unreserved bytes, encode everything else
/// (including spaces as %20) as uppercase %XX. Operates on UTF-8 bytes.
fn percent_encode(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for &b in s.as_bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

/// Find an engine by its key or one of its aliases (case-insensitive).
fn find_engine(name: &str) -> Option<&'static Engine> {
    let name = name.to_ascii_lowercase();
    ENGINES
        .iter()
        .find(|e| e.key == name || e.aliases.contains(&name.as_str()))
}

/// Hand the URL to PowerShell's `b` (Open-DefaultBrowser from the settings
/// profile). The profile is dot-sourced by `pwsh`, so `b` is defined; the URL
/// is already percent-encoded, so single-quoting it is safe.
fn open_in_browser(url: &str) -> ExitCode {
    println!("opening {url}");
    let status = Command::new("pwsh")
        .arg("-c")
        .arg(format!("b '{url}'"))
        .status();

    match status {
        Ok(s) if s.success() => ExitCode::SUCCESS,
        Ok(s) => {
            eprintln!("error: `b` exited with {s}");
            ExitCode::FAILURE
        }
        Err(e) => {
            eprintln!("error: could not launch pwsh: {e}");
            ExitCode::FAILURE
        }
    }
}

/// Resolve the persisted default engine, falling back to INITIAL_DEFAULT if the
/// config is missing, unreadable, or names an engine that no longer exists.
fn current_default() -> &'static Engine {
    let key = read_default_key();
    find_engine(&key)
        .or_else(|| find_engine(INITIAL_DEFAULT))
        .expect("INITIAL_DEFAULT must name a real engine")
}

/// Validate and persist a new default engine.
fn set_default(value: &str) -> ExitCode {
    let Some(engine) = find_engine(value) else {
        eprintln!("error: unknown engine '{value}'");
        eprintln!("run `search --help` to see available engines");
        return ExitCode::FAILURE;
    };

    let Some(path) = config_path() else {
        eprintln!("error: could not determine a config location (no APPDATA/USERPROFILE)");
        return ExitCode::FAILURE;
    };

    if let Some(dir) = path.parent()
        && let Err(e) = fs::create_dir_all(dir)
    {
        eprintln!("error: could not create config dir: {e}");
        return ExitCode::FAILURE;
    }

    if let Err(e) = fs::write(&path, format!("default = {}\n", engine.key)) {
        eprintln!("error: could not write config: {e}");
        return ExitCode::FAILURE;
    }

    println!("default engine set to {}", engine.key);
    ExitCode::SUCCESS
}

/// Read the `default = <key>` line from the config file, if present.
fn read_default_key() -> String {
    let Some(path) = config_path() else {
        return INITIAL_DEFAULT.to_string();
    };
    let Ok(contents) = fs::read_to_string(&path) else {
        return INITIAL_DEFAULT.to_string();
    };
    for line in contents.lines() {
        if let Some((k, v)) = line.split_once('=')
            && k.trim() == "default"
        {
            return v.trim().to_string();
        }
    }
    INITIAL_DEFAULT.to_string()
}

/// `%APPDATA%\search\config`, falling back to `%USERPROFILE%\.search\config`.
fn config_path() -> Option<PathBuf> {
    if let Ok(appdata) = env::var("APPDATA") {
        return Some(PathBuf::from(appdata).join("search").join("config"));
    }
    if let Ok(home) = env::var("USERPROFILE") {
        return Some(PathBuf::from(home).join(".search").join("config"));
    }
    None
}

/// Group the engine table by `category`, preserving the first-seen order of
/// both the categories and the engines within each. Shared by `--help` and
/// `--list` so the two stay consistent.
fn engines_by_category() -> Vec<(&'static str, Vec<&'static Engine>)> {
    let mut groups: Vec<(&'static str, Vec<&'static Engine>)> = Vec::new();
    for e in ENGINES {
        match groups.iter_mut().find(|(name, _)| *name == e.category) {
            Some((_, list)) => list.push(e),
            None => groups.push((e.category, vec![e])),
        }
    }
    groups
}

/// Compact selector summary for one engine: `key` or `key/alias1,alias2`.
fn engine_flags(e: &Engine) -> String {
    if e.aliases.is_empty() {
        e.key.to_string()
    } else {
        format!("{}/{}", e.key, e.aliases.join(","))
    }
}

/// Print the tagline, usage, options, and the engine list grouped by category.
fn print_help() {
    println!("search — build a search-engine query URL and open it in your default browser");
    println!();
    println!("USAGE");
    println!(
        "  search <query>...              search the default engine (currently: {})",
        current_default().key
    );
    println!(
        "  search --<engine> <query>...   search a specific engine, e.g. `search --gh ripgrep`"
    );
    println!("  search --set-default <engine>  change the default engine");
    println!("  search --list                  show every engine with its URL template");
    println!("  search                         print the current default engine");
    println!();
    println!("OPTIONS");
    println!("  -n, --dry-run   print the URL instead of opening it");
    println!("      --list      list every engine (name, aliases, URL template)");
    println!("  -h, --help      show this help");
    println!("  --              stop reading flags; treat the rest as the query");
    println!();
    println!("ENGINES  (select with --<name> or an alias)");
    let groups = engines_by_category();
    let label_width = groups.iter().map(|(name, _)| name.len()).max().unwrap_or(0);
    for (category, engines) in groups {
        let tokens: Vec<String> = engines.iter().map(|e| engine_flags(e)).collect();
        println!("  {category:label_width$}   {}", tokens.join("  "));
    }
}

/// Print every engine grouped by category, each with its full flags and URL
/// template — more detail than the one-line summary in `--help`.
fn print_list() {
    let width = ENGINES.iter().map(|e| e.key.len()).max().unwrap_or(0);
    for (category, engines) in engines_by_category() {
        println!("{category}:");
        for e in engines {
            let flags = if e.aliases.is_empty() {
                format!("--{}", e.key)
            } else {
                format!("--{}, --{}", e.key, e.aliases.join(", --"))
            };
            println!("  {:width$}  {}", e.key, e.template, width = width);
            println!("  {:width$}  {}", "", flags, width = width);
        }
        println!();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn google() -> &'static Engine {
        find_engine("google").unwrap()
    }

    #[test]
    fn encodes_spaces_and_punctuation() {
        assert_eq!(
            percent_encode("what is a monkey?"),
            "what%20is%20a%20monkey%3F"
        );
    }

    #[test]
    fn keeps_unreserved_characters() {
        assert_eq!(percent_encode("a-z_0.9~"), "a-z_0.9~");
    }

    #[test]
    fn encodes_utf8_bytes() {
        assert_eq!(percent_encode("café"), "caf%C3%A9");
    }

    #[test]
    fn builds_google_query_url() {
        assert_eq!(
            build_url(google(), "what is a monkey?"),
            "https://www.google.com/search?q=what%20is%20a%20monkey%3F"
        );
    }

    #[test]
    fn engine_lookup_by_key_and_alias_is_case_insensitive() {
        assert_eq!(find_engine("GOOGLE").unwrap().key, "google");
        assert_eq!(find_engine("g").unwrap().key, "google");
        assert!(find_engine("nope").is_none());
    }

    /// C1: invariants that must hold for the whole ENGINES table as it grows.
    #[test]
    fn engine_table_is_well_formed() {
        let mut seen = std::collections::HashSet::new();
        for e in ENGINES {
            assert!(
                e.template.contains("{q}"),
                "engine '{}' template is missing the {{q}} placeholder",
                e.key
            );
            assert!(
                !e.category.is_empty(),
                "engine '{}' has an empty category",
                e.key
            );
            assert!(seen.insert(e.key), "duplicate engine token '{}'", e.key);
            for a in e.aliases {
                assert!(seen.insert(*a), "duplicate engine token '{a}'");
            }
        }
        assert!(
            find_engine(INITIAL_DEFAULT).is_some(),
            "INITIAL_DEFAULT '{INITIAL_DEFAULT}' does not name a real engine"
        );
    }

    #[test]
    fn builds_sprint1_query_urls() {
        let q = "hello world";
        let url = |key: &str| build_url(find_engine(key).unwrap(), q);
        assert_eq!(
            url("brave"),
            "https://search.brave.com/search?q=hello%20world"
        );
        assert_eq!(url("duckduckgo"), "https://duckduckgo.com/?q=hello%20world");
        assert_eq!(
            url("ecosia"),
            "https://www.ecosia.org/search?q=hello%20world"
        );
    }

    #[test]
    fn sprint1_aliases_resolve() {
        assert_eq!(find_engine("br").unwrap().key, "brave");
        assert_eq!(find_engine("dg").unwrap().key, "duckduckgo");
        assert_eq!(find_engine("ec").unwrap().key, "ecosia");
    }

    #[test]
    fn builds_sprint2_query_urls() {
        let q = "hello world";
        let url = |key: &str| build_url(find_engine(key).unwrap(), q);
        assert_eq!(
            url("perplexity"),
            "https://www.perplexity.ai/search?q=hello%20world"
        );
        assert_eq!(url("chatgpt"), "https://chatgpt.com/?q=hello%20world");
        assert_eq!(url("claude"), "https://claude.ai/new?q=hello%20world");
    }

    #[test]
    fn sprint2_aliases_resolve() {
        assert_eq!(find_engine("px").unwrap().key, "perplexity");
        assert_eq!(find_engine("pplx").unwrap().key, "perplexity");
        assert_eq!(find_engine("gpt").unwrap().key, "chatgpt");
        assert_eq!(find_engine("cl").unwrap().key, "claude");
    }

    #[test]
    fn builds_sprint3_query_urls() {
        let q = "hello world";
        let url = |key: &str| build_url(find_engine(key).unwrap(), q);
        assert_eq!(
            url("github"),
            "https://github.com/search?q=hello%20world&type=repositories"
        );
        assert_eq!(
            url("gitlab"),
            "https://gitlab.com/search?search=hello%20world"
        );
        assert_eq!(
            url("dockerhub"),
            "https://hub.docker.com/search?q=hello%20world"
        );
        assert_eq!(url("npm"), "https://www.npmjs.com/search?q=hello%20world");
    }

    #[test]
    fn sprint3_aliases_resolve() {
        assert_eq!(find_engine("gh").unwrap().key, "github");
        assert_eq!(find_engine("gl").unwrap().key, "gitlab");
        assert_eq!(find_engine("dh").unwrap().key, "dockerhub");
        assert_eq!(find_engine("docker").unwrap().key, "dockerhub");
        assert_eq!(find_engine("np").unwrap().key, "npm");
    }

    #[test]
    fn builds_sprint4_query_urls() {
        let q = "hello world";
        let url = |key: &str| build_url(find_engine(key).unwrap(), q);
        assert_eq!(
            url("youtube"),
            "https://www.youtube.com/results?search_query=hello%20world"
        );
        assert_eq!(
            url("reddit"),
            "https://www.reddit.com/search/?q=hello%20world"
        );
        assert_eq!(
            url("wikipedia"),
            "https://en.wikipedia.org/w/index.php?search=hello%20world"
        );
    }

    #[test]
    fn sprint4_aliases_resolve() {
        assert_eq!(find_engine("yt").unwrap().key, "youtube");
        assert_eq!(find_engine("rd").unwrap().key, "reddit");
        assert_eq!(find_engine("wiki").unwrap().key, "wikipedia");
        assert_eq!(find_engine("wp").unwrap().key, "wikipedia");
    }
}
