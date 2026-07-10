# Command Palette Dock (default top bar)

This is a *pointer*, not vendored code — the same pattern `zebar/.marketplace/`
uses for the overline-zebar pack. The actual bar is a PowerToys **Command
Palette** extension, **GlazeWMDock**, which renders your GlazeWM workspace strip
on the CmdPal Dock. It reserves screen space via the Windows AppBar API, so
`gaps.outer_gap.top` stays at `2px` (no `50px` reservation like Zebar needs).

It shows the workspace strip as live text on the bar:

- **focused** workspace → filled circled digit
- **active** workspace (displayed / has windows) → outline circled digit
- **inactive / empty** → plain digit

State comes from GlazeWM's IPC WebSocket (`ws://127.0.0.1:6123`).

## Get the extension

- **Microsoft Store / Command Palette gallery:** *coming soon* — search Command
  Palette's built-in "install extensions" gallery for **GlazeWM Workspaces**.
- **Meanwhile (sideload):** build + deploy the `GlazeWMDock` project (Visual
  Studio → **Deploy**, not just Build), or grab a signed `.msix` from its
  Releases and `Add-AppxPackage` it.

## Enable it

1. Command Palette → **Settings → enable Dock**, Position = **Top**.
2. **Settings → Bands** → toggle **GlazeWM Workspaces** on. This pins the
   live-text strip. Do *not* use *"Pin to Dock"* on the top-level *GlazeWM
   Workspaces* command — that pins the search page (opens a flyout popup) instead
   of showing text on the bar.
3. Switch workspaces with `Alt+1..0`; the strip updates on the bar. Click it to
   open the switcher page.

If the band shows an icon but no text, right-click it in Dock **Edit** mode and
enable **Show Titles** (and optionally **Show Subtitles**).
