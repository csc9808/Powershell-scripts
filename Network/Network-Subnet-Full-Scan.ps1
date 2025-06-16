# Prompt user for subnet base IP
$subnetBase = Read-Host "Enter the subnet IP address in this format: 192.168.127.1"

# Validate IPv4 format
if (-not ($subnetBase -match '^(\d{1,3}\.){3}\d{1,3}$')) {
    Write-Host "Invalid IP format. Please enter a correct IP like 192.168.127.1"
    exit
}

# Extract subnet prefix (first 3 octets)
$subnetPrefix = ($subnetBase -split '\.')[0..2] -join '.'

Write-Host "Pinging hosts in subnet $subnetPrefix.1 - $subnetPrefix.254 ..."

# Ping all hosts to populate ARP cache
for ($i=1; $i -le 254; $i++) {
    $ip = "$subnetPrefix.$i"
    # Ping quietly without output
    Test-Connection -ComputerName $ip -Count 1 -Quiet | Out-Null
}

# Get full ARP table
$arpOutput = & "$env:SystemRoot\System32\arp.exe" -a

# Filter ARP output lines by subnet IPs
# Group by interface line and print in the same format

$currentInterface = ""
$interfaceEntries = @{}

foreach ($line in $arpOutput) {
    # Detect Interface line
    if ($line -match "^Interface:\s+(\d{1,3}(\.\d{1,3}){3})\s---\s0x[0-9a-f]+$") {
        $currentInterface = $Matches[1]
        if (-not $interfaceEntries.ContainsKey($currentInterface)) {
            $interfaceEntries[$currentInterface] = @()
        }
    }
    elseif ($line -match '^\s*Internet Address\s+Physical Address\s+Type\s*$') {
        # Header line - ignore
        continue
    }
    elseif ($line -match '^\s*(\d{1,3}(\.\d{1,3}){3})\s+([0-9a-fA-F-]{17})\s+(\w+)\s*$') {
        $ipAddr = $Matches[1]
        $macAddr = $Matches[3]
        $type = $Matches[4]

        # Only keep entries that belong to the scanned subnet prefix
        if ($ipAddr.StartsWith($subnetPrefix)) {
            $interfaceEntries[$currentInterface] += [PSCustomObject]@{
                'Internet Address' = $ipAddr
                'Physical Address' = $macAddr
                'Type' = $type
            }
        }
    }
}

# Output the grouped entries like arp -a format
foreach ($iface in $interfaceEntries.Keys) {
    Write-Host ""
    Write-Host "Interface: $iface --- 0x3"
    Write-Host "  Internet Address      Physical Address      Type"

    foreach ($entry in $interfaceEntries[$iface]) {
        # Format output nicely with padding
        $ipPad = $entry.'Internet Address'.PadRight(20)
        $macPad = $entry.'Physical Address'.PadRight(20)
        $typeVal = $entry.'Type'

        Write-Host "  $ipPad $macPad $typeVal"
    }
}
