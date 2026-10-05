# =====================================================================
#   InsideEARTH - Two Worlds Tools & Utilities Launcher v1.0
# =====================================================================

# ---------------------------------------------------------------------
#  ** UNVERIFIED PLACEHOLDER DATA **
#  This game's GitHub repo, VPN/community server address, subnet and
#  level-repository were GUESSED from the Earth 2150 naming pattern -
#  they do not point at anything real yet. Confirm/replace before use:
#    GitHub repo : InsideTwoWorlds/Files
#    VPN server  : warnet.insideearth-tw.info
#    Subnet      : 10.21.100.0/24
#    Levels repo : InsideTwoWorlds/Levels
# ---------------------------------------------------------------------

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Self-elevation check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Exit
}

clear

$host.ui.RawUI.WindowTitle = "InsideEARTH - Two Worlds Tools & Utilities Launcher"
$ErrorActionPreference = 'Stop'

# Main loop for top-level menu selection
while ($true) {
    Clear-Host

    Write-Host " ===================================================" -ForegroundColor Green
    Write-Host "   InsideEARTH - Two Worlds Tools & Utilities Menu" -ForegroundColor Green
    Write-Host " ===================================================" -ForegroundColor Green
    Write-Host
    Write-Host " Select an option to download and run:" -ForegroundColor Cyan
    Write-Host "   [1] System Information"
    Write-Host "   [2] Multiplayer Setup"
    Write-Host "   [3] Levels Downloader"
    Write-Host "   [4] Registry Tools"
    Write-Host ""
    Write-Host "   [5] Exit" -ForegroundColor Red
    Write-Host

    $choice = Read-Host "Enter option (1-5)"

    $scriptName  = $null
    $apiPath     = $null
    $downloadUrl = $null

    switch ($choice) {
        "1" {
            $scriptName  = "ITW-System-Information.ps1"
            $apiPath     = "Tools/toolbox/modules/system/ITW-System-Information.ps1"
            $downloadUrl = "https://raw.githubusercontent.com/InsideTwoWorlds/Files/refs/heads/main/Tools/toolbox/modules/system/ITW-System-Information.ps1"
        }
        "2" {
            $scriptName  = "ITW-MP-Setup.ps1"
            $apiPath     = "Tools/toolbox/modules/mp-setup/ITW-MP-Setup.ps1"
            $downloadUrl = "https://raw.githubusercontent.com/InsideTwoWorlds/Files/refs/heads/main/Tools/toolbox/modules/mp-setup/ITW-MP-Setup.ps1"
        }
        "3" {
            $scriptName  = "ITW-Level-Downloader.ps1"
            $apiPath     = "Tools/toolbox/modules/downloaders/ITW-Level-Downloader.ps1"
            $downloadUrl = "https://raw.githubusercontent.com/InsideTwoWorlds/Files/refs/heads/main/Tools/toolbox/modules/downloaders/ITW-Level-Downloader.ps1"
        }
        "4" {
            $scriptName  = "ITW-Registry-Editor.ps1"
            $apiPath     = "Tools/toolbox/modules/registry/editor/ITW-Registry-Editor.ps1"
            $downloadUrl = "https://raw.githubusercontent.com/InsideTwoWorlds/Files/refs/heads/main/Tools/toolbox/modules/registry/editor/ITW-Registry-Editor.ps1"
        }
        "5" {
            Write-Host "`nExiting..." -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "Invalid selection. Press Enter to try again..." -ForegroundColor Red
            Start-Sleep -Seconds 2
            continue
        }
    }

    # 1. Target Paths in TEMP & Hash Setup
    $targetScriptPath = Join-Path $env:TEMP $scriptName
    $hashFileName     = "$([System.IO.Path]::GetFileNameWithoutExtension($scriptName)).sha"
    $hashPath         = Join-Path $env:TEMP $hashFileName
    $apiUrl           = "https://api.github.com/repos/InsideTwoWorlds/Files/commits?path=$apiPath&page=1&per_page=1"

    $needsDownload = $true

    # 2. SHA Comparison & Conditional Download
    if ((Test-Path $targetScriptPath) -and (Test-Path $hashPath)) {
        try {
            $remoteHash = (Invoke-RestMethod -Uri $apiUrl -UseBasicParsing)[0].sha
            $localHash  = (Get-Content $hashPath -Raw).Trim()

            if ($remoteHash.Trim() -eq $localHash) {
                $needsDownload = $false
            }
        } catch {
            # Default to running existing file if API rate limit or network check fails
            $needsDownload = $false
        }
    }

    if ($needsDownload) {
        Write-Host
        Write-Host "Downloading latest version of $scriptName to TEMP..." -ForegroundColor Cyan
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $downloadUrl -OutFile $targetScriptPath -UseBasicParsing

            try {
                $latestHash = (Invoke-RestMethod -Uri $apiUrl -UseBasicParsing)[0].sha
                Set-Content -Path $hashPath -Value $latestHash -Force
            } catch {}

            Write-Host "Download complete: $targetScriptPath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to download the script from GitHub: $_" -ForegroundColor Red
            Start-Sleep -Seconds 3
            continue
        }
    } else {
        Write-Host
        Write-Host "$scriptName in TEMP is up to date." -ForegroundColor Green
    }

    # 3. Execute Downloaded Tool Script from TEMP
    Write-Host "Starting $scriptName..." -ForegroundColor Cyan
    Write-Host

    Set-Location -Path $env:TEMP
    & $targetScriptPath

    # Reset location and prompt before looping back to main menu
    Set-Location -Path $PSScriptRoot
    Write-Host
    Read-Host "Process completed. Press Enter to return to main menu..."
}
