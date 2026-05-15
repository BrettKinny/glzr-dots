# glzr configs

Version-controlled GlazeWM + Zebar configuration.

## Layout

- `glazewm/config.yaml` — GlazeWM keybindings, workspaces, window rules
- `glazewm/autotile.py` — autotiling helper script
- `zebar/settings.json` — Zebar startup config (which pack/widget/preset to launch)
- `zebar/.marketplace/*.json` — installed marketplace widget references

## Setting up on a new PC

1. Install [GlazeWM](https://github.com/glzr-io/glazewm) and [Zebar](https://github.com/glzr-io/zebar).
2. Clone this repo to `%USERPROFILE%\.glzr`:
   ```powershell
   git clone <repo-url> $env:USERPROFILE\.glzr
   ```
   If `.glzr` already exists from a fresh install, back it up or clone elsewhere and copy contents in.
3. Open Zebar once so it can pull down the marketplace widgets referenced in `zebar/.marketplace/`.
4. Start GlazeWM.
