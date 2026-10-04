# awesome-SUSE

AwesomeWM config, carried over from a NixOS/home-manager setup, for use on a base Arch Linux + AwesomeWM install (not openSUSE, despite the repo name).

## Contents

- `config/rc.lua` — main Awesome config.
- `config/theme.lua` — theme.
- `config/wallpaper.jpg` — desktop wallpaper referenced by the theme.
- `config/view-tag.sh` — helper script invoked from the quickshell bar to switch Awesome tags; on the old system it was deployed to `~/.config/quickshell/awesome-view-tag.sh`.
- `quickshell/shell.qml` — the quickshell bar UI. **This file is shared with a Hyprland setup on the source system** — most of it is generic, but the tag-state polling (reads `~/.cache/awesome/tags.json`) and the calls to `awesome-view-tag.sh` are Awesome-specific. Keep that in mind if adapting or trimming it.
- `quickshell/nix-snowflake-white.svg` — distro-logo icon used in the bar. **This is literally the NixOS snowflake logo** — swap it for something else (e.g. an Arch logo) or drop that bar button once this is running on Arch, since the icon won't make sense there anymore.
- `wallpapers/` — general wallpaper collection, copied from `~/Pictures/wallpapers` (78 files, ~87MB). Used by the Hyprland `wallpaper-picker`/`random-wallpaper` scripts in `home.nix`, not by Awesome directly (Awesome just uses `config/wallpaper.jpg`). Note: a near-duplicate folder, `~/Hyprland/wallpapers`, exists on the source system and differs by a few files — `Pictures/wallpapers` was chosen as the canonical copy.

## Not yet ported (Nix-specific, needs manual equivalent on Arch)

The original NixOS config wired these up declaratively; on a base Arch + AwesomeWM install they'll need doing by hand (or via a future install script):

- Deploy `rc.lua`/`theme.lua`/`wallpaper.jpg` to `~/.config/awesome/`, and `view-tag.sh` to `~/.config/quickshell/awesome-view-tag.sh`.
- Ensure `~/.cache/awesome/` exists (rc.lua writes `tags.json` there for the quickshell bar).
- `pacman -S awesome` (should already be in place from the base Arch/AwesomeWM install) and confirm it's selected as the session at the display manager / in `~/.xinitrc`.
- Install a Nerd Font (the theme uses `JetBrainsMono Nerd Font`) and a Font Awesome package (AUR: `ttf-font-awesome`) for the icons the bar/theme use.
- `quickshell` itself isn't part of a base Awesome install — install it (AUR: `quickshell-git` or similar) if you want the bar from `quickshell/shell.qml`.
- The old config also had DPMS/screen-blanking and logout logic tied into `awesome-client 'awesome.quit()'` — check `rc.lua` for how that's invoked and make sure any replacement lock/power-menu scripts call it the same way.
