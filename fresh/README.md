# fresh (getfresh.dev) keybindings

Keymap for the [Fresh](https://getfresh.dev) terminal editor, made canonical with the
Omarchy-style GlazeWM bindings in `../glazewm/config.yaml`.

## The grammar

Three layers stack on the same keyboard. Each owns one modifier:

| Layer | Modifier | Owns |
|---|---|---|
| GlazeWM (windows, workspaces) | `Alt` | global — always wins |
| Fresh (splits, panes) | `Ctrl+Alt` | "Alt, one level in" |
| Fresh (text editing) | `Ctrl` / `Ctrl+Shift` | stock defaults |

Windows Terminal sits between GlazeWM and Fresh and is deliberately made
transparent — see *Windows Terminal* below.

### Mirrored pairs

The WM gesture and its in-editor equivalent share a key, one modifier apart:

| Concept | GlazeWM (window) | Fresh (split) |
|---|---|---|
| move focus | `Alt+←/→` | `Ctrl+Alt+←/→` |
| split direction | `Alt+J` | `Ctrl+Alt+J` / `Ctrl+Alt+Shift+J` |
| fullscreen / maximize | `Alt+F` | `Ctrl+Alt+F` |
| close | `Alt+W` | `Ctrl+Alt+W` |
| resize | `Alt+=` / `Alt+-` | `Ctrl+Alt+=` / `Ctrl+Alt+-` |
| new terminal | `Alt+Enter` | `Ctrl+Alt+Enter` |

## What GlazeWM took, and where it went

`Alt` is registered globally by GlazeWM, so Fresh never receives these at all.
19 stock Fresh bindings were affected:

| Fresh default | Lost to | Now |
|---|---|---|
| `Alt+↑/↓` move line | focus window | `Ctrl+Alt+↑/↓` |
| `Alt+Shift+arrows` block select | move window | `Ctrl+Alt+Shift+arrows` |
| `Alt+←/→` position history | focus window | `Ctrl+Alt+[` / `Ctrl+Alt+]` |
| `Alt+Enter` project search | new terminal | `Ctrl+Shift+F` (live grep), `Ctrl+Shift+R` (query replace) |
| `Alt+0`–`9` jump to bookmark | focus workspace | dropped — `Ctrl+Alt+B` lists them, or use the palette |

`Ctrl+Alt+↑/↓` was stock *add cursor above/below*; that moved to `Ctrl+Shift+↑/↓`.

These Fresh `Alt` defaults survive untouched, because GlazeWM does not claim them:
`Alt+U` / `Alt+L` (case), `Alt+N` / `Alt+P` (find selection), `Alt+.` (code actions),
`Alt+|` (shell command).

They only work because `editor.menu_bar_mnemonics` is `false` here. The menu bar is
already hidden (`show_menu_bar: false`), so the Alt+letter mnemonics were claiming
keys for a menu that never renders.

## Limits of the mirror

Fresh has no action for these, so the mirror is cycle-based rather than directional.
Verified against the action table compiled into `fresh.exe`:

- **No directional split focus** — only `next_split` / `prev_split`. `Ctrl+Alt+←/→`
  cycles; it does not move by direction the way `Alt+←/→` does for windows.
- **No "go to tab N"** — so there is no `Ctrl+Alt+1..9` mirror of `Alt+1..9`
  workspace switching. Use `Ctrl+P` then `#` to switch buffers.
- **No "move split"** — nothing mirrors `Alt+Shift+arrows`.

## Windows Terminal

Fresh runs inside WT (`wt fresh`), so WT gets first refusal on every key. Its
bindings are stripped in
`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
via `{ "id": "unbound", "keys": "..." }` — the documented mechanism for
"underlying terminal applications".

Unbound: WT's panes/tabs/palette/find, and critically `Ctrl+C` / `Ctrl+V`
(previously custom-bound to WT's own clipboard, which stopped Fresh seeing them),
`Ctrl+Shift+↑/↓` (scroll — needed for add-cursor) and `Ctrl+Shift+F` (find —
needed for live grep).

Terminal clipboard stays reachable on `Ctrl+Shift+C` / `Ctrl+Shift+V`.

Rationale: GlazeWM already manages windows and Fresh already manages splits and
tabs, so WT's equivalents were redundant middlemen. The tradeoff is that WT panes
are no longer available in plain shell tabs.

## How this file is deployed

`%APPDATA%\fresh\config.json` is a **hardlink** to `config.json` here, so edits in
either place are the same bytes. A hardlink rather than a junction because
`%APPDATA%\fresh\` also holds session state (`file_states/`, `sessions/`, `logs/`,
`workspaces/`) that does not belong in git.

```powershell
New-Item -ItemType HardLink -Path "$env:APPDATA\fresh\config.json" `
         -Target "$env:USERPROFILE\.glzr\fresh\config.json"
```

**Caveat:** if Fresh's Settings UI or Keybinding Editor saves by
write-temp-then-rename, the hardlink breaks silently and the two files drift.
After saving config from inside Fresh, check the link still holds:

```powershell
(Get-Item "$env:APPDATA\fresh\config.json").LinkType   # expect: HardLink
```

If it reads empty, re-run the `New-Item` above. Alternatively Fresh accepts
`fresh --config <path>`, which avoids the link entirely at the cost of every bare
`fresh` invocation missing it.

## Verifying

```powershell
fresh --cmd config show      # echoes the effective config
```

Inside Fresh, `Ctrl+H` shows the keybinding reference, and the Keybinding Editor
(Edit menu, or `Ctrl+P` -> "Keybinding Editor") browses the live resolved keymap.
That is the authoritative check, since the `default` map is compiled into the
binary and not written to any file.
