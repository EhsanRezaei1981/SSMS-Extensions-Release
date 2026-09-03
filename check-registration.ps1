<#
.SYNOPSIS
    Reports whether SSMS has merged the Jarvis pkgdef into its configuration hive.

.DESCRIPTION
    The shell keeps its merged configuration in privateregistry.bin. A package that is not in
    there does not exist as far as SSMS is concerned, whatever is sitting in the Extensions
    folder. Reading it directly means an install can be verified without starting SSMS.

    The hive is opened with RegLoadAppKey, which needs no elevation, and is only read.
    SSMS must be closed, because Windows locks the hive while it runs.

    With more than one SSMS installed you are asked which one to check, so that this reports on
    the same installation install.ps1 wrote to. Use -Version to answer in advance.

.EXAMPLE
    .\build\check-registration.ps1
    .\build\check-registration.ps1 -Version 22
    .\build\check-registration.ps1 -All
#>
[CmdletBinding()]
param(
    [string]$Guid = '{ce715d37-1a20-4603-8cad-53388d856cf2}',

    # Check this version without being asked, for example 22.
    [string]$Version,

    # Check every installed SSMS.
    [switch]$All
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\SsmsCommon.ps1"

Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices; using Microsoft.Win32.SafeHandles;
public static class JarvisHive {
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int RegLoadAppKey(string file, out IntPtr hKey, int samDesired, int options, int reserved);
    public static SafeRegistryHandle Load(string file) {
        IntPtr h; int rc = RegLoadAppKey(file, out h, 0x20019, 0, 0);
        if (rc != 0) throw new System.ComponentModel.Win32Exception(rc);
        return new SafeRegistryHandle(h, true);
    }
}
'@ -ErrorAction Stop

$extensionId = 'Jarvis.SSMSExtension.ce715d37-1a20-4603-8cad-53388d856cf2'

# What an install from before the rename calls itself. Reported if found, because it and the
# current one register the same package GUID and the symptom is a menu that misbehaves.
$legacyExtensionId = 'Jarvis.SqlFormatter.ce715d37-1a20-4603-8cad-53388d856cf2'
$sourceDll = Join-Path (Split-Path -Parent $PSScriptRoot) 'src\Jarvis.SSMSExtension.Vsix\bin\Release\Jarvis.SSMSExtension.Vsix.dll'

<#
.SYNOPSIS
    Checks one installation and returns 0 registered, 1 not registered, 2 not installed.
#>
function Test-Registration {
    param([Parameter(Mandatory)][psobject]$Installation)

    Write-Host ("SSMS {0}   {1}" -f $Installation.DisplayVersion, $Installation.IdePath) -ForegroundColor Cyan

    if (-not $Installation.Hive) {
        Write-Host "  No per user folder yet; start SSMS once." -ForegroundColor Yellow
        return 2
    }

    $hivePath = $Installation.Hive

    # Is it even installed? Without this the script reports MISSING for an extension that was
    # never there, which reads like a failure rather than "nothing to register".
    $installedAt = $null
    $legacyAt = $null

    foreach ($dir in Get-ChildItem $Installation.ExtensionsFolder -Directory -ErrorAction SilentlyContinue) {
        $manifest = Join-Path $dir.FullName 'extension.vsixmanifest'
        if (-not (Test-Path $manifest)) { continue }

        $text = Get-Content $manifest -Raw -ErrorAction SilentlyContinue
        if (-not $text) { continue }

        if ($text -match [regex]::Escape($extensionId)) {
            $installedAt = $dir.FullName
        }
        elseif ($text -match [regex]::Escape($legacyExtensionId)) {
            $legacyAt = $dir.FullName
        }
    }

    # Both at once is the state worth shouting about: two extensions registering one package
    # GUID, which shows up as a duplicated or missing Jarvis menu rather than as an error.
    if ($legacyAt) {
        Write-Host "  pre-rename  $legacyAt" -ForegroundColor Yellow
        Write-Warning "  An install from before the rename is still here. Remove it with .\uninstall.ps1"
    }

    if (-not $installedAt) {
        Write-Host "  hive        $hivePath"
        Write-Host ""
        Write-Host "  The extension is not installed here, so there is nothing to register." -ForegroundColor Yellow
        Write-Host ("      .\build\install.ps1 -Version {0}" -f $Installation.DisplayVersion) -ForegroundColor Yellow
        return 2
    }

    Write-Host "  files       $installedAt"

    # Show when the installed assembly was built, so "did the update take?" is answerable at a
    # glance. The version number is the same on every build and cannot answer it.
    $installedDll = Join-Path $installedAt 'Jarvis.SSMSExtension.Vsix.dll'
    if (Test-Path $installedDll) {
        $installedTime = (Get-Item $installedDll).LastWriteTime
        Write-Host ("  build       {0:yyyy-MM-dd HH:mm:ss}" -f $installedTime)

        if (Test-Path $sourceDll) {
            $sourceTime = (Get-Item $sourceDll).LastWriteTime
            if ($sourceTime -gt $installedTime.AddMinutes(1)) {
                Write-Host ("              a newer build exists ({0:yyyy-MM-dd HH:mm:ss}); run .\build\update.ps1" -f $sourceTime) -ForegroundColor Yellow
            }
        }
    }

    $root = [Microsoft.Win32.RegistryKey]::FromHandle([JarvisHive]::Load($hivePath))

    try {
        $configRoot = $null
        $ssms = $root.OpenSubKey('Software\Microsoft\SSMS')
        if ($ssms) {
            foreach ($name in $ssms.GetSubKeyNames()) {
                if ($name -match '_Config$') { $configRoot = "Software\Microsoft\SSMS\$name"; break }
            }
        }
        if (-not $configRoot) { throw "No _Config root found inside $hivePath" }

        $cfg = $root.OpenSubKey($configRoot)
        $menus = $cfg.OpenSubKey('Menus')
        $menuValue = if ($menus) { $menus.GetValue($Guid) } else { $null }
        $pkg = $cfg.OpenSubKey("Packages\$Guid")

        Write-Host "  hive        $hivePath"
        Write-Host "  config root $configRoot"
        Write-Host ""

        $okPkg = $null -ne $pkg
        $okMenu = $null -ne $menuValue

        Write-Host ("    Packages\{0}  {1}" -f $Guid, $(if ($okPkg) { 'present' } else { 'MISSING' })) `
            -ForegroundColor $(if ($okPkg) { 'Green' } else { 'Yellow' })
        Write-Host ("    Menus  {0}  {1}" -f $Guid, $(if ($okMenu) { "= '$menuValue'" } else { 'MISSING' })) `
            -ForegroundColor $(if ($okMenu) { 'Green' } else { 'Yellow' })
        Write-Host ("    (Menus holds {0} entries in total)" -f $(if ($menus) { $menus.GetValueNames().Count } else { 0 })) -ForegroundColor DarkGray

        if ($okPkg -and $okMenu) {
            Write-Host "`n  Registered. Starting SSMS should show the menu." -ForegroundColor Green
            return 0
        }

        Write-Host "`n  Not registered: SSMS is skipping the extension when it rebuilds its configuration." -ForegroundColor Yellow
        return 1
    }
    finally {
        $root.Dispose()
    }
}

# ---------------------------------------------------------------------------------------
# Work
# ---------------------------------------------------------------------------------------

$installations = @(Get-SsmsInstallations)

if ($All) {
    $targets = $installations
}
else {
    $targets = @(Select-SsmsInstallation -Version $Version -Installations $installations -Question 'Which one should be checked?')
}

# Windows locks the hive while SSMS runs, so it has to be closed regardless of which one is
# being checked.
Assert-SsmsClosed

$worst = 0
foreach ($target in $targets) {
    $code = Test-Registration -Installation $target
    if ($code -gt $worst) { $worst = $code }
    Write-Host ""
}

exit $worst
