# -----------------------------
# FastPortScanner.ps1
# -----------------------------
param (
    [string]$Target = "localhost",
    [int]$StartPort = 1,
    [int]$EndPort = 1024,
    [int]$Timeout = 200,
    [int]$ThrottleLimit = 100  # how many parallel ports to scan at once
)

Write-Host "`n📡 Scanning $Target for open TCP ports from $StartPort to $EndPort..." -ForegroundColor Cyan

$ports = $StartPort..$EndPort

$ports | ForEach-Object -Parallel {
    param ($Target, $Timeout)

    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
        $iar = $tcpClient.BeginConnect($using:Target, $_, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne($using:Timeout, $false)

        if ($success -and $tcpClient.Connected) {
            $tcpClient.EndConnect($iar)
            Write-Host "✅ Port $_ is OPEN" -ForegroundColor Green
        }
        $tcpClient.Close()
    } catch {
        # Silently ignore closed ports for speed, or uncomment for detail:
        # Write-Host "❌ Port $_ is CLOSED" -ForegroundColor DarkGray
    }

} -ArgumentList $Target, $Timeout -ThrottleLimit $ThrottleLimit
