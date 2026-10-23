# ttt-pr: review a Bitbucket Cloud PR in ttt (https://tttedit.dev).
#
#   ttt pr 123           worktree at <repo-parent>/<repo>-ttt-pr-123 with the PR staged on top of
#                        its merge-base, then open ttt there on Current Changes
#   ttt pr 123 -Remove   delete that worktree (refuses if you've edited anything in it)
#   (`ttt pr` needs the `ttt` wrapper in profile.ps1; `ttt-pr 123` works standalone)
#
# Run from anywhere inside the repo. ttt can only diff HEAD vs index vs working tree, not two refs,
# so HEAD is detached at the merge-base and the PR head is soft-reset onto it: Staged Changes is then
# exactly origin/<target>...<source>, i.e. what Bitbucket shows. Don't commit in it (local only, harmless).
# Separate from fresh-pr's worktree on purpose: that one keeps HEAD at the PR head.
#
# Needs: PowerShell 7, git 2.31+, ttt on PATH, Bitbucket credentials:
#   $env:BITBUCKET_USER       Atlassian account email
#   $env:BITBUCKET_API_TOKEN  https://id.atlassian.com/manage-profile/security/api-tokens
# Falls back to the env block of ~/.claude/settings.local.json if those aren't set.
#
# Load it from $PROFILE:  . path\to\ttt-pr.ps1

function ttt-pr {
    param(
        [Parameter(Mandatory)][int]$Id,
        [switch]$Remove
    )
    $commonDir = git rev-parse --path-format=absolute --git-common-dir 2>$null
    if (-not $commonDir) { Write-Host 'ttt pr: not in a git repo' -ForegroundColor Red; return }
    # Main checkout even when run from inside another worktree.
    $main = Split-Path $commonDir -Parent
    $repo = Split-Path $main -Leaf
    $wt = Join-Path (Split-Path $main -Parent) "$repo-ttt-pr-$Id"

    # Untouched = index matches the PR head (ORIG_HEAD, left by reset --soft), nothing unstaged or untracked.
    # ORIG_HEAD moved by anything else reads as edited, so this errs towards keeping files.
    $hasEdits = {
        git -C $wt diff --quiet; if ($LASTEXITCODE) { return $true }
        git -C $wt diff --quiet --cached ORIG_HEAD 2>$null; if ($LASTEXITCODE) { return $true }
        [bool](git -C $wt ls-files --others --exclude-standard)
    }

    if ($Remove) {
        if ((Test-Path $wt) -and (& $hasEdits)) {
            Write-Host "ttt pr: $wt has local edits, not removed (git worktree remove --force to discard)" -ForegroundColor Yellow; return
        }
        # --force: the staged PR counts as uncommitted changes.
        git -C $main worktree remove --force $wt
        # git can unregister the worktree yet fail to delete the folder when something holds it.
        if (Test-Path $wt) { Write-Host "ttt pr: $wt still in use (ttt open there?)" -ForegroundColor Yellow }
        return
    }

    $remote = git -C $main remote get-url origin
    if ($remote -notmatch 'bitbucket\.org[:/]([^/]+)/([^/]+?)(\.git)?$') {
        Write-Host "ttt pr: origin isn't Bitbucket ($remote)" -ForegroundColor Red; return
    }
    $api = "https://api.bitbucket.org/2.0/repositories/$($Matches[1])/$($Matches[2])/pullrequests/$Id"

    $user = $env:BITBUCKET_USER; $token = $env:BITBUCKET_API_TOKEN
    if (-not $token -and (Test-Path "$HOME\.claude\settings.local.json")) {
        $envBlock = (Get-Content "$HOME\.claude\settings.local.json" -Raw | ConvertFrom-Json).env
        $user = $envBlock.BITBUCKET_USER; $token = $envBlock.BITBUCKET_API_TOKEN
    }
    if (-not $token) { Write-Host 'ttt pr: set BITBUCKET_USER and BITBUCKET_API_TOKEN' -ForegroundColor Red; return }
    $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${user}:$token"))

    try { $pr = Invoke-RestMethod $api -Headers @{ Authorization = $auth } }
    catch { Write-Host "ttt pr: PR #$Id lookup failed: $($_.Exception.Message)" -ForegroundColor Red; return }
    if ($pr.source.repository.full_name -ne $pr.destination.repository.full_name) {
        Write-Host "ttt pr: PR is from a fork ($($pr.source.repository.full_name)); not supported" -ForegroundColor Red; return
    }
    $src = $pr.source.branch.name
    $dst = $pr.destination.branch.name

    git -C $main fetch --quiet origin "+refs/heads/${src}:refs/remotes/origin/$src" "+refs/heads/${dst}:refs/remotes/origin/$dst"
    if ($LASTEXITCODE) { return }
    $base = git -C $main merge-base "origin/$dst" "origin/$src"
    if (-not $base) { Write-Host "ttt pr: no merge-base for $src and $dst" -ForegroundColor Red; return }

    # Detached, so no branch to clash with fresh-pr or a checkout of the source branch.
    if (Test-Path $wt) {
        if (& $hasEdits) { Write-Host "ttt pr: $wt has local edits, left as is" -ForegroundColor Yellow }
        else { git -C $wt reset --quiet --hard "origin/$src"; git -C $wt reset --quiet --soft $base }
    } else {
        git -C $main worktree add --quiet --detach $wt "origin/$src"
        if ($LASTEXITCODE) { return }
        git -C $wt reset --quiet --soft $base
    }

    Write-Host "#$Id $($pr.title)" -ForegroundColor Cyan
    Write-Host "$($pr.author.display_name)  $src -> $dst  $($pr.links.html.href)" -ForegroundColor DarkGray

    # Not --exec: that runs ttt headless (renders to a virtual screen, terminal stays blank).
    $lua = Join-Path ([IO.Path]::GetTempPath()) 'ttt-pr-open-changes.lua'
    Set-Content $lua 'local ttt = require("ttt"); ttt.set_timeout(0, function() ttt.exec_command("changes.viewAll") end)'

    Push-Location $wt
    # ttt.exe, not ttt: the profile's `ttt` wrapper would route back here on `ttt pr`.
    try { ttt.exe --plugin $lua } finally { Pop-Location }
}
