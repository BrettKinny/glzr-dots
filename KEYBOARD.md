# Keyboard cheat sheet — Omarchy + Windows

[Printable one-page PDF](KEYBOARD.pdf) · [Scalable SVG](KEYBOARD.svg)

Use the same pattern on both systems: **`Mod` = `Super` on Omarchy and `Alt` on
Windows**. `Ctrl` belongs to the focused application; adding `Shift` usually
moves, reverses, or raises the scope of an action.

## Windows and workspaces

| Action | Shortcut |
| --- | --- |
| Close / fullscreen | `Mod+W` / `Mod+F` |
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
| Editor | `Mod+Shift+N` | Microsoft Edit | Fresh |
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

Fresh runs inside Herdr panes and there is no pass-through, so Herdr keeps `Ctrl`
only where Fresh has no claim. The rest moved up to `Ctrl+Shift` or down to the
`F12` prefix.

| Action | Shortcut |
| --- | --- |
| New tab / close pane | `Ctrl+Shift+T` / `Ctrl+Shift+W` |
| Next / previous workspace | `Ctrl+Tab` / `Ctrl+Shift+Tab` |
| Next / previous tab | `F12 N` / `F12 P` |
| Select tab | `Ctrl+1..9` |
| Focus / move pane | `F12 H/J/K/L` / `F12 Shift+…` |
| Sidebar / go to | `Ctrl+Shift+B` / `Ctrl+G` |
| Split vertical / horizontal | `Ctrl+\` / `Ctrl+Shift+\` |
| Zoom pane / new workspace | `F12 Z` / `Ctrl+Shift+N` |
| New worktree workspace | `Ctrl+Shift+G` |
| Pick URL / file path (Windows) | `Ctrl+Shift+U` |

`F12` remains the Herdr recovery prefix, and every command still answers to its
`F12` form. System-only extras: Omarchy uses `Alt+Space` for hold-to-dictate;
Windows uses `Mod+R` for resize mode and `Mod+Shift+R` to reload GlazeWM.
