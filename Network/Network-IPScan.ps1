# Prompt user for subnet input with format guidance
do {
    $subnetInput = Read-Host "Enter the subnet to scan (Example format: 192.168.127.1)"
    $validFormat = $subnetInput -match '^(\d{1,3}\.){3}1$'
    if (-not $validFormat) {
        Write-Host "Invalid format. Please enter an IP ending with .1, e.g., 192.168.127.1" -ForegroundColor Yellow
    }
} while (-not $validFormat)

# Extract subnet base (remove trailing .1)
$subnetBase = $subnetInput.Substring(0, $subnetInput.LastIndexOf('.'))

$totalIPs = 254
$liveDevices = @()

Write-Host "Scanning subnet $subnetBase.1 to $subnetBase.254 ..."
Write-Host ""

for ($i = 1; $i -le $totalIPs; $i++) {
    $ip = "$subnetBase.$i"
    Write-Progress -Activity "Scanning $subnetBase.0/24" -Status "Checking $ip" -PercentComplete (($i / $totalIPs) * 100)

    # Run Test-Connection without TimeoutSeconds param
    $pingResult = Test-Connection -ComputerName $ip -Count 1 -Quiet

    $timestamp = Get-Date -Format "HH:mm:ss"

    if ($pingResult) {
        Write-Host "[$timestamp] [$ip] is ONLINE  ✔" -ForegroundColor Green
        $liveDevices += $ip
    } else {
        Write-Host "[$timestamp] [$ip] is offline ✘" -ForegroundColor DarkGray
    }
}

Write-Progress -Activity "Scanning complete" -Completed

Write-Host ""
Write-Host "Scan complete! Live devices found:" -ForegroundColor Cyan

if ($liveDevices.Count -eq 0) {
    Write-Host "No devices responded to ping." -ForegroundColor Red
} else {
    $liveDevices | ForEach-Object { Write-Host $_ }
}
