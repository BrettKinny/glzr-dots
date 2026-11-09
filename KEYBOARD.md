# Keyboard cheat sheet — Omarchy + Windows

[Printable one-page PDF](KEYBOARD.pdf) · [Scalable SVG](KEYBOARD.svg)

Use the same pattern on both systems: **`Mod` = `Super` on Omarchy and `Alt` on
Windows**. `Ctrl` belongs to the focused application; adding `Shift` usually
moves, reverses, or raises the scope of an action.

## Windows and workspaces

| Action | Shortcut |
| --- | --- |
| Close / fullscreen | `Mod+W` / `Mod+F` |
| Cycle width: 50% → default → full | Windows only: `Mod+Shift+W` |
| Toggle split direction / floating | `Mod+J` / `Mod+Shift+V` |
| Focus window | `Mod+Arrow` |
| Move window | `Mod+Shift+Arrow` |
| Workspace 1–10 | `Mod+1..0` |
| Move window to workspace and follow | `Mod+Shift+1..0` |
| Next / previous workspace | `Mod+Tab` / `Mod+Shift+Tab` |
| Previous workspace | `Mod+Ctrl+Tab` |
| Resize width | Omarchy: `Mod+-` grow, `Mod+=` shrink · Windows: `Mod+=` grow, `Mod+-` shrink |
| Resize height | `Mod+Shift+=` grow / `Mod+Shift+-` shrink |

## Launchers

| Job | Shortcut | Omarchy | Windows |
| --- | --- | --- | --- |
| Terminal | `Mod+Enter` | Default terminal | Windows Terminal |
| Browser | `Mod+Shift+B` | Default browser | Zen |
| Editor | `Mod+Shift+N` | Microsoft Edit | ttt |
| Files | `Mod+Shift+F` | Elio | Elio |
| Notes | `Mod+Shift+O` | Obsidian | Obsidian |
| Email | `Mod+Shift+E` | Email web app | Outlook |
| Calendar | `Mod+Shift+C` | gcal-tui | Outlook Calendar |
| Messaging | `Mod+Shift+G` | Signal | Teams |
| AI | `Mod+Shift+A` | Gemini | Gemini |
| Jira issue (key, number → MMS, or search) | `Mod+Shift+J` | — | Jira jump popup |

## Clipboard

| Action | Shortcut |
| --- | --- |
| Copy / paste / cut | `Mod+C` / `Mod+V` / `Mod+X` |
| Clipboard history | `Mod+Ctrl+V` |

These send universal clipboard chords, so they work in terminals and GUI apps.

## Herdr

ttt runs inside Herdr panes and there is no pass-through, so Herdr keeps `Ctrl`
only where ttt has no claim. The rest moved up to `Ctrl+Shift`, `Ctrl+Alt`, or
down to the `F9` prefix.

| Action | Shortcut |
| --- | --- |
| New tab / close pane | `Ctrl+Shift+T` / `Ctrl+Shift+W` |
| Next / previous workspace | `Ctrl+Tab` / `Ctrl+Shift+Tab` |
| Next / previous tab | `F9 N` / `F9 P` |
| Select tab | `Ctrl+1..9` |
| Focus pane | `Ctrl+Alt+←/→` · `F9 H/J/K/L` |
| Move pane | `F9 Shift+H/J/K/L` |
| Side ttt (explorer + git): open / toggle focus | `Ctrl+Shift+E` |
| Sidebar / go to | `Ctrl+Shift+B` / `Ctrl+Shift+P` |
| Split vertical / horizontal | `Ctrl+Shift+\` / `Ctrl+Shift+-` |
| Zoom pane / new workspace | `F9 Z` / `Ctrl+Shift+N` |
| New worktree workspace | `Ctrl+Shift+G` |
| Pick URL / file path (Windows): files open in side ttt, else the ttt window | `Ctrl+Shift+U` |

`F9` remains the Herdr recovery prefix, and every command still answers to its
`F9` form. System-only extras: Omarchy uses `Alt+Space` for hold-to-dictate;
Windows uses `Mod+R` for resize mode and `Mod+Shift+R` to reload GlazeWM.

## ttt

Defaults, except where GlazeWM (`Alt`) takes the key.

| Action | Shortcut |
| --- | --- |
| Command palette / quick open | `Ctrl+P` / `Ctrl+K P` |
| Explorer / changes / sidebar | `Ctrl+K E` / `Ctrl+K C` / `Ctrl+B` |
| Search files / replace | `Ctrl+K F` / `Ctrl+R` |
| Next / previous tab | `Alt+.` / `Alt+,` |
| Move line / add cursor | `Ctrl+Alt+↑/↓` / `Ctrl+Shift+↑/↓` |
| Go to definition / LSP chords | `F12` / `Ctrl+L …` |
| Terminal / menu bar | `Ctrl+T` / `F10` |

## Zen (Windows)

Splits and sidebar follow Herdr; `Ctrl+T/W/N/Tab` stay browser-standard. GlazeWM
owns `Mod+Arrow`, so `Alt+←` never reaches Zen. Vimium handles in-page keys.

| Action | Shortcut |
| --- | --- |
| Back / forward | `Backspace` · `Ctrl+,` / `Ctrl+.` · Vimium `H` / `L` |
| Split vertical / horizontal | `Ctrl+\` / `Ctrl+Shift+\` |
| Unsplit | `Ctrl+Shift+W` |
| Sidebar (compact mode) | `Ctrl+Shift+B` |
| Go to open tab | `Ctrl+G` or Vimium `T` |
| Next / previous tab | Vimium `J` / `K` |
| Next / previous Zen workspace | `Ctrl+Alt+→` / `Ctrl+Alt+←` |
| Link hints / copy URL | Vimium `f` / `yy` |
