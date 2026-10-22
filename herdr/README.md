# Herdr

Herdr is the application layer of the shared keyboard language: Windows uses
`Alt` for GlazeWM where Omarchy uses `Super`, while Herdr uses immediate `Ctrl`
bindings. `Shift` means move, reverse, or a higher-level variant.

Fresh runs *inside* Herdr panes, so both want the `Ctrl` layer and Herdr has no
pass-through mode. Herdr yields wherever Fresh has a claim: `Ctrl+T`/`W`/`B` moved
up to `Ctrl+Shift`, and pane focus/move, zoom and tab cycling moved to the `F12`
prefix. Fresh's `Ctrl+Alt` split layer never collides.

## Bindings

| Binding | Action |
|---|---|
| `Ctrl+Shift+T` / `Ctrl+Shift+W` | New tab / close pane |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous workspace |
| `F12 N` / `F12 P` | Next / previous tab |
| `Ctrl+1..9` | Select tab |
| `F12 H/J/K/L` | Focus pane |
| `F12 Shift+H/J/K/L` | Move pane |
| `Ctrl+Shift+B` / `Ctrl+G` | Sidebar / go to |
| `Ctrl+\` / `Ctrl+Shift+\` | Split vertically / horizontally |
| `F12 Z` | Zoom pane |
| `Ctrl+Shift+N` | New workspace |
| `Ctrl+Shift+G` | New worktree workspace |
| `F12 Shift+D` | Close workspace |
| `Ctrl+Shift+U` | Pick a URL or file path from the pane |

Herdr still needs a prefix for commands without a good native chord. It is `F12`,
and the original prefix forms remain alongside every remapped command.

## URL and path picker

foot's URL mode, for Herdr. Windows Terminal's mark-mode link hopping
(`Ctrl+Shift+M`, `Tab`) can't see pane output because Herdr draws the whole screen,
so [`url-picker.ps1`](url-picker.ps1) reads it through the API instead:

- `Ctrl+Shift+U` / `F12 U` → popup over the focused pane
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

The tracked Windows Terminal settings explicitly unbind these chords so they
reach Herdr. Use the `F12` fallbacks if a particular keyboard or terminal cannot
send one — and note WT keeps unbinding the plain `Ctrl` chords Herdr gave back,
because Fresh still needs them to fall through.
