#!/bin/bash
RAW_GITHUB="https://raw.githubusercontent.com/z-Eduard005/gnome-obs-hotkeys/main"
OBS_HOTKEYS_DIR="$HOME/Programs/obs-hotkeys"

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }

install_nodejs() {
  if command -v dnf &>/dev/null; then
    sudo dnf install -y nodejs
  elif command -v apt &>/dev/null; then
    sudo apt install -y nodejs
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm nodejs
  elif command -v zypper &>/dev/null; then
    sudo zypper install -y nodejs
  else
    echo "$(err "No supported package manager found. Please install nodejs manually.")"; exit 1
  fi
}

ask_confirm() {
  read -rp "$(warn "$1 [y/N]: ")" proceed
  if [[ "$proceed" == [yY] ]]; then
    return 0
  else
    return 1
  fi
}

create_gnome_shortcut() {
  local id="$1" name="$2" command="$3" binding="$4"
  local schema="org.gnome.settings-daemon.plugins.media-keys"
  local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${id}/"

  local existing
  existing=$(gsettings get "$schema" custom-keybindings)

  if echo "$existing" | grep -q "'$path'"; then
    local updated="$existing"
  else
    local updated=$(echo "$existing" | sed "s|]|, '${path}']|" | sed "s|\[, |[|")
  fi

  gsettings set "$schema" custom-keybindings "$updated"
  gsettings set "${schema}.custom-keybinding:${path}" name "$name"
  gsettings set "${schema}.custom-keybinding:${path}" command "$command"
  gsettings set "${schema}.custom-keybinding:${path}" binding "$binding"
}

proceed_install=true
if [ -d "$OBS_HOTKEYS_DIR" ]; then
  echo "$(warn "OBS hotkeys already installed")"
  ask_confirm "Do you want to reinstall?" || proceed_install=false
fi

if $proceed_install; then
  install_nodejs || { echo "$(err "Failed to install nodejs")"; exit 1; }
  rm -rf "$OBS_HOTKEYS_DIR"
  mkdir -p "$OBS_HOTKEYS_DIR"
  for f in package.json toggle-pause.js toggle-record.js; do
    curl -fsSL "$RAW_GITHUB/obs-hotkeys/$f" -o "$OBS_HOTKEYS_DIR/$f" || { echo "$(err "Failed to download $f")"; exit 1; }
  done
  (cd "$OBS_HOTKEYS_DIR" && npm install) || { echo "$(err "npm install failed")"; exit 1; }

  create_gnome_shortcut "obs-pause" "OBS Toggle Pause" "node $OBS_HOTKEYS_DIR/toggle-pause.js" "<Control><Alt>BackSpace"
  create_gnome_shortcut "obs-record" "OBS Toggle Record" "node $OBS_HOTKEYS_DIR/toggle-record.js" "<Control><Shift><Alt>BackSpace"

  echo "$(success "OBS hotkeys set")"
  echo "$(success "<Ctrl+Alt+Backspace> to toggle pause")"
  echo "$(success "<Ctrl+Shift+Alt+Backspace> to toggle recording")"
  echo "$(success "You can change hotkeys in default settings app later")"
fi
