import asyncio
import json
import os

import websockets

# ---------------------------------------------------------------------------
# Toggle the focused window between full monitor width and its previous
# state/rect (Alt+Shift+W). GlazeWM bindings can't branch on state, hence a
# script. Pre-toggle state is kept per window id in STATE_FILE.
# ---------------------------------------------------------------------------

# 127.0.0.1, not localhost: localhost tries IPv6 ::1 first and stalls ~2s.
URI = "ws://127.0.0.1:6123"
STATE_FILE = os.path.join(os.environ["LOCALAPPDATA"], "glazewm", "fullwidth.json")
TOLERANCE = 4  # px


def iter_windows(container):
    for child in container.get("children", []):
        if child.get("type") == "window":
            yield child
        else:
            yield from iter_windows(child)


def load_saved():
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def store_saved(saved):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(saved, f)


async def send(ws, message):
    await ws.send(message)
    return json.loads(await ws.recv()).get("data") or {}


async def toggle():
    async with websockets.connect(URI) as ws:
        win = (await send(ws, "query focused")).get("focused") or {}
        if win.get("type") != "window":
            return

        monitors = (await send(ws, "query monitors")).get("monitors", [])
        monitor = next((m for m in monitors
                        if any(w["id"] == win["id"] for w in iter_windows(m))), None)
        if not monitor:
            return

        live_ids = {w["id"] for m in monitors for w in iter_windows(m)}
        saved = {k: v for k, v in load_saved().items() if k in live_ids}

        wid = win["id"]
        state = win.get("state", {}).get("type")
        prev = saved.pop(wid, None)
        # Decide on current width, not on having an entry: after a manual
        # Alt+T etc. the saved entry is stale.
        is_full = (state == "floating"
                   and abs(win.get("width", 0) - monitor["width"]) <= TOLERANCE)

        if is_full:
            # No saved rect (state file lost) → tile; autotile.py re-centers.
            if not prev or prev["state"] == "tiling":
                await send(ws, f"command --id {wid} set-tiling")
            else:
                await send(ws, f"command --id {wid} size "
                               f"--width {prev['width']}px --height {prev['height']}px")
                await send(ws, f"command --id {wid} position "
                               f"--x-pos {prev['x']} --y-pos {prev['y']}")
        else:
            saved[wid] = {"state": state, "x": win["x"], "y": win["y"],
                          "width": win["width"], "height": win["height"]}
            # `size`, not `set-floating --width`: set-floating won't resize a
            # window that already has a placement (e.g. one autotile.py centered).
            await send(ws, f"command --id {wid} set-floating")
            await send(ws, f"command --id {wid} size --width 100%")
            await send(ws, f"command --id {wid} position --centered")

        store_saved(saved)


if __name__ == "__main__":
    asyncio.run(toggle())
