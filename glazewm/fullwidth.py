import asyncio
import json
import os

import websockets

# ---------------------------------------------------------------------------
# Cycle the focused window's width (Alt+Shift+W): 50% centered → default →
# full width → 50%. GlazeWM bindings can't branch on state, hence a script.
# "default" = tiled, or the window's own floating rect if it had one.
# State file: pre-cycle rects + ids autotile.py must not re-center.
# ---------------------------------------------------------------------------

# 127.0.0.1, not localhost: localhost tries IPv6 ::1 first and stalls ~2s.
URI = "ws://127.0.0.1:6123"
STATE_FILE = os.path.join(os.environ["LOCALAPPDATA"], "glazewm", "fullwidth.json")
TOLERANCE = 4  # px
WIDTH_FRACTION = 0.5  # keep = autotile.py, so its centered windows read as the 50% step


def iter_windows(container):
    for child in container.get("children", []):
        if child.get("type") == "window":
            yield child
        else:
            yield from iter_windows(child)


def load_state():
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        return {}
    return data if isinstance(data, dict) and "saved" in data else {}


def store_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f)


async def send(ws, message):
    await ws.send(message)
    return json.loads(await ws.recv()).get("data") or {}


async def cycle():
    async with websockets.connect(URI) as ws:
        win = (await send(ws, "query focused")).get("focused") or {}
        if win.get("type") != "window":
            return

        monitors = (await send(ws, "query monitors")).get("monitors", [])
        found = next(((m, space) for m in monitors for space in m.get("children", [])
                      if any(w["id"] == win["id"] for w in iter_windows(space))), None)
        if not found:
            return
        monitor, space = found

        live_ids = {w["id"] for m in monitors for w in iter_windows(m)}
        state = load_state()
        saved = {k: v for k, v in state.get("saved", {}).items() if k in live_ids}
        exempt = [i for i in state.get("exempt", []) if i in live_ids]

        wid = win["id"]
        floating = win.get("state", {}).get("type") == "floating"
        width = win.get("width", 0)
        half = round(monitor["width"] * WIDTH_FRACTION)
        if wid in exempt:
            exempt.remove(wid)

        # Step from current width, not stored state: manual resizes make it stale.
        if floating and abs(width - monitor["width"]) <= TOLERANCE:
            # full → 50%, centered, workspace height (same rect autotile.py uses)
            cmds = [f"size --width {half}px --height {space['height']}px",
                    f"position --x-pos {monitor['x'] + (monitor['width'] - half) // 2}"
                    f" --y-pos {space['y']}"]
        elif floating and abs(width - half) <= TOLERANCE:
            # 50% → default
            prev = saved.pop(wid, None)
            if prev and prev["state"] == "floating":
                cmds = [f"size --width {prev['width']}px --height {prev['height']}px",
                        f"position --x-pos {prev['x']} --y-pos {prev['y']}"]
            else:
                exempt.append(wid)  # else autotile.py re-centers a lone ultrawide window
                cmds = ["set-tiling"]
        else:
            # default → full
            saved[wid] = {"state": "floating" if floating else "tiling",
                          "x": win["x"], "y": win["y"],
                          "width": width, "height": win["height"]}
            # `size`, not `set-floating --width`: set-floating won't resize a
            # window that already has a placement. Explicit height + y:
            # set-floating on a tiled window shrinks it to the default float size.
            cmds = ["set-floating",
                    f"size --width {monitor['width']}px --height {win['height']}px",
                    f"position --x-pos {monitor['x']} --y-pos {win['y']}"]

        # Write before commanding: set-tiling fires events autotile.py reacts to.
        store_state({"saved": saved, "exempt": exempt})
        for cmd in cmds:
            await send(ws, f"command --id {wid} {cmd}")


if __name__ == "__main__":
    asyncio.run(cycle())
