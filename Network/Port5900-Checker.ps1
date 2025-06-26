param (
    [string]$ip = "192.168.124.95",   # Replace with the IP you want to check
    [int]$port = 5900                # Default VNC port
)

function Test-VNCConnection {
    param (
        [string]$Address,
        [int]$Port
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($Address, $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(3000, $false)  # 3 second timeout

        if ($wait -and $tcpClient.Connected) {
            $tcpClient.EndConnect($asyncResult)
            $tcpClient.Close()
            return $true
        } else {
            $tcpClient.Close()
            return $false
        }
    } catch {
        return $false
    }
}

if (Test-VNCConnection -Address $ip -Port $port) {
    Write-Host "✅ $ip is reachable on port $port (VNC available)" -ForegroundColor Green
} else {
    Write-Host "❌ $ip is NOT reachable on port $port (VNC not available)" -ForegroundColor Red
}
