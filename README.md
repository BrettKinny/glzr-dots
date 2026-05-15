# .glzr — Omarchy on Windows

**A faithful port of the [Omarchy](https://omarchy.org/) tiling-WM experience to Windows**, built on [GlazeWM](https://github.com/glzr-io/glazewm) + [Zebar](https://github.com/glzr-io/zebar). If you've used Omarchy (or Hyprland), your muscle memory works here — same keybinding layout, same workflow, same dwindle autotiling, just with `Alt` standing in for `Super` (Windows reserves it).

> Lives at `%USERPROFILE%\.glzr` — the default config path for both tools — so the repo *is* the config. No symlinks, no bootstrap script.

## Screenshots

<!-- Drop a screenshot in docs/ and uncomment:
![desktop](docs/desktop.png)
-->

## What this gives you

The goal is **Omarchy parity** — every binding below is the Omarchy default with `Super` swapped for `Alt`. If a workflow exists in Omarchy, it should work the same way here.

| Omarchy / Hyprland | This config | Notes |
|---|---|---|
| `Super` as mod key | `Alt` | Windows owns `Super` (Win key); using it as a mod conflicts with too many OS shortcuts. |
| `Super + 1..0` workspaces | `Alt + 1..0` | 10 workspaces, same layout. |
| `Super + Shift + N` to send window to workspace *and follow* | `Alt + Shift + N` | Same "follow" behavior — not vanilla GlazeWM default. |
| `Super + Arrows` focus, `Super + Shift + Arrows` move | `Alt + Arrows` / `Alt + Shift + Arrows` | Identical. |
| `Super + =/-` resize | `Alt + =/-` | Plus a vim-style `Alt + R` resize mode (`hjkl`). |
| `Super + Shift + B/E/F/...` app launchers | `Alt + Shift + B/E/F/...` | Same letters, mapped to Windows-native apps (Zen, Outlook, Explorer, VS Code, Obsidian, Teams, Gemini). |
| Hyprland dwindle layout | `autotile.py` | WebSocket client that flips split direction based on the focused window's longest axis. |
| Waybar top bar | Zebar with [`overline-zebar`](https://github.com/mushfikurr/overline-zebar) | Started automatically by GlazeWM; outer top gap reserves `50px` for it. |
| Focus-follows-cursor | ✅ | Plus cursor-jump on monitor focus change. |
| Tiling by default | ✅ | `initial_state: tiling`. |

Extras specific to Windows: window rules that ignore PowerToys overlays, browser picture-in-picture, Office sub-windows, Outlook reminders, and Lively wallpaper.

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [GlazeWM](https://github.com/glzr-io/glazewm) | Tiling WM | `winget install glzr-io.GlazeWM` |
| [Zebar](https://github.com/glzr-io/zebar) | Status bar | `winget install glzr-io.Zebar` |
| Python 3 + `websockets` | Autotile script | `winget install Python.Python.3.12` then `pip install websockets` |
| Windows Terminal | Default terminal binding | `winget install Microsoft.WindowsTerminal` |

**Strongly recommended:** [PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/) — install [Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview) as your app/file launcher (the Omarchy `walker`/`wofi` equivalent). `winget install Microsoft.PowerToys`

Optional (only needed if you use the matching launcher binding): Zen Browser, VS Code, Obsidian, Microsoft Teams, New Outlook.

## Install

Clone directly into the config location:

```powershell
# If ~/.glzr already exists (fresh install), move it aside first
Move-Item $env:USERPROFILE\.glzr $env:USERPROFILE\.glzr.bak -ErrorAction SilentlyContinue

git clone https://github.com/BrettKinny/glzr-dotfiles.git $env:USERPROFILE\.glzr
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

**Mod key:** <kbd>Alt</kbd> (stands in for Omarchy's <kbd>Super</kbd>). Everything else matches Omarchy 1:1 — read these tables as "Omarchy with `Super` → `Alt`".

### Window management

| Binding | Action | Omarchy equivalent |
|---|---|---|
| <kbd>Alt</kbd>+<kbd>W</kbd> | Close window | `Super + W` |
| <kbd>Alt</kbd>+<kbd>F</kbd> | Toggle fullscreen | `Super + F` |
| <kbd>Alt</kbd>+<kbd>T</kbd> | Toggle tiling/floating | `Super + T` |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd> | Toggle floating (centered) | `Super + Shift + V` |
| <kbd>Alt</kbd>+<kbd>J</kbd> | Toggle tiling direction | `Super + J` |
| <kbd>Alt</kbd>+<kbd>M</kbd> | Minimize | *(no Omarchy equivalent)* |

### Focus & move

| Binding | Action | Omarchy equivalent |
|---|---|---|
| <kbd>Alt</kbd>+<kbd>←</kbd>/<kbd>→</kbd>/<kbd>↑</kbd>/<kbd>↓</kbd> | Focus window | `Super + Arrows` |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>Arrows</kbd> | Move/swap window | `Super + Shift + Arrows` |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>Ctrl</kbd>+<kbd>Arrows</kbd> | Move workspace to monitor | `Super + Shift + Alt + Arrows` |

### Resize

| Binding | Action | Omarchy equivalent |
|---|---|---|
| <kbd>Alt</kbd>+<kbd>=</kbd>/<kbd>-</kbd> | Grow/shrink width 2% | `Super + =/-` |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>=</kbd>/<kbd>-</kbd> | Grow/shrink height 2% | `Super + Shift + =/-` |
| <kbd>Alt</kbd>+<kbd>R</kbd> | Vim-style resize mode (`hjkl`, `Esc` to exit) | *(extra)* |

### Workspaces

| Binding | Action | Omarchy equivalent |
|---|---|---|
| <kbd>Alt</kbd>+<kbd>1</kbd>…<kbd>0</kbd> | Focus workspace 1–10 | `Super + 1..0` |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>1</kbd>…<kbd>0</kbd> | Move window to workspace *and follow* | `Super + Shift + 1..0` |
| <kbd>Alt</kbd>+<kbd>Tab</kbd> / <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd> | Next / previous workspace | `Super + Tab` / `Super + Shift + Tab` |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>Tab</kbd> | Recent workspace | `Super + Ctrl + Tab` |

### Launchers

Same letters as Omarchy, mapped to Windows-native apps.

| Binding | App | Omarchy equivalent |
|---|---|---|
| <kbd>Alt</kbd>+<kbd>Enter</kbd> | Windows Terminal | `Super + Return` (terminal) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>B</kbd> | Zen browser | `Super + Shift + B` (browser) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | VS Code | `Super + Shift + N` (editor) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | File Explorer | `Super + Shift + F` (file manager) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> | Obsidian | `Super + Shift + O` (Obsidian) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> | Outlook (mail) | `Super + Shift + E` (email) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>C</kbd> | Outlook calendar (Edge PWA) | `Super + Shift + C` (calendar) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd> | Microsoft Teams | `Super + Shift + G` (messaging) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>A</kbd> | Gemini (Edge PWA) | `Super + Shift + A` (AI) |

### WM control

| Binding | Action |
|---|---|
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | Reload config |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> | Pause WM |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>W</kbd> | Redraw all windows |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>Q</kbd> | Exit WM |

### Known deviations from Omarchy

- **Mod key is `Alt`, not `Super`.** Windows hard-binds many `Super` (Win key) chords to OS-level actions (search, snap layouts, etc.) — using `Super` as the WM mod is a constant fight. `Alt` is the cleanest substitute.
- **Exit is `Alt + Ctrl + Q`**, not `Super + Shift + E` — that letter is reserved here for the Outlook launcher to match Omarchy's email binding.
- **No app-rofi / launcher menu.** Recommended to pair with [PowerToys Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview) as your launcher — it fills the same role as `walker` / `wofi` / `rofi` on Omarchy.

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
