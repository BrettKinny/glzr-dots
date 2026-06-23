# glzr-dots PowerShell profile
# Sourced by the real $PROFILE (a one-line shim in OneDrive's Documents\PowerShell).
# Everything tool-dependent is guarded so this loads cleanly on a fresh machine
# before the optional tools are installed.

#region Prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
}
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

    if (Get-Module -ListAvailable PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}
#endregion

#region PSReadLine  ->  inline + list predictions from history, menu-style tab
if (Get-Module PSReadLine) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    # Prediction needs a VT-capable, non-redirected console; swallow the error
    # when the profile is sourced in a plain/redirected host (e.g. from a script).
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView -ErrorAction Stop
    } catch { }
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

#region lazygit  ->  `lg` terminal UI for git
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias lg lazygit
}
#endregion

#region Aliases
Set-Alias -Name c -Value claude

# Microsoft Edit v2.0 (winget) instead of the older System32 edit.exe.
# Resolve the newest installed build at load time so the alias survives upgrades.
$editExe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Microsoft.Edit_*" -Recurse -Filter edit.exe -ErrorAction SilentlyContinue |
    Sort-Object { [version]$_.VersionInfo.FileVersion } -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if ($editExe) { Set-Alias edit $editExe }
#endregion
