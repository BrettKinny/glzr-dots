import asyncio
import json
import os
import subprocess

import websockets

# ---------------------------------------------------------------------------
# Omarchy-style terminal launcher (Alt+Enter).
#
# Omarchy's Super+Enter opens the new terminal in the cwd of the focused
# terminal window (bin/omarchy-cmd-terminal-cwd: focused-window pid ->
# child shell pid -> /proc/<pid>/cwd, falling back to $HOME). That trick
# doesn't port: every Windows Terminal window shares one WindowsTerminal.exe
# process, so a window can't be mapped to its shell via the process tree,
# and Windows has no /proc.
#
# Instead the prompt hook in powershell/profile.ps1 records each pane's cwd
# keyed by its WT window handle (%LOCALAPPDATA%\glazewm\term-cwd\<hwnd>.txt).
# This script reads that back:
#   1. Focused window is a terminal  -> its recorded cwd.
#   2. Otherwise, terminals exist on the focused workspace -> the most
#      recently recorded cwd among them.
#   3. Fresh workspace / nothing recorded / dir gone -> home.
#
# Run with pythonw (like autotile.py) so no console window is created —
# a hidden console still takes a tile slot under hide_method: cloak.
# ---------------------------------------------------------------------------

# 127.0.0.1, not localhost: localhost tries IPv6 ::1 first and stalls ~2s
# before falling back to IPv4, which GlazeWM actually listens on.
URI = "ws://127.0.0.1:6123"
TERMINAL_PROCESS = "WindowsTerminal"
CWD_DIR = os.path.join(os.environ["LOCALAPPDATA"], "glazewm", "term-cwd")


def iter_windows(container):
    for child in container.get("children", []):
        if child.get("type") == "window":
            yield child
        else:
            yield from iter_windows(child)


def recorded_cwd(handle):
    """Return (cwd, recorded-at mtime) for a WT window handle, or None."""
    path = os.path.join(CWD_DIR, f"{handle}.txt")
    try:
        with open(path, encoding="utf-8") as f:
            cwd = f.read().strip()
        if cwd and os.path.isdir(cwd):
            return cwd, os.path.getmtime(path)
    except OSError:
        pass
    return None


async def query(ws, message):
    await ws.send(message)
    return json.loads(await ws.recv()).get("data") or {}


async def pick_target():
    async with websockets.connect(URI) as ws:
        focused = (await query(ws, "query focused")).get("focused") or {}
        if (focused.get("type") == "window"
                and focused.get("processName") == TERMINAL_PROCESS):
            hit = recorded_cwd(focused.get("handle"))
            if hit:
                return hit[0]

        workspaces = (await query(ws, "query workspaces")).get("workspaces", [])
        ws_focused = next((w for w in workspaces if w.get("hasFocus")), None)
        if ws_focused:
            hits = [hit for w in iter_windows(ws_focused)
                    if w.get("processName") == TERMINAL_PROCESS
                    and (hit := recorded_cwd(w.get("handle")))]
            if hits:
                return max(hits, key=lambda h: h[1])[0]

    return None


def main():
    try:
        target = asyncio.run(pick_target())
    except Exception:
        target = None
    subprocess.Popen(
        ["wt", "-f", "-d", target or os.path.expanduser("~")],
        creationflags=subprocess.CREATE_NO_WINDOW,
    )


if __name__ == "__main__":
    main()
