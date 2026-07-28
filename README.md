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
| `Super + Shift + B/E/F/...` app launchers | `Alt + Shift + B/E/F/...` | Same letters (Zen, Outlook, Obsidian, Teams, Gemini). The file manager and editor are TUIs in a Terminal window — elio and `fresh` — rather than Explorer and VS Code, which keeps them inside the tiling layout. |
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

Optional (only needed if you use the matching launcher binding): Zen Browser, Obsidian, Microsoft Teams, New Outlook, plus [elio](#elio-tui-file-manager) (`cargo install elio`) and [fresh](https://github.com/sinelaw/fresh-editor) (`winget install sinelaw.fresh-editor`) for the file-manager and editor bindings.

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
│   ├── profile.ps1      # shell profile (zoxide, fzf, eza, bat, PSReadLine)
│   └── set-edit-associations.ps1  # open text/config files in Microsoft Edit (TUI)
├── elio/
│   ├── config.toml      # TUI file manager: sidebar places + open rules
│   └── theme.toml       # elio colour theme
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
| [starship](https://starship.rs/) | prompt; config in `powershell/starship.toml`, styled with ANSI colour names so it follows the terminal theme | `winget install Starship.Starship` |
| [elio](https://crates.io/crates/elio) | TUI file manager; config in `elio/` — see [elio](#elio-tui-file-manager) | `cargo install elio` |
| [Microsoft Edit](https://github.com/microsoft/edit) | `edit` TUI editor — the `$EDITOR` and file-association target | `winget install Microsoft.Edit` |

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

### Text files open in the terminal

The Omarchy reflex is that a config file opens in a terminal editor, not a GUI. `powershell/set-edit-associations.ps1` points plain-text and config extensions at [Microsoft Edit](https://github.com/microsoft/edit) (`winget install Microsoft.Edit`), so double-clicking one from Explorer, Command Palette, or Everything drops you into the TUI editor in a Windows Terminal window — which GlazeWM then tiles like any other window.

```powershell
.\powershell\set-edit-associations.ps1                # apply
.\powershell\set-edit-associations.ps1 -Verify        # show what each extension opens with
.\powershell\set-edit-associations.ps1 -Revert        # undo
```

Covers `.txt .md .markdown .log .ini .cfg .conf .env .properties .json .jsonc .yaml .yml .toml .xml .ps1 .psm1 .psd1 .sql .diff .patch` — no admin, no reboot. Pass `-Extensions` to override the list. Executable types (`.bat .cmd .reg .py .sh .vbs`) are deliberately left alone: retargeting those would break double-click-to-run. `-Verify` resolves each extension through `AssocQueryString`, i.e. it reports what the shell will *actually* launch rather than what the registry looks like it says.

<details>
<summary><b>Why this needs more than a registry write</b> (getting past <code>UserChoice</code>)</summary>

Extensions an app has already claimed — `.txt`, `.log`, `.ini`, `.json`, `.xml`, `.ps1*` here — carry a `UserChoice` key whose `Hash` value Windows verifies. You cannot rewrite it. You *can* delete it, after which the extension falls back to the `HKCU\Software\Classes` default the script owns. Three things get in the way:

1. **The key's DACL grants you nothing.** You're still its owner though, so `WRITE_DAC` is implicitly yours — grant yourself `FullControl` first.
2. **`RegistryKey.DeleteSubKeyTree()` can't do it.** It opens the victim `KEY_READ|KEY_WRITE` before deleting, and that open is refused. .NET then reports the refusal as `"Cannot delete a subkey tree because the subkey does not exist"` — badly misleading. `RegDeleteKeyExW` needs only `DELETE`, so it works.
3. **`RegDeleteKeyExW` only deletes leaf keys**, and recent builds add a `UserChoiceLatest` alongside `UserChoice` *with a `ProgId` subkey*. Delete children depth-first, or you strand an orphaned `Hash` — which sends the extension to `OpenWith.exe` instead of your default.

The script also seeds `edit.exe` into each extension's `OpenWithList` MRU, since an extension left with an empty MRU can resolve to `OpenWith.exe` rather than falling through to the class default.

**This is destructive to your existing picks.** `-Revert` restores *Windows'* defaults, not what you had before — if VS Code owned `.json`, re-assign it afterwards via **Open with → Always use this app**. `-PickManually` remains as a fallback for anything the registry path misses; note Windows only offers the "Always" option once the old `UserChoice` is gone, so apply first.
</details>

**Requires Windows Terminal as your default terminal** (Settings → System → For developers → Terminal), otherwise `edit` opens in legacy conhost.

`profile.ps1` also exports `EDITOR=edit`, which covers anything that shells out to an editor (git, lazygit) rather than going through a file association. It's set as a persistent User-scope env var too, so GUI-launched apps see it; the profile line is what makes a fresh clone work before that's been done.

### elio (TUI file manager)

[elio](https://crates.io/crates/elio) (`cargo install elio`) does **not** consult Windows file associations — it has its own opener rules — so `elio/config.toml` carries a matching rule:

```toml
[[open.rules]]
ext = ["txt", "md", "log", "ini", "conf", "json", "yaml", "toml", "ps1", "..."]
command = "edit {path}"
terminal = true
```

`terminal = true` is load-bearing: it runs `edit` **inline in elio's own terminal** instead of spawning a separate window that GlazeWM would then tile alongside elio. Extensions are bare — no leading dot — matching elio's own `[extensions.*]` tables. Valid rule keys are `type`, `ext`, `platform`, `command`, `terminal`; at least one of `type`/`ext` is required, and elio prints `elio: open.rules[N]: unknown field ...; skipping rule` on **stderr** for anything it rejects, which is the quickest way to check a rule took.

**Wiring:** elio reads `%APPDATA%\elio` (or `$XDG_CONFIG_HOME/elio`), so like the PowerShell profile it can't live in this repo directly. It's junctioned rather than shimmed:

```powershell
# Run once, after cloning (no admin needed -- junctions don't require it):
Move-Item $env:APPDATA\elio $env:APPDATA\elio.bak -ErrorAction SilentlyContinue
cmd /c mklink /J "$env:APPDATA\elio" "$env:USERPROFILE\.glzr\elio"
```

> Don't be tempted by `XDG_CONFIG_HOME=~/.glzr` as a no-symlink alternative — elio honours it on Windows, but so do other tools, and it would redirect everything already living in `~/.config` (git, scoop, micro…) to a directory that has none of their configs.

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
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | [fresh](https://github.com/sinelaw/fresh-editor) in a Terminal window | `Super + Shift + N` (editor) |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | [elio](#elio-tui-file-manager) in a Terminal window | `Super + Shift + F` (file manager) |
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
