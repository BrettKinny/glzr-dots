# glzr-dots PowerShell profile
# Sourced by the real $PROFILE (a one-line shim in OneDrive's Documents\PowerShell).
# Everything tool-dependent is guarded so this loads cleanly on a fresh machine
# before the optional tools are installed.

#region Console encoding  ->  UTF-8 in, UTF-8 out
# MUST come before the starship region. `starship init powershell` emits a stub
# that runs `starship init powershell --print-full-init | Out-String`, and that
# inner capture is decoded with [Console]::OutputEncoding — which an interactive
# console leaves on the OEM codepage (437/850). The full init text contains a
# literal ❯ for the transient prompt, so on an OEM codepage it gets baked into
# the session as "Γ¥»" (U+276F's UTF-8 bytes E2 9D AF read as CP437) and stays
# broken for the life of the shell. The main prompt escapes this because
# starship's per-prompt calls pin StandardOutputEncoding to UTF8 themselves.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
#endregion

#region $EDITOR  ->  Microsoft Edit (the `edit` TUI)
# Covers anything that shells out to an editor: git, lazygit, and elio's fallback
# when no [[open.rules]] entry matches. A persistent User-scope env var is set too
# (so GUI-launched apps see it); this region is what makes a fresh clone work
# before that's been done.
#
# The value must be the FULL winget path, never the bare name `edit`: Windows 11
# ships its own edit.exe in System32, so anything resolving `edit` on PATH gets
# v1.2.1 instead of the v2.0.0 we installed. Aliases don't help — lazygit and git
# spawn the editor themselves and never see PowerShell's alias table.
#
# Resolved at load time (the winget package dir is version-stamped) so this
# survives upgrades; $editExe is reused by the `edit` alias further down.
$editExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Microsoft.Edit_*" -Recurse -Filter edit.exe -ErrorAction SilentlyContinue |
    Sort-Object { [version]$_.VersionInfo.FileVersion } -Descending |
    Select-Object -First 1 -ExpandProperty FullName

# Don't clobber an explicit override from the parent process — but do correct a
# stale value we set ourselves on an earlier upgrade.
$editorTarget = if ($editExe) { $editExe } elseif (Get-Command edit.exe -ErrorAction SilentlyContinue) { 'edit' }
if ($editorTarget -and (-not $env:EDITOR -or $env:EDITOR -eq 'edit' -or $env:EDITOR -like '*\Microsoft.Edit_*')) {
    $env:EDITOR = $editorTarget
    # Keep the User-scope copy in step for GUI-launched apps (writes only on drift).
    if ([Environment]::GetEnvironmentVariable('EDITOR', 'User') -ne $editorTarget) {
        [Environment]::SetEnvironmentVariable('EDITOR', $editorTarget, 'User')
    }
}
#endregion

#region PSReadLine  ->  inline predictions from history, menu-style tab
# InlineView, not ListView, and that's deliberate — think twice before switching
# back. ListView's prediction rows are drawn below the input line, and anything
# that moves the cursor out from under PSReadLine orphans them on screen:
#   - Microsoft Edit (now $EDITOR, see the region above) runs in the alternate
#     screen buffer and doesn't restore the cursor row on exit, so the next
#     prompt is drawn near the top of the buffer while the list rows are still
#     keyed to the old, lower row. Dead "[History]" lines, one per `edit`.
#   - starship's transient prompt only pads the rows away if it saw ListView at
#     init time (it captures `$script:DoesUseLists` once), which made this
#     region's position relative to the starship region load-bearing.
# InlineView renders the suggestion on the input line itself, so there are no
# rows to orphan and neither trap applies.
if (Get-Module PSReadLine) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    # Prediction needs a VT-capable, non-redirected console; swallow the error
    # when the profile is sourced in a plain/redirected host (e.g. from a script).
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle InlineView -ErrorAction Stop
    } catch { }
}
#endregion

#region Prompt  ->  starship (config in ./starship.toml, ANSI-themed)
# Must stay above the "Terminal cwd tracking" region, which wraps whatever
# prompt function this installs, and below the two regions above — see their
# notes for why the order is load-bearing.
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $env:STARSHIP_CONFIG = Join-Path $PSScriptRoot 'starship.toml'
    Invoke-Expression (& starship init powershell)
    # Transient prompt: once a command is submitted, redraw the prompt that ran
    # it as a bare glyph. Scrollback becomes a clean column of commands instead
    # of a repeated path/git wall. Needs a VT-capable host, so don't let a
    # redirected/plain host (e.g. sourcing this from a script) take the profile
    # down with it.
    try { Enable-TransientPrompt } catch { }
}
# Previous prompt, kept for a one-line revert (winget: JanDeDobbeleer.OhMyPosh):
# if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
#     oh-my-posh init pwsh | Invoke-Expression
# }
#endregion

#region zoxide  ->  `z <dir>` to jump, `zi` for interactive picker
# (Replaces the `cd` muscle memory with frecency-based jumping.)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
#endregion

#region fzf + PSFzf  ->  Ctrl+T fuzzy file finder, Ctrl+R history
# Use fd for the file walk (fast, respects .gitignore, skips .git) and bat for previews.
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = '--height 60% --layout=reverse --border --info=inline --cycle'

    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
        $env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
        $env:FZF_ALT_C_COMMAND   = 'fd --type d --hidden --follow --exclude .git'
    }
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        $env:FZF_CTRL_T_OPTS = '--preview "bat --color=always --style=numbers --line-range :300 {}"'
    }

    # Don't guard with `Get-Module -ListAvailable PSFzf` — that walks every
    # PSModulePath entry (one of which is on OneDrive) to answer a question
    # Import-Module can answer for free: ~90ms of the profile's load time for
    # nothing. Just try the import and move on if it isn't installed.
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Module PSFzf) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}
#endregion

#region eza  ->  modern `ls` (git status, icons, tree)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza --icons --group-directories-first @args }
    function ll { eza -l --icons --git --group-directories-first @args }
    function la { eza -la --icons --git --group-directories-first @args }
    function lt { eza --tree --level=2 --icons @args }
}
#endregion

#region bat  ->  `cat` with syntax highlighting
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    function cat { bat --style=plain --paging=never @args }
}
#endregion

#region gsudo  ->  `sudo` (only if Windows has no native sudo)
if ((Get-Command gsudo -ErrorAction SilentlyContinue) -and -not (Get-Command sudo -ErrorAction SilentlyContinue)) {
    Set-Alias sudo gsudo
}
#endregion

#region Small Linux-reflex helpers
# `which <cmd>` -> resolved path, like the Unix builtin
function which { (Get-Command @args -ErrorAction SilentlyContinue).Source }
# `touch <file>` -> create if missing, bump timestamp if it exists (no truncate)
function touch {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path $Path) { (Get-Item $Path).LastWriteTime = Get-Date }
    else { New-Item -ItemType File -Path $Path | Out-Null }
}
#endregion

#region Aliases
Set-Alias -Name c -Value claude
Set-Alias -Name f -Value fresh
Set-Alias -Name lg -Value lazygit
Set-Alias -Name lj -Value lazyjira
Set-Alias -Name e -Value edit

# Microsoft Edit v2.0 (winget) instead of the older System32 edit.exe.
# $editExe is resolved in the $EDITOR region at the top of this file.
if ($editExe) { Set-Alias edit $editExe }
#endregion

#region Terminal cwd tracking  ->  Alt+Enter opens new terminals in this pane's folder
# Records "WT window handle -> $PWD" on every prompt so glazewm/new-terminal.ps1
# can launch the next terminal in the same folder (omarchy-style). All WT windows
# share one WindowsTerminal.exe process, so the window handle — captured via
# GetForegroundWindow at prompt time — is the only reliable key to this pane.
# Must stay below the starship/zoxide regions: it wraps whatever prompt
# function they installed.
if ($env:WT_SESSION) {
    $script:__cwdTrackDir = Join-Path $env:LOCALAPPDATA 'glazewm\term-cwd'
    New-Item -ItemType Directory -Force -Path $script:__cwdTrackDir | Out-Null

    # Compiling these two P/Invokes with Add-Type costs ~445ms on every single
    # shell start — it invokes the C# compiler. Measured (12 interleaved reps,
    # median, net of an empty-pwsh baseline): compile 444ms vs loading a
    # pre-built assembly 145ms. So compile once into a cached DLL next to the
    # term-cwd data and just load it thereafter. This was the largest single
    # cost in the profile.
    if (-not ('GlzrDots.Win32' -as [type])) {
        $__win32Src = @'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
'@
        $__win32Asm = Join-Path $env:LOCALAPPDATA 'glazewm\GlzrDots.Win32.dll'
        if (-not (Test-Path $__win32Asm)) {
            # First run on this machine (or after deleting the cache): pay the
            # compile once and write the assembly out for every later shell.
            Add-Type -Namespace GlzrDots -Name Win32 -MemberDefinition $__win32Src -OutputAssembly $__win32Asm
        }
        try {
            Add-Type -Path $__win32Asm -ErrorAction Stop
        } catch {
            # Cache truncated, or built for the wrong runtime. Bin it so the
            # next shell regenerates a good one, then compile in-memory for this
            # session so Alt+Enter never silently breaks. Without the delete, a
            # bad cache would cost every future shell a failed load *plus* the
            # full compile, which is worse than having no cache at all.
            Remove-Item $__win32Asm -Force -ErrorAction SilentlyContinue
            Add-Type -Namespace GlzrDots -Name Win32 -MemberDefinition $__win32Src
        }
    }

    # Cache pid -> is-it-WindowsTerminal so the common case is one Win32 call.
    $script:__wtPidCache = @{}
    $script:__cwdTrackPrevPrompt = $function:prompt

    function prompt {
        $prevSuccess = $global:?
        $prevExitCode = $global:LASTEXITCODE
        try {
            $hwnd = [GlzrDots.Win32]::GetForegroundWindow()
            $wpid = 0u
            [GlzrDots.Win32]::GetWindowThreadProcessId($hwnd, [ref]$wpid) | Out-Null
            if ($wpid) {
                if (-not $script:__wtPidCache.ContainsKey($wpid)) {
                    $script:__wtPidCache[$wpid] =
                        (Get-Process -Id $wpid -ErrorAction SilentlyContinue).ProcessName -eq 'WindowsTerminal'
                }
                if ($script:__wtPidCache[$wpid]) {
                    [IO.File]::WriteAllText(
                        (Join-Path $script:__cwdTrackDir "$([int64]$hwnd).txt"), $PWD.Path)
                }
            }
        } catch { }
        # Restore $LASTEXITCODE and $? so prompt segments (e.g. starship's
        # character/status modules) still see the user's last command, not our hook.
        $global:LASTEXITCODE = $prevExitCode
        if (-not $prevSuccess) { Write-Error '' -ErrorAction SilentlyContinue }
        & $script:__cwdTrackPrevPrompt
    }
}
#endregion

#region ask  ->  one-shot Claude (haiku) straight into the terminal
# `ask "how do I ..."`        chat mode: no tools, general knowledge, fastest
# `ask -f "what does X do"`   file mode: read-only Read/Glob/Grep over the cwd
# `git diff | ask "explain"`  anything piped in is appended as context
# `-r` / `-Raw`               force glow rendering on / off (see below)
#
# Wraps the `claude` CLI rather than the raw API so it reuses the existing
# subscription auth. The speed flags matter: --effort low kills the extended
# thinking block (the single biggest latency win), and the mcp/slash/session
# flags skip startup work that a one-shot question never uses. Output is parsed
# out of stream-json so tokens appear as they arrive instead of in one dump.
#
# Rendering is per-mode because glow can't stream — it needs the whole document,
# so piping through it means waiting for the full answer before anything appears.
# Chat mode replaces the system prompt outright and reliably answers in plain
# text, so it streams raw. File mode can only *append* to Claude Code's default
# system prompt, which keeps emitting fences and bold no matter how the terse
# instruction is worded, so it buffers and renders. Both are overridable.
function ask {
    [CmdletBinding()]
    param(
        [Alias('f')][switch]$Files,
        [Alias('r')][switch]$Render,
        [switch]$Raw,
        [Alias('m')][Parameter(DontShow)][string]$Model = 'haiku',
        [Parameter(ValueFromPipeline, DontShow)][string]$InputObject,
        # Position 0 + remaining args, so `ask what is a hard link` works unquoted
        # and the pipeline/model params never swallow the question.
        [Parameter(Position = 0, ValueFromRemainingArguments)][string[]]$Question
    )
    begin { $piped = [System.Collections.Generic.List[string]]::new() }
    process { if ($PSBoundParameters.ContainsKey('InputObject')) { $piped.Add($InputObject) } }
    end {
        $q = ($Question -join ' ').Trim()
        if (-not $q) {
            Write-Host 'usage: ask [-f] [-m <model>] "your question"' -ForegroundColor Yellow
            Write-Host '       -f  search the files in the current folder for the answer' -ForegroundColor DarkGray
            return
        }
        if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
            Write-Host 'claude CLI not found on PATH.' -ForegroundColor Red; return
        }
        if ($piped.Count) { $q = "$q`n`n--- piped input ---`n" + ($piped -join "`n") }

        $terse = 'You are answering at a shell prompt. Be terse: no preamble, no restating the ' +
                 'question, no sign-off. Plain text only - never use markdown code fences, headers, ' +
                 'or bold. Put any command on its own line, followed by at most one short line of ' +
                 'explanation. The user is on Windows 11 with PowerShell 7 unless they say otherwise.'

        $cmd = @(
            '-p', $q
            '--model', $Model
            '--effort', 'low'
            '--no-session-persistence'
            '--strict-mcp-config'
            '--disable-slash-commands'
            '--output-format', 'stream-json'
            '--include-partial-messages'
            '--verbose'
        )
        if ($Files) {
            $cmd += @(
                '--allowed-tools', 'Read', 'Glob', 'Grep'
                '--disallowed-tools', 'Edit', 'Write', 'Bash', 'WebFetch', 'WebSearch'
                '--append-system-prompt', ($terse + ' Answer from the files in this directory and ' +
                    'cite path:line. If the files do not answer it, say so rather than guessing.')
            )
        } else {
            # --tools "" disables every tool, so the default system prompt (all the
            # tool-use scaffolding) is dead weight; replace it outright with --system-prompt.
            $cmd += @('--tools', '', '--system-prompt', $terse)
        }

        $glow = (Get-Command glow -ErrorAction SilentlyContinue).Source
        $useGlow = $glow -and -not $Raw -and ($Render -or $Files)
        $buf = if ($useGlow) { [System.Text.StringBuilder]::new() } else { $null }

        $started = $false
        Write-Host -NoNewline '...' -ForegroundColor DarkGray
        & claude @cmd 2>$null | ForEach-Object {
            if ($_.Length -eq 0 -or $_[0] -ne '{') { return }
            try { $ev = $_ | ConvertFrom-Json } catch { return }
            switch ($ev.type) {
                'stream_event' {
                    $b = $ev.event
                    if ($b.type -eq 'content_block_delta' -and $b.delta.type -eq 'text_delta') {
                        if ($useGlow) { [void]$buf.Append($b.delta.text); return }
                        if (-not $started) { Write-Host -NoNewline "`r   `r"; $started = $true }
                        Write-Host -NoNewline $b.delta.text
                    }
                    elseif ($b.type -eq 'content_block_start' -and $b.content_block.type -eq 'tool_use') {
                        Write-Host -NoNewline "`r   `r"; $started = $true
                        # Only the tool name is known at block start - the arguments arrive
                        # later as input_json_delta fragments, not worth reassembling.
                        Write-Host ("  · {0}" -f $b.content_block.name) -ForegroundColor DarkGray
                    }
                }
                'result' {
                    if (-not $started) { Write-Host -NoNewline "`r   `r" }
                    if ($ev.is_error) { Write-Host $ev.result -ForegroundColor Red }
                }
            }
        }

        if ($useGlow -and $buf.Length) {
            # -w keeps glow's wrap inside the window (it defaults to 80 and its own
            # style adds a 2-col margin); - reads the document from stdin.
            $w = [Math]::Max(40, $Host.UI.RawUI.WindowSize.Width - 2)
            # The console-encoding region sets $OutputEncoding to UTF8 *with* a BOM,
            # which PowerShell writes into any native command's stdin. glow treats
            # those three bytes as document text and prints a stray U+FEFF before the
            # first word. Swap in a BOM-less encoder just for this pipe.
            $prevOut = $OutputEncoding
            $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
            try { $buf.ToString() | & $glow -s auto -w $w - }
            finally { $OutputEncoding = $prevOut }
        } else {
            Write-Host ''
        }
    }
}
#endregion

#region local LLM (llama.cpp - Qwen3.6-35B-A3B on Arc 140V)
function llm {
    # Start the local LLM server (http://localhost:8080). See C:\llama.cpp\start-llm.ps1
    if (Get-Process llama-server -ErrorAction SilentlyContinue) {
        Write-Host 'llama-server already running -> http://localhost:8080' -ForegroundColor Yellow
        return
    }
    Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','C:\llama.cpp\start-llm.ps1' `
        -RedirectStandardOutput 'C:\llama.cpp\server.log' -RedirectStandardError 'C:\llama.cpp\server.err.log' -WindowStyle Hidden
    Write-Host 'Starting llama-server... (loads in ~30s)  ->  http://localhost:8080' -ForegroundColor Cyan
    for ($i=0; $i -lt 40; $i++) {
        try { if ((Invoke-RestMethod http://localhost:8080/health -TimeoutSec 3).status -eq 'ok') { Write-Host 'Ready.' -ForegroundColor Green; return } } catch {}
        Start-Sleep 2
    }
    Write-Host 'Not ready yet - check: llm-log' -ForegroundColor Red
}
function llm-stop { Get-Process llama-server -ErrorAction SilentlyContinue | Stop-Process -Force; Write-Host 'llama-server stopped.' }
function llm-log  { Get-Content 'C:\llama.cpp\server.err.log' -Tail 20 }
#endregion
