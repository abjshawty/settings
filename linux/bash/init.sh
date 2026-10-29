#!/bin/bash
# Bootstrap a fresh Arch install: update the system, then build the yay AUR helper.
# Omarchy already ships yay, so on Omarchy this only updates the system.
set -euo pipefail

sudo pacman -Syu
sudo pacman -S --needed git base-devel

if ! command -v yay &>/dev/null; then
  build_dir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
  (cd "$build_dir/yay" && makepkg -si)
  rm -rf "$build_dir"
fi
