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

Herdr reads `%APPDATA%\herdr`. Keep the repo as the source of truth with a
directory junction (no administrator shell required):

```powershell
Move-Item $env:APPDATA\herdr $env:APPDATA\herdr.bak -ErrorAction SilentlyContinue
cmd /c mklink /J "$env:APPDATA\herdr" "$env:USERPROFILE\.glzr\herdr"
herdr server reload-config
```

The tracked Windows Terminal settings explicitly unbind these chords so they
reach Herdr. Herdr deliberately owns them before a shell or nested TUI does;
use its `F12` fallbacks if a particular keyboard or terminal cannot send one.
