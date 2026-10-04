# awesome-SUSE

AwesomeWM config, carried over from a NixOS/home-manager setup, for use on a base Arch Linux or Void Linux + AwesomeWM install (not openSUSE, despite the repo name).

## Install

Run the script matching the target machine from a checkout of this repo:

- `./install.sh` — Arch Linux. Installs packages with `pacman`, deploys the quickshell bar as a `systemd --user` service.
- `./install-void.sh` — Void Linux. Installs packages with `xbps-install`. Void has no systemd, so the quickshell bar is instead launched and kept alive by `scripts/quickshell-runsv`, a small retry-loop wrapper.

Both scripts symlink everything into place (backing up anything already there as `.bak`), so re-running a script after a `git pull` keeps the live config in sync, and both print the same handful of gotchas at the end that need a manual look (see below).

## Contents

- `config/rc.lua` — main Awesome config.
- `config/theme.lua` — theme.
- `config/wallpaper.jpg` — desktop wallpaper referenced by the theme.
- `config/view-tag.sh` — helper script invoked from the quickshell bar to switch Awesome tags; deployed to `~/.config/quickshell/awesome-view-tag.sh`.
- `quickshell/shell.qml` — the quickshell bar UI. **This file is shared with a Hyprland setup on the source system** — most of it is generic, but the tag-state polling (reads `~/.cache/awesome/tags.json`) and the calls to `awesome-view-tag.sh` are Awesome-specific. Keep that in mind if adapting or trimming it.
- `quickshell/nix-snowflake-white.svg` — distro-logo icon used in the bar. **This is literally the NixOS snowflake logo** — swap it for something else or drop that bar button, since the icon won't make sense on Arch/Void.
- `scripts/lock-screen`, `scripts/power-menu`, `scripts/toggle-hdmi`, `scripts/polkit-agent` — small helper scripts `rc.lua`'s keybindings shell out to. Plain re-writes of what used to be Nix `writeShellScriptBin` derivations in `home.nix`; deployed to `~/.local/bin`.
- `scripts/quickshell-runsv` — Void only. Launches quickshell and relaunches it if it dies, standing in for the systemd user service used on Arch.
- `systemd/quickshell.service` — Arch only. `systemd --user` unit that runs the quickshell bar.
- `wallpapers/` — general wallpaper collection, copied from `~/Pictures/wallpapers` (78 files, ~87MB). Used by the Hyprland `wallpaper-picker`/`random-wallpaper` scripts in `home.nix`, not by Awesome directly (Awesome just uses `config/wallpaper.jpg`). Note: a near-duplicate folder, `~/Hyprland/wallpapers`, exists on the source system and differs by a few files — `Pictures/wallpapers` was chosen as the canonical copy.

## Known gotchas (not fixed by the install scripts — need a manual edit to `rc.lua`)

- **Quickshell restart trigger**: `rc.lua` only (re)starts quickshell when `$DESKTOP_SESSION == "none+awesome"`, a NixOS/lightdm-specific session name. On Arch with a different display manager, or on Void (which may have no display manager at all), that variable will likely be something else or unset, so the check silently never fires. Either change the check in `rc.lua` to match whatever `$DESKTOP_SESSION` actually is on the target machine, or (Arch) rely on the systemd service / (Void) call `quickshell-runsv` directly from Awesome's own autostart instead.
- **Hardcoded monitor layout**: the `xrandr` call near the top of `rc.lua`, and `scripts/toggle-hdmi`, hardcode the source machine's exact outputs/modes/refresh rates (`DisplayPort-0/1/2`, `HDMI-A-0`). Update these if the target machine's monitor setup differs.
- **Packages with no official binary package**: `quickshell` and `openrgb` aren't in Arch's official repos or Void's — both install scripts just check whether they're already on `$PATH` and print a reminder rather than attempting to install them (AUR for Arch; an `xbps-src` template or manual build for Void).
