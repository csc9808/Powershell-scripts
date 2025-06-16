# ┌──────────────────────────────────────────────┐
# │   Network Device Status Checker              |
# └──────────────────────────────────────────────┘

# ========== CONFIGURATION ==========
$deviceList = @(
    "192.x.x.x",   # Host
    "192.x.x.x",   # Target 1
    "192.x.x.x",   # Target 2
    "192.x.x.x",   # Printer
    "8.8.8.8"      # Internet Test
)

$logDir = "C:\NetworkMaintenance"
$logFile = "$logDir\DeviceStatus_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

# Create log folder if not exists
if (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}

# ========== FUNCTIONS ==========

function Write-Banner {
    Write-Host ""
    Write-Host "  ███╗   ██╗███████╗████████╗" -ForegroundColor Cyan
    Write-Host "  ████╗  ██║██╔════╝╚══██╔══╝" -ForegroundColor Cyan
    Write-Host "  ██╔██╗ ██║███████╗   ██║   " -ForegroundColor Cyan
    Write-Host "  ██║╚██╗██║╚════██║   ██║   " -ForegroundColor Cyan
    Write-Host "  ██║ ╚████║███████║   ██║   " -ForegroundColor Cyan
    Write-Host "  ╚═╝  ╚═══╝╚══════╝   ╚═╝   " -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Network Status Tool"
    Write-Host " Created By Luke Cho"
    Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
}
function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $entry
}

function Check-Device {
    param([string]$device)

    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "`n[$time] 🎯 Checking: $device" -ForegroundColor Yellow
    Log "Checking device: $device"

    if (Test-Connection -ComputerName $device -Count 3 -Quiet) {
        Write-Host "[$time] ✅ ONLINE: $device" -ForegroundColor Green
        Log "STATUS: ONLINE"
    } else {
        Write-Host "[$time] ❌ OFFLINE or UNREACHABLE: $device" -ForegroundColor Red
        Log "STATUS: OFFLINE or UNREACHABLE"
    }

    Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
    Log "--------------------------------------------------------"
}

# ========== MAIN SCRIPT ==========

Clear-Host
Write-Banner
Log "Network Device Status Log - $(Get-Date)"

foreach ($device in $deviceList) {
    Check-Device -device $device
}

Write-Host "`n✅ Device check complete!" -ForegroundColor Cyan
Write-Host "📂 Log saved to: $logFile" -ForegroundColor Magenta
