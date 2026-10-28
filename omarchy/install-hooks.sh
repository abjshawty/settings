#!/bin/bash
# Install every hook in omarchy/hooks/ on this machine, then run the theme-set
# ones once so each app picks up the current theme without waiting for a switch.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)/hooks"

for dir in "$HOOKS_DIR"/*.d; do
  event=$(basename "$dir" .d)
  for script in "$dir"/*; do
    omarchy hook install "$event" "$script"
  done
done

theme=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
for script in "$HOOKS_DIR"/theme-set.d/*; do
  "$HOME/.config/omarchy/hooks/theme-set.d/$(basename "$script")" "$theme"
done
