# Omarchy side

Verbatim copies of the Omarchy machine's personal Hyprland overrides, kept here
so both halves of the shared keyboard language live in one repo. Omarchy now
configures Hyprland in Lua; these replace the old `bindings.conf` clipboard
override.

| File | Live location | What it does |
|---|---|---|
| `bindings.lua` | `~/.config/hypr/bindings.lua` | Launcher overrides matching the Windows letters (`Mod+Shift+N` ttt, `F` elio, `A` Gemini, `C` calendar, `O` Obsidian, `E` email, `G` messaging), plus Linux-only extras (Bitwarden, TIDAL, dictation). F9 is left free for Herdr's prefix. |
| `input.lua` | `~/.config/hypr/input.lua` | `altwin:swap_alt_win`: the physical Alt key acts as `Super`. |

## Why there is no clipboard override any more

The old `bindings.conf` moved Omarchy's universal clipboard from `Super` to
`Alt` so the physical key matched Windows. With `altwin:swap_alt_win`, the
physical Alt key *is* `Super`, so Omarchy's stock `Super+C/V/X` and
`Super+Ctrl+V` already sit under the same physical chords as `Alt+C/V/X` on
Windows. No override needed.

## Install

Copy both files into `~/.config/hypr/` (merge with any existing overrides),
then `hyprctl reload`.
