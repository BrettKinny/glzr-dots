import ctypes
import re
import tkinter as tk
from urllib.parse import quote

# ---------------------------------------------------------------------------
# Jira jump (Alt+Shift+J): tiny prompt → opens the issue in Zen.
#   802 / mms802 / MMS-802  → MMS-802
#   TAN-12                  → TAN-12
#   anything else           → Jira text search
# Prefills with an issue key from the clipboard (Enter opens it, typing
# replaces it). Esc / click away closes.
# ---------------------------------------------------------------------------

SITE = "https://multinail.atlassian.net"
DEFAULT_PROJECT = "MMS"
TITLE = "Jira jump"  # matched by the ignore rule in config.yaml
KEY_RE = re.compile(r"([A-Za-z]+)-?(\d+)")


def url_for(text):
    text = text.strip()
    if text.isdigit():
        return f"{SITE}/browse/{DEFAULT_PROJECT}-{text}"
    m = KEY_RE.fullmatch(text)
    if m:
        return f"{SITE}/browse/{m[1].upper()}-{m[2]}"
    return f"{SITE}/issues/?jql=" + quote(f'text ~ "{text}" ORDER BY updated DESC')


def clipboard_key(root):
    try:
        clip = root.clipboard_get()
    except tk.TclError:
        return ""
    # Hyphen required here, else any word+number in the clipboard matches.
    m = re.search(r"\b[A-Z][A-Z0-9]+-\d+\b", clip[:2000])
    return m[0] if m else ""


BG, FG, DIM, ACCENT = "#1e1e1e", "#e6e6e6", "#6b6b6b", "#2684ff"
FONT = ("Segoe UI", 14)


def round_corners(root):
    # Win11 DWM rounding; also applies to borderless (overrideredirect) windows.
    hwnd = ctypes.windll.user32.GetParent(root.winfo_id())
    pref = ctypes.c_int(2)  # DWMWCP_ROUND
    ctypes.windll.dwmapi.DwmSetWindowAttribute(hwnd, 33, ctypes.byref(pref), 4)


def main():
    ctypes.windll.shcore.SetProcessDpiAwareness(1)  # else Tk text is bitmap-scaled + blurry
    root = tk.Tk()
    root.title(TITLE)
    root.overrideredirect(True)
    root.attributes("-topmost", True)
    root.configure(bg=ACCENT)  # shows as 1px border around the frame

    frame = tk.Frame(root, bg=BG)
    frame.pack(padx=1, pady=1)
    tk.Label(frame, text="Jira", font=FONT, bg=BG, fg=ACCENT).pack(side="left", padx=(16, 8), pady=10)

    text = tk.StringVar()
    entry = tk.Entry(frame, textvariable=text, font=FONT, width=24, relief="flat", bd=0,
                     bg=BG, fg=FG, insertbackground=FG,
                     selectbackground=ACCENT, selectforeground=FG)
    entry.pack(side="left", padx=(0, 16), pady=10)

    hint = tk.Label(frame, text="issue key or search", font=FONT, bg=BG, fg=DIM)
    text.trace_add("write", lambda *_: hint.place_forget() if text.get() else
                   hint.place(in_=entry, x=0, rely=0.5, anchor="w"))
    hint.bind("<Button-1>", lambda _: entry.focus_set())

    text.set(clipboard_key(root))
    if not text.get():
        hint.place(in_=entry, x=0, rely=0.5, anchor="w")
    entry.select_range(0, "end")

    def go(_=None):
        if entry.get().strip():
            # ShellExecute resolves `zen` via App Paths like shell-exec does.
            # Not os.startfile: its `arguments` param is 3.10+ and pythonw is 3.9.
            ctypes.windll.shell32.ShellExecuteW(None, None, "zen", url_for(entry.get()), None, 1)
        root.destroy()

    entry.bind("<Return>", go)
    root.bind("<Escape>", lambda _: root.destroy())
    # FocusOut also fires on entry↔root shuffles; only close once the app has no focus at all.
    root.bind("<FocusOut>", lambda _: root.after(100, lambda: root.focus_get() or root.destroy()))

    root.update_idletasks()
    w, h = root.winfo_width(), root.winfo_height()
    x = (root.winfo_screenwidth() - w) // 2
    y = root.winfo_screenheight() // 3
    root.geometry(f"+{x}+{y}")
    round_corners(root)

    root.focus_force()
    entry.focus_set()
    root.mainloop()


if __name__ == "__main__":
    main()
