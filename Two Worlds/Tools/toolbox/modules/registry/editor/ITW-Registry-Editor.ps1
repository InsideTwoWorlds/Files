# =====================================================================
#    InsideEARTH - Two Worlds Registry Tools v1.0
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

# Self-elevation check to run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Clear-Host

$host.UI.RawUI.WindowTitle = "InsideEARTH - Two Worlds Tools & Utilities Launcher"
$ErrorActionPreference = 'Stop'

# Suffix appended to the game folder to form the 'datapath' value (empty string if none)
$DataPathSuffix = ''

# ---------------------------------------------------------------------
#  DEFAULT REGISTRY SETTINGS - one block per game/variant
#
#  Curated from Dan's real .reg exports: license/serial keys, hardware IDs,
#  opaque binary blobs and personal session state (LastPlayer, history, etc.)
#  are deliberately left out. Resolution is forced to 1920x1080 @ 60Hz per
#  his instruction. '(root)' means the game's top-level key.
# ---------------------------------------------------------------------

# ===== Two Worlds =====
$Defaults_TwoWorlds = @{
        HKCU = [ordered]@{
            '(root)' = [ordered]@{}
            'Console' = [ordered]@{}
            'Graphics' = [ordered]@{
                Width = 1920
                Height = 1080
                FullScreen = 1
                EnableMultisampleInWindowedMode = 0
            }
            'Interface' = [ordered]@{
                TranslateNumKeys = 1
                Charset = 1
                UseFontsCache = 1
            }
            'Network' = [ordered]@{
                EarthNet_ServersAddresses = '"ITW-WarNet""10.17.0.1""WarNet Europe""warnet.insideearth-tw.info""WarNet Europe 2""netserver.2-worlds.com"'
                EarthNet_NATResolverAddress = 'warnet.insideearth-tw.info'
                EarthNet_ServerPort = 17151
                EarthNet_GamePort = 17851
                EarthNet_UseDPDefaultGamePort = 1
                EarthNet_UseNATResolver = 1
                EarthNet_AddNATResolverInHost = 1
            }
            'Sound' = [ordered]@{
                EnableSound = 1
                Enable3DSound = 1
            }
            'FileSystem' = [ordered]@{
                MyDocumentsFolder = 'Two Worlds Saves'
                EnableGamesForWindows = 1
            }
        }
        HKLM = [ordered]@{
            '(root)' = [ordered]@{}
            'Console' = [ordered]@{}
            'Graphics' = [ordered]@{}
            'Interface' = [ordered]@{}
            'Network' = [ordered]@{}
            'Sound' = [ordered]@{}
            'FileSystem' = [ordered]@{}
        }
}

# Define game/variant configurations.
$games = @(
    @{
        Name     = 'Two Worlds'
        HkcuBase = 'HKCU:\Software\Reality Pump\TwoWorlds'
        HklmBase = 'HKLM:\Software\WOW6432Node\Reality Pump\TwoWorlds'
        HasBaseGame = $false
        Defaults = $Defaults_TwoWorlds
    }
)

# ---------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------
function Get-FileSystemPaths {
    param($Game)
    $sub = if ($Game.HasBaseGame) { 'BaseGame\FileSystem' } else { 'FileSystem' }
    return @(
        "$($Game.HkcuBase)$sub",
        "$($Game.HklmBase)$sub"
    )
}

function Write-Header {
    param([string]$Title)
    Clear-Host
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "   $Title" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
}

function Wait-AnyKey {
    param([string]$Message = "Press any key to continue...")
    Write-Host ""
    Write-Host $Message -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Write-RegistryEntries {
    param(
        [string]$Base,
        $Entries
    )
    foreach ($sub in $Entries.Keys) {
        $keyPath = if ($sub -eq '(root)') { $Base } else { "$Base\$sub" }
        if (-not (Test-Path -LiteralPath $keyPath)) {
            $null = New-Item -Path $keyPath -Force
        }
        foreach ($name in $Entries[$sub].Keys) {
            $value = $Entries[$sub][$name]
            $type  = if ($value -is [int]) { 'DWord' } else { 'String' }
            Set-ItemProperty -LiteralPath $keyPath -Name $name -Value $value -Type $type -Force
        }
    }
}

function Show-GameMenu {
    Write-Header "InsideEARTH - Two Worlds Tools & Utilities Menu"
    Write-Host "Select a game:" -ForegroundColor White
    for ($i = 0; $i -lt $games.Count; $i++) {
        Write-Host "    [$($i + 1)] $($games[$i].Name)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "    [$($games.Count + 1)] Exit" -ForegroundColor Red
    Write-Host ""
}

function Show-ActionMenu {
    param([string]$GameName)
    Write-Header "InsideEARTH - $GameName"
    Write-Host "Select an action:" -ForegroundColor White
    Write-Host "    [1] Registry Editor   (set game install path)" -ForegroundColor White
    Write-Host "    [2] Registry Default  (install default registry settings)" -ForegroundColor White
    Write-Host "    [3] Registry Backup   (HKCU + HKLM into a single .reg file)" -ForegroundColor White
    Write-Host ""
    Write-Host "    [4] Back" -ForegroundColor Red
    Write-Host ""
}

# ---------------------------------------------------------------------
#  Option 1: Registry Editor - set install path
# ---------------------------------------------------------------------
function Edit-RegistryValues {
    param(
        [string]$GameName,
        [string[]]$RegPaths
    )

    Write-Header "InsideEARTH - $GameName Registry Configuration"

    Write-Host "Current Registry Information (HKCU & HKLM):" -ForegroundColor Cyan

    foreach ($path in $RegPaths) {
        Write-Host "  [$path]" -ForegroundColor DarkGray
        try {
            if (Test-Path -LiteralPath $path) {
                $currentDatapath  = (Get-ItemProperty -LiteralPath $path -Name "datapath" -ErrorAction SilentlyContinue).datapath
                $currentOutputDir = (Get-ItemProperty -LiteralPath $path -Name "OutputDir" -ErrorAction SilentlyContinue).OutputDir
            } else {
                $currentDatapath  = $null
                $currentOutputDir = $null
            }

            Write-Host "     datapath  : $(if ($currentDatapath) { $currentDatapath } else { '(not set)' })" -ForegroundColor White
            Write-Host "     OutputDir : $(if ($currentOutputDir) { $currentOutputDir } else { '(not set)' })" -ForegroundColor White
        } catch {
            Write-Host "    [!] Could not access registry path: $_" -ForegroundColor Red
        }
    }
    Write-Host ""

    $choice = Read-Host "Do you wish to edit these values for both locations? (y/n)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        Write-Host ""
        $fullPath = Read-Host "Enter the full file path (e.g., G:\Games\Steam\steamapps\common\GameName)"

        if ([string]::IsNullOrWhiteSpace($fullPath)) {
            Write-Host "Path cannot be empty." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }

        $cleanPath    = $fullPath.Trim().Trim('"').TrimEnd('/', '\')
        $newDatapath  = "$cleanPath$DataPathSuffix"
        $newOutputDir = $cleanPath

        foreach ($path in $RegPaths) {
            try {
                if (-not (Test-Path -LiteralPath $path)) {
                    $null = New-Item -Path $path -Force
                }

                Set-ItemProperty -LiteralPath $path -Name "datapath" -Value $newDatapath -Type String -Force
                Set-ItemProperty -LiteralPath $path -Name "OutputDir" -Value $newOutputDir -Type String -Force

            } catch {
                Write-Host "    [!] Failed to update $path : $_" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "Changes successfully applied to all targets!" -ForegroundColor Green
        Write-Host "Updated Registry Information:" -ForegroundColor Cyan
        Write-Host "  datapath  : $newDatapath" -ForegroundColor White
        Write-Host "  OutputDir : $newOutputDir" -ForegroundColor White
    }

    Wait-AnyKey "Press any key to return to the menu..."
}

# ---------------------------------------------------------------------
#  Option 2: Registry Default
# ---------------------------------------------------------------------
function Install-DefaultRegistry {
    param($Game)

    Write-Header "InsideEARTH - $($Game.Name) Default Registry Settings"
    Write-Host "This will write the default settings under:" -ForegroundColor Cyan
    Write-Host "  $($Game.HkcuBase)" -ForegroundColor DarkGray
    Write-Host "  $($Game.HklmBase)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Existing values with the same names will be overwritten." -ForegroundColor Yellow
    Write-Host "Your install path (datapath / OutputDir) is preserved if already set." -ForegroundColor Yellow
    Write-Host "Tip: run Registry Backup first if you want to be able to undo this." -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Continue? (y/n)"
    if ($choice -ne 'y' -and $choice -ne 'Y') { return }

    try {
        $fsPaths = Get-FileSystemPaths $Game
        $keepDatapath  = $null
        $keepOutputDir = $null
        foreach ($p in $fsPaths) {
            if (Test-Path -LiteralPath $p) {
                if (-not $keepDatapath)  { $keepDatapath  = (Get-ItemProperty -LiteralPath $p -Name "datapath" -ErrorAction SilentlyContinue).datapath }
                if (-not $keepOutputDir) { $keepOutputDir = (Get-ItemProperty -LiteralPath $p -Name "OutputDir" -ErrorAction SilentlyContinue).OutputDir }
            }
        }

        if (-not $keepDatapath -or -not $keepOutputDir) {
            Write-Host ""
            $fullPath = Read-Host "No install path found. Enter the game folder (blank to leave unset)"
            if (-not [string]::IsNullOrWhiteSpace($fullPath)) {
                $cleanPath     = $fullPath.Trim().Trim('"').TrimEnd('/', '\')
                $keepDatapath  = "$cleanPath$DataPathSuffix"
                $keepOutputDir = $cleanPath
            }
        }

        Write-RegistryEntries -Base $Game.HkcuBase -Entries $Game.Defaults.HKCU
        Write-RegistryEntries -Base $Game.HklmBase -Entries $Game.Defaults.HKLM

        if ($keepDatapath -and $keepOutputDir) {
            foreach ($p in $fsPaths) {
                if (-not (Test-Path -LiteralPath $p)) { $null = New-Item -Path $p -Force }
                Set-ItemProperty -LiteralPath $p -Name "datapath" -Value $keepDatapath -Type String -Force
                Set-ItemProperty -LiteralPath $p -Name "OutputDir" -Value $keepOutputDir -Type String -Force
            }
        }

        Write-Host ""
        Write-Host "Default registry settings installed for $($Game.Name)." -ForegroundColor Green
        if ($keepDatapath) {
            Write-Host "  datapath  : $keepDatapath" -ForegroundColor White
            Write-Host "  OutputDir : $keepOutputDir" -ForegroundColor White
        } else {
            Write-Host "  Install path left unset - use Registry Editor to set it." -ForegroundColor Yellow
        }
    } catch {
        Write-Host ""
        Write-Host "[!] Failed to install defaults: $_" -ForegroundColor Red
    }

    Wait-AnyKey "Press any key to return to the menu..."
}

# ---------------------------------------------------------------------
#  Option 3: Registry Backup (HKCU + HKLM merged into one .reg file)
# ---------------------------------------------------------------------
function Backup-GameRegistry {
    param($Game)

    Write-Header "InsideEARTH - $($Game.Name) Registry Backup"

    $desktop   = [Environment]::GetFolderPath('Desktop')
    $timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $safeName  = ($Game.Name -replace '[^A-Za-z0-9]', '')
    $backupFile = Join-Path $desktop "ITW-Backup-$safeName-$timestamp.reg"

    $sources = @(
        @{ Label = 'HKCU'; Path = $Game.HkcuBase; Native = ($Game.HkcuBase -replace '^HKCU:\\', 'HKEY_CURRENT_USER\') },
        @{ Label = 'HKLM'; Path = $Game.HklmBase; Native = ($Game.HklmBase -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\') }
    )

    $merged   = New-Object System.Collections.Generic.List[string]
    $exported = 0

    try {
        foreach ($src in $sources) {
            if (-not (Test-Path -LiteralPath $src.Path)) {
                Write-Host " - $($src.Label): key not found, skipping." -ForegroundColor Yellow
                continue
            }

            $tmp = Join-Path $env:TEMP "ITW-$($src.Label)-$timestamp.reg"
            & reg.exe export $src.Native $tmp /y *> $null
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmp)) {
                Write-Host " - $($src.Label): export failed." -ForegroundColor Red
                continue
            }

            $lines = @(Get-Content -LiteralPath $tmp -Encoding Unicode)
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue

            if ($exported -eq 0) {
                foreach ($l in $lines) { $merged.Add($l) }
            } else {
                $merged.Add('')
                foreach ($l in ($lines | Select-Object -Skip 1)) { $merged.Add($l) }
            }
            $exported++
            Write-Host " - $($src.Label): exported." -ForegroundColor Green
        }

        if ($exported -eq 0) {
            Write-Host ""
            Write-Host "Nothing to back up - neither key exists for $($Game.Name)." -ForegroundColor Yellow
        } else {
            Set-Content -LiteralPath $backupFile -Value $merged -Encoding Unicode
            Write-Host ""
            Write-Host "Backup saved to:" -ForegroundColor Green
            Write-Host "  $backupFile" -ForegroundColor White
        }
    } catch {
        Write-Host ""
        Write-Host "[!] Backup failed: $_" -ForegroundColor Red
    }

    Wait-AnyKey "Press any key to return to the menu..."
}

# ---------------------------------------------------------------------
#  Per-game action menu
# ---------------------------------------------------------------------
function Start-GameActions {
    param($Game)

    do {
        Show-ActionMenu -GameName $Game.Name
        $sel = Read-Host "Enter option (1-4)"

        switch ($sel) {
            '1' { Edit-RegistryValues -GameName $Game.Name -RegPaths (Get-FileSystemPaths $Game) }
            '2' { Install-DefaultRegistry -Game $Game }
            '3' { Backup-GameRegistry -Game $Game }
            '4' { return }
            default {
                Write-Host ""
                Write-Host "Invalid selection." -ForegroundColor Red
                Wait-AnyKey "Press any key to try again..."
            }
        }
    } while ($true)
}

# ---------------------------------------------------------------------
#  Main loop
# ---------------------------------------------------------------------
do {
    Show-GameMenu
    $maxOption = $games.Count + 1
    $selection = Read-Host "Enter option (1-$maxOption)"

    switch ($selection) {
        '1' { Start-GameActions -Game $games[0] }
        "$maxOption" { exit }
        default {
            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red
            Wait-AnyKey "Press any key to try again..."
        }
    }
} while ($true)
