<#
.SYNOPSIS
    Updates the copy of Jarvis installed in SSMS to the current source.

.DESCRIPTION
    Build, remove the old copy, install the new one, then prove it registered. One command,
    because doing these by hand has a trap in it: VSIXInstaller.exe compares versions and will
    quietly do nothing when the version on disk equals the one already installed. Removing
    first sidesteps that, and the registration check catches it if anything still goes wrong.

    With more than one SSMS installed you are asked which one to update, once: the answer is
    passed on to the uninstall, install and verify steps so they all act on the same one.

    SSMS must be closed. The extension assembly is locked while it runs, and the merged command
    table is only rebuilt at start up.

.EXAMPLE
    .\build\update.ps1
    .\build\update.ps1 -Version 22
    .\build\update.ps1 -All -SkipTests
#>
[CmdletBinding()]
param(
    # Update this version without being asked, for example 22.
    [string]$Version,

    # Update every installed SSMS.
    [switch]$All,

    # Build without running the test suite first. Not recommended.
    [switch]$SkipTests,

    # Report what would happen and stop.
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\SsmsCommon.ps1"

$root = Split-Path -Parent $PSScriptRoot

function Step($text) {
    Write-Host ""
    Write-Host "==> $text" -ForegroundColor Cyan
}

# Ask once, up front, and hand the answer to every step below. Asking again inside install.ps1
# and uninstall.ps1 would let the two steps disagree about which SSMS is being updated.
$installations = @(Get-SsmsInstallations)

if ($All) {
    $targets = $installations
}
else {
    $targets = @(Select-SsmsInstallation -Version $Version -Installations $installations -Question 'Which one should Jarvis be updated on?')
}

# Downstream scripts take a version, not an object, so pin the choice to an exact version. With
# several targets they are each run in turn rather than being handed a list.
$forward = @{}
if ($targets.Count -eq $installations.Count -and $installations.Count -gt 1) {
    $forward['All'] = $true
}
elseif ($targets.Count -eq 1) {
    $forward['Version'] = $targets[0].Version
}

$running = @(Get-SsmsProcesses)
if ($running.Count -gt 0 -and -not $DryRun) {
    Assert-SsmsClosed
}

if ($DryRun) {
    Step "Dry run"
    Write-Host ("  would {0}uninstall, install and verify" -f
        $(if (Test-Path (Join-Path $PSScriptRoot 'build.ps1')) { 'build, ' } else { 'use the package beside this script, ' }))
    Write-Host ("  target(s)      {0}" -f (($targets | ForEach-Object { 'SSMS ' + $_.DisplayVersion }) -join ', '))
    Write-Host ("  SSMS running   {0}" -f ($running.Count -gt 0))

    try {
        & (Join-Path $PSScriptRoot 'check-registration.ps1') @forward
    }
    catch {
        # The hive cannot be read while SSMS holds it; that is expected here, not a failure.
        Write-Host ("  registration   not checkable right now: " + $_.Exception.Message)
    }

    return
}

$buildScript = Join-Path $PSScriptRoot 'build.ps1'

if (Test-Path $buildScript) {
    Step "Building"

    # Splat a hashtable rather than building an argument array: an empty array is passed as one
    # positional argument, which lands on -Configuration and fails to convert.
    $buildArgs = @{}
    if ($SkipTests) {
        $buildArgs['SkipTests'] = $true
    }

    & $buildScript @buildArgs
}
else {
    # A published release has no source to build from, only the .vsix sitting beside these
    # scripts. Reinstalling that is exactly what updating means there.
    Step "Using the package beside this script"
}

Step "Removing the installed copy"
& (Join-Path $PSScriptRoot 'uninstall.ps1') -Force @forward

Step "Installing the new build"
& (Join-Path $PSScriptRoot 'install.ps1') @forward

Step "Verifying"
& (Join-Path $PSScriptRoot 'check-registration.ps1') @forward

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Updated. Start SSMS." -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Warning ("The files are in place but SSMS has not registered them. Run " +
                   ".\build\doctor.ps1 -Log to find out why before starting SSMS.")
}
