"""
clipboard.py - Omarchy-style universal clipboard for Windows.

Part of glzr-dots. Mirrors Omarchy's hypr/bindings/clipboard.conf, which binds
Super+C/V/X to the universal Ctrl+Insert / Shift+Insert combos that work in BOTH
terminals and GUI apps. Here Alt stands in for Super (Windows owns the Win key),
matching the rest of this config:

    Alt + C         ->  Ctrl + Insert    copy   (works in terminals + GUI)
    Alt + V         ->  Shift + Insert   paste  (works in terminals + GUI)
    Alt + X         ->  Ctrl + X         cut    (GUI only, same as Omarchy)
    Alt + Ctrl + V  ->  Win + V          Windows clipboard history

Implementation: a WH_KEYBOARD_LL low-level keyboard hook using only the stdlib
(ctypes). It intercepts ONLY the four chords above and passes every other key -
including all of GlazeWM's Alt bindings - straight through. Native Ctrl+C/Ctrl+V
keep working as a fallback. The held Alt (and Ctrl) is released around the
injected chord so e.g. Alt+C produces a clean Ctrl+Insert, not Alt+Ctrl+Insert.

Started automatically by GlazeWM via startup_commands under pythonw, exactly
like autotile.py.
"""
import ctypes
from ctypes import wintypes

# --- Win32 constants -------------------------------------------------------
WH_KEYBOARD_LL        = 13
HC_ACTION             = 0
WM_KEYDOWN            = 0x0100
WM_SYSKEYDOWN         = 0x0104
KEYEVENTF_EXTENDEDKEY = 0x0001
KEYEVENTF_KEYUP       = 0x0002
INPUT_KEYBOARD        = 1

# Tag stamped on every key we inject, so our own events skip the remap logic.
MAGIC = 0x6C7A7200  # "lzr\0"

# Virtual-key codes
VK_C, VK_V, VK_X = 0x43, 0x56, 0x58
VK_INSERT        = 0x2D
VK_CONTROL       = 0x11      # generic Ctrl  (for the chords we send)
VK_SHIFT         = 0x10      # generic Shift
VK_LWIN          = 0x5B

# L/R modifier keys we release + restore around an injected chord.
MOD_VKS  = (0xA4, 0xA5,   # L/R Alt   (VK_LMENU / VK_RMENU)
            0xA2, 0xA3,   # L/R Ctrl
            0xA0, 0xA1,   # L/R Shift
            0x5B, 0x5C)   # L/R Win
ALT_VKS  = (0xA4, 0xA5)
CTRL_VKS = (0xA2, 0xA3)
# Keys that need the extended-key flag when injected.
EXTENDED = {0x2D, 0x5B, 0x5C, 0xA5, 0xA3}  # Insert, L/R Win, R Alt, R Ctrl

# Alt+V stays a universal *text* paste (Shift+Insert) in terminals AND GUI apps
# - that's the Omarchy behaviour. It only diverts to the app when there's an
# IMAGE or a copied FILE on the clipboard AND a terminal is focused: CLIs like
# Claude Code bind Alt+V to "paste image from clipboard" on Windows (Windows
# Terminal eats Ctrl+V for text paste), so in that one case we pass the real
# Alt+V through instead of turning it into a text paste. Alt+C / Alt+X /
# Alt+Ctrl+V are untouched. Add your terminal's exe (lower-case) if not listed.
TERMINAL_EXES = {
    'windowsterminal.exe', 'wt.exe',
    'wezterm-gui.exe', 'wezterm.exe',
    'alacritty.exe', 'conemu64.exe', 'conemu.exe',
    'powershell.exe', 'pwsh.exe', 'cmd.exe', 'conhost.exe',
    'code.exe',
}
PROCESS_QUERY_LIMITED_INFORMATION = 0x1000

# Clipboard formats that mean "image-paste-able": a screenshot bitmap or a file
# copied in Explorer (image files are the reliable Claude Code path). Text-only
# clipboard contents are NOT here, so a normal copy still pastes via Shift+Insert.
CF_BITMAP, CF_DIB, CF_HDROP, CF_DIBV5 = 2, 8, 15, 17
IMAGE_CF = (CF_BITMAP, CF_DIB, CF_DIBV5, CF_HDROP)

ULONG_PTR = wintypes.WPARAM
LRESULT   = ctypes.c_ssize_t
HANDLE    = ctypes.c_void_p

user32   = ctypes.WinDLL('user32',   use_last_error=True)
kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)


# --- structs ---------------------------------------------------------------
class KBDLLHOOKSTRUCT(ctypes.Structure):
    _fields_ = [("vkCode", wintypes.DWORD), ("scanCode", wintypes.DWORD),
                ("flags", wintypes.DWORD), ("time", wintypes.DWORD),
                ("dwExtraInfo", ULONG_PTR)]


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [("dx", wintypes.LONG), ("dy", wintypes.LONG),
                ("mouseData", wintypes.DWORD), ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD), ("dwExtraInfo", ULONG_PTR)]


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [("wVk", wintypes.WORD), ("wScan", wintypes.WORD),
                ("dwFlags", wintypes.DWORD), ("time", wintypes.DWORD),
                ("dwExtraInfo", ULONG_PTR)]


class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [("uMsg", wintypes.DWORD),
                ("wParamL", wintypes.WORD), ("wParamH", wintypes.WORD)]


class _INPUTUNION(ctypes.Union):
    _fields_ = [("mi", MOUSEINPUT), ("ki", KEYBDINPUT), ("hi", HARDWAREINPUT)]


class INPUT(ctypes.Structure):
    _fields_ = [("type", wintypes.DWORD), ("u", _INPUTUNION)]


# --- prototypes (set restype/argtypes so 64-bit pointers don't truncate) ---
user32.SendInput.restype  = wintypes.UINT
user32.SendInput.argtypes = [wintypes.UINT, ctypes.c_void_p, ctypes.c_int]
user32.GetAsyncKeyState.restype  = ctypes.c_short
user32.GetAsyncKeyState.argtypes = [ctypes.c_int]
user32.SetWindowsHookExW.restype  = HANDLE
user32.SetWindowsHookExW.argtypes = [ctypes.c_int, ctypes.c_void_p, HANDLE,
                                     wintypes.DWORD]
user32.CallNextHookEx.restype  = LRESULT
user32.CallNextHookEx.argtypes = [HANDLE, ctypes.c_int, wintypes.WPARAM,
                                  wintypes.LPARAM]
user32.GetMessageW.restype  = ctypes.c_int
user32.GetMessageW.argtypes = [ctypes.c_void_p, HANDLE, wintypes.UINT,
                               wintypes.UINT]
user32.TranslateMessage.argtypes = [ctypes.c_void_p]
user32.DispatchMessageW.argtypes = [ctypes.c_void_p]
kernel32.GetModuleHandleW.restype  = HANDLE
kernel32.GetModuleHandleW.argtypes = [wintypes.LPCWSTR]
user32.GetForegroundWindow.restype  = HANDLE
user32.GetForegroundWindow.argtypes = []
user32.GetWindowThreadProcessId.restype  = wintypes.DWORD
user32.GetWindowThreadProcessId.argtypes = [HANDLE,
                                            ctypes.POINTER(wintypes.DWORD)]
kernel32.OpenProcess.restype  = HANDLE
kernel32.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
kernel32.QueryFullProcessImageNameW.restype  = wintypes.BOOL
kernel32.QueryFullProcessImageNameW.argtypes = [HANDLE, wintypes.DWORD,
                                                wintypes.LPWSTR,
                                                ctypes.POINTER(wintypes.DWORD)]
kernel32.CloseHandle.argtypes = [HANDLE]
user32.IsClipboardFormatAvailable.restype  = wintypes.BOOL
user32.IsClipboardFormatAvailable.argtypes = [wintypes.UINT]


# --- input injection -------------------------------------------------------
def _send(events):
    """events: list of (vk, is_keyup). Injected as one atomic SendInput batch."""
    n = len(events)
    arr = (INPUT * n)()
    for i, (vk, is_up) in enumerate(events):
        flags = KEYEVENTF_KEYUP if is_up else 0
        if vk in EXTENDED:
            flags |= KEYEVENTF_EXTENDEDKEY
        arr[i].type = INPUT_KEYBOARD
        arr[i].u.ki = KEYBDINPUT(vk, 0, flags, 0, MAGIC)
    user32.SendInput(n, ctypes.byref(arr), ctypes.sizeof(INPUT))


def _down(vk):
    return user32.GetAsyncKeyState(vk) & 0x8000


def _fg_exe():
    """Lower-case basename of the foreground window's process, or '' on failure.
    Only called on the Alt+V chord (not every keystroke), so the process lookup
    stays well inside the low-level-hook time budget."""
    hwnd = user32.GetForegroundWindow()
    if not hwnd:
        return ''
    pid = wintypes.DWORD()
    user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
    if not pid.value:
        return ''
    h = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid.value)
    if not h:
        return ''
    try:
        buf  = ctypes.create_unicode_buffer(260)
        size = wintypes.DWORD(260)
        if kernel32.QueryFullProcessImageNameW(h, 0, buf, ctypes.byref(size)):
            return buf.value.rsplit('\\', 1)[-1].lower()
        return ''
    finally:
        kernel32.CloseHandle(h)


def _clip_has_image():
    """True if the clipboard holds a bitmap or a copied file (image-paste-able).
    IsClipboardFormatAvailable needs no OpenClipboard, so it's cheap + safe."""
    return any(user32.IsClipboardFormatAvailable(cf) for cf in IMAGE_CF)


def remap(*combo):
    """Release any held modifiers, tap `combo` (e.g. VK_CONTROL, VK_INSERT),
    then restore the modifiers - so the chord lands without the trigger's Alt."""
    held = [vk for vk in MOD_VKS if _down(vk)]
    events  = [(vk, True)  for vk in held]              # release held mods
    events += [(vk, False) for vk in combo]             # press chord
    events += [(vk, True)  for vk in reversed(combo)]   # release chord
    events += [(vk, False) for vk in held]              # restore held mods
    _send(events)


# --- the hook ---------------------------------------------------------------
def _proc(nCode, wParam, lParam):
    if nCode == HC_ACTION and wParam in (WM_KEYDOWN, WM_SYSKEYDOWN):
        kb = ctypes.cast(lParam, ctypes.POINTER(KBDLLHOOKSTRUCT)).contents
        if kb.dwExtraInfo != MAGIC:                     # skip our own injection
            vk = kb.vkCode
            if _down(ALT_VKS[0]) or _down(ALT_VKS[1]):  # Alt held?
                if vk == VK_C:
                    remap(VK_CONTROL, VK_INSERT)
                    return 1                            # suppress original
                if vk == VK_X:
                    remap(VK_CONTROL, VK_X)
                    return 1
                if vk == VK_V:
                    if _down(CTRL_VKS[0]) or _down(CTRL_VKS[1]):
                        remap(VK_LWIN, VK_V)            # clipboard history
                        return 1
                    if _clip_has_image() and _fg_exe() in TERMINAL_EXES:
                        # Image/file on the clipboard + a terminal focused: let
                        # the real Alt+V through so the CLI (Claude Code) pastes
                        # it. Text pastes fall through to Shift+Insert below.
                        return user32.CallNextHookEx(None, nCode, wParam,
                                                     lParam)
                    remap(VK_SHIFT, VK_INSERT)          # universal text paste
                    return 1
    return user32.CallNextHookEx(None, nCode, wParam, lParam)


HOOKPROC  = ctypes.WINFUNCTYPE(LRESULT, ctypes.c_int, wintypes.WPARAM,
                               wintypes.LPARAM)
_HOOK_REF = HOOKPROC(_proc)   # module-global: must outlive the process


def main():
    hook = user32.SetWindowsHookExW(WH_KEYBOARD_LL, _HOOK_REF,
                                    kernel32.GetModuleHandleW(None), 0)
    if not hook:
        raise ctypes.WinError(ctypes.get_last_error())
    msg = wintypes.MSG()
    while user32.GetMessageW(ctypes.byref(msg), None, 0, 0) != 0:
        user32.TranslateMessage(ctypes.byref(msg))
        user32.DispatchMessageW(ctypes.byref(msg))


if __name__ == '__main__':
    try:
        main()
    except Exception:
        import os
        import traceback
        log = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           'clipboard.log')
        with open(log, 'a', encoding='utf-8') as f:
            f.write(traceback.format_exc() + '\n')
        raise
