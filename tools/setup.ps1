<#
.SYNOPSIS
    MASM64 Framework Setup Script
    
.DESCRIPTION
    Detects development environment and offers to install missing components:
    - Visual Studio Build Tools (required)
    - Windows SDK (required)
    - Windows Driver Kit (optional, for driver development)
    
.EXAMPLE
    .\setup.ps1
    .\setup.ps1 -SkipWDK
    .\setup.ps1 -Force
#>

param(
    [switch]$SkipWDK,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Status { param($msg) Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "[-] $msg" -ForegroundColor Red }

# Banner
Write-Host ""
Write-Host "  MASM64 Framework Setup" -ForegroundColor White
Write-Host "  ======================" -ForegroundColor Gray
Write-Host ""

#-----------------------------------------------------------------------------
# Detect Visual Studio / Build Tools
#-----------------------------------------------------------------------------
function Find-VSInstallation {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -property installationPath 2>$null
        if ($vsPath) {
            return $vsPath
        }
    }
    
    # Fallback to common paths
    $paths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional", 
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

function Find-ML64 {
    param($vsPath)
    
    if (-not $vsPath) { return $null }
    
    $ml64Paths = @(
        "$vsPath\VC\Tools\MSVC\*\bin\Hostx64\x64\ml64.exe"
    )
    
    foreach ($pattern in $ml64Paths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | 
                 Sort-Object -Descending | 
                 Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }
    
    return $null
}

#-----------------------------------------------------------------------------
# Detect Windows SDK
#-----------------------------------------------------------------------------
function Find-WindowsSDK {
    $sdkRoot = "${env:ProgramFiles(x86)}\Windows Kits\10"
    
    if (-not (Test-Path $sdkRoot)) {
        return $null
    }
    
    $versions = Get-ChildItem "$sdkRoot\Lib" -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
                Sort-Object Name -Descending
    
    if ($versions) {
        return @{
            Path = $sdkRoot
            Version = $versions[0].Name
        }
    }
    
    return $null
}

#-----------------------------------------------------------------------------
# Detect Windows Driver Kit
#-----------------------------------------------------------------------------
function Find-WDK {
    $wdkRoot = "${env:ProgramFiles(x86)}\Windows Kits\10"
    
    if (-not (Test-Path $wdkRoot)) {
        return $null
    }
    
    # WDK adds km (kernel mode) libraries
    $versions = Get-ChildItem "$wdkRoot\Lib" -Directory -ErrorAction SilentlyContinue |
                Where-Object { 
                    $_.Name -match '^\d+\.\d+\.\d+\.\d+$' -and
                    (Test-Path "$($_.FullName)\km\x64\ntoskrnl.lib")
                } |
                Sort-Object Name -Descending
    
    if ($versions) {
        return @{
            Path = $wdkRoot
            Version = $versions[0].Name
        }
    }
    
    return $null
}

#-----------------------------------------------------------------------------
# Installation Functions
#-----------------------------------------------------------------------------
function Install-VSBuildTools {
    Write-Status "Downloading Visual Studio Build Tools installer..."
    
    $installerUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
    $installerPath = "$env:TEMP\vs_buildtools.exe"
    
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    }
    catch {
        Write-Error "Failed to download installer: $_"
        return $false
    }
    
    Write-Status "Installing Visual Studio Build Tools with MASM support..."
    Write-Warning "This will open an installer window. Please wait for completion."
    
    $args = @(
        "--quiet",
        "--wait",
        "--norestart",
        "--add", "Microsoft.VisualStudio.Workload.VCTools",
        "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "--add", "Microsoft.VisualStudio.Component.Windows11SDK.22621"
    )
    
    $process = Start-Process -FilePath $installerPath -ArgumentList $args -Wait -PassThru
    
    Remove-Item $installerPath -ErrorAction SilentlyContinue
    
    return $process.ExitCode -eq 0
}

function Install-WDK {
    Write-Status "Windows Driver Kit Installation"
    Write-Host ""
    Write-Host "  WDK requires a matching Windows SDK version." -ForegroundColor Gray
    Write-Host "  The installer will download ~2GB of files." -ForegroundColor Gray
    Write-Host ""
    
    $wdkUrl = "https://go.microsoft.com/fwlink/?linkid=2249371"  # WDK for Windows 11, version 22H2
    $installerPath = "$env:TEMP\wdksetup.exe"
    
    Write-Status "Downloading WDK installer..."
    
    try {
        Invoke-WebRequest -Uri $wdkUrl -OutFile $installerPath -UseBasicParsing
    }
    catch {
        Write-Error "Failed to download WDK: $_"
        Write-Host ""
        Write-Host "  Manual download: https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk" -ForegroundColor Yellow
        return $false
    }
    
    Write-Status "Running WDK installer..."
    Write-Warning "This will open the WDK installer. Follow the prompts."
    
    $process = Start-Process -FilePath $installerPath -Wait -PassThru
    
    Remove-Item $installerPath -ErrorAction SilentlyContinue
    
    # Verify installation
    $wdk = Find-WDK
    return $null -ne $wdk
}

#-----------------------------------------------------------------------------
# Main Setup Logic
#-----------------------------------------------------------------------------

$results = @{
    VisualStudio = $null
    ML64 = $null
    WindowsSDK = $null
    WDK = $null
}

# Check Visual Studio
Write-Status "Checking for Visual Studio / Build Tools..."
$vsPath = Find-VSInstallation

if ($vsPath) {
    Write-Success "Found: $vsPath"
    $results.VisualStudio = $vsPath
    
    $ml64 = Find-ML64 -vsPath $vsPath
    if ($ml64) {
        Write-Success "Found ML64: $ml64"
        $results.ML64 = $ml64
    }
    else {
        Write-Warning "ML64 not found - MASM component may not be installed"
    }
}
else {
    Write-Warning "Visual Studio / Build Tools not found"
}

# Check Windows SDK
Write-Status "Checking for Windows SDK..."
$sdk = Find-WindowsSDK

if ($sdk) {
    Write-Success "Found Windows SDK $($sdk.Version)"
    $results.WindowsSDK = $sdk
}
else {
    Write-Warning "Windows SDK not found"
}

# Check WDK
Write-Status "Checking for Windows Driver Kit..."
$wdk = Find-WDK

if ($wdk) {
    Write-Success "Found WDK $($wdk.Version)"
    $results.WDK = $wdk
}
else {
    Write-Warning "WDK not found (required only for driver development)"
}

Write-Host ""

#-----------------------------------------------------------------------------
# Offer to install missing components
#-----------------------------------------------------------------------------

$needsVS = $null -eq $results.VisualStudio -or $null -eq $results.ML64
$needsWDK = $null -eq $results.WDK -and -not $SkipWDK

if ($needsVS) {
    Write-Host "Visual Studio Build Tools with MASM is required." -ForegroundColor Yellow
    
    if (-not $Quiet) {
        $response = Read-Host "Install Visual Studio Build Tools? [Y/n]"
        if ($response -eq "" -or $response -match "^[Yy]") {
            if (Install-VSBuildTools) {
                Write-Success "Visual Studio Build Tools installed successfully"
                Write-Warning "Please restart your terminal to use the new tools"
            }
            else {
                Write-Error "Installation failed. Please install manually."
            }
        }
    }
}

if ($needsWDK -and -not $needsVS) {
    Write-Host ""
    Write-Host "Windows Driver Kit (WDK) is optional but required for:" -ForegroundColor Yellow
    Write-Host "  - Building kernel drivers (rawmouse example)" -ForegroundColor Gray
    Write-Host "  - Driver template projects" -ForegroundColor Gray
    Write-Host ""
    
    if (-not $Quiet) {
        $response = Read-Host "Install Windows Driver Kit? [y/N]"
        if ($response -match "^[Yy]") {
            if (Install-WDK) {
                Write-Success "WDK installed successfully"
            }
            else {
                Write-Error "WDK installation may have failed. Please verify."
            }
        }
        else {
            Write-Host "Skipping WDK. Driver projects will not build." -ForegroundColor Gray
        }
    }
}

#-----------------------------------------------------------------------------
# Summary
#-----------------------------------------------------------------------------

Write-Host ""
Write-Host "  Setup Summary" -ForegroundColor White
Write-Host "  =============" -ForegroundColor Gray

$canBuildUsermode = $results.ML64 -and $results.WindowsSDK
$canBuildDrivers = $canBuildUsermode -and $results.WDK

Write-Host ""
Write-Host "  Usermode builds (console, gui, dll, shellcode): " -NoNewline
if ($canBuildUsermode) {
    Write-Host "READY" -ForegroundColor Green
}
else {
    Write-Host "NOT READY" -ForegroundColor Red
}

Write-Host "  Kernel driver builds:                           " -NoNewline
if ($canBuildDrivers) {
    Write-Host "READY" -ForegroundColor Green
}
else {
    Write-Host "NOT AVAILABLE" -ForegroundColor Yellow
}

Write-Host ""

# Create environment config file
$configPath = Join-Path $PSScriptRoot "..\config\environment.json"
$configDir = Split-Path $configPath -Parent

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$config = @{
    LastChecked = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    VisualStudioPath = $results.VisualStudio
    ML64Path = $results.ML64
    WindowsSDKPath = if ($results.WindowsSDK) { $results.WindowsSDK.Path } else { $null }
    WindowsSDKVersion = if ($results.WindowsSDK) { $results.WindowsSDK.Version } else { $null }
    WDKPath = if ($results.WDK) { $results.WDK.Path } else { $null }
    WDKVersion = if ($results.WDK) { $results.WDK.Version } else { $null }
    CanBuildUsermode = $canBuildUsermode
    CanBuildDrivers = $canBuildDrivers
}

$config | ConvertTo-Json | Out-File $configPath -Encoding UTF8

Write-Host "  Configuration saved to: config\environment.json" -ForegroundColor Gray
Write-Host ""

if ($canBuildUsermode) {
    Write-Host "  Ready to build! Try:" -ForegroundColor Green
    Write-Host "    cd examples\hashcheck" -ForegroundColor Gray
    Write-Host "    .\build.bat" -ForegroundColor Gray
}

Write-Host ""

