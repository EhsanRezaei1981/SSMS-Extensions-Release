<#
.SYNOPSIS
    Removes the Jarvis SSMS Extension from SQL Server Management Studio.

.DESCRIPTION
    Finds the extension by reading the identity out of every installed extension.vsixmanifest,
    rather than by guessing a folder name. That matters: VSIXInstaller.exe installs into a
    randomly named folder such as "5iwnnhvg.ybn", while a -Method Copy install lands in a folder
    called "Jarvis.SSMSExtension". Scanning the manifests catches both, plus any older copy left
    behind by a previous version.

    Both the per user folder and the machine wide one under the SSMS install are searched.
    Removing a machine wide copy needs an elevated prompt.

    SSMS must be closed.

.EXAMPLE
    .\build\uninstall.ps1
    .\build\uninstall.ps1 -DryRun
    .\build\uninstall.ps1 -Force
#>
[CmdletBinding()]
param(
    # Remove from this version without being asked, for example 22.
    [string]$Version,

    # Remove from every installed SSMS without being asked.
    [switch]$All,

    # List what would be removed and stop.
    [switch]$DryRun,

    # Skip the confirmation prompt.
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\SsmsCommon.ps1"

$extensionId = 'Jarvis.SSMSExtension.ce715d37-1a20-4603-8cad-53388d856cf2'

# Installs from before the rename carry the old identity. Removing means removing, so this takes
# either — otherwise "uninstall" would leave a working copy behind and look like it had failed.
$legacyExtensionId = 'Jarvis.SqlFormatter.ce715d37-1a20-4603-8cad-53388d856cf2'
$extensionIds = @($extensionId, $legacyExtensionId)

$displayName = 'Jarvis SSMS Extension'

# ---------------------------------------------------------------------------------------
# Locating SSMS
# ---------------------------------------------------------------------------------------

<#
.SYNOPSIS
    Every folder an installation could be holding a copy in: its per user Extensions folder
    and the machine wide one under the install itself.
#>
function Get-ExtensionRoots {
    param([psobject[]]$Targets)

    $result = New-Object System.Collections.Generic.List[string]

    foreach ($target in $Targets) {
        if ($target.ExtensionsFolder) {
            $result.Add($target.ExtensionsFolder)
        }

        $result.Add((Join-Path $target.IdePath 'Extensions'))
    }

    return $result | Where-Object { Test-Path $_ } | Select-Object -Unique
}

function Find-InstalledCopies {
    param([string[]]$ExtensionRoots)

    $copies = New-Object System.Collections.Generic.List[psobject]

    foreach ($root in $ExtensionRoots) {
        foreach ($dir in Get-ChildItem $root -Directory -ErrorAction SilentlyContinue) {
            $manifest = Join-Path $dir.FullName 'extension.vsixmanifest'
            if (-not (Test-Path $manifest)) { continue }

            try { $text = Get-Content $manifest -Raw -ErrorAction Stop } catch { continue }
            $matched = $false
            foreach ($id in $extensionIds) {
                if ($text -match [regex]::Escape($id)) { $matched = $true; break }
            }
            if (-not $matched) { continue }

            # Take the Version off the Identity element. A plain Version="..." match would
            # pick up PackageManifest Version="2.0.0", which is the schema version.
            $version = if ($text -match '<Identity[^>]*\sVersion="([^"]+)"') { $Matches[1] } else { 'unknown' }

            $copies.Add([pscustomobject]@{
                Path      = $dir.FullName
                Version   = $version
                Root      = $root
                MachineWide = $root -notlike "$env:LOCALAPPDATA*"
            })
        }
    }

    return $copies
}

function Test-Elevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ---------------------------------------------------------------------------------------
# Work
# ---------------------------------------------------------------------------------------

$installations = @(Get-SsmsInstallations)

# Removing from the wrong SSMS is as confusing as installing into it, so the same choice is
# offered here. Removing from all of them is the safer default when asked.
if ($All -or (-not $Version -and $installations.Count -gt 1 -and $Force)) {
    $targets = $installations
}
else {
    $targets = @(Select-SsmsInstallation -Version $Version -Installations $installations -Question 'Which one should Jarvis be removed from?')
}

$roots = @(Get-ExtensionRoots -Targets $targets)

Write-Host "Looking for $displayName" -ForegroundColor Cyan
foreach ($t in $targets) { Write-Host ("  SSMS {0}    {1}" -f $t.DisplayVersion, $t.IdePath) }
foreach ($r in $roots)   { Write-Host "  searching  $r" }

$copies = @(Find-InstalledCopies -ExtensionRoots $roots)

if ($copies.Count -eq 0) {
    Write-Host "`nNothing to do: $displayName is not installed." -ForegroundColor Green
    return
}

Write-Host "`nFound $($copies.Count) installed cop$(if ($copies.Count -eq 1) { 'y' } else { 'ies' }):" -ForegroundColor Cyan
foreach ($c in $copies) {
    $scope = if ($c.MachineWide) { 'machine wide' } else { 'per user' }
    Write-Host ("  {0}  version {1}  ({2})" -f $c.Path, $c.Version, $scope)
}

if ($DryRun) {
    Write-Host "`nDry run, nothing was changed." -ForegroundColor Cyan
    Write-Host "  SSMS running  $([bool](Get-Process -Name 'Ssms' -ErrorAction SilentlyContinue))"
    return
}

if ($copies | Where-Object { $_.MachineWide } | Select-Object -First 1) {
    if (-not (Test-Elevated)) {
        Write-Warning "A machine wide copy was found. Re-run this from an elevated prompt to remove it."
    }
}

if (-not $Force) {
    $answer = Read-Host "`nRemove $displayName from SSMS? [y/N]"
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host "Cancelled. Nothing was changed."
        return
    }
}

Assert-SsmsClosed

# 1. Delete the folders ourselves.
#
# VSIXInstaller.exe /uninstall is deliberately NOT used. It does not remove the extension, it
# writes a PendingDeletions entry keyed on the extension id and lets the shell act on it at
# the next start up. That entry outlives the uninstall: reinstall the same extension id and
# the next SSMS start silently deletes the fresh copy, which looks exactly like an install
# that never worked. Deleting the folder and rebuilding the configuration avoids the queue
# entirely.
$removed = 0
$failed  = New-Object System.Collections.Generic.List[string]

foreach ($c in Find-InstalledCopies -ExtensionRoots $roots) {
    try {
        Remove-Item -LiteralPath $c.Path -Recurse -Force -ErrorAction Stop
        Write-Host "  removed $($c.Path)"
        $removed++
    }
    catch {
        $failed.Add("$($c.Path) : $($_.Exception.Message)")
    }
}

# 3. Nudge the shell so it rebuilds its extension cache on next start.
foreach ($root in $roots) {
    $marker = Join-Path $root 'extensions.configurationchanged'
    try {
        Set-Content -LiteralPath $marker -Value ([DateTime]::UtcNow.ToString('o')) -ErrorAction Stop
    }
    catch {
        # Not fatal: SSMS notices on its own, it may just take one extra start.
    }
}

# 4. Purge the registration itself.
#
# Deleting the files is only half an uninstall. The package's pkgdef was merged into the
# shell's private registry hive, and those entries outlive the files: the extension's pages
# keep showing under Tools, Options, pointing at an assembly that is no longer there.
# /updateconfiguration re-derives the hive from the extensions that actually exist, which is
# what genuinely removes it.
Write-Host ""
foreach ($target in $targets) {
    Update-SsmsConfiguration -Installation $target
}

if ($failed.Count -gt 0) {
    Write-Host ""
    foreach ($f in $failed) { Write-Warning "Could not remove $f" }
    throw ("$($failed.Count) folder(s) could not be removed. If they are machine wide, re-run " +
           "from an elevated prompt; otherwise check that SSMS is really closed.")
}

Write-Host "`n$displayName removed ($removed folder(s))." -ForegroundColor Green
Write-Host "Your settings under Tools, Options are left behind harmlessly; they are ignored"
Write-Host "unless you install it again."
