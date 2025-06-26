# Run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
    Write-Warning "This script must be run as Administrator."
    exit
}

# Initialization
$ErrorActionPreference = "Stop"
$uvncUrl = "https://www.uvnc.com/downloads/ultravnc/1009-ultravnc-1230.html"
$installerLink = "https://www.uvnc.com/component/jdownloads/send/5-ultravnc/442-ultravnc-1-2-30-x64-setup.html?Itemid=0"
$tempInstaller = "$env:TEMP\UltraVNC_Setup.exe"
$totalSteps = 5
$step = 1

function Show-Progress {
    param (
        [string]$Activity,
        [int]$Step
    )
    Write-Progress -Activity $Activity -Status "$Step of $totalSteps steps completed..." -PercentComplete (($Step / $totalSteps) * 100)
}

# Step 1: Download UltraVNC
Show-Progress -Activity "Downloading UltraVNC Installer..." -Step $step
Write-Host "[Step $step/$totalSteps] Downloading UltraVNC..." -ForegroundColor Cyan

Invoke-WebRequest -Uri $installerLink -OutFile $tempInstaller
$step++

# Step 2: Install UltraVNC Silently
Show-Progress -Activity "Installing UltraVNC..." -Step $step
Write-Host "[Step $step/$totalSteps] Installing UltraVNC..." -ForegroundColor Cyan

Start-Process -FilePath $tempInstaller -ArgumentList "/verysilent /norestart" -Wait
$step++

# Step 3: Add Firewall Rule for VNC (Port 5900)
Show-Progress -Activity "Adding Firewall Rule..." -Step $step
Write-Host "[Step $step/$totalSteps] Opening port 5900 on Windows Firewall..." -ForegroundColor Cyan

New-NetFirewallRule -DisplayName "Allow VNC Port 5900" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5900 `
    -Action Allow `
    -Profile Any `
    -Enabled True

$step++

# Step 4: Enable VNC Server to run as a service
Show-Progress -Activity "Setting UltraVNC Service..." -Step $step
Write-Host "[Step $step/$totalSteps] Configuring UltraVNC service to auto-start..." -ForegroundColor Cyan

$servicePath = "C:\Program Files\UltraVNC\winvnc.exe"

if (Test-Path $servicePath) {
    Start-Process -FilePath $servicePath -ArgumentList "-install" -Wait
    Set-Service -Name "uvnc_service" -StartupType Automatic
} else {
    Write-Warning "UltraVNC executable not found. Install may have failed."
}

$step++

# Step 5: Start VNC Server
Show-Progress -Activity "Starting VNC Server..." -Step $step
Write-Host "[Step $step/$totalSteps] Starting UltraVNC Server..." -ForegroundColor Cyan

Start-Service -Name "uvnc_service"

Show-Progress -Activity "VNC Setup Complete" -Step $step
Write-Host "`n✅ UltraVNC installation and setup completed successfully!" -ForegroundColor Green
