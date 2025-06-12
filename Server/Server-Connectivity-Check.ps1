<#
.SYNOPSIS
    Checks network and PowerShell remoting connectivity to a list of server IPs.

.DESCRIPTION
    This script pings each server to confirm it's reachable and then attempts a WinRM connection 
    (used by PowerShell Remoting) to verify if it's ready for remote commands.

.NOTES
    Author: Luke Cho
    Date: 2025-06-10
#>

# -------------------- CONFIGURATION --------------------
# List of server IPs
$servers = @(
    "192.168.120.124", # Back up Server (Linux) WinRM will not work
    "192.168.120.121", # MES WEB Server (Linux) WinRM will not work
    "192.168.120.122", # MES WEB Server 2 (Linux) WinRM will not work
    "192.168.120.55",  # IPScanner Server (Windows) 
    "192.168.120.147"  # Badge Server (Windows) 
    "192.168.130.10",  # WMS Server
    "192.168.120.254"  # Firewall 


)

# Optional: Output log file
$logFile = "C:\Scripts\Logs\ConnectivityCheck-$(Get-Date -Format yyyyMMdd_HHmm).log"
if (!(Test-Path (Split-Path $logFile))) {
    New-Item -Path (Split-Path $logFile) -ItemType Directory
}

# -------------------- CHECK CONNECTIVITY --------------------
foreach ($server in $servers) {
    Write-Host "`nChecking server: $server" -ForegroundColor Cyan
    $log = "Checking server: $server`n"

    # Check ping
    if (Test-Connection -ComputerName $server -Count 3 -Quiet) {
        Write-Host "✔ Ping: Reachable" -ForegroundColor Green
        $log += "✔ Ping: Reachable`n"
    } else {
        Write-Host "❌ Ping: Not reachable" -ForegroundColor Red
        $log += "❌ Ping: Not reachable`n"
        $log += "`n"
        $log | Out-File -FilePath $logFile -Append
        continue  # Skip to next server
    }

    # Check WinRM
    try {
        Test-WSMan -ComputerName $server -ErrorAction Stop | Out-Null
        Write-Host "✔ WinRM: Available" -ForegroundColor Green
        $log += "✔ WinRM: Available`n"
    } catch {
        Write-Host "❌ WinRM: Not available - $($_.Exception.Message)" -ForegroundColor Yellow
        $log += "❌ WinRM: Not available - $($_.Exception.Message)`n"
    }

    $log += "`n"
    $log | Out-File -FilePath $logFile -Append
}

Write-Host "`n✅ Connectivity check complete. Results saved to $logFile" -ForegroundColor Cyan