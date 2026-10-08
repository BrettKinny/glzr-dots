# freshpr: review a Bitbucket Cloud PR in Fresh (https://getfresh.dev).
#
#   freshpr 123          worktree at <repo-parent>/<repo>-pr-123 on the PR head, then open Fresh there
#   freshpr 123 -Remove  delete that worktree
#
# Run from anywhere inside the repo. Then in Fresh: Ctrl+P > Review Diff: Range, clear HEAD,
# paste (the range is put on the clipboard).
#
# Needs: PowerShell 7, git 2.31+, `fresh` on PATH (exe or function), Bitbucket credentials:
#   $env:BITBUCKET_USER       Atlassian account email
#   $env:BITBUCKET_API_TOKEN  https://id.atlassian.com/manage-profile/security/api-tokens
# Falls back to the env block of ~/.claude/settings.local.json if those aren't set.
#
# Load it from $PROFILE:  . path\to\freshpr.ps1

function freshpr {
    param(
        [Parameter(Mandatory)][int]$Id,
        [switch]$Remove
    )
    $commonDir = git rev-parse --path-format=absolute --git-common-dir 2>$null
    if (-not $commonDir) { Write-Host 'freshpr: not in a git repo' -ForegroundColor Red; return }
    # Main checkout even when run from inside another worktree.
    $main = Split-Path $commonDir -Parent
    $repo = Split-Path $main -Leaf
    $wt = Join-Path (Split-Path $main -Parent) "$repo-pr-$Id"

    if ($Remove) { git -C $main worktree remove $wt; return }

    $remote = git -C $main remote get-url origin
    if ($remote -notmatch 'bitbucket\.org[:/]([^/]+)/([^/]+?)(\.git)?$') {
        Write-Host "freshpr: origin isn't Bitbucket ($remote)" -ForegroundColor Red; return
    }
    $api = "https://api.bitbucket.org/2.0/repositories/$($Matches[1])/$($Matches[2])/pullrequests/$Id"

    $user = $env:BITBUCKET_USER; $token = $env:BITBUCKET_API_TOKEN
    if (-not $token -and (Test-Path "$HOME\.claude\settings.local.json")) {
        $envBlock = (Get-Content "$HOME\.claude\settings.local.json" -Raw | ConvertFrom-Json).env
        $user = $envBlock.BITBUCKET_USER; $token = $envBlock.BITBUCKET_API_TOKEN
    }
    if (-not $token) { Write-Host 'freshpr: set BITBUCKET_USER and BITBUCKET_API_TOKEN' -ForegroundColor Red; return }
    $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${user}:$token"))

    try { $pr = Invoke-RestMethod $api -Headers @{ Authorization = $auth } }
    catch { Write-Host "freshpr: PR #$Id lookup failed: $($_.Exception.Message)" -ForegroundColor Red; return }
    if ($pr.source.repository.full_name -ne $pr.destination.repository.full_name) {
        Write-Host "freshpr: PR is from a fork ($($pr.source.repository.full_name)); not supported" -ForegroundColor Red; return
    }
    $src = $pr.source.branch.name
    $dst = $pr.destination.branch.name

    git -C $main fetch --quiet origin "+refs/heads/${src}:refs/remotes/origin/$src" "+refs/heads/${dst}:refs/remotes/origin/$dst"
    if ($LASTEXITCODE) { return }

    # Detached HEAD so it never clashes with the source branch being checked out elsewhere.
    if (Test-Path $wt) {
        if (git -C $wt status --porcelain) { Write-Host "freshpr: $wt has local changes, left as is" -ForegroundColor Yellow }
        else { git -C $wt checkout --quiet --detach "origin/$src" }
    } else {
        git -C $main worktree add --quiet --detach $wt "origin/$src"
        if ($LASTEXITCODE) { return }
    }

    # Three-dot = diff from merge-base, i.e. what Bitbucket shows. The Fresh range prompt
    # can't be pre-filled from outside, so hand it over via the clipboard.
    $range = "origin/$dst...HEAD"
    Set-Clipboard $range
    Write-Host "#$Id $($pr.title)" -ForegroundColor Cyan
    Write-Host "$($pr.author.display_name)  $src -> $dst  $($pr.links.html.href)" -ForegroundColor DarkGray
    Write-Host "Ctrl+P > Review Diff: Range, clear HEAD, paste $range" -ForegroundColor DarkGray

    Push-Location $wt
    try { fresh } finally { Pop-Location }
}
