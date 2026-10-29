#!/bin/bash
# Regenerate the "Omarchy" Yaak theme plugin from the current Omarchy theme colors.
# Plugin dir: ~/.local/share/yaak-omarchy-theme (add it once in Yaak > Settings > Plugins)

COLORS="$HOME/.local/state/omarchy/current/theme/colors.toml"
PLUGIN_DIR="$HOME/.local/share/yaak-omarchy-theme"

[[ -f $COLORS ]] || exit 0

python3 -I - "$COLORS" "$PLUGIN_DIR" "${1:-}" <<'PY'
import json, os, sys, tomllib

colors_path, plugin_dir, slug = sys.argv[1], sys.argv[2], sys.argv[3]
with open(colors_path, "rb") as f:
    c = tomllib.load(f)

def rgb(h):
    h = h.lstrip("#")[:6]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def mix(a, b, pct):
    """Blend pct% of colour b into colour a."""
    a, b = rgb(a), rgb(b)
    return "#" + "".join(f"{round(x + (y - x) * pct / 100):02x}" for x, y in zip(a, b))

def get(*keys):
    for k in keys:
        if k in c:
            return c[k]
    raise KeyError(keys[0])

bg, fg = get("background"), get("foreground")
dark = get("mode") != "light"
shade = "#000000" if dark else "#ffffff"

base = {
    "surface": bg,
    "surfaceHighlight": mix(bg, fg, 8),
    "text": fg,
    "textSubtle": mix(fg, bg, 30),
    "textSubtlest": mix(fg, bg, 50),
    "border": mix(bg, fg, 14),
    "borderSubtle": mix(bg, fg, 9),
    "selection": get("selection"),
    "primary": get("accent"),
    "secondary": mix(fg, bg, 30),
    "info": get("cyan"),
    "success": get("green"),
    "notice": get("yellow"),
    "warning": get("orange", "bright_yellow"),
    "danger": get("red"),
}

panel = get("dark_background", "background")
panel_border = mix(panel, fg, 12)
buttons = {k: mix(base[k], shade, 12)
           for k in ("primary", "secondary", "info", "success", "notice", "warning", "danger")}

theme = {
    "id": "omarchy",
    "label": "Omarchy",
    "dark": dark,
    "base": base,
    "components": {
        "dialog": {"surface": panel},
        "sidebar": {"surface": panel, "border": panel_border},
        "appHeader": {"surface": get("darker_background", "dark_background", "background"),
                      "border": panel_border},
        "responsePane": {"surface": panel, "border": panel_border},
        "button": buttons,
    },
}

build_dir = os.path.join(plugin_dir, "build")
os.makedirs(build_dir, exist_ok=True)

def write(rel, text, replace=True):
    path = os.path.join(plugin_dir, rel)
    if not replace and os.path.exists(path):
        return
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)

# Yaak watches index.js and package.json by inode, so those are written once and
# never replaced. The loader reads theme.json on every theme request instead.
write("package.json", json.dumps({
    "name": "@local/yaak-omarchy-theme",
    "displayName": "Omarchy Theme",
    "version": "0.1.0",
    "private": True,
    "description": "Yaak theme generated from the current Omarchy theme",
}, indent=2) + "\n", replace=False)
write("build/index.js", """// Loader for the Omarchy theme. Colors live in theme.json, rewritten by the
// Omarchy theme-set hook; this file must stay unchanged so Yaak keeps watching it.
const fs = require("node:fs");
const path = require("node:path");

let lastGood = null;

const plugin = {
  get themes() {
    try {
      lastGood = JSON.parse(fs.readFileSync(path.join(__dirname, "theme.json"), "utf8"));
    } catch (err) {
      // Keep the previous theme if the file is missing or mid-write
    }
    return lastGood ? [lastGood] : [];
  },
};

exports.plugin = plugin;
""", replace=False)
write("build/theme.json", json.dumps(theme, indent=2) + "\n")
write("build/metadata.json", json.dumps({
    "schemaVersion": 1,
    "apiTypes": ["themes"],
    "apis": {"themes": {"label": "Theme", "source": "themes", "count": 1, "items": [theme]}},
}, indent=2) + "\n")

# Bump package.json's mtime in place to make Yaak reload the plugin and re-read the themes
os.utime(os.path.join(plugin_dir, "package.json"))
PY
