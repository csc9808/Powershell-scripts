# === CONFIGURATION ===
$subnet = "192.168.121"
$outputFile = "C:\Scripts\NetworkScanResults.xlsx"
$totalIPs = 254

# === Initialize Excel ===
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.Workbooks.Add()
$sheet = $workbook.Sheets.Item(1)

# Write headers
$sheet.Cells.Item(1, 1).Value2 = "IP Address"
$sheet.Cells.Item(1, 2).Value2 = "MAC Address"

# === Sequential Ping Sweep with Progress ===

$aliveIPs = @()

Write-Host "Starting ping sweep on $subnet.0/24..."

for ($i = 1; $i -le $totalIPs; $i++) {
    $ip = "$subnet.$i"
    
    # Clear stale ARP entry, suppress error if not found
    arp -d $ip 2>$null

    # Ping device
    if (Test-Connection -Count 1 -Quiet -ComputerName $ip) {
        # Wait briefly to allow ARP cache update
        Start-Sleep -Milliseconds 150
        $aliveIPs += $ip
    }

    $percent = [math]::Round(($i / $totalIPs) * 100, 1)
    Write-Progress -Activity "Pinging devices..." -Status "$percent% complete" -PercentComplete $percent
}

Write-Host "Ping sweep completed. Found $($aliveIPs.Count) alive devices."

# === Get ARP Table ===
Write-Host "Getting ARP table..."
$arpOutput = arp -a

# === Match alive IPs to MACs and write to Excel ===
$row = 2

foreach ($ip in $aliveIPs) {
    # Find line in ARP matching IP
    $line = $arpOutput | Where-Object { $_ -match [regex]::Escape($ip) }
    if ($line) {
        # Parse MAC from the line (second column)
        if ($line -match "^\s*($ip)\s+([a-fA-F0-9\-]+)\s+dynamic") {
            $mac = $matches[2].ToLower()
        } else {
            $mac = "Unknown"
        }
    } else {
        $mac = "Unknown"
    }

    $sheet.Cells.Item($row, 1).Value2 = $ip
    $sheet.Cells.Item($row, 2).Value2 = $mac
    $row++
}

# === Save and Cleanup ===
$workbook.SaveAs($outputFile)
$workbook.Close()
$excel.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($sheet) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()

Write-Host "✅ Network scan complete. Results saved to: $outputFile"
