# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Rust CLI (`search`) that builds search-engine query URLs and opens them in the
default browser. It does **not** perform HTTP requests itself — it delegates the
actual "open a URL" step to the user's `b` command (see Browser integration).

The whole tool lives in `src/main.rs` (hand-rolled, zero dependencies).

## Build / run / test

Standard cargo workflow (Rust edition 2024):

```
cargo run -- <args>      # run the CLI with arguments after `--`
cargo build              # debug build
cargo build --release    # optimized build
cargo test               # all tests
cargo test <name>        # single test by (sub)string match
cargo clippy             # lint
cargo fmt                # format
```

## CLI design

- **Naked invocation searches the default engine.** `search what is a monkey?`
  builds a query URL for the current default engine and opens it. The initial
  default is **Google**: `https://www.google.com/search?q=<url-encoded query>`.
- **The default is modifiable and persisted.** `search --set-default <engine>`
  writes the chosen engine to a config file so future naked `search ...` calls
  use it. Config lives at `%APPDATA%\search\config` (fallback
  `%USERPROFILE%\.search\config`), format `default = <key>`. A missing/invalid
  config falls back to `INITIAL_DEFAULT`.
- **Each engine is selectable via a flag.** Any `--<key>` or `--<alias>`
  overrides the default for one call (e.g. `-g` / `--google`).
- **`search` with no query** prints the current default + usage (does not open).
- **`--dry-run` / `-n`** prints the URL instead of opening it (used by tests and
  handy for scripting). **`--list`** prints every engine with its template.
  **`--`** ends flag parsing; everything after is query.

Currently implemented engines, grouped by their `category` (which drives the
`--help` / `--list` grouping):
- **Google** (default)
- Sprint 1 (general web): **Brave** (`br`), **DuckDuckGo** (`dg`), **Ecosia** (`ec`)
- Sprint 2 (AI): **Perplexity** (`px`, `pplx`), **ChatGPT** (`gpt`), **Claude** (`cl`)
- Sprint 3 (dev): **GitHub** (`gh`), **GitLab** (`gl`), **Docker Hub** (`dh`, `docker`), **npm** (`np`)
- Sprint 4 (community/ref): **YouTube** (`yt`), **Reddit** (`rd`), **Wikipedia** (`wiki`, `wp`)

Note the AI engines' query params (`chatgpt.com/?q=`, `claude.ai/new?q=`,
`perplexity.ai/search?q=`) seed a chat/answer and may require login; if a site
changes its param, only its `template` needs updating.

### Adding an engine

Engines are a single `const ENGINES: &[Engine]` table in `main.rs`. Each entry
is `{ key, aliases, category, template }` where `template` contains a `{q}`
placeholder and `category` is the heading it's grouped under in `--help` /
`--list`. Append an entry and it automatically gains its selection flag,
`--list`/`--help` entry, and `--set-default` support — there is no other place
to touch. Keep `INITIAL_DEFAULT` pointing at a real `key`.

Query strings are percent-encoded by a hand-rolled `percent_encode` (RFC 3986
unreserved set kept, everything else `%XX`, spaces `%20`, UTF-8 by byte). Unit
tests in `main.rs` cover encoding, URL building, and engine lookup, plus a
`engine_table_is_well_formed` invariant test (no duplicate keys/aliases, every
template has `{q}`, non-empty `category`, `INITIAL_DEFAULT` resolves) — add a
per-engine `build_url` test when you add an engine.

## Browser integration (the `b` command)

URLs are opened by shelling out to `b`, a PowerShell alias defined in the user's
profile at `D:\settings\powershell\profile.ps1`:

```powershell
Set-Alias b Open-DefaultBrowser     # Open-DefaultBrowser -Url <url>
```

`Open-DefaultBrowser` reads the Windows registry
(`HKCU:\...\UrlAssociations\http\UserChoice`) to find the default browser
executable and launches it with the URL.

The whole `D:\settings` profile is dot-sourced into the user's PowerShell
profile, so `b` (and the other functions/aliases) are available directly in any
profile-loading shell. Because `b` is a PowerShell function alias (not an
`.exe` on PATH), invoking it from Rust means running it through PowerShell —
e.g. `pwsh -c "b '<url>'"` — rather than spawning `b` directly. Note `pwsh
-Command` loads the profile by default (don't pass `-NoProfile`, or `b` won't
be defined).

## Toolbelt wiring

This is a personal tool exposed through the settings PowerShell toolbelt. A
`search` function in `D:\settings\powershell\profile.ps1` forwards args to the
**release** binary:

```powershell
function search { & 'D:/personal/search/target/release/search.exe' @args }
```

So after changing the Rust code you must `cargo build --release` for the toolbelt
`search` to pick it up. The profile's old history-search alias was renamed from
`search` to `hist`, freeing the `search` name for this tool.
