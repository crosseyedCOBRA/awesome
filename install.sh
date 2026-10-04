#!/usr/bin/env bash
# Deploys this repo's AwesomeWM config onto a base Arch + AwesomeWM install.
# Symlinks everything back into this repo's checkout, so `git pull` here
# keeps the live config up to date. Safe to re-run.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/awesome"
QUICKSHELL_DIR="$HOME/.config/quickshell"
CACHE_DIR="$HOME/.cache/awesome"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
WALLPAPERS_DIR="$HOME/Pictures/wallpapers"

# Packages available in the official repos. base-devel + git are here so
# the AUR fallback build below (makepkg) always has what it needs.
PACMAN_PKGS=(
  base-devel git
  alacritty rofi xorg-xrandr xorg-xset polkit-gnome i3lock
  libnotify playerctl brightnessctl pavucontrol flameshot xclip
  thunar tumbler blueman
  ttf-jetbrains-mono-nerd ttf-font-awesome
)

# Not in the official repos -- installed from the AUR below, via an AUR
# helper if one is already present, otherwise by building directly.
AUR_PKGS=(quickshell openrgb)

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "  backing up existing $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
  echo "  linked $dst -> $src"
}

echo "==> Installing packages from official repos"
for pkg in "${PACMAN_PKGS[@]}"; do
  sudo pacman -S --needed --noconfirm "$pkg" || echo "  WARNING: failed to install $pkg, check the package name/repo"
done

aur_helper() {
  for helper in yay paru; do
    command -v "$helper" >/dev/null 2>&1 && { echo "$helper"; return 0; }
  done
  return 1
}

install_aur_pkg() {
  local pkg="$1" helper
  if command -v "$pkg" >/dev/null 2>&1; then
    echo "  $pkg: already installed"
    return 0
  fi
  if helper=$(aur_helper); then
    echo "  installing $pkg via $helper"
    "$helper" -S --needed --noconfirm "$pkg" || echo "  WARNING: $helper failed to install $pkg"
  else
    echo "  no AUR helper found; building $pkg directly from the AUR"
    local build_dir
    build_dir="$(mktemp -d)"
    if git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$build_dir/$pkg" \
        && (cd "$build_dir/$pkg" && makepkg -si --noconfirm); then
      :
    else
      echo "  WARNING: failed to build $pkg from the AUR"
    fi
    rm -rf "$build_dir"
  fi
}

echo "==> Installing AUR packages"
for pkg in "${AUR_PKGS[@]}"; do
  install_aur_pkg "$pkg"
done

# Not auto-installed: pipewire-pulse and pulseaudio both provide pactl and
# conflict with each other, so picking one here could silently replace
# whatever audio stack is already set up on this machine.
if ! command -v pactl >/dev/null 2>&1; then
  echo "  pactl: NOT FOUND -- volume keybinds need it; install pipewire-pulse or pulseaudio yourself"
fi

echo "==> Linking Awesome config into $CONFIG_DIR"
link "$REPO_DIR/config/rc.lua" "$CONFIG_DIR/rc.lua"
link "$REPO_DIR/config/theme.lua" "$CONFIG_DIR/theme.lua"
link "$REPO_DIR/config/wallpaper.jpg" "$CONFIG_DIR/wallpaper.jpg"

echo "==> Creating Awesome cache dir (for the quickshell tag-state file)"
mkdir -p "$CACHE_DIR"

echo "==> Linking quickshell bar into $QUICKSHELL_DIR"
chmod +x "$REPO_DIR/config/view-tag.sh"
link "$REPO_DIR/quickshell/shell.qml" "$QUICKSHELL_DIR/shell.qml"
link "$REPO_DIR/quickshell/nix-snowflake-white.svg" "$QUICKSHELL_DIR/nix-snowflake-white.svg"
link "$REPO_DIR/config/view-tag.sh" "$QUICKSHELL_DIR/awesome-view-tag.sh"

echo "==> Linking helper scripts into $BIN_DIR"
mkdir -p "$BIN_DIR"
for script in lock-screen power-menu toggle-hdmi polkit-agent; do
  chmod +x "$REPO_DIR/scripts/$script"
  link "$REPO_DIR/scripts/$script" "$BIN_DIR/$script"
done
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "  NOTE: $BIN_DIR is not on your PATH -- add it in ~/.bash_profile or ~/.profile" ;;
esac

echo "==> Installing quickshell systemd user service"
link "$REPO_DIR/systemd/quickshell.service" "$SYSTEMD_USER_DIR/quickshell.service"
systemctl --user daemon-reload
# Deliberately not `enable`d: the unit has no [Install] section by design --
# rc.lua itself (re)starts this service when Awesome's standalone session
# starts, rather than systemd auto-starting it at login.

echo "==> Linking wallpaper collection into $WALLPAPERS_DIR"
link "$REPO_DIR/wallpapers" "$WALLPAPERS_DIR"

echo
echo "Done."
echo
echo "Check: the xrandr monitor layout hardcoded in config/rc.lua and"
echo "scripts/toggle-hdmi matches the source machine's monitor setup --"
echo "update the output names/modes/resolutions if this machine differs."
