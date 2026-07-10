# glzr-dots (Omarchy\* on Windows)

<sub>\* Omarchy is ofcouse Linux; this recreates the experience on Windows with [GlazeWM](https://github.com/glzr-io/glazewm) + a top bar that's either the [Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview) Dock (default) or [Zebar](https://github.com/glzr-io/zebar).</sub>

**A faithful port of the [Omarchy](https://omarchy.org/) tiling-WM experience to Windows.** If you've used Omarchy (or Hyprland), your muscle memory works here: same keybinding layout, same workflow, same dwindle autotiling, just with `Alt` standing in for `Super` (Windows reserves it).

> Lives at `%USERPROFILE%\.glzr` (the default config path for both tools), so the repo *is* the config. No symlinks, no bootstrap script.

> 💡 **Cross-machine muscle memory:** if you dual-boot or jump between Omarchy and Windows, flip Omarchy's "Hyprland mod key" setting to <kbd>Alt</kbd> (Omarchy ships a built-in toggle to swap <kbd>Super</kbd> ↔ <kbd>Alt</kbd> as the mod). Then *every* binding in this README works identically on both systems. No mental remapping when switching machines.

## Screenshot

![Desktop showing Zebar top bar, PowerToys Command Palette launcher, and Workspace 1 indicator](https://github.com/user-attachments/assets/b1208277-29e8-4691-b3b7-03f548c96fb6)

*Top: the Zebar bar option (overline-zebar pack) with workspace switcher, system stats, tray, and clock. Center: PowerToys Command Palette acting as the launcher. (The default bar is now the Command Palette Dock — see [Choose your bar](#choose-your-bar).)*

![Desktop screenshot](https://github.com/user-attachments/assets/39d227c9-81ea-4316-b2f6-89268770e6d0)

*lazygit on the left, fastfetch on the right, both running in minimal Terminal windows with Oh My Posh.*

## What this gives you

The goal is **Omarchy parity**: every binding below is the Omarchy default with `Super` swapped for `Alt`. If a workflow exists in Omarchy, it should work the same way here.

| Omarchy / Hyprland | This config | Notes |
|---|---|---|
| `Super` as mod key | `Alt` | Windows owns `Super` (Win key); using it as a mod conflicts with too many OS shortcuts. |
| `Super + 1..0` workspaces | `Alt + 1..0` | 10 workspaces, same layout. |
| `Super + Shift + N` to send window to workspace *and follow* | `Alt + Shift + N` | Same "follow" behavior (not vanilla GlazeWM default). |
| `Super + Arrows` focus, `Super + Shift + Arrows` move | `Alt + Arrows` / `Alt + Shift + Arrows` | Identical. |
| `Super + =/-` resize | `Alt + =/-` | Plus a vim-style `Alt + R` resize mode (`hjkl`). |
| `Super + Shift + B/E/F/...` app launchers | `Alt + Shift + B/E/F/...` | Same letters, mapped to Windows-native apps (Zen, Outlook, Explorer, VS Code, Obsidian, Teams, Gemini). |
| Hyprland dwindle layout | `autotile.py` | WebSocket client that flips split direction based on the focused window's longest axis. |
| Lone window centered on ultrawides | `autotile.py` | On a monitor wider than ~2:1, a single window in a workspace floats centered at half the monitor width instead of stretching edge-to-edge; opening a second window drops it back to tiling. No-op on 16:9 displays. |
| Waybar top bar | Command Palette Dock *(default)* or Zebar with [`overline-zebar`](https://github.com/mushfikurr/overline-zebar) | Two options — see [Choose your bar](#choose-your-bar). The Dock reserves its own space (AppBar); Zebar needs a `50px` top gap. |
| Focus-follows-cursor | ✅ | Plus cursor-jump on monitor focus change. |
| Tiling by default | ✅ | `initial_state: tiling`. |
| `Super + C/V/X` universal clipboard | `Alt + C/V/X` via `clipboard.py` | Sends `Ctrl+Insert` / `Shift+Insert` / `Ctrl+X` — works in terminals *and* GUI. `Alt + Ctrl + V` opens the `Win+V` history. |

Extras specific to Windows: window rules that ignore PowerToys overlays, browser picture-in-picture, Office sub-windows, Outlook reminders, and Lively wallpaper.

## Choose your bar

The top bar (workspace switcher + status) can be one of two things. **This repo ships with the Command Palette Dock as the active default** — `gaps.outer_gap.top` is `2px` and no bar is launched from `startup_commands`. Zebar is a one-uncomment fallback.

| | Command Palette Dock *(default)* | Zebar |
|---|---|---|
| What it is | A [Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview) extension (**GlazeWMDock**, see [`cmdpal/`](cmdpal/)) that renders the workspace strip on the CmdPal Dock | Standalone status bar app with the [`overline-zebar`](https://github.com/mushfikurr/overline-zebar) pack |
| Install | Command Palette gallery → *GlazeWM Workspaces* *(Store listing pending; sideload meanwhile — see [`cmdpal/`](cmdpal/))* | `winget install glzr-io.Zebar` + install the pack from the Marketplace |
| Screen space | Reserves its own via the Windows AppBar API → keep `outer_gap.top: 2px` | Overlay bar → set `outer_gap.top: 50px` |
| Shows | Workspace numbers as glyphs (filled = focused, outline = active, plain = empty) | Full widgets: workspaces, system stats, tray, clock |
| Startup | None — enabled in Command Palette settings | `shell-exec zebar` in `startup_commands` |

**Use the Dock (default):** install the extension (see [`cmdpal/`](cmdpal/)), then in Command Palette — Settings → enable Dock (Position = Top) → Bands → toggle **GlazeWM Workspaces** on.

**Switch to Zebar:** in `glazewm/config.yaml`, uncomment the `shell-exec zebar` line in `startup_commands`, set `shutdown_commands` to `['shell-exec taskkill /IM zebar.exe /F']`, and set `gaps.outer_gap.top` to `50px`. Then do the Zebar pack step in [Install](#install).

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [GlazeWM](https://github.com/glzr-io/glazewm) | Tiling WM | `winget install glzr-io.GlazeWM` |
| [PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/) (Command Palette) | Launcher + the default top bar (Dock) | `winget install Microsoft.PowerToys` |
| [Zebar](https://github.com/glzr-io/zebar) | *Alternative* top bar (only if you don't use the Dock) | `winget install glzr-io.Zebar` |
| Python 3 + `websockets` | Autotile script | `winget install Python.Python.3.12` then `pip install websockets` |
| Windows Terminal | Default terminal binding | `winget install Microsoft.WindowsTerminal` |

**PowerToys / [Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview)** does double duty here: it's your app/file launcher (the Omarchy `walker`/`wofi` equivalent) *and*, via the [GlazeWMDock](cmdpal/) extension, the default top bar. `winget install Microsoft.PowerToys`

Optional (only needed if you use the matching launcher binding): Zen Browser, VS Code, Obsidian, Microsoft Teams, New Outlook.

## Install

Clone directly into the config location:

```powershell
# If ~/.glzr already exists (fresh install), move it aside first
Move-Item $env:USERPROFILE\.glzr $env:USERPROFILE\.glzr.bak -ErrorAction SilentlyContinue

git clone https://github.com/BrettKinny/glzr-dots.git $env:USERPROFILE\.glzr
pip install websockets
```

**Set up your top bar.** The default is the Command Palette Dock; Zebar is the alternative. See [Choose your bar](#choose-your-bar) for the full comparison.

- **Command Palette Dock (default):** install the [GlazeWMDock](cmdpal/) extension and enable it in Command Palette — details in [`cmdpal/`](cmdpal/). Nothing to launch from GlazeWM; the Dock lives with Command Palette.
- **Zebar (alternative):** this repo ships only the *pointer* to `mushfikurr.overline-zebar` (in `zebar/.marketplace/`); the widget code lives in `%APPDATA%\zebar\downloads\` and isn't versioned here. Launch Zebar, open the Marketplace UI, install **overline-zebar** by `mushfikurr`, then restart Zebar. Also make the config edits noted in [Choose your bar](#choose-your-bar).

Then launch GlazeWM. It starts the autotile and clipboard scripts automatically via `startup_commands` (and Zebar too, if you enabled that option).

## Structure

```
.glzr/
├── glazewm/
│   ├── config.yaml      # keybindings, workspaces, gaps, window rules
│   ├── autotile.py      # dwindle-layout autotiler (WebSocket client)
│   └── clipboard.py     # Omarchy-style universal clipboard (Alt+C/V/X) — ctypes keyboard hook
├── cmdpal/
│   └── README.md        # pointer to the GlazeWMDock Command Palette Dock extension (default bar)
├── zebar/
│   ├── settings.json    # startup widget (overline-zebar / main / default) — alternative bar
│   └── .marketplace/    # references to installed marketplace packs
├── powershell/
│   └── profile.ps1      # shell profile (zoxide, fzf, eza, bat, PSReadLine)
└── omarchy/
    └── bindings.conf    # Omarchy-side clipboard override (copy into ~/.config/hypr/bindings.conf)
```

## Shell (PowerShell)

Brings the modern-Linux terminal niceties to PowerShell 7+. `powershell/profile.ps1` is the real profile; everything in it is **guarded with `Get-Command`**, so it loads cleanly on a fresh machine and each feature lights up only once its tool is installed.

| Tool | Gives you | Install |
|------|-----------|---------|
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `z <dir>` frecency jump, `zi` interactive picker | `winget install ajeetdsouza.zoxide` |
| [fzf](https://github.com/junegunn/fzf) + [PSFzf](https://github.com/kelleyma49/PSFzf) | <kbd>Ctrl</kbd>+<kbd>T</kbd> fuzzy file finder, <kbd>Ctrl</kbd>+<kbd>R</kbd> history | `winget install junegunn.fzf` + `Install-Module PSFzf` |
| [fd](https://github.com/sharkdp/fd) | fast file walk behind fzf (skips `.git`, respects `.gitignore`) | `winget install sharkdp.fd` |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting; powers the <kbd>Ctrl</kbd>+<kbd>T</kbd> preview | `winget install sharkdp.bat` |
| [eza](https://github.com/eza-community/eza) | `ls`/`ll`/`la`/`lt` with git status, icons, tree | `winget install eza-community.eza` |
| [delta](https://github.com/dandavison/delta) | syntax-highlighted git diffs (configured in `~/.gitconfig`) | `winget install dandavison.delta` |
| [gsudo](https://github.com/gerardog/gsudo) | `sudo` for Windows (aliased only if no native `sudo`) | `winget install gerardog.gsudo` |
| [oh-my-posh](https://ohmyposh.dev/) | prompt | `winget install JanDeDobbeleer.OhMyPosh` |

Plus `which` and `touch` helpers for muscle memory.

**Wiring:** unlike GlazeWM/Zebar, PowerShell's profile path isn't `~/.glzr`, so it can't live in the repo directly. Instead the real `$PROFILE` is a one-line shim that sources this one:

```powershell
# Point your $PROFILE at the repo copy (run once):
$shim = '$glzrProfile = "$HOME\.glzr\powershell\profile.ps1"' + "`n" + 'if (Test-Path $glzrProfile) { . $glzrProfile }'
New-Item -ItemType File -Path $PROFILE -Force | Out-Null
Set-Content -Path $PROFILE -Value $shim
. $PROFILE
```

**delta** also needs a few lines in `~/.gitconfig` (not tracked here):

```powershell
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global merge.conflictStyle zdiff3
```

## Keybindings

**Mod key:** <kbd>Alt</kbd> (stands in for Omarchy's <kbd>Super</kbd>). Everything else matches Omarchy 1:1; read these tables as "Omarchy with `Super` → `Alt`".

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

### Clipboard

Omarchy's trick: `Super + C` doesn't send `Ctrl+C` (which is SIGINT in a terminal) — it sends `Ctrl+Insert`, the legacy CUA combo that copies in *both* terminals and GUI apps. This config does the same with `Alt` as the trigger, via a small stdlib `ctypes` keyboard hook (`glazewm/clipboard.py`, started at login by `startup_commands`). Native `Ctrl+C` / `Ctrl+V` keep working as a fallback.

| Binding | Action | Sends | Omarchy equivalent |
|---|---|---|---|
| <kbd>Alt</kbd>+<kbd>C</kbd> | Copy | `Ctrl+Insert` | `Super + C` |
| <kbd>Alt</kbd>+<kbd>V</kbd> | Paste | `Shift+Insert` | `Super + V` |
| <kbd>Alt</kbd>+<kbd>X</kbd> | Cut (GUI only) | `Ctrl+X` | `Super + X` |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>V</kbd> | Clipboard history | `Win+V` | `Super + Ctrl + V` (walker) |

> `Win+V` needs Clipboard History enabled once (Settings → Clipboard, or press it and accept the prompt). If the hook ever isn't running, native `Ctrl+C`/`Ctrl+V` still work.

**Omarchy side (for true cross-machine parity):** Omarchy's `clipboard.conf` hardcodes `Super` and is *not* covered by its Super↔Alt mod toggle, so flipping the mod key leaves copy/paste on `Super`. To put it on `Alt` to match this config, add to `~/.config/hypr/bindings.conf` (sourced last, highest priority):

```conf
unbind = SUPER, C
unbind = SUPER, V
unbind = SUPER, X
unbind = SUPER CTRL, V

bindd = ALT, C, Universal copy, sendshortcut, CTRL, Insert, activewindow
bindd = ALT, V, Universal paste, sendshortcut, SHIFT, Insert, activewindow
bindd = ALT, X, Universal cut, sendshortcut, CTRL, X, activewindow
bindd = ALT CTRL, V, Clipboard manager, exec, omarchy-launch-walker -m clipboard
```

### WM control

| Binding | Action |
|---|---|
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | Reload config |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> | Pause WM |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>W</kbd> | Redraw all windows |
| <kbd>Alt</kbd>+<kbd>Ctrl</kbd>+<kbd>Q</kbd> | Exit WM |

### Known deviations from Omarchy

- **Mod key is `Alt`, not `Super`.** Windows hard-binds many `Super` (Win key) chords to OS-level actions (search, snap layouts, etc.), so using `Super` as the WM mod is a constant fight. `Alt` is the cleanest substitute.
- **Exit is `Alt + Ctrl + Q`**, not `Super + Shift + E`. That letter is reserved here for the Outlook launcher to match Omarchy's email binding.
- **No app-rofi / launcher menu.** Recommended to pair with [PowerToys Command Palette](https://learn.microsoft.com/en-us/windows/powertoys/command-palette/overview) as your launcher; it fills the same role as `walker` / `wofi` / `rofi` on Omarchy.

## Customization

- **Change the mod key**: search/replace `alt+` in `glazewm/config.yaml`. Note that `lwin+` / `rwin+` work but collide with many Windows shortcuts.
- **Top bar height**: `gaps.outer_gap.top` in `config.yaml`. The Dock reserves its own space, so leave it small (`2px`); for Zebar, set it to the bar height (`50px`).
- **Swap the Zebar pack**: edit `zebar/settings.json` → `startupConfigs[].pack` to any pack listed in `zebar/.marketplace/`.
- **Border color**: `window_effects.focused_window.border.color` (currently `#8dbcff`).
- **Ultrawide centering**: tune the constants at the top of `glazewm/autotile.py` — `WIDTH_FRACTION` (centered width, default `0.5`), `ULTRAWIDE_MIN_RATIO` (default `2.0`), or set `ENABLE_CENTER_SINGLE = False` to turn it off.

## Credits

- [Omarchy](https://omarchy.org/) for keybinding philosophy and defaults
- [`mushfikurr/overline-zebar`](https://github.com/mushfikurr/overline-zebar), the Zebar pack this config launches (Zebar option)
- [glzr-io](https://github.com/glzr-io) for GlazeWM and Zebar themselves
- **GlazeWMDock** — the Command Palette Dock extension that renders the default workspace bar (see [`cmdpal/`](cmdpal/))

## License

MIT. Do whatever you want with it.
