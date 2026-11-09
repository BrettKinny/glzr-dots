# ttt

Config for [ttt](https://github.com/eugenioenko/ttt): `settings.json`, `keybindings.json`
(defaults + GlazeWM-clash overrides, see [`../KEYBOARD.md`](../KEYBOARD.md)), `plugins.ttt.json`.

## Wiring

ttt defaults to `~/.config/ttt`, but honours **`TTT_CONFIG_DIR`**, so this dir *is* the config.

```powershell
# Run once per machine:
[Environment]::SetEnvironmentVariable(
    'TTT_CONFIG_DIR', "$env:USERPROFILE\.glzr\ttt", 'User')
```

Restart GlazeWM + herdr after setting it: their children inherit the old env, and
`reuseWindow` forwarding only matches instances with the same config dir.

Untracked: `plugins/` (reinstall from `plugins.ttt.json` via the Plugins panel;
`bitbucket-review` is its own repo), `state.json`.

`spell.filetypes` maps `Markdown` → `markdown`: ttt reports the language capitalised but
the spell plugin only matches lowercase, so without it Markdown is never checked.
