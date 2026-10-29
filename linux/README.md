# Linux settings

Setup for my Arch / Omarchy machines.

## Structure

```
linux/
├── bash/
│   ├── init.sh      # Fresh Arch: update the system, build yay if missing
│   └── profile.sh   # Bash functions and aliases
└── omarchy/
    ├── hooks/theme-set.d/  # Make Yaak and Spotify follow the Omarchy theme
    └── install-hooks.sh    # Install every hook and apply the current theme
```

## Bash profile

Source it from `~/.bashrc`:

```sh
source ~/Projects/settings/linux/bash/profile.sh
```

Key functions and aliases: `connect_wifi` / `disconnect_wifi` (iwd), `find_from_port`, `find_port`, `get_ip`, `new_nodeapp`, `remove_folder [--dry-run]`, `dev` (go to `~/Projects`), `hist` (search history), `n` (nvim), `s` (fuzzy-pick a pacman package to install), and eza-backed `ls` / `ll` / `la` / `lt`.

## Omarchy hooks

`omarchy/hooks/<event>.d/` mirrors `~/.config/omarchy/hooks/`. To install them all on a machine and apply the current theme right away:

```sh
./omarchy/install-hooks.sh
```

The `theme-set` hooks need some one-time setup in each app (adding the Yaak plugin, patching Spotify with Spicetify). That's documented in the vault's *Omarchy theme sync* note.

## search

The `search` CLI lives in the main settings repo under `rust/search`. Install it onto PATH with:

```sh
cargo install --path rust/search
```
