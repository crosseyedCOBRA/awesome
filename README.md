# awesome-SUSE

AwesomeWM config, carried over from a NixOS/home-manager setup, for use on a base Arch Linux + AwesomeWM install (not openSUSE, despite the repo name).

## Install

Run `./install.sh` from a checkout of this repo. It installs packages with `pacman`, symlinks everything into place (backing up anything already there as `.bak`), and deploys the quickshell bar as a `systemd --user` service. Safe to re-run after a `git pull` to keep the live config in sync.

## Contents

- `config/rc.lua` — main Awesome config.
- `config/theme.lua` — theme.
- `config/wallpaper.jpg` — desktop wallpaper referenced by the theme.
- `config/view-tag.sh` — helper script invoked from the quickshell bar to switch Awesome tags; deployed to `~/.config/quickshell/awesome-view-tag.sh`.
- `quickshell/shell.qml` — the quickshell bar UI. **This file is shared with a Hyprland setup on the source system** — most of it is generic, but the tag-state polling (reads `~/.cache/awesome/tags.json`) and the calls to `awesome-view-tag.sh` are Awesome-specific. Keep that in mind if adapting or trimming it.
- `quickshell/nix-snowflake-white.svg` — distro-logo icon used in the bar. **This is literally the NixOS snowflake logo** — swap it for something else or drop that bar button, since the icon won't make sense on Arch.
- `scripts/lock-screen`, `scripts/power-menu`, `scripts/toggle-hdmi`, `scripts/polkit-agent` — small helper scripts `rc.lua`'s keybindings shell out to. Plain re-writes of what used to be Nix `writeShellScriptBin` derivations in `home.nix`; deployed to `~/.local/bin`.
- `systemd/quickshell.service` — `systemd --user` unit that runs the quickshell bar.
- `wallpapers/` — general wallpaper collection, copied from `~/Pictures/wallpapers` (78 files, ~87MB). Used by the Hyprland `wallpaper-picker`/`random-wallpaper` scripts in `home.nix`, not by Awesome directly (Awesome just uses `config/wallpaper.jpg`). Note: a near-duplicate folder, `~/Hyprland/wallpapers`, exists on the source system and differs by a few files — `Pictures/wallpapers` was chosen as the canonical copy.

## Known gotchas (not fixed by install.sh — need a manual edit to `rc.lua`)

- **Hardcoded monitor layout**: the `xrandr` call near the top of `rc.lua`, and `scripts/toggle-hdmi`, hardcode the source machine's exact outputs/modes/refresh rates (`DisplayPort-0/1/2`, `HDMI-A-0`). Update these if the target machine's monitor setup differs.
- **Packages with no official Arch binary**: `quickshell` and `openrgb` aren't in the official repos — `install.sh` just checks whether they're already on `$PATH` and prints a reminder to grab them from the AUR instead of attempting to install them.
