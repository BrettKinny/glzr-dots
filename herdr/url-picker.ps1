# Foot-style URL mode: fzf over URLs and file paths in the focused pane. Enter opens, Ctrl+Y copies.
$panes = (herdr pane list | Out-String | ConvertFrom-Json).result.panes
$pane = $panes | Where-Object focused | Select-Object -First 1
if (-not $pane) { return }

# recent-unwrapped rejoins URLs that soft-wrapped across lines
$text = herdr pane read $pane.pane_id --source recent-unwrapped --lines 2000 | Out-String

function Trim-Trailing($s) {
    $s = $s -replace '[.,;:!?\]}>]+$', ''
    # drop a closing paren only when unbalanced, so wiki-style a_(b) URLs survive
    while ($s.EndsWith(')') -and ($s.Split('(').Count -lt $s.Split(')').Count)) {
        $s = $s.Substring(0, $s.Length - 1) -replace '[.,;:!?]+$', ''
    }
    $s
}

$hits = [System.Collections.Generic.List[object]]::new()
$urlRx = '(?:https?|file)://[^\s<>"''`]+'
foreach ($m in [regex]::Matches($text, $urlRx)) {
    $hits.Add([pscustomobject]@{ At = $m.Index; Value = Trim-Trailing $m.Value })
}

# Paths need a separator; anything that doesn't exist on disk is dropped, which filters
# out false positives like "and/or". Relative ones resolve against the pane's cwd.
$pathText = [regex]::Replace($text, $urlRx, { ' ' * $args[0].Length })
$pathRx = '(?<![\w/\\])(?:[A-Za-z]:[\\/]|~[\\/]|\.{1,2}[\\/])?[\w.\-~@+]+(?:[\\/][\w.\-~@+]*)+'
foreach ($m in [regex]::Matches($pathText, $pathRx)) {
    # strip file:line:col suffixes
    $p = (Trim-Trailing $m.Value) -replace '(?<=\.\w+):\d+(?::\d+)?$', ''
    if ($p -match '^~[\\/]') { $p = Join-Path $HOME $p.Substring(2) }
    elseif (-not [IO.Path]::IsPathRooted($p)) { $p = Join-Path $pane.cwd $p }
    try { if (Test-Path -LiteralPath $p) { $hits.Add([pscustomobject]@{ At = $m.Index; Value = [IO.Path]::GetFullPath($p) }) } } catch {}
}
if (-not $hits.Count) { Write-Host 'No URLs or paths in pane.'; Start-Sleep -Milliseconds 800; return }

# newest first
$items = $hits | Sort-Object At -Descending | Select-Object -ExpandProperty Value -Unique
$out = $items | fzf --no-sort --expect=ctrl-y --prompt='open> ' --header='enter: open  ctrl-y: copy'
if (-not $out -or $out.Count -lt 2) { return }

$key, $target = $out[0], $out[1]
if ($key -eq 'ctrl-y') { Set-Clipboard $target } else { Start-Process $target }
