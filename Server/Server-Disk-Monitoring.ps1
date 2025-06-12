<#
.SYNOPSIS
    Monitors disk space on multiple servers and alerts if free space is low.

.DESCRIPTION
    Queries each fixed drive on each server, calculates free space percentage,
    and outputs results with warnings if below threshold.

.NOTES
    Author: Luke Cho
    Date: 2025-06-10
#>

# List of servers to check (replace with your servers or IPs)
$servers = @(
    "192.168.120.124", # Back up Server (Linux) WinRM will not work
    "192.168.120.121", # MES WEB Server (Linux) WinRM will not work
    "192.168.120.122", # MES WEB Server 2 (Linux) WinRM will not work
    "192.168.120.55",  # IPScanner Server (Windows) 
    "192.168.120.147"  # Badge Server (Windows) 
    "192.168.130.10",  # WMS Server
    "192.168.120.254"  # Firewall 


)

# Threshold percentage below which a warning is triggered
$thresholdPercent = 15

foreach ($server in $servers) {
    Write-Host "Checking disk space on server: $server" -ForegroundColor Cyan

    try {
        # Get all local fixed drives on the server
        $disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $server -Filter "DriveType=3"

        foreach ($disk in $disks) {
            # Calculate free space percentage
            $freePercent = ($disk.FreeSpace / $disk.Size) * 100
            $freePercentRounded = [math]::Round($freePercent, 2)
            
            # Status based on threshold
            if ($freePercent -lt $thresholdPercent) {
                Write-Host "WARNING: Drive $($disk.DeviceID) on $server has LOW free space: $freePercentRounded%" -ForegroundColor Red
            } else {
                Write-Host "Drive $($disk.DeviceID) on $server free space: $freePercentRounded%" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error connecting to $server : $_" -ForegroundColor Red
    }
}
