# One ttt split per herdr tab: focus it, open one at the repo root, or open a file in it.
# -Open takes file[:line[:col]]. Called from a keybind (Ctrl+Shift+E) and url-picker.ps1.
param([string]$Open)

# Not named Herdr: PowerShell is case-insensitive, so it would shadow herdr.exe and recurse.
function Hq { (& herdr.exe @args | Out-String | ConvertFrom-Json).result }

$active = $env:HERDR_ACTIVE_PANE_ID
if (-not $active) { $active = (Hq pane current).pane.pane_id }
$layout = (Hq pane layout --pane $active).layout

# ttt runs as a child of the pane's shell; process-info only reports the shell.
$ttts = @(Get-CimInstance Win32_Process -Filter "Name='ttt.exe'")
$side = $null; $tttPid = $null
if ($ttts) {
    foreach ($p in $layout.panes) {
        $shell = (Hq pane process-info --pane $p.pane_id).process_info.shell_pid
        $hit = $ttts | Where-Object ParentProcessId -eq $shell | Select-Object -First 1
        if ($hit) { $side = $p; $tttPid = $hit.ProcessId; break }
    }
}

# herdr CLI can't focus a pane by id, only by direction, so walk there using the rects.
function Focus-Pane($targetId) {
    for ($i = 0; $i -lt 8; $i++) {
        $l = (Hq pane layout --pane $active).layout
        if ($l.focused_pane_id -eq $targetId) { return }
        $c = ($l.panes | Where-Object pane_id -eq $l.focused_pane_id).rect
        $t = ($l.panes | Where-Object pane_id -eq $targetId).rect
        $dir = if ($t.x -ge $c.x + $c.width) { 'right' } elseif ($t.x + $t.width -le $c.x) { 'left' }
               elseif ($t.y -ge $c.y + $c.height) { 'down' } else { 'up' }
        herdr pane focus --direction $dir --pane $l.focused_pane_id | Out-Null
    }
}

function Quote($s) { "'" + ($s -replace "'", "''") + "'" }

if (-not $side) {
    $cwd = $env:HERDR_ACTIVE_PANE_CWD
    if (-not $cwd) { $cwd = (Hq pane get $active).pane.cwd }
    $root = git -C $cwd rev-parse --show-toplevel 2>$null
    if (-not $root) { $root = $cwd }
    $new = (Hq pane split $active --direction right --ratio 0.65 --cwd $root --right-click pane --focus).pane.pane_id
    # --new-window: with reuseWindow on, a folder arg would otherwise land in another tab's ttt
    $cmd = "ttt --new-window $(Quote $root)"
    if ($Open) { $cmd += " $(Quote $Open)" }
    herdr pane run $new "$cmd; exit" | Out-Null
    return
}

if ($Open) {
    # Socket name ends in the editor's pid, base 36; pin to this tab's editor, not the newest.
    $b36 = ''; $n = [long]$tttPid
    do { $b36 = "$('0123456789abcdefghijklmnopqrstuvwxyz'[[int]($n % 36)])$b36"; $n = [math]::Floor($n / 36) } while ($n -gt 0)
    $sock = Get-ChildItem "$env:TEMP\ttt--1\*-$b36.sock" -ErrorAction SilentlyContinue | Select-Object -First 1
    # No socket → skip: a failed forward starts a full editor here, which hangs with no TTY.
    if ($sock) {
        $env:TTT_FORWARD_SOCKET = $sock.FullName
        ttt $Open 2>$null
    }
    Focus-Pane $side.pane_id
} elseif ($layout.focused_pane_id -eq $side.pane_id) {
    herdr pane focus --direction left --pane $side.pane_id | Out-Null
} else {
    Focus-Pane $side.pane_id
}
