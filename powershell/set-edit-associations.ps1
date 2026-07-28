<#
.SYNOPSIS
    Make plain-text / config files open in Microsoft Edit (the `edit` TUI) on double-click.

.DESCRIPTION
    Registers an "MSEdit.TextFile" ProgId under HKCU (no admin needed), points the listed
    extensions at it, and registers edit.exe so it appears in Explorer's "Open with" list.

    Extensions already claimed by another app (Notepad AppX, VS Code, Edge...) carry a
    hash-protected UserChoice/UserChoiceLatest key. Its *value* can't be rewritten, but the
    key can be deleted, which drops the extension back to our HKCU default. See the comments
    on Remove-UserChoice for why that needs an ACL grant plus a native RegDeleteKeyExW.

    Applying is therefore destructive to your existing picks: reverting restores Windows'
    defaults, NOT whatever you had before (e.g. VS Code for .json won't come back on its own).

    Deliberately excluded: .bat .cmd .reg .py .sh .vbs -- changing those defaults would
    break double-click-to-run. (.ps1/.psm1/.psd1 ARE included: Windows opens those in an
    editor by default, it does not execute them.)

.PARAMETER Verify
    Report only: what each extension currently resolves to. Changes nothing.

.PARAMETER PickManually
    Fallback for anything the registry path couldn't claim: opens Explorer's "Open with"
    dialog on a scratch file per extension so the choice can be made by hand. Note Windows
    only offers "Always use this app" when no UserChoice exists yet, so run a plain apply
    first -- that clears the old key and makes the "Always" option appear.

.PARAMETER Revert
    Delete the ProgId and the HKCU per-extension defaults, reverting to Windows' defaults.

.EXAMPLE
    .\set-edit-associations.ps1                      # apply
    .\set-edit-associations.ps1 -Verify              # show current state
    .\set-edit-associations.ps1 -PickManually        # fix the UserChoice-locked ones
    .\set-edit-associations.ps1 -Revert
#>
[CmdletBinding(DefaultParameterSetName = 'Apply')]
param(
    [string[]] $Extensions = @(
        '.txt', '.md', '.markdown', '.log',
        '.ini', '.cfg', '.conf', '.env', '.properties',
        '.json', '.jsonc', '.yaml', '.yml', '.toml',
        '.xml',
        '.ps1', '.psm1', '.psd1',
        '.sql', '.diff', '.patch'
    ),
    [Parameter(ParameterSetName = 'Verify')]       [switch] $Verify,
    [Parameter(ParameterSetName = 'PickManually')] [switch] $PickManually,
    [Parameter(ParameterSetName = 'Revert')]       [switch] $Revert
)

$ErrorActionPreference = 'Stop'

$ProgId    = 'MSEdit.TextFile'
$EditExe   = Join-Path $env:SystemRoot 'System32\edit.exe'
$ClassRoot = 'HKCU:\SOFTWARE\Classes'
$FileExts  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts'

if (-not (Test-Path $EditExe)) {
    throw "Microsoft Edit not found at $EditExe. Install it with: winget install Microsoft.Edit"
}

Add-Type -Namespace GlzrAssoc -Name Native -MemberDefinition @'
[DllImport("shlwapi.dll", CharSet=CharSet.Unicode)]
public static extern int AssocQueryStringW(int flags, int str, string pszAssoc,
    string pszExtra, System.Text.StringBuilder pszOut, ref int pcchOut);

[DllImport("shell32.dll")]
public static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);

[DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
public static extern int RegOpenKeyExW(IntPtr hKey, string subKey, int options, int rights, out IntPtr result);

[DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
public static extern int RegDeleteKeyExW(IntPtr hKey, string subKey, int samDesired, int reserved);

[DllImport("advapi32.dll", SetLastError=true)]
public static extern int RegCloseKey(IntPtr hKey);
'@

# What would Explorer actually launch for this extension?
function Get-OpenCommand {
    param([string] $Extension)
    $sb  = New-Object System.Text.StringBuilder 2048
    $len = 2048
    # ASSOCF_NOTRUNCATE = 0x20, ASSOCSTR_COMMAND = 1
    $rc = [GlzrAssoc.Native]::AssocQueryStringW(0x20, 1, $Extension, 'open', $sb, [ref]$len)
    if ($rc -ne 0) { return $null }
    return $sb.ToString()
}

function Test-UsesEdit {
    param([string] $Extension)
    $cmd = Get-OpenCommand $Extension
    return ($null -ne $cmd) -and ($cmd -match '(?i)\\edit\.exe')
}

function Update-ShellAssociations {
    # SHCNE_ASSOCCHANGED -- Explorer caches associations until told otherwise.
    [GlzrAssoc.Native]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
}

function Get-UserChoice {
    param([string] $Extension)
    $key = Join-Path $FileExts "$Extension\UserChoice"
    if (-not (Test-Path $key)) { return $null }
    return (Get-ItemProperty -Path $key -Name ProgId -ErrorAction SilentlyContinue).ProgId
}

# Windows hash-protects the UserChoice/UserChoiceLatest *values*, so they can't be rewritten.
# They can be DELETED though, which drops the extension back to the HKCU\Software\Classes
# default -- i.e. ours. Two wrinkles make this fiddly:
#
#   1. Their DACL grants the user nothing (owner is us, so WRITE_DAC is still implicitly
#      available -- we grant ourselves FullControl first).
#   2. RegistryKey.DeleteSubKeyTree() opens the victim with KEY_READ|KEY_WRITE before
#      deleting, and that open is refused. The refusal surfaces as the *misleading*
#      "subkey does not exist". RegDeleteKeyExW needs only DELETE, so it succeeds.
function Grant-SelfFullControl {
    param([string] $KeyPath)
    try {
        $rk = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
                $KeyPath,
                [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
                [System.Security.AccessControl.RegistryRights]'ChangePermissions')
        if (-not $rk) { return }
        $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
        $acl = $rk.GetAccessControl([System.Security.AccessControl.AccessControlSections]::Access)
        $acl.SetAccessRule((New-Object System.Security.AccessControl.RegistryAccessRule($sid, 'FullControl', 'Allow')))
        $rk.SetAccessControl($acl)
        $rk.Close()
    } catch { }   # best effort; the delete below reports the real outcome
}

# RegDeleteKeyExW only removes *leaf* keys, and UserChoiceLatest carries a ProgId subkey,
# so children must go first -- depth-first, or we strand a half-deleted key (an orphaned
# Hash with no ProgId makes the shell fall back to OpenWith.exe).
function Remove-KeyTreeNative {
    param([string] $ParentPath, [string] $Leaf)

    $HKCU    = [IntPtr](-2147483647)   # HKEY_CURRENT_USER
    $KEY_ALL = 0xF003F
    $fullPath = "$ParentPath\$Leaf"

    $probe = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($fullPath)
    if ($probe) {
        $children = $probe.GetSubKeyNames()
        $probe.Close()
        foreach ($child in $children) {
            Remove-KeyTreeNative -ParentPath $fullPath -Leaf $child | Out-Null
        }
    }

    Grant-SelfFullControl $fullPath
    $hParent = [IntPtr]::Zero
    if ([GlzrAssoc.Native]::RegOpenKeyExW($HKCU, $ParentPath, 0, $KEY_ALL, [ref]$hParent) -ne 0) {
        return $false
    }
    try   { return ([GlzrAssoc.Native]::RegDeleteKeyExW($hParent, $Leaf, 0, 0) -eq 0) }
    finally { [GlzrAssoc.Native]::RegCloseKey($hParent) | Out-Null }
}

function Remove-UserChoice {
    param([string] $Extension)

    $parentPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension"
    $removed    = @()
    foreach ($leaf in 'UserChoice', 'UserChoiceLatest') {
        if (-not (Test-Path (Join-Path $FileExts "$Extension\$leaf"))) { continue }
        if (Remove-KeyTreeNative -ParentPath $parentPath -Leaf $leaf) {
            $removed += $leaf
        } else {
            Write-Warning "$Extension : could not remove $leaf -- set it by hand in Settings > Apps > Default apps."
        }
    }
    return $removed
}

# Clearing UserChoice is necessary but not always sufficient: the shell also consults the
# per-extension OpenWithList MRU, and an extension left with an empty/absent one can resolve
# to OpenWith.exe (the "how do you want to open this?" shim) instead of falling through to
# the HKCU class default. Seeding edit.exe at the head of the MRU settles it.
function Set-OpenWithListMru {
    param([string] $Extension)

    $owl = Join-Path $FileExts "$Extension\OpenWithList"
    New-Item -Path $owl -Force | Out-Null
    $key = Get-Item $owl

    $slots  = @($key.Property | Where-Object { $_ -cmatch '^[a-z]$' })
    $mine   = $slots | Where-Object { $key.GetValue($_) -eq 'edit.exe' } | Select-Object -First 1
    if (-not $mine) {
        # First unused single-letter slot; 'a' when the list is empty.
        $mine = ([char[]](97..122) | Where-Object { $slots -notcontains [string]$_ } | Select-Object -First 1)
        if (-not $mine) { return }
        Set-ItemProperty -Path $owl -Name $mine -Value 'edit.exe'
    }

    $mru   = [string] $key.GetValue('MRUList')
    $order = $mine + (($mru -split '' | Where-Object { $_ -and $_ -ne $mine }) -join '')
    Set-ItemProperty -Path $owl -Name 'MRUList' -Value $order
}

function Show-State {
    param([string[]] $Exts)
    $rows = foreach ($ext in $Exts) {
        $cmd = Get-OpenCommand $ext
        [pscustomobject]@{
            Extension  = $ext
            OpensWith  = if ($cmd) { Split-Path -Leaf ($cmd -replace '^"([^"]+)".*$', '$1') } else { '(none)' }
            UsesEdit   = if (Test-UsesEdit $ext) { 'yes' } else { 'NO' }
            UserChoice = Get-UserChoice $ext
        }
    }
    $rows | Format-Table -AutoSize | Out-Host
    return $rows
}

# ---------------------------------------------------------------- Verify -----
if ($Verify) {
    $rows = Show-State $Extensions
    $bad  = @($rows | Where-Object UsesEdit -eq 'NO')
    if ($bad.Count) {
        Write-Host "$($bad.Count) extension(s) not on Edit: $($bad.Extension -join ', ')" -ForegroundColor Yellow
        Write-Host "Fix with: .\set-edit-associations.ps1 -PickManually" -ForegroundColor DarkGray
    } else {
        Write-Host "All $($Extensions.Count) extensions open in Microsoft Edit." -ForegroundColor Green
    }
    return
}

# ---------------------------------------------------------------- Revert -----
if ($Revert) {
    foreach ($ext in $Extensions) {
        Remove-UserChoice -Extension $ext | Out-Null
        $extKey = Join-Path $ClassRoot $ext
        if (Test-Path $extKey) {
            if ((Get-Item $extKey).GetValue('') -eq $ProgId) {
                # Remove the value, don't blank it -- an empty default still shadows HKLM.
                Remove-ItemProperty -Path $extKey -Name '(default)' -ErrorAction SilentlyContinue
            }
            $owp = Join-Path $extKey 'OpenWithProgids'
            if (Test-Path $owp) { Remove-ItemProperty -Path $owp -Name $ProgId -ErrorAction SilentlyContinue }
        }
        # Drop edit.exe from the per-extension Open-with MRU.
        $owl = Join-Path $FileExts "$ext\OpenWithList"
        if (Test-Path $owl) {
            $key  = Get-Item $owl
            $mine = @($key.Property | Where-Object { $_ -cmatch '^[a-z]$' -and $key.GetValue($_) -eq 'edit.exe' })
            foreach ($slot in $mine) {
                Remove-ItemProperty -Path $owl -Name $slot -ErrorAction SilentlyContinue
                $mru = [string] $key.GetValue('MRUList')
                Set-ItemProperty -Path $owl -Name 'MRUList' -Value (($mru -split '' | Where-Object { $_ -and $_ -ne $slot }) -join '')
            }
        }
    }
    Remove-Item -Path (Join-Path $ClassRoot $ProgId) -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $ClassRoot 'Applications\edit.exe') -Recurse -Force -ErrorAction SilentlyContinue
    Update-ShellAssociations
    Write-Host 'Reverted to Windows defaults.' -ForegroundColor Yellow
    Write-Host 'Note: your PREVIOUS picks are not restored -- applying deleted those UserChoice keys.' -ForegroundColor DarkGray
    Write-Host 'Re-assign any you want back (e.g. VS Code for .json) via Open with > Always use this app.' -ForegroundColor DarkGray
    return
}

# ---------------------------------------------------------- PickManually -----
if ($PickManually) {
    $pending = @($Extensions | Where-Object { -not (Test-UsesEdit $_) })
    if (-not $pending.Count) {
        Write-Host 'Nothing to do -- every extension already opens in Edit.' -ForegroundColor Green
        return
    }
    $scratch = Join-Path ([System.IO.Path]::GetTempPath()) 'glzr-edit-assoc'
    New-Item -ItemType Directory -Path $scratch -Force | Out-Null
    Write-Host "$($pending.Count) extension(s) need a manual pick: $($pending -join ', ')" -ForegroundColor Cyan
    Write-Host 'In each dialog: choose Edit (scroll / "More apps" if needed), TICK "Always use this app", then OK.' -ForegroundColor Cyan
    Write-Host 'Windows only offers "Always" once the old UserChoice is gone -- run without -PickManually first.' -ForegroundColor DarkGray
    Write-Host ''
    foreach ($ext in $pending) {
        $sample = Join-Path $scratch "open-me$ext"
        Set-Content -LiteralPath $sample -Value "Pick 'Edit' and tick 'Always use this app' for $ext files." -Encoding UTF8
        Write-Host "  -> $ext ... " -NoNewline

        # OpenAs_RunDLL is the same dialog as Explorer's "Open with > Choose another app".
        # rundll32 delegates to a separate picker process and exits at once, so -Wait returns
        # long before the user has clicked anything. Poll the registry instead.
        Start-Process -FilePath 'rundll32.exe' -ArgumentList 'shell32.dll,OpenAs_RunDLL', $sample
        $deadline = (Get-Date).AddSeconds(120)
        $claimed  = $false
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 500
            $choice = Get-UserChoice $ext
            if ($choice -and $choice -match '(?i)edit\.exe|MSEdit\.') { $claimed = $true; break }
            $picker = Get-Process -Name 'OpenWith', 'rundll32' -ErrorAction SilentlyContinue
            if (-not $picker) { break }   # dialog closed without choosing Edit
        }
        Update-ShellAssociations
        if ($claimed -or (Test-UsesEdit $ext)) { Write-Host '[ok]' -ForegroundColor Green }
        else                                   { Write-Host '[skipped]' -ForegroundColor Yellow }
    }
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    Show-State $Extensions | Out-Null
    return
}

# ----------------------------------------------------------------- Apply -----

# 1. The ProgId
$progKey = Join-Path $ClassRoot $ProgId
New-Item -Path "$progKey\shell\open\command" -Force | Out-Null
New-Item -Path "$progKey\DefaultIcon"        -Force | Out-Null
Set-ItemProperty -Path $progKey                      -Name '(default)'        -Value 'Text Document'
Set-ItemProperty -Path $progKey                      -Name 'FriendlyTypeName' -Value 'Text Document'
Set-ItemProperty -Path "$progKey\DefaultIcon"        -Name '(default)'        -Value "$EditExe,0"
Set-ItemProperty -Path "$progKey\shell\open"         -Name 'FriendlyAppName'  -Value 'Edit'
Set-ItemProperty -Path "$progKey\shell\open\command" -Name '(default)'        -Value "`"$EditExe`" `"%1`""

# 2. Application registration, so "Edit" is offered in the Open-with dialog
$appKey = Join-Path $ClassRoot 'Applications\edit.exe'
New-Item -Path "$appKey\shell\open\command" -Force | Out-Null
New-Item -Path "$appKey\SupportedTypes"     -Force | Out-Null
Set-ItemProperty -Path $appKey                      -Name 'FriendlyAppName' -Value 'Edit'
Set-ItemProperty -Path "$appKey\shell\open\command" -Name '(default)'       -Value "`"$EditExe`" `"%1`""
foreach ($ext in $Extensions) {
    Set-ItemProperty -Path "$appKey\SupportedTypes" -Name $ext -Value ''
}

# 3. Point each extension at the ProgId, and offer Edit in its Open-with list
foreach ($ext in $Extensions) {
    Remove-UserChoice -Extension $ext | Out-Null
    $extKey = Join-Path $ClassRoot $ext
    New-Item -Path "$extKey\OpenWithProgids" -Force | Out-Null
    Set-ItemProperty -Path $extKey -Name '(default)' -Value $ProgId
    Set-ItemProperty -Path "$extKey\OpenWithProgids" -Name $ProgId -Value ([byte[]]@()) -Type Binary
    Set-OpenWithListMru -Extension $ext
}

Update-ShellAssociations

$rows    = Show-State $Extensions
$blocked = @($rows | Where-Object UsesEdit -eq 'NO')
Write-Host "$($Extensions.Count - $blocked.Count)/$($Extensions.Count) extensions now open in Microsoft Edit." -ForegroundColor Green
if ($blocked.Count) {
    Write-Host "Still locked by an Explorer UserChoice: $($blocked.Extension -join ', ')" -ForegroundColor Yellow
    Write-Host 'Run  .\set-edit-associations.ps1 -PickManually  to claim those.' -ForegroundColor Yellow
}
Write-Host 'Edit opens in your default terminal. Undo with -Revert.' -ForegroundColor DarkGray
