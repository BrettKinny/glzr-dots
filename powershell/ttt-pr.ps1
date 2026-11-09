# ttt-pr: `ttt pr 123` → worktree <repo-parent>/<repo>-ttt-pr-123 with Bitbucket PR 123 staged on its
# merge-base (Staged Changes = what Bitbucket shows), added to the running ttt (reuseWindow).
# Review, reply, merge and clean up (Done) in ttt's bitbucket-review plugin.
# Needs: PowerShell 7, git, ttt, bkt (authenticated). Run from inside the repo.

function ttt-pr {
    param([Parameter(Mandatory)][int]$Id)
    $commonDir = git rev-parse --path-format=absolute --git-common-dir 2>$null
    if (-not $commonDir) { Write-Host 'ttt pr: not in a git repo' -ForegroundColor Red; return }
    $main = Split-Path $commonDir -Parent
    $wt = Join-Path (Split-Path $main -Parent) "$(Split-Path $main -Leaf)-ttt-pr-$Id"

    # Existing worktree: just open it; Enter on the PR in ttt refreshes it.
    if (-not (Test-Path $wt)) {
        $json = bkt pr view $Id --json
        if ($LASTEXITCODE) { return }
        $pr = ($json | ConvertFrom-Json).pull_request
        $src = $pr.source.branch.name; $dst = $pr.destination.branch.name
        git -C $main fetch --quiet origin "+refs/heads/${src}:refs/remotes/origin/$src" "+refs/heads/${dst}:refs/remotes/origin/$dst"
        if ($LASTEXITCODE) { return }
        $base = git -C $main merge-base "origin/$dst" "origin/$src"
        if (-not $base) { Write-Host "ttt pr: no merge-base for $src and $dst" -ForegroundColor Red; return }
        # ttt diffs HEAD vs index only, so detach at the PR head and soft-reset onto the merge-base.
        git -C $main worktree add --quiet --detach $wt "origin/$src"
        if ($LASTEXITCODE) { return }
        git -C $wt reset --quiet --soft $base
    }
    # ttt.exe, not ttt: the profile's `ttt` wrapper would route back here on `ttt pr`.
    ttt.exe $wt
}
