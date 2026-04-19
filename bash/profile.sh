#!/bin/bash
# ============================================================================
# VARIABLES
# ============================================================================

export WORKSPACE="${HOME}/Projects"

# ============================================================================
# INITIALIZATION
# ============================================================================

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

if command -v oh-my-posh &>/dev/null; then
  export POSH_THEME="material"
  eval "$(oh-my-posh init bash --config "$POSH_THEME")"
fi

# ============================================================================
# CLEANUP
# ============================================================================

unset -f ls cd curl 2>/dev/null

# ============================================================================
# FUNCTIONS
# ============================================================================

update_python_modules() {
  pip list --format=json | python3 -c "import sys, json; [__import__('subprocess').run(['pip', 'install', '--upgrade', p['name']]) for p in json.load(sys.stdin)]"
}

connect_wifi() {
  local ssid="$1"
  if [[ -z "$ssid" ]]; then
    echo "Usage: connect_wifi <ssid>"
    return 1
  fi
  iwctl station wlan0 connect "$ssid"
}

disconnect_wifi() {
  iwctl station wlan0 disconnect
}

find_from_port() {
  local port="$1"
  if [[ -z "$port" ]]; then
    echo "Usage: find_from_port <port>"
    return 1
  fi
  if command -v lsof &>/dev/null; then
    lsof -i :"$port"
  else
    netstat -tlnp 2>/dev/null | grep ":$port"
  fi
}

find_https_url() {
  local url="$1"
  if [[ -z "$url" ]]; then
    echo "Usage: find_https_url <git@github.com:user/repo.git>"
    return 1
  fi
  echo "$url" | sed 's|:|/|g' | sed 's|git@|https://|'
}

find_port() {
  local pid="$1"
  if [[ -z "$pid" ]]; then
    echo "Usage: find_port <pid>"
    return 1
  fi
  if command -v lsof &>/dev/null; then
    lsof -i -P -n 2>/dev/null | grep "^python3.*$pid" | awk '{print $9}' | cut -d':' -f2 | sort -u
  else
    echo "lsof not available"
    return 1
  fi
}

get_ip() {
  ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1
}

get_storage() {
  df -h / | tail -1
}

new_file() {
  local name="$1"
  local path="${2:-.}"
  local extension="$3"

  if [[ -z "$name" ]]; then
    echo "Usage: new_file <filename> [path] [extension]"
    return 1
  fi

  local filename="$name"
  if [[ -n "$extension" && "$name" != *"$extension"* ]]; then
    filename="$name$extension"
  fi

  local full_path="$path/$filename"
  touch "$full_path"
  echo "Created: $full_path"
}

new_nodeapp() {
  local framework="$1"
  local name="${2:-.}"
  local package_manager="${3:-yarn}"

  local -A commands=(
    ["react"]="npm create vite@latest $name -- --template react-ts"
    ["svelte"]="npm create vite@latest $name -- --template svelte-ts"
    ["solid"]="npm create vite@latest $name -- --template solid-ts"
    ["vue"]="npm create vue@latest $name"
    ["next"]="npx create-next-app@latest $name --use-npm"
  )

  if [[ -z "${commands[$framework]}" ]]; then
    echo "Available frameworks: ${!commands[@]}"
    return 1
  fi

  echo "Starting..."
  eval "${commands[$framework]}"
  echo "Done."
}

search_history() {
  local search="$1"
  if [[ -z "$search" ]]; then
    echo "Usage: search_history <term>"
    return 1
  fi
  history | grep "$search"
}

set_location_dev() {
  local path="${1:-$WORKSPACE}"
  if [[ ! -d "$path" ]]; then
    echo "Directory does not exist: $path"
    return 1
  fi
  cd "$path"
}

remove_folder() {
  local path="$1"
  local dry_run=false

  if [[ "$path" == "--dry-run" ]]; then
    shift
    dry_run=true
  fi

  if [[ -z "$path" ]]; then
    echo "Usage: remove_folder [--dry-run] <path>"
    return 1
  fi

  local full_path
  full_path=$(realpath "$path" 2>/dev/null)

  if [[ -z "$full_path" ]]; then
    echo "Path does not exist: $path"
    return 1
  fi

  local dangerous=("/" "$HOME" "/home" "/tmp")
  for d in "${dangerous[@]}"; do
    if [[ "$full_path" == "$d" ]]; then
      echo "Refusing to remove: $full_path"
      return 1
    fi
  done

  if [[ "$dry_run" == "true" ]]; then
    echo "DRY RUN: Would remove: $full_path"
    echo "Contents:"
    ls -la "$full_path"
  else
    rm -rf "$full_path"
    echo "Removed: $full_path"
  fi
}

# ============================================================================
# ALIASES
# ============================================================================

alias cd='z' 2>/dev/null || true
alias ls='eza --icons'
alias ll='eza -l --icons'
alias lt='eza --tree --icons -L 2'
alias la='eza -la --icons'
alias ip='get_ip'
alias dev='set_location_dev'
alias search='search_history'
alias s='pacman -Ssq | fzf | xargs -o sudo pacman -S'

if command -v nvim &>/dev/null; then
  alias v='nvim'
  alias vim='nvim'
fi

if command -v lsd &>/dev/null; then
  alias ls='lsd --icon always'
fi
