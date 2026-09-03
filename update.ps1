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

<#
    Clear the build workers before touching the installation.

    MSBuild leaves worker processes behind and VSIXInstaller refuses to install while any are
    running. Building and then installing therefore blocked itself. build.ps1 now turns node
    reuse off so none should be left, but a worker from an earlier build, or from Visual Studio
    having built this solution, would still be here — and the removal below has already happened
    by the time that is discovered.
#>
Step "Clearing build workers"
& dotnet build-server shutdown 2>&1 | Out-Null
$workers = @(Get-Process -Name MSBuild, VBCSCompiler -ErrorAction SilentlyContinue)
if ($workers.Count -gt 0) {
    $workers | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    Write-Host ("  stopped {0}" -f $workers.Count)
}
else {
    Write-Host "  none running"
}

Step "Removing the installed copy"
& (Join-Path $PSScriptRoot 'uninstall.ps1') -Force @forward

Step "Installing the new build"

# From here the old copy is gone. A failure now leaves nothing installed, so it says so and says
# what to run, rather than ending on an exception that looks like the update simply did not go.
try {
    & (Join-Path $PSScriptRoot 'install.ps1') @forward
}
catch {
    Write-Host ""
    Write-Host "The new build did not install, and the old one has already been removed." -ForegroundColor Red
    Write-Host "Jarvis is not installed at the moment. Once the problem below is dealt with:" -ForegroundColor Yellow
    Write-Host "    .\install.ps1" -ForegroundColor Yellow
    Write-Host ""
    throw
}

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
