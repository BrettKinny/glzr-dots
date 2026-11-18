# Herdr

Layers: `Alt` = OS (GlazeWM; `Super` on Omarchy), `Ctrl+Shift` = Herdr,
`Ctrl` = the focused app. `Ctrl+Alt` is out: Omarchy's physical Alt is `Super`.

ttt runs *inside* Herdr panes and Herdr has no pass-through mode, so Herdr takes
no plain `Ctrl` chord except `Ctrl+Tab`. Everything else direct is a `Ctrl+Shift` chord
ttt doesn't bind, so ttt only loses `Ctrl+Tab` / `Ctrl+Shift+Tab` inside a pane; the rest
is on the `F9` prefix.

## Bindings

| Binding | Action |
|---|---|
| `Ctrl+Shift+T` / `Ctrl+Shift+W` | New tab / close pane |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous workspace |
| `Ctrl+Alt+←` / `Ctrl+Alt+→` | Focus pane left / right |
| `Ctrl+Shift+1..9` | Select tab |
| `Ctrl+Shift+.` / `Ctrl+Shift+,` | Next / previous tab (also `F9 N` / `F9 P`) |
| `F9 Shift+1..9` | Focus Nth agent |
| `F9 H/J/K/L` | Focus pane |
| `F9 Shift+H/J/K/L` | Move pane |
| `Ctrl+Shift+B` / `F9 G` | Sidebar / go to |
| `Ctrl+Shift+\` / `Ctrl+Shift+-` | Split vertically / horizontally |
| `F9 Z` | Zoom pane |
| `Ctrl+Shift+N` / `Ctrl+Shift+R` | New / rename workspace |
| `Ctrl+Shift+Y` / `F9 Shift+O` | New worktree workspace / open on-disk worktree |
| `F9 Shift+D` | Close workspace |
| `Ctrl+Shift+J` | Jump to latest notification's pane |
| `Ctrl+Shift+Q` | Detach |
| `Ctrl+Shift+U` | Pick a URL or file path from the pane |
| `Ctrl+?` | Help |
| `F9 E` | Side ttt: open / toggle focus |

Every command also answers to its `F9` prefix form.

## URL and path picker

foot's URL mode, for Herdr. Windows Terminal's mark-mode link hopping
(`Ctrl+Shift+M`, `Tab`) can't see pane output because Herdr draws the whole screen,
so [`url-picker.ps1`](url-picker.ps1) reads it through the API instead:

- `Ctrl+Shift+U` / `F9 U` → popup over the focused pane
- `herdr pane read --source recent-unwrapped` → URLs + file paths, newest first
- Paths kept only if they exist on disk (relative → pane cwd, `:line:col` stripped)
- `Enter` opens with the default app, `Ctrl+Y` copies
- Needs `fzf` on `PATH`. Windows-only (`[[keys.command]]` runs through `cmd.exe`),
  so it isn't mirrored to Omarchy

## Wiring

Herdr defaults to `%APPDATA%\herdr\config.toml`, but honours
**`HERDR_CONFIG_PATH`** — so this file *is* the config, with no link and no copy.
Same escape hatch as [`../fresh/`](../fresh/README.md), which is passed with
`--config` for the same reason.

```powershell
# Run once per machine:
[Environment]::SetEnvironmentVariable(
    'HERDR_CONFIG_PATH', "$env:USERPROFILE\.glzr\herdr\config.toml", 'User')

herdr server stop   # the server resolves its config path at startup
herdr              # relaunch; `herdr --help` prints the path it resolved
```

`herdr server stop` **ends the current session and every pane in it**, so run it
when you're not mid-task. The `User`-scope variable is what makes GUI-launched
Herdr see the path too, not just shells that have sourced a profile.

Verify with `herdr --help`, which prints the resolved `Config:` line, and
`herdr config check`, which parses it and prints diagnostics.

> **`herdr server reload-config` cannot pick up a config-path change** — only
> edits to the path the running server already resolved. Set the variable, then
> restart. Until you do, Herdr runs its old config while the tracked Windows
> Terminal settings have already unbound these chords, leaving them dead.

### Why not a junction or a copy

`%APPDATA%\herdr` is not a config directory. It also holds `herdr-server.log`,
`herdr-client.log`, `herdr.sock`, `herdr-client.sock`, `session.json` and
`.plugins.lock` — junction it and all of that lands in the working tree. The
same objection [`../windows-terminal/`](../windows-terminal/README.md) raises
against junctioning `LocalState\`.

A copy, or appending just the `[keys]` block into the live file, is worse across
two machines: nothing in git then represents what either machine runs, live and
repo legitimately differ so there is no hash check for drift, and a second append
produces a duplicate `[keys]` table — a hard TOML error rather than a merge.

### Herdr writes this file

Settings toggled in Herdr's UI are written back to `config.toml` (and
`herdr config reset-keys` backs it up and strips custom keybindings). With
`HERDR_CONFIG_PATH` pointed here, those writes land **in the repo**, so
`git status` surfaces them and you can commit or discard them deliberately.
Expect reformatting and key reordering, as with Windows Terminal's settings UI.

That is also why the portable preferences at the top of `config.toml`
(`onboarding`, `[ui.toast]`, and `[theme]`) live here rather than in
`%APPDATA%`. The companion Omarchy repository mirrors those values and the
`[keys]` table; Windows alone adds `[terminal] default_shell = "pwsh"`.
There is no config layering, so genuinely per-machine values must remain
explicitly platform-specific.

## Key ownership

The tracked Windows Terminal settings unbind WT's own `Ctrl+Shift` chords so they
reach Herdr. WT drops `Ctrl+Shift+digit`, so they translate `Ctrl+Shift+1..9` to
`F9` + digit (see [`../windows-terminal/`](../windows-terminal/README.md)).
