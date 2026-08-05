# Herdr

Herdr is the application layer of the shared keyboard language: Windows uses
`Alt` for GlazeWM where Omarchy uses `Super`, while Herdr uses immediate `Ctrl`
bindings. `Shift` means move, reverse, or a higher-level variant.

## Bindings

| Binding | Action |
|---|---|
| `Ctrl+T` / `Ctrl+W` | New tab / close pane |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab |
| `Ctrl+1..9` | Select tab |
| `Ctrl+Arrow` | Focus pane |
| `Ctrl+Shift+Arrow` | Move pane |
| `Ctrl+B` / `Ctrl+G` | Sidebar / go to |
| `Ctrl+\` / `Ctrl+Shift+\` | Split vertically / horizontally |
| `Ctrl+Shift+Z` | Zoom pane |
| `Ctrl+Shift+N` | New workspace |

Herdr still needs a prefix for commands without a good native chord. It is `F12`,
and the original prefix forms remain alongside every remapped command.

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

That is also why the machine-agnostic preferences at the top of `config.toml`
(`onboarding`, `[ui.toast]`, `[theme]`, `[terminal] default_shell`) live here
rather than in `%APPDATA%`: both machines should get them from `git pull`, which
is then the entire sync story. There is no layering, so anything genuinely
per-machine has nowhere to go — nothing here needs it yet.

## Key ownership

The tracked Windows Terminal settings explicitly unbind these chords so they
reach Herdr. Herdr deliberately owns them before a shell or nested TUI does;
use its `F12` fallbacks if a particular keyboard or terminal cannot send one.
