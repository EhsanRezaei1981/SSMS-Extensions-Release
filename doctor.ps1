<#
.SYNOPSIS
    Diagnoses why the Jarvis menu is or is not showing up in SSMS, and fixes the usual cause.

.DESCRIPTION
    Menus in the Visual Studio shell come from a command table that is merged and cached when
    the shell starts. A newly installed package whose cache was not rebuilt registers fine,
    shows its Tools, Options pages, and still has no menu. That is the failure this script is
    built to find and fix.

    It reports, in order:
      1. where SSMS is and which per user shell folder it uses
      2. which copies of the extension are installed, and their versions
      3. whether the package is registered in the shell's private registry
      4. whether the command table cache looks stale

    With more than one SSMS installed you are asked which one to look at. Use -All to report on
    every one of them, or -Version to answer in advance.

    With -Fix it reinstalls from the freshly built .vsix and runs SSMS /updateconfiguration,
    which is what forces the command table to be rebuilt.

    With -Log it then starts SSMS with /log and reads ActivityLog.xml back, which is the only
    way to see package load errors that the UI swallows.

.EXAMPLE
    .\build\doctor.ps1
    .\build\doctor.ps1 -Version 22
    .\build\doctor.ps1 -All
    .\build\doctor.ps1 -Fix -Log
#>
[CmdletBinding()]
param(
    # Diagnose this version without being asked, for example 22.
    [string]$Version,

    # Diagnose every installed SSMS.
    [switch]$All,

    # Reinstall the current build and rebuild the shell's command table cache.
    [switch]$Fix,

    # After fixing, start SSMS with /log and report what the activity log says.
    [switch]$Log
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\SsmsCommon.ps1"

$root = Split-Path -Parent $PSScriptRoot

$packageGuid = 'ce715d37-1a20-4603-8cad-53388d856cf2'
$extensionId = "Jarvis.SSMSExtension.$packageGuid"

function Write-Head($text) {
    Write-Host ""
    Write-Host $text -ForegroundColor Cyan
    Write-Host ('-' * $text.Length) -ForegroundColor DarkGray
}

function Write-Check($ok, $label, $detail) {
    $mark = if ($ok) { 'OK  ' } else { 'FAIL' }
    $colour = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ('  [{0}] {1}' -f $mark, $label) -ForegroundColor $colour
    if ($detail) { Write-Host ('         ' + $detail) -ForegroundColor DarkGray }
}

function Get-InstalledCopies {
    param([string]$ExtensionsFolder)

    $result = @()
    foreach ($dir in Get-ChildItem $ExtensionsFolder -Directory -ErrorAction SilentlyContinue) {
        $manifest = Join-Path $dir.FullName 'extension.vsixmanifest'
        if (-not (Test-Path $manifest)) { continue }

        $text = Get-Content $manifest -Raw -ErrorAction SilentlyContinue
        if (-not $text -or $text -notmatch [regex]::Escape($extensionId)) { continue }

        $dll = Join-Path $dir.FullName 'Jarvis.SSMSExtension.Vsix.dll'
        $result += [pscustomobject]@{
            Path    = $dir.FullName
            Version = if ($text -match '<Identity[^>]*\sVersion="([^"]+)"') { $Matches[1] } else { '?' }
            Built   = if (Test-Path $dll) { (Get-Item $dll).LastWriteTime } else { $null }
            HasPkgdef = Test-Path (Join-Path $dir.FullName 'Jarvis.SSMSExtension.Vsix.pkgdef')
        }
    }

    return $result
}

<#
.SYNOPSIS
    The whole diagnosis for one installation.
#>
function Invoke-Diagnosis {
    param([Parameter(Mandatory)][psobject]$Installation)

    $shell = $Installation.ShellFolder
    $extensions = $Installation.ExtensionsFolder
    $running = @(Get-SsmsProcesses -Installation $Installation)

    Write-Head ("SSMS {0}" -f $Installation.DisplayVersion)
    Write-Check $true 'SSMS' $Installation.IdePath
    Write-Check ($null -ne $shell) 'Shell folder' $shell
    Write-Check ($running.Count -eq 0) "SSMS closed" $(
        if ($running.Count -gt 0) {
            "running: " + (($running | ForEach-Object { "PID $($_.Id)" }) -join ', ') +
            " - a restart is required for any menu or code change"
        } else { 'not running' })

    Write-Head "Installed copies"
    $copies = @()
    if ($extensions) { $copies = @(Get-InstalledCopies -ExtensionsFolder $extensions) }

    if ($copies.Count -eq 0) {
        Write-Check $false 'Extension installed' "nothing matching $extensionId under $extensions"
    }
    else {
        foreach ($c in $copies) {
            Write-Check $true "version $($c.Version)" $c.Path
            Write-Check $c.HasPkgdef '  pkgdef present' $(if ($c.HasPkgdef) { 'yes' } else { 'MISSING - the shell cannot register the package' })
            if ($c.Built) { Write-Host ("         built    " + $c.Built) -ForegroundColor DarkGray }
        }
        if ($copies.Count -gt 1) {
            Write-Check $false 'Single copy' "$($copies.Count) copies found; run .\build\uninstall.ps1 -Force first"
        }
    }

    $built = Join-Path $root 'src\Jarvis.SSMSExtension.Vsix\bin\Release\Jarvis.SSMSExtension.Vsix.dll'
    if (Test-Path $built) {
        $b = (Get-Item $built).LastWriteTime
        Write-Host ("         latest build " + $b) -ForegroundColor DarkGray
        $stale = $copies | Where-Object { $_.Built -and $_.Built -lt $b }
        if ($stale) {
            Write-Check $false 'Installed copy is current' 'the build on disk is newer than what is installed'
        }
    }

    Write-Head "Shell registration"
    $privateReg = $Installation.Hive
    if ($privateReg -and (Test-Path $privateReg)) {
        # The package guid is written into the shell's private hive when the pkgdef is merged.
        # SSMS keeps the hive open while it runs, so share the handle rather than demanding it.
        try {
            $fs = New-Object System.IO.FileStream($privateReg, 'Open', 'Read', 'ReadWrite')
            try {
                $bytes = New-Object byte[] $fs.Length
                $read = 0
                while ($read -lt $fs.Length) {
                    $n = $fs.Read($bytes, $read, [int][Math]::Min(1MB, $fs.Length - $read))
                    if ($n -le 0) { break }
                    $read += $n
                }
            }
            finally { $fs.Dispose() }

            # UTF-16 only decodes from an even byte offset, so a string that happens to start on
            # an odd one is invisible to a single pass. Both alignments are searched.
            $text = [System.Text.Encoding]::Unicode.GetString($bytes)
            $textOdd = [System.Text.Encoding]::Unicode.GetString($bytes, 1, $bytes.Length - 1)
            $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)

            $registered = ($text -match [regex]::Escape($packageGuid)) -or
                          ($textOdd -match [regex]::Escape($packageGuid))

            Write-Check $registered 'Package in the private registry' $(
                if ($registered) {
                    'the pkgdef was merged, so Tools, Options should list Jarvis'
                }
                else {
                    'NOT merged - that is why there is no menu; run this script with -Fix'
                })

            # Registering the package and registering its menus are two different entries. The
            # pkgdef writes [$RootKey$\Menus] "{guid}" = ", Menus.ctmenu, 1", and without that the
            # shell never reads the command table, so every menu is missing while the options
            # pages still work. This is the check that tells those two apart.
            $menusRegistered = ($text -match 'Menus\.ctmenu') -or ($textOdd -match 'Menus\.ctmenu') -or
                               ($ascii -match 'Menus\.ctmenu')

            Write-Check $menusRegistered 'Menu resource registered' $(
                if ($menusRegistered) {
                    'the shell knows where to find the command table'
                }
                else {
                    'the Menus entry is NOT in the hive - the command table is never read, which is exactly "options page but no menu"'
                })

            if ($registered -and $running.Count -gt 0) {
                Write-Host "         note: the hive was read while SSMS is running, so it reflects the last start" -ForegroundColor DarkGray
            }
        }
        catch {
            if ($running.Count -gt 0) {
                # Windows loads the hive for the running shell, so nothing else may open it.
                Write-Check $true 'Private registry' `
                    'cannot be checked while SSMS is running; close SSMS and run this again to verify registration'
            }
            else {
                Write-Check $false 'Private registry' "could not be read: $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Check $false 'Private registry' 'not found; start SSMS once'
    }
}

# ---------------------------------------------------------------------------------------

Write-Host "Jarvis doctor" -ForegroundColor Cyan

$installations = @(Get-SsmsInstallations)

if ($installations.Count -gt 1) {
    Write-Host ("  {0} SSMS installations found: {1}" -f $installations.Count,
        (($installations | ForEach-Object { $_.DisplayVersion }) -join ', ')) -ForegroundColor DarkGray
}

if ($All) {
    $targets = $installations
}
else {
    $targets = @(Select-SsmsInstallation -Version $Version -Installations $installations -Question 'Which one should be diagnosed?')
}

foreach ($target in $targets) {
    Invoke-Diagnosis -Installation $target
}

if (-not $Fix -and -not $Log) {
    Write-Host ""
    Write-Host "Run .\build\doctor.ps1 -Fix to reinstall and rebuild the command table cache." -ForegroundColor Cyan
    Write-Host "Run .\build\doctor.ps1 -Log to start SSMS with logging and read the result back." -ForegroundColor Cyan
    return
}

# ---------------------------------------------------------------------------------------
# Fix
# ---------------------------------------------------------------------------------------

# Fixing rewrites files and starts the shell, so it acts on one installation. With several
# chosen, say which one to name rather than picking silently.
if ($targets.Count -gt 1) {
    throw ("-Fix and -Log act on a single installation. Re-run naming one, for example " +
           ".\build\doctor.ps1 -Fix -Version " + $targets[0].DisplayVersion)
}

$target = $targets[0]

# Any running SSMS is a problem here, not only this one: they can share a copy of the assembly.
Assert-SsmsClosed

$forward = @{ Version = $target.Version }

if ($Fix) {
    Write-Head "Reinstalling"
    & (Join-Path $PSScriptRoot 'uninstall.ps1') -Force @forward
    & (Join-Path $PSScriptRoot 'install.ps1') @forward

    Write-Head "Rebuilding the command table cache"
    Write-Host "  SSMS.exe /updateconfiguration - this takes a moment and opens no window."
    Update-SsmsConfiguration -Installation $target
}

if (-not $Log) {
    Write-Host ""
    Write-Host "Done. Start SSMS; the Jarvis menu should be on the menu bar." -ForegroundColor Green
    return
}

Write-Head "Starting SSMS with logging"
$logPath = Join-Path $target.ShellFolder 'ActivityLog.xml'
Remove-Item -LiteralPath $logPath -ErrorAction SilentlyContinue

Write-Host "  SSMS is starting. Look for the Jarvis menu, then close SSMS to finish."
Start-Process -FilePath $target.Exe -ArgumentList '/log' -Wait | Out-Null

if (-not (Test-Path $logPath)) {
    Write-Warning "No activity log was written at $logPath"
    return
}

Write-Head "What the activity log says about Jarvis"
try {
    [xml]$xml = Get-Content $logPath -Raw
    $entries = $xml.activity.entry | Where-Object {
        $_.description -match 'Jarvis' -or $_.source -match 'Jarvis' -or $_.guid -match $packageGuid
    }

    if (-not $entries) {
        Write-Host "  Nothing about Jarvis, which means the package loaded without complaint." -ForegroundColor Green
    }
    else {
        foreach ($e in $entries) {
            $colour = if ($e.type -eq 'Error') { 'Red' } else { 'Gray' }
            Write-Host ("  [{0}] {1}" -f $e.type, $e.description) -ForegroundColor $colour
        }
    }

    $errors = @($xml.activity.entry | Where-Object { $_.type -eq 'Error' })
    Write-Host ""
    Write-Host ("  {0} error entr{1} in the log overall." -f $errors.Count, $(if ($errors.Count -eq 1) { 'y' } else { 'ies' }))
}
catch {
    Write-Warning "Could not parse $logPath : $($_.Exception.Message)"
}
