<#
.SYNOPSIS
    Installs the Jarvis SQL Formatter into SQL Server Management Studio.

.DESCRIPTION
    When more than one SSMS is installed you are asked which one to install into, and you can
    pick all of them. Use -Version to choose without being asked.

    SSMS must be closed: its extension assembly is locked while it runs, and the merged command
    table is only rebuilt at start up.

.PARAMETER Version
    Install into this version without asking, for example 22.

.PARAMETER All
    Install into every installed SSMS without asking.

.PARAMETER Method
    Installer unpacks through VSIXInstaller.exe, which is the only route observed to register
    the package properly. Copy unpacks the .vsix by hand as a fallback.

.EXAMPLE
    .\build\install.ps1
    .\build\install.ps1 -Version 22
    .\build\install.ps1 -All
    .\build\install.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [string]$VsixPath,

    [string]$Version,

    [switch]$All,

    [ValidateSet('Installer', 'Copy')]
    [string]$Method = 'Installer',

    [switch]$Uninstall,

    # Print the resolved paths and stop, changing nothing.
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\SsmsCommon.ps1"

$root = Split-Path -Parent $PSScriptRoot
$extensionId = 'Jarvis.SqlFormatter.ce715d37-1a20-4603-8cad-53388d856cf2'
$folderName = 'Jarvis.SqlFormatter'

if ($Uninstall) {
    # One implementation only. uninstall.ps1 finds the extension by reading manifests, which
    # is the only reliable way: VSIXInstaller installs into a randomly named folder.
    $forward = @{ Force = $true }
    if ($Version) { $forward['Version'] = $Version }
    if ($All) { $forward['All'] = $true }

    & (Join-Path $PSScriptRoot 'uninstall.ps1') @forward
    return
}

# ---------------------------------------------------------------------------------------
# Which SSMS
# ---------------------------------------------------------------------------------------

$installations = @(Get-SsmsInstallations)

if ($All) {
    $targets = $installations
}
else {
    $targets = @(Select-SsmsInstallation -Version $Version -Installations $installations)
}

foreach ($target in $targets) {
    if (-not $target.ExtensionsFolder) {
        throw ("SSMS {0} has no per user folder yet. Start it once, then run this again." -f $target.DisplayVersion)
    }
}

# ---------------------------------------------------------------------------------------
# The package
# ---------------------------------------------------------------------------------------

<#
.SYNOPSIS
    The newest .vsix under a releases\<version>\ folder, or nothing.
.DESCRIPTION
    How the public release repository is laid out: every version kept in its own folder so the
    older ones stay downloadable. Ordered by version rather than by name or write time, because
    a fresh clone gives every file the same timestamp and 2026.903.1.10 sorts before .1.2 as
    text.
#>
function Find-NewestReleasedVsix {
    param([string]$Folder)

    $releases = Join-Path $Folder 'releases'
    if (-not (Test-Path $releases)) { return $null }

    $best = $null
    $bestVersion = $null

    foreach ($directory in Get-ChildItem $releases -Directory) {
        $vsix = Get-ChildItem $directory.FullName -Filter '*.vsix' -File |
            Select-Object -First 1

        if (-not $vsix) { continue }

        $parsed = $null
        [void][version]::TryParse($directory.Name, [ref]$parsed)

        if ($null -eq $bestVersion -or
            ($parsed -and $bestVersion -and $parsed -gt $bestVersion) -or
            ($parsed -and -not $bestVersion)) {
            $best = $vsix.FullName
            $bestVersion = $parsed
        }
    }

    return $best
}

if (-not $VsixPath) {
    # Beside the script first, which is how a release folder is laid out: the .vsix and
    # these scripts together, no source tree anywhere.
    $VsixPath = Get-ChildItem $PSScriptRoot -Filter '*.vsix' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName

    # Then releases\<version>\, which is how the public repository is laid out: one folder per
    # version so the older ones stay downloadable. The newest wins.
    if (-not $VsixPath) {
        $VsixPath = Find-NewestReleasedVsix -Folder $PSScriptRoot
    }

    if (-not $VsixPath) {
        $VsixPath = Join-Path $root 'artifacts\Jarvis.SqlFormatter.vsix'
    }

    if (-not (Test-Path $VsixPath)) {
        $VsixPath = Join-Path $root 'src\Jarvis.SqlFormatter.Vsix\bin\Release\Jarvis.SqlFormatter.Vsix.vsix'
    }
}

if (-not (Test-Path $VsixPath)) {
    throw ("No .vsix found. Put one beside this script or under releases\<version>\, " +
           "run .\build\build.ps1, or pass -VsixPath.")
}

if ($DryRun) {
    Write-Host "Dry run, nothing will be changed." -ForegroundColor Cyan
    Write-Host "  package     $VsixPath"
    Write-Host ("  installed SSMS versions: {0}" -f (($installations | ForEach-Object { $_.DisplayVersion }) -join ', '))
    Write-Host ""

    foreach ($target in $targets) {
        Write-Host ("  -> SSMS {0}" -f $target.DisplayVersion) -ForegroundColor Cyan
        Write-Host ("     ide         {0}" -f $target.IdePath)
        Write-Host ("     extensions  {0}" -f $target.ExtensionsFolder)
        Write-Host ("     running     {0}" -f (@(Get-SsmsProcesses -Installation $target).Count -gt 0))
    }

    return
}

function Test-Installed {
    param([string]$ExtensionsFolder)

    foreach ($dir in Get-ChildItem $ExtensionsFolder -Directory -ErrorAction SilentlyContinue) {
        $manifest = Join-Path $dir.FullName 'extension.vsixmanifest'
        if (-not (Test-Path $manifest)) { continue }

        $text = Get-Content $manifest -Raw -ErrorAction SilentlyContinue
        if ($text -and $text -match [regex]::Escape($extensionId)) {
            return $dir.FullName
        }
    }

    return $null
}

function Install-Into {
    param([Parameter(Mandatory)][psobject]$Target)

    Write-Host ""
    Write-Host ("Installing into SSMS {0}" -f $Target.DisplayVersion) -ForegroundColor Cyan
    Write-Host ("  ide         {0}" -f $Target.IdePath)
    Write-Host ("  extensions  {0}" -f $Target.ExtensionsFolder)

    Assert-SsmsClosed -Installation $Target

    if ($Method -eq 'Installer') {
        $installer = Join-Path $Target.IdePath 'VSIXInstaller.exe'

        if (Test-Path $installer) {
            # Capture VSIXInstaller's own log. It exits 0 when it decides the package does not
            # apply to this product and installs nothing at all, and the log is the only place
            # that says so.
            $installerLog = Join-Path $env:TEMP ("jarvis-vsixinstaller-{0}.log" -f $Target.Version)
            Remove-Item -LiteralPath $installerLog -ErrorAction SilentlyContinue

            $process = Start-Process -FilePath $installer `
                -ArgumentList '/quiet', "/logFile:`"$installerLog`"", "`"$VsixPath`"" -Wait -PassThru

            $landed = Test-Installed -ExtensionsFolder $Target.ExtensionsFolder

            if ($process.ExitCode -eq 0 -and $landed) {
                Write-Host "  installed to $landed" -ForegroundColor Green
                Update-SsmsConfiguration -Installation $Target
                return $true
            }

            if ($process.ExitCode -eq 0) {
                Write-Warning "  VSIXInstaller reported success but nothing landed."
            }
            else {
                Write-Warning "  VSIXInstaller returned $($process.ExitCode)."
            }

            if (Test-Path $installerLog) {
                Write-Host "  --- what VSIXInstaller said ---" -ForegroundColor Cyan
                Get-Content $installerLog |
                    Where-Object { $_ -match 'error|warn|skip|not applicable|target|sku|signature|Install' } |
                    Select-Object -Last 20 |
                    ForEach-Object { '    ' + $_.Trim() }
                Write-Host "    (full log: $installerLog)" -ForegroundColor DarkGray
            }

            Write-Warning "  Falling back to a direct copy."
        }
        else {
            Write-Warning "  VSIXInstaller.exe was not found; using a direct copy."
        }
    }

    # Direct copy: a .vsix is just a zip, and SSMS loads any extension folder it finds here.
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $destination = Join-Path $Target.ExtensionsFolder $folderName
    if (Test-Path $destination) {
        Remove-Item $destination -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path $VsixPath), $destination)

    # The square brackets are wildcard characters to PowerShell, hence -LiteralPath.
    Remove-Item -LiteralPath (Join-Path $destination '[Content_Types].xml') -ErrorAction SilentlyContinue

    if (-not (Test-Installed -ExtensionsFolder $Target.ExtensionsFolder)) {
        throw "The copy to $destination did not produce a manifest SSMS will recognise."
    }

    Write-Host "  copied to $destination" -ForegroundColor Green
    Write-Warning ("  A copied folder is often discovered but not registered. Verify with " +
                   ".\build\check-registration.ps1 before assuming it worked.")

    Update-SsmsConfiguration -Installation $Target
    return $true
}

Write-Host "Installing $VsixPath" -ForegroundColor Cyan

foreach ($target in $targets) {
    Install-Into -Target $target | Out-Null
}

Write-Host ""
Write-Host ("Done. Start SSMS {0}; the Jarvis menu is on the menu bar." -f
    (($targets | ForEach-Object { $_.DisplayVersion }) -join ' and ')) -ForegroundColor Green
