#!/usr/bin/env bash
# Deploys this repo's AwesomeWM config onto a base Void Linux + AwesomeWM
# install. Symlinks everything back into this repo's checkout, so `git pull`
# here keeps the live config up to date. Safe to re-run.
#
# Differs from install.sh (the Arch version) in two structural ways:
#   - xbps instead of pacman, with Void's package names.
#   - Void has no systemd; it uses runit. There's no equivalent of a
#     systemd --user service here, so quickshell is instead launched
#     directly and kept alive by a tiny supervising loop (see
#     scripts/quickshell-runsv below) rather than a service unit.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/awesome"
QUICKSHELL_DIR="$HOME/.config/quickshell"
CACHE_DIR="$HOME/.cache/awesome"
BIN_DIR="$HOME/.local/bin"
WALLPAPERS_DIR="$HOME/Pictures/wallpapers"

# Packages available in the official Void repos (void-packages).
XBPS_PKGS=(
  alacritty rofi xrandr xset polkit-gnome i3lock
  libnotify playerctl brightnessctl pavucontrol flameshot xclip
  Thunar tumbler blueman
  nerd-fonts font-awesome
)

# Not in the official Void repos as far as we know -- would need building
# from a void-packages template (xbps-src) or another manual source.
MANUAL_PKGS=(quickshell openrgb)

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

echo "==> Installing packages from official Void repos"
sudo xbps-install -Sy >/dev/null
for pkg in "${XBPS_PKGS[@]}"; do
  sudo xbps-install -y "$pkg" || echo "  WARNING: failed to install $pkg, check the package name"
done

echo "==> Checking packages with no official Void binary (need xbps-src or manual build)"
for pkg in "${MANUAL_PKGS[@]}"; do
  if command -v "$pkg" >/dev/null 2>&1; then
    echo "  $pkg: found"
  else
    echo "  $pkg: NOT FOUND -- not in the official repos; build via a void-packages"
    echo "    template (xbps-src) or from source"
  fi
done

if ! command -v pactl >/dev/null 2>&1; then
  echo "  pactl: NOT FOUND -- volume keybinds need it; install pulseaudio or pipewire (with pipewire-pulse)"
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
for script in lock-screen power-menu toggle-hdmi polkit-agent quickshell-runsv; do
  chmod +x "$REPO_DIR/scripts/$script"
  link "$REPO_DIR/scripts/$script" "$BIN_DIR/$script"
done
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "  NOTE: $BIN_DIR is not on your PATH -- add it in ~/.bash_profile or ~/.profile" ;;
esac

echo "==> Linking wallpaper collection into $WALLPAPERS_DIR"
link "$REPO_DIR/wallpapers" "$WALLPAPERS_DIR"

echo
echo "Done."
echo
echo "KNOWN GOTCHA (Void has no systemd): config/rc.lua restarts quickshell"
echo "via 'systemctl --user restart quickshell.service', which doesn't exist"
echo "on Void. Change that line in config/rc.lua to instead run:"
echo "    awful.spawn.with_shell(\"quickshell-runsv\")"
echo "which is the supervising wrapper just linked into $BIN_DIR -- it kills"
echo "any existing quickshell instance and relaunches it, restarting it"
echo "automatically if it ever dies, without needing a service manager."
echo
echo "KNOWN GOTCHA: config/rc.lua only takes that action when"
echo "\$DESKTOP_SESSION == \"none+awesome\" (a NixOS/lightdm-specific session"
echo "name). If this machine starts X via startx/.xinitrc rather than a"
echo "display manager, DESKTOP_SESSION won't be set at all unless you export"
echo "it yourself in .xinitrc before 'exec awesome' -- or just change the"
echo "check in config/rc.lua to whatever this machine actually sets."
echo
echo "Also check: the xrandr monitor layout hardcoded in config/rc.lua and"
echo "scripts/toggle-hdmi matches the source machine's monitor setup --"
echo "update the output names/modes/resolutions if this machine differs."
