# One ttt split per herdr tab: focus it, open one at the repo root, or open a file in it.
# -Open takes file[:line[:col]] (url-picker.ps1): this tab's split if it has one, else the
# standalone ttt window, else a new window. Ctrl+Shift+E calls it bare.
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

# Socket name ends in the editor's pid, base 36; pin to that editor, not the newest.
function Forward($procId) {
    $b36 = ''; $n = [long]$procId
    do { $b36 = "$('0123456789abcdefghijklmnopqrstuvwxyz'[[int]($n % 36)])$b36"; $n = [math]::Floor($n / 36) } while ($n -gt 0)
    $sock = Get-ChildItem "$env:TEMP\ttt--1\*-$b36.sock" -ErrorAction SilentlyContinue | Select-Object -First 1
    # No socket → skip: a failed forward starts a full editor here, which hangs with no TTY.
    if (-not $sock) { return $false }
    $env:TTT_FORWARD_SOCKET = $sock.FullName
    ttt $Open 2>$null | Out-Null
    $true
}

function Get-Root {
    $cwd = $env:HERDR_ACTIVE_PANE_CWD
    if (-not $cwd) { $cwd = (Hq pane get $active).pane.cwd }
    $root = git -C $cwd rev-parse --show-toplevel 2>$null
    if ($root) { $root } else { $cwd }
}

function Quote($s) { "'" + ($s -replace "'", "''") + "'" }

if ($Open -and -not $side) {
    # Standalone = not under a herdr pane shell (Alt+Shift+N window, or ttt run in a plain wt tab).
    $win = $ttts | Where-Object {
        $p = Get-Process -Id $_.ParentProcessId -ErrorAction SilentlyContinue
        $p -and $p.ProcessName -ne 'herdr' -and $p.Parent.ProcessName -ne 'herdr'
    } | Sort-Object CreationDate | Select-Object -Last 1
    if ($win -and (Forward $win.ProcessId)) {
        # ttt sets no title; the wt launchers title the window "ttt" so GlazeWM can find it.
        $w = (glazewm query windows | ConvertFrom-Json).data.windows | Where-Object title -eq 'ttt' | Select-Object -First 1
        if ($w) { glazewm command focus --container-id $w.id | Out-Null }
    } else {
        wt.exe --title ttt --suppressApplicationTitle (Get-Command ttt).Source --new-window (Get-Root) $Open
    }
    return
}

if (-not $side) {
    $root = Get-Root
    $new = (Hq pane split $active --direction right --ratio 0.65 --cwd $root --right-click pane --focus).pane.pane_id
    # --new-window: with reuseWindow on, a folder arg would otherwise land in another tab's ttt
    herdr pane run $new "ttt --new-window $(Quote $root); exit" | Out-Null
    return
}

if ($Open) {
    Forward $tttPid | Out-Null
    Focus-Pane $side.pane_id
} elseif ($layout.focused_pane_id -eq $side.pane_id) {
    herdr pane focus --direction left --pane $side.pane_id | Out-Null
} else {
    Focus-Pane $side.pane_id
}
