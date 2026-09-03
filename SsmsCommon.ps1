<#
.SYNOPSIS
    Finding SQL Server Management Studio, shared by every script in this folder.

.DESCRIPTION
    Dot-source this file:  . "$PSScriptRoot\SsmsCommon.ps1"

    More than one SSMS can be installed side by side, and installing an extension into the
    wrong one looks exactly like installing into none of them. Every script therefore resolves
    the target the same way and says which one it picked.
#>

# No Set-StrictMode here on purpose: this file is dot-sourced, so it would silently change the
# behaviour of every script that includes it.

<#
.SYNOPSIS
    Every SSMS 21 or later found on this machine, newest first.
#>
function Get-SsmsInstallations {
    [CmdletBinding()]
    param()

    $found = New-Object System.Collections.Generic.List[psobject]

    $candidates = New-Object System.Collections.Generic.List[string]

    if ($env:SSMS_IDE_PATH) {
        $candidates.Add($env:SSMS_IDE_PATH)
    }

    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }) {
        # 30 is simply a generous upper bound; unknown future versions still get picked up.
        foreach ($major in 30..21) {
            $candidates.Add((Join-Path $base "Microsoft SQL Server Management Studio $major\Release\Common7\IDE"))
        }
    }

    foreach ($ide in $candidates) {
        if (-not (Test-Path (Join-Path $ide 'SSMS.exe'))) { continue }
        if ($found | Where-Object { $_.IdePath -eq $ide }) { continue }

        $found.Add((New-SsmsInstallation -IdePath $ide))
    }

    return $found | Sort-Object -Property @{ Expression = { [version]$_.Version }; Descending = $true }
}

<#
.SYNOPSIS
    Describes one installation: where it lives and which per user folder it uses.
#>
function New-SsmsInstallation {
    param([Parameter(Mandatory)][string]$IdePath)

    $ini = Join-Path $IdePath 'SSMS.isolation.ini'
    $installationId = $null
    $version = '0.0'
    $display = $null

    if (Test-Path $ini) {
        foreach ($line in Get-Content $ini) {
            if ($line -match '^InstallationID=(.+)$') { $installationId = $Matches[1].Trim() }
            if ($line -match '^InstallationVersion=([\d\.]+)') { $version = $Matches[1] }
            if ($line -match '^DisplayVersion=(.+)$') { $display = $Matches[1].Trim() }
        }
    }

    if (-not $display) { $display = $version }

    $major = ($version -split '\.')[0]
    $shell = Find-SsmsShellFolder -InstallationId $installationId -Major $major

    return [pscustomobject]@{
        IdePath          = $IdePath
        Version          = $version
        DisplayVersion   = $display
        InstallationId   = $installationId
        ShellFolder      = $shell
        ExtensionsFolder = if ($shell) { Join-Path $shell 'Extensions' } else { $null }
        Hive             = if ($shell) { Join-Path $shell 'privateregistry.bin' } else { $null }
        Exe              = Join-Path $IdePath 'SSMS.exe'
    }
}

<#
.SYNOPSIS
    The per user shell folder, named <major>.0_<installation id>.
.DESCRIPTION
    Note the MAJOR version: SSMS 22.6.0 still lives under 22.0_*. The installation id is the
    reliable half, so it is matched on first.
#>
function Find-SsmsShellFolder {
    param([string]$InstallationId, [string]$Major)

    $base = Join-Path $env:LOCALAPPDATA 'Microsoft\SSMS'
    if (-not (Test-Path $base)) { return $null }

    $folders = @(Get-ChildItem $base -Directory -ErrorAction SilentlyContinue)

    if ($InstallationId) {
        $match = $folders | Where-Object { $_.Name -like "*_$InstallationId" } | Select-Object -First 1
        if ($match) { return $match.FullName }
    }

    if ($Major) {
        $match = $folders |
            Where-Object { $_.Name -match "^$Major\.\d+_" } |
            Sort-Object Name -Descending | Select-Object -First 1
        if ($match) { return $match.FullName }
    }

    return $null
}

<#
.SYNOPSIS
    Picks which installation to act on, asking when there is a genuine choice.

.PARAMETER Version
    Choose without being asked: a major version such as 22, or any prefix of the full version.

.PARAMETER Quiet
    Never prompt. With several installed and no -Version, the newest is used and reported.

.PARAMETER Question
    What the caller is about to do, so the prompt reads correctly whether it is installing,
    removing, or only reporting.
#>
function Select-SsmsInstallation {
    [CmdletBinding()]
    param(
        [string]$Version,
        [switch]$Quiet,
        [psobject[]]$Installations,
        [string]$Question = 'Which one should this extension be installed on?'
    )

    if (-not $Installations) {
        $Installations = @(Get-SsmsInstallations)
    }

    if ($Installations.Count -eq 0) {
        throw ("No SQL Server Management Studio 21 or later was found. Set SSMS_IDE_PATH to its " +
               "Common7\IDE folder if it is installed somewhere unusual.")
    }

    if ($Version) {
        $selected = @($Installations | Where-Object {
            $_.Version -eq $Version -or
            $_.Version.StartsWith("$Version.") -or
            $_.DisplayVersion -eq $Version -or
            $_.DisplayVersion.StartsWith("$Version.")
        })

        if ($selected.Count -eq 0) {
            $available = ($Installations | ForEach-Object { $_.DisplayVersion }) -join ', '
            throw "No installed SSMS matches version '$Version'. Available: $available"
        }

        return $selected[0]
    }

    if ($Installations.Count -eq 1) {
        return $Installations[0]
    }

    if ($Quiet) {
        Write-Host ("Several SSMS versions are installed; using the newest, {0}." -f $Installations[0].DisplayVersion) -ForegroundColor Yellow
        return $Installations[0]
    }

    Write-Host ""
    Write-Host "More than one SQL Server Management Studio is installed." -ForegroundColor Cyan
    Write-Host $Question -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $Installations.Count; $i++) {
        $item = $Installations[$i]
        $running = if (@(Get-SsmsProcesses -Installation $item).Count -gt 0) { "  (running)" } else { "" }
        Write-Host ("  [{0}] SSMS {1}{2}" -f ($i + 1), $item.DisplayVersion, $running)
        Write-Host ("      {0}" -f $item.IdePath) -ForegroundColor DarkGray
    }

    Write-Host ("  [A] all of them")
    Write-Host ""

    while ($true) {
        $answer = Read-Host ("Choose 1-{0}, or A" -f $Installations.Count)

        if ($answer -match '^[Aa]') {
            return $Installations
        }

        $index = 0
        if ([int]::TryParse($answer, [ref]$index) -and $index -ge 1 -and $index -le $Installations.Count) {
            return $Installations[$index - 1]
        }

        Write-Host "  Not one of the choices." -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Running SSMS processes, all of them or only the ones from a given installation.
#>
function Get-SsmsProcesses {
    param([psobject]$Installation)

    $all = @(Get-Process -Name 'Ssms' -ErrorAction SilentlyContinue)
    if (-not $Installation) { return $all }

    return @($all | Where-Object {
        try { $_.MainModule.FileName -eq $Installation.Exe } catch { $false }
    })
}

<#
.SYNOPSIS
    Stops with a clear message when SSMS is open, because its files are locked.
#>
function Assert-SsmsClosed {
    param([psobject]$Installation)

    $running = @(Get-SsmsProcesses -Installation $Installation)
    if ($running.Count -eq 0) { return }

    Write-Host "SSMS is running:" -ForegroundColor Yellow
    foreach ($p in $running) {
        $title = if ($p.MainWindowTitle) { $p.MainWindowTitle } else { '(no window)' }
        Write-Host ("  PID {0}  {1}" -f $p.Id, $title)
    }

    throw ("Close SSMS and run this again. Save your work first; these scripts will not close it " +
           "for you, because an SSMS window can hold unsaved queries.")
}

<#
.SYNOPSIS
    Rebuilds the merged command table, which is what makes a new menu appear.
#>
function Update-SsmsConfiguration {
    param([Parameter(Mandatory)][psobject]$Installation)

    Write-Host ("Rebuilding the SSMS {0} command table cache (/updateconfiguration)..." -f $Installation.DisplayVersion) -ForegroundColor Cyan

    $process = Start-Process -FilePath $Installation.Exe -ArgumentList '/updateconfiguration' -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "  done" -ForegroundColor Green
    }
    else {
        Write-Warning "  /updateconfiguration returned $($process.ExitCode); the menu may need one extra SSMS start."
    }
}
