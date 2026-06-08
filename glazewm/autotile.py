import asyncio
import json
import websockets

# ---------------------------------------------------------------------------
# GlazeWM tiling helper.
#
#   1. Dwindle autotiling  - flip the split direction based on the focused
#      window's longest axis (mimics Hyprland's dwindle layout).
#   2. Single-window center - on an ultrawide monitor, a lone window in a
#      workspace is floated and centered at a fraction of the monitor width
#      instead of being stretched edge-to-edge (mimics how Omarchy/Hyprland
#      feel on ultrawides). As soon as a second window appears, the centered
#      window is handed back to tiling so the two tile normally.
# ---------------------------------------------------------------------------

URI = "ws://localhost:6123"

ENABLE_DWINDLE = True

ENABLE_CENTER_SINGLE = True
WIDTH_FRACTION = 0.5        # centered window width, as a fraction of monitor width
ULTRAWIDE_MIN_RATIO = 2.0   # only act on monitors wider than this (21:9 ~= 2.39)
TOP_GAP = 50                # leave room for the Zebar bar (matches config.yaml)
BOTTOM_GAP = 10             # matches config.yaml outer_gap.bottom


def iter_windows(container):
    """Recursively yield every window node beneath a container."""
    for child in container.get("children", []):
        if child.get("type") == "window":
            yield child
        else:
            yield from iter_windows(child)


def state_of(window):
    return window.get("state", {}).get("type")


async def send_recv(ws, message):
    """Send an IPC message and return the parsed JSON reply."""
    await ws.send(message)
    return json.loads(await ws.recv())


async def reconcile(cmd_ws, centered_ids):
    """Query WM state, then apply single-window centering and dwindle."""
    reply = await send_recv(cmd_ws, "query monitors")
    monitors = reply.get("data", {}).get("monitors", [])

    # Drop ids of windows that no longer exist.
    all_ids = {w["id"] for m in monitors for w in iter_windows(m)}
    centered_ids &= all_ids

    focused = None

    for monitor in monitors:
        mon_w = monitor.get("width", 0)
        mon_h = monitor.get("height", 0)
        mon_x = monitor.get("x", 0)
        mon_y = monitor.get("y", 0)
        is_ultrawide = mon_h and (mon_w / mon_h) >= ULTRAWIDE_MIN_RATIO

        for workspace in monitor.get("children", []):
            if workspace.get("type") != "workspace":
                continue

            windows = list(iter_windows(workspace))
            for w in windows:
                if w.get("hasFocus"):
                    focused = w

            if not (ENABLE_CENTER_SINGLE and is_ultrawide):
                continue

            tiling = [w for w in windows if state_of(w) == "tiling"]

            # Re-adopt windows we previously centered (e.g. after a daemon
            # restart): a lone floating window whose width matches our
            # centered size was almost certainly placed by us.
            target_width = round(mon_w * WIDTH_FRACTION)
            for w in windows:
                if (state_of(w) == "floating"
                        and w["id"] not in centered_ids
                        and abs((w.get("width") or 0) - target_width) <= 4):
                    centered_ids.add(w["id"])

            ours = [w for w in windows
                    if w["id"] in centered_ids and state_of(w) == "floating"]

            if tiling and ours:
                # A tiling window joined our centered one -> give it back.
                for w in ours:
                    await send_recv(cmd_ws, f"command --id {w['id']} set-tiling")
                    centered_ids.discard(w["id"])
            elif len(tiling) >= 2:
                pass  # normal tiling layout, leave it alone
            elif len(tiling) == 1 and not ours:
                # Lone window -> float it centered at WIDTH_FRACTION of the monitor.
                w = tiling[0]
                width = round(mon_w * WIDTH_FRACTION)
                height = mon_h - TOP_GAP - BOTTOM_GAP
                x = mon_x + (mon_w - width) // 2
                y = mon_y + TOP_GAP
                await send_recv(
                    cmd_ws,
                    f"command --id {w['id']} set-floating "
                    f"--x-pos {x} --y-pos {y} --width {width} --height {height}",
                )
                centered_ids.add(w["id"])

    # Dwindle: split direction follows the focused window's longest axis.
    if ENABLE_DWINDLE and focused and state_of(focused) == "tiling":
        width = focused.get("width") or 0
        height = focused.get("height") or 0
        if width and height:
            direction = "horizontal" if width > height else "vertical"
            await send_recv(cmd_ws, f"command set-tiling-direction {direction}")


async def run():
    centered_ids = set()
    async with websockets.connect(URI) as event_ws, \
               websockets.connect(URI) as cmd_ws:
        for event in ("window_managed", "window_unmanaged", "focus_changed",
                      "workspace_activated", "workspace_updated"):
            await send_recv(event_ws, f"sub -e {event}")

        # Apply once on startup so the current layout is corrected immediately.
        await reconcile(cmd_ws, centered_ids)

        while True:
            message = json.loads(await event_ws.recv())
            if message.get("messageType") == "event_subscription":
                await reconcile(cmd_ws, centered_ids)


async def main():
    while True:
        try:
            await run()
        except Exception:
            # GlazeWM restarted or the socket dropped; wait and reconnect.
            await asyncio.sleep(2)


if __name__ == "__main__":
    asyncio.run(main())
