#Requires -Version 5.1
<#
.SYNOPSIS
    Sets up and runs LARPing Simulator.

.DESCRIPTION
    Finds a working Rojo, downloads one into this folder if it can't find one,
    installs the Roblox Studio plugin, and starts the live-sync server.

    Run it again any time you want to start syncing -- it only downloads once.

.PARAMETER Build
    Build LarpingSimulator.rbxl and exit, instead of starting the sync server.
    Use this if you just want a place file to double-click.

.PARAMETER SkipPlugin
    Don't try to install the Roblox Studio plugin.

.PARAMETER ForceDownload
    Ignore any Rojo already on your system and fetch a private copy into this
    folder. Useful if your existing install is misbehaving.

.PARAMETER Port
    Port to serve on. Defaults to 34872, which is what the Studio plugin
    expects. The script moves to a free port automatically if this one is taken
    by something that isn't Rojo.

.PARAMETER Force
    Don't ask before stopping a Rojo server that is already running.

.EXAMPLE
    .\START-HERE.ps1
    .\START-HERE.ps1 -Build
    .\START-HERE.ps1 -ForceDownload
    .\START-HERE.ps1 -Port 34873
#>
[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$SkipPlugin,
    [switch]$ForceDownload,
    [int]$Port = 34872,
    [switch]$Force
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

$LocalRojo = Join-Path $PSScriptRoot 'rojo.exe'

# --- Finding a Rojo that actually runs ------------------------------------

<#
    Existing on disk is not the same as working. Toolchain managers (Rokit,
    Aftman, Foreman) put a shim on PATH that refuses to run unless the project
    declares the tool, so `rojo` can be present and still fail every command.
    Everything below tests by execution, never by existence.
#>
function Test-Rojo {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }

    try {
        $null = & $Path --version 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Get-RojoVersion {
    param([string]$Path)
    try { return (& $Path --version 2>&1 | Select-Object -First 1) } catch { return 'unknown version' }
}

# Best-effort: teach the toolchain manager about this project so its shim works.
function Repair-Toolchain {
    $rokit = Get-Command rokit -ErrorAction SilentlyContinue
    if (-not $rokit) { return $false }

    Write-Warn "Found Rokit. Installing this project's tools..."

    # Rokit asks for trust before installing an unfamiliar tool; granting it up
    # front keeps this non-interactive. Both commands are allowed to fail.
    try { & $rokit.Source trust 'rojo-rbx/rojo' 2>&1 | Out-Null } catch { }
    try { & $rokit.Source install 2>&1 | Out-Host } catch { }

    return $true
}

function Get-WorkingRojo {
    # 1. A copy we fetched previously. We know this one is real.
    if ((Test-Path $LocalRojo) -and (Test-Rojo $LocalRojo)) {
        return $LocalRojo
    }

    # 2. Whatever is on PATH -- but only if it genuinely runs.
    $onPath = Get-Command rojo -ErrorAction SilentlyContinue
    if ($onPath) {
        if (Test-Rojo $onPath.Source) {
            return $onPath.Source
        }

        Write-Warn "Found $($onPath.Source), but it won't run."

        if ($onPath.Source -match '\.rokit|\.aftman|\.foreman') {
            Write-Warn "That's a toolchain-manager shim, not Rojo itself."
            if (Repair-Toolchain) {
                if (Test-Rojo $onPath.Source) {
                    Write-Ok "Repaired."
                    return $onPath.Source
                }
            }
            Write-Warn "Still not working. Fetching a private copy instead."
        }
    }

    return $null
}

function Install-Rojo {
    Write-Step "Downloading Rojo into this folder..."

    $api = 'https://api.github.com/repos/rojo-rbx/rojo/releases/latest'
    try {
        $release = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'larping-sim-setup' }
    } catch {
        throw @"
Couldn't reach GitHub to download Rojo ($($_.Exception.Message)).

Install it yourself, then run this script again:
  https://github.com/rojo-rbx/rojo/releases/latest
Download the Windows .zip and put rojo.exe next to this script.
"@
    }

    # Asset names have changed shape across releases, so match rather than assume.
    $asset = $release.assets |
        Where-Object { $_.name -match 'win' -and $_.name -match '\.zip$' } |
        Select-Object -First 1

    if (-not $asset) {
        throw "No Windows build in Rojo release $($release.tag_name). Grab it manually from https://github.com/rojo-rbx/rojo/releases/latest"
    }

    Write-Ok "Fetching $($asset.name) ($($release.tag_name))"

    $zip = Join-Path $env:TEMP $asset.name
    $staging = Join-Path $env:TEMP ("rojo-extract-" + [Guid]::NewGuid().ToString('N'))

    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
        Expand-Archive -LiteralPath $zip -DestinationPath $staging -Force

        # Some releases nest the binary inside a folder, so search for it.
        $found = Get-ChildItem -LiteralPath $staging -Filter 'rojo.exe' -Recurse |
            Select-Object -First 1

        if (-not $found) {
            throw "The download didn't contain rojo.exe. Extract it manually next to this script."
        }

        Copy-Item -LiteralPath $found.FullName -Destination $LocalRojo -Force
    } finally {
        Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Rojo $LocalRojo)) {
        throw "Downloaded rojo.exe but it won't run. Your system may be blocking it -- try unblocking the file in its Properties."
    }

    Write-Ok "Installed to $LocalRojo"
    return $LocalRojo
}

if ($ForceDownload) {
    Remove-Item -LiteralPath $LocalRojo -Force -ErrorAction SilentlyContinue
    $rojo = Install-Rojo
} else {
    $rojo = Get-WorkingRojo
    if ($rojo) {
        Write-Step "Using Rojo at $rojo"
    } else {
        $rojo = Install-Rojo
    }
}

Write-Ok (Get-RojoVersion $rojo)

# --- Build and exit, if that's all they wanted ----------------------------

if ($Build) {
    Write-Step "Building LarpingSimulator.rbxl..."
    & $rojo build -o 'LarpingSimulator.rbxl'
    if ($LASTEXITCODE -ne 0) { throw "Build failed." }

    Write-Ok "Built $(Join-Path $PSScriptRoot 'LarpingSimulator.rbxl')"
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

# --- Make sure the port is actually free ----------------------------------

<#
    Rojo crashes rather than reporting a friendly message when its port is
    taken, and the usual cause is a sync server you already have running --
    often from a second copy of this folder, which would quietly sync the wrong
    files. Sort it out before starting rather than after crashing.
#>
function Test-PortBusy {
    param([int]$Number)

    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Number)
        $listener.Start()
        $listener.Stop()
        return $false
    } catch {
        return $true
    }
}

function Get-PortOwner {
    param([int]$Number)

    # Get-NetTCPConnection is Windows-only; absence just means we can't name the
    # process, which is not fatal.
    try {
        $conn = Get-NetTCPConnection -LocalPort $Number -State Listen -ErrorAction Stop |
            Select-Object -First 1
        return Get-Process -Id $conn.OwningProcess -ErrorAction Stop
    } catch {
        return $null
    }
}

function Find-FreePort {
    param([int]$Start)

    for ($candidate = $Start; $candidate -lt ($Start + 20); $candidate++) {
        if (-not (Test-PortBusy $candidate)) { return $candidate }
    }
    throw "Couldn't find a free port near $Start."
}

if (Test-PortBusy $Port) {
    Write-Step "Port $Port is already in use."

    $owner = Get-PortOwner $Port

    if ($owner -and $owner.ProcessName -match 'rojo') {
        Write-Warn "A Rojo server is already running (PID $($owner.Id))."
        Write-Warn "If it's serving a different copy of this project, Studio will sync the wrong files."

        $stop = $Force
        if (-not $stop) {
            Write-Host ""
            Write-Host "  [S] Stop it and serve this folder instead  (recommended)" -ForegroundColor White
            Write-Host "  [K] Keep it running and just use it" -ForegroundColor Gray
            Write-Host ""
            $answer = Read-Host "  Which? [S/K]"
            $stop = ($answer -eq '' -or $answer -match '^[Ss]')
        }

        if ($stop) {
            Write-Ok "Stopping PID $($owner.Id)..."
            try {
                Stop-Process -Id $owner.Id -Force -ErrorAction Stop
                Start-Sleep -Milliseconds 700
            } catch {
                Write-Warn "Couldn't stop it: $($_.Exception.Message)"
            }

            if (Test-PortBusy $Port) {
                $Port = Find-FreePort ($Port + 1)
                Write-Warn "Port still busy. Using $Port instead."
            }
        } else {
            Write-Host ""
            Write-Host "  Leaving it running. In Studio: Plugins -> Rojo -> Connect (port $Port)." -ForegroundColor White
            Write-Host ""
            return
        }
    } else {
        $who = if ($owner) { "$($owner.ProcessName) (PID $($owner.Id))" } else { "something else" }
        Write-Warn "Held by $who, which isn't Rojo."
        $Port = Find-FreePort ($Port + 1)
        Write-Warn "Using port $Port instead."
    }
}

# --- Serve ----------------------------------------------------------------

Write-Step "Starting the sync server on port $Port..."
Write-Host ""
Write-Host "  Now, in Roblox Studio:" -ForegroundColor White
Write-Host "    1. Open any new baseplate place" -ForegroundColor Gray
Write-Host "    2. Plugins tab -> Rojo -> Connect" -ForegroundColor Gray
if ($Port -ne 34872) {
Write-Host "       (change the port to $Port -- it is not the default)" -ForegroundColor Yellow
}
Write-Host "    3. Allow the plugin to access localhost when Studio asks" -ForegroundColor Gray
Write-Host "    4. Press Play" -ForegroundColor Gray
Write-Host ""
Write-Host "  Saving a .lua file updates Studio instantly." -ForegroundColor DarkGray
Write-Host "  Ctrl+C here stops syncing." -ForegroundColor DarkGray
Write-Host ""

& $rojo serve --port $Port

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Warn "Rojo exited with code $LASTEXITCODE."
    Write-Warn "If it mentioned 'error binding', another Rojo is still running."
    Write-Warn "Close the other window, or re-run this script and choose [S]."
}
