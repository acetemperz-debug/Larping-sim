#Requires -Version 5.1
<#
.SYNOPSIS
    Sets up and runs LARPing Simulator.

.DESCRIPTION
    Finds Rojo, downloads it into this folder if it isn't already installed,
    installs the Roblox Studio plugin, and starts the live-sync server.

    Run it again any time you want to start syncing -- it only downloads once.

.PARAMETER Build
    Build LarpingSimulator.rbxl and exit, instead of starting the sync server.
    Use this if you just want a place file to double-click.

.PARAMETER SkipPlugin
    Don't try to install the Roblox Studio plugin.

.EXAMPLE
    .\START-HERE.ps1
    .\START-HERE.ps1 -Build
#>
[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$SkipPlugin
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-Location -LiteralPath $PSScriptRoot

function Write-Step { param($Text) Write-Host "`n>> $Text" -ForegroundColor Cyan }
function Write-Ok   { param($Text) Write-Host "   $Text" -ForegroundColor Green }
function Write-Warn { param($Text) Write-Host "   $Text" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  LARPing Simulator" -ForegroundColor White
Write-Host "  none of it is yours" -ForegroundColor DarkGray
Write-Host ""

if (-not (Test-Path 'default.project.json')) {
    throw "default.project.json not found. Run this script from inside the project folder."
}

# --- Find or fetch Rojo ---------------------------------------------------

function Find-Rojo {
    $onPath = Get-Command rojo -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }

    $local = Join-Path $PSScriptRoot 'rojo.exe'
    if (Test-Path $local) { return $local }

    return $null
}

function Install-Rojo {
    Write-Step "Rojo not found. Downloading the latest Windows build..."

    $api = 'https://api.github.com/repos/rojo-rbx/rojo/releases/latest'
    try {
        $release = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'larping-sim-setup' }
    } catch {
        throw @"
Couldn't reach GitHub to download Rojo ($($_.Exception.Message)).

Install it yourself instead, then run this script again:
  https://github.com/rojo-rbx/rojo/releases/latest
Download the Windows .zip, put rojo.exe next to this script.
"@
    }

    # Asset names have changed shape across releases, so match rather than assume.
    $asset = $release.assets |
        Where-Object { $_.name -match 'win' -and $_.name -match '\.zip$' } |
        Select-Object -First 1

    if (-not $asset) {
        throw "No Windows build in Rojo release $($release.tag_name). Grab it manually from https://github.com/rojo-rbx/rojo/releases/latest"
    }

    Write-Ok "Found $($asset.name) ($($release.tag_name))"

    $zip = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
    Expand-Archive -LiteralPath $zip -DestinationPath $PSScriptRoot -Force
    Remove-Item -LiteralPath $zip -Force

    $exe = Join-Path $PSScriptRoot 'rojo.exe'
    if (-not (Test-Path $exe)) {
        throw "Extracted the download but rojo.exe isn't there. Extract it manually next to this script."
    }

    Write-Ok "Installed to $exe"
    return $exe
}

$rojo = Find-Rojo
if (-not $rojo) {
    $rojo = Install-Rojo
} else {
    Write-Step "Using Rojo at $rojo"
}

Write-Ok (& $rojo --version)

# --- Build and exit, if that's all they wanted ----------------------------

if ($Build) {
    Write-Step "Building LarpingSimulator.rbxl..."
    & $rojo build -o 'LarpingSimulator.rbxl'
    if ($LASTEXITCODE -ne 0) { throw "Build failed." }

    $out = Join-Path $PSScriptRoot 'LarpingSimulator.rbxl'
    Write-Ok "Built $out"
    Write-Host ""
    Write-Host "  Double-click that file to open it in Roblox Studio, then press Play." -ForegroundColor White
    Write-Host ""
    return
}

# --- Studio plugin --------------------------------------------------------

if (-not $SkipPlugin) {
    Write-Step "Installing the Roblox Studio plugin..."
    & $rojo plugin install
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Installed. Restart Studio if it's already open."
    } else {
        Write-Warn "Couldn't install it automatically."
        Write-Warn "Get 'Rojo' from the Studio plugin marketplace instead."
    }
}

# --- Serve ----------------------------------------------------------------

Write-Step "Starting the sync server..."
Write-Host ""
Write-Host "  Now, in Roblox Studio:" -ForegroundColor White
Write-Host "    1. Open any new baseplate place" -ForegroundColor Gray
Write-Host "    2. Plugins tab -> Rojo -> Connect" -ForegroundColor Gray
Write-Host "    3. Allow the plugin to access localhost when Studio asks" -ForegroundColor Gray
Write-Host "    4. Press Play" -ForegroundColor Gray
Write-Host ""
Write-Host "  Saving a .lua file updates Studio instantly." -ForegroundColor DarkGray
Write-Host "  Ctrl+C here stops syncing." -ForegroundColor DarkGray
Write-Host ""

& $rojo serve
