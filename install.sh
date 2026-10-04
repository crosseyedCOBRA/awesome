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

# Packages available in the official repos.
PACMAN_PKGS=(
  alacritty rofi xorg-xrandr xorg-xset polkit-gnome i3lock
  libnotify playerctl brightnessctl pavucontrol flameshot xclip
  thunar tumbler blueman
  ttf-jetbrains-mono-nerd ttf-font-awesome
)

# AUR-only, or uncertain enough across Arch/distro versions that we just
# check for them rather than risk a failed pacman transaction.
AUR_OR_MANUAL_PKGS=(quickshell openrgb)

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

echo "==> Checking AUR-only / manual-install packages"
for pkg in "${AUR_OR_MANUAL_PKGS[@]}"; do
  if command -v "$pkg" >/dev/null 2>&1; then
    echo "  $pkg: found"
  else
    echo "  $pkg: NOT FOUND -- install from the AUR (e.g. 'yay -S $pkg' or '$pkg-git')"
  fi
done

if ! command -v pactl >/dev/null 2>&1; then
  echo "  pactl: NOT FOUND -- volume keybinds need it; install pipewire-pulse or pulseaudio"
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
systemctl --user enable quickshell.service

echo "==> Linking wallpaper collection into $WALLPAPERS_DIR"
link "$REPO_DIR/wallpapers" "$WALLPAPERS_DIR"

echo
echo "Done."
echo
echo "Check: the xrandr monitor layout hardcoded in config/rc.lua and"
echo "scripts/toggle-hdmi matches the source machine's monitor setup --"
echo "update the output names/modes/resolutions if this machine differs."
