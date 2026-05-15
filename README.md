# .glzr

My personal [GlazeWM](https://github.com/glzr-io/glazewm) + [Zebar](https://github.com/glzr-io/zebar) dotfiles for Windows. A tiling window manager setup inspired by [Omarchy](https://omarchy.org/) / Hyprland, adapted for Windows ergonomics.

> Lives at `%USERPROFILE%\.glzr` — the default config path for both tools — so the repo *is* the config. No symlinks, no bootstrap script.

## Screenshots

<!-- Drop a screenshot in docs/ and uncomment:
![desktop](docs/desktop.png)
-->

## Features

- **Omarchy-style keybindings** — `Alt` is the mod key (Windows reserves `Super`), with the same muscle-memory layout as Omarchy/Hyprland.
- **Autotiling** — `autotile.py` subscribes to GlazeWM's WebSocket and switches split direction based on the focused window's aspect ratio (dwindle layout).
- **Zebar top bar** — runs the [`overline-zebar`](https://github.com/mushfikurr/overline-zebar) widget pack at startup; outer gap reserves `50px` at the top for it.
- **Focus-follows-cursor** with cursor jump on monitor focus change.
- **App launcher bindings** for terminal, browser, editor, Outlook, Teams, Obsidian, etc.
- **Sensible window rules** that ignore PowerToys overlays, PiP windows, Office sub-windows, Outlook reminders, and Lively wallpaper.

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [GlazeWM](https://github.com/glzr-io/glazewm) | Tiling WM | `winget install glzr-io.GlazeWM` |
| [Zebar](https://github.com/glzr-io/zebar) | Status bar | `winget install glzr-io.Zebar` |
| Python 3 + `websockets` | Autotile script | `winget install Python.Python.3.12` then `pip install websockets` |
| Windows Terminal | Default terminal binding | `winget install Microsoft.WindowsTerminal` |

Optional (only needed if you use the matching launcher binding): Zen Browser, VS Code, Obsidian, Microsoft Teams, New Outlook.

## Install

Clone directly into the config location:

```powershell
# If ~/.glzr already exists (fresh install), move it aside first
Move-Item $env:USERPROFILE\.glzr $env:USERPROFILE\.glzr.bak -ErrorAction SilentlyContinue

git clone https://github.com/<you>/dotfiles-glzr.git $env:USERPROFILE\.glzr
pip install websockets
```

Then launch GlazeWM — it will start Zebar and the autotile script automatically via `startup_commands`.

## Structure

```
.glzr/
├── glazewm/
│   ├── config.yaml      # keybindings, workspaces, gaps, window rules
│   └── autotile.py      # dwindle-layout autotiler (WebSocket client)
└── zebar/
    ├── settings.json    # startup widget (overline-zebar / main / default)
    └── .marketplace/    # references to installed marketplace packs
```

## Keybindings

Mod key: <kbd>Alt</kbd>

### Window management

| Binding | Action |
|---|---|
| <kbd>Alt</kbd>+<kbd>W</kbd> | Close window |
| <kbd>Alt</kbd>+<kbd>F</kbd> | Toggle fullscreen |
| <kbd>Alt</kbd>+<kbd>T</kbd> | Toggle tiling/floating |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd> | Toggle floating (centered) |
| <kbd>Alt</kbd>+<kbd>M</kbd> | Minimize |
| <kbd>Alt</kbd>+<kbd>J</kbd> | Toggle tiling direction |

### Focus & move

| Binding | Action |
|---|---|
| <kbd>Alt</kbd>+<kbd>←</kbd>/<kbd>→</kbd>/<kbd>↑</kbd>/<kbd>↓</kbd> | Focus window |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>Arrows</kbd> | Move/swap window |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>Ctrl</kbd>+<kbd>Arrows</kbd> | Move workspace to monitor |

### Resize

| Binding | Action |
|---|---|
| <kbd>Alt</kbd>+<kbd>=</kbd>/<kbd>-</kbd> | Grow/shrink width 2% |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>=</kbd>/<kbd>-</kbd> | Grow/shrink height 2% |
| <kbd>Alt</kbd>+<kbd>R</kbd> | Enter vim-style resize mode (`hjkl`, `Esc` to exit) |

### Workspaces

| Binding | Action |
|---|---|
| <kbd>Alt</kbd>+<kbd>1</kbd>…<kbd>0</kbd> | Focus workspace 1–10 |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>1</kbd>…<kbd>0</kbd> | Move window to workspace *and follow* |
| <kbd>Alt</kbd>+<kbd>Tab</kbd> / <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd> | Next / previous workspace |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>Tab</kbd> | Recent workspace |

### Launchers

| Binding | App |
|---|---|
| <kbd>Alt</kbd>+<kbd>Enter</kbd> | Windows Terminal |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>B</kbd> | Zen browser |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | VS Code |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | File Explorer |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> | Obsidian |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> | Outlook (mail) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>C</kbd> | Outlook calendar (Edge PWA) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd> | Microsoft Teams |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>A</kbd> | Gemini (Edge PWA) |

### WM control

| Binding | Action |
|---|---|
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | Reload config |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> | Pause WM |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>W</kbd> | Redraw all windows |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>Q</kbd> | Exit WM |

## Customization

- **Change the mod key**: search/replace `alt+` in `glazewm/config.yaml`. Note that `lwin+` / `rwin+` work but collide with many Windows shortcuts.
- **Top bar height**: adjust `gaps.outer_gap.top` in `config.yaml` to match your Zebar height.
- **Swap the Zebar pack**: edit `zebar/settings.json` → `startupConfigs[].pack` to any pack listed in `zebar/.marketplace/`.
- **Border color**: `window_effects.focused_window.border.color` (currently `#8dbcff`).

## Credits

- [Omarchy](https://omarchy.org/) — keybinding philosophy and defaults
- [`mushfikurr/overline-zebar`](https://github.com/mushfikurr/overline-zebar) — the Zebar pack this config launches
- [glzr-io](https://github.com/glzr-io) — for GlazeWM and Zebar themselves

## License

MIT — do whatever you want with it.
