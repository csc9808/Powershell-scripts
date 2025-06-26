# -----------------------------
# Toggle-WindowsUpdate.ps1
# -----------------------------
# Automatically run as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script with Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define service name
$serviceName = "wuauserv"

# Get the current status of the Windows Update service
try {
    $service = Get-Service -Name $serviceName -ErrorAction Stop
} catch {
    Write-Host "❌ Windows Update service not found!" -ForegroundColor Red
    exit
}

$currentStatus = $service.Status
Write-Host "`n🔍 Windows Update service is currently: $currentStatus" -ForegroundColor Cyan

# Ask user if they want to toggle the service
if ($currentStatus -eq 'Running') {
    $response = Read-Host "`nDo you want to TURN OFF automatic Windows Updates? (y/n)"
    if ($response -match '^[yY]') {
        Stop-Service -Name $serviceName -Force
        Set-Service -Name $serviceName -StartupType Disabled
        Write-Host "✅ Windows Update has been turned OFF." -ForegroundColor Yellow
    } else {
        Write-Host "ℹ️ No changes made." -ForegroundColor Green
    }
} elseif ($currentStatus -eq 'Stopped') {
    $response = Read-Host "`nDo you want to TURN ON automatic Windows Updates? (y/n)"
    if ($response -match '^[yY]') {
        Set-Service -Name $serviceName -StartupType Manual
        Start-Service -Name $serviceName
        Write-Host "✅ Windows Update has been turned ON." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No changes made." -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ Unexpected service state: $currentStatus" -ForegroundColor Red
}
