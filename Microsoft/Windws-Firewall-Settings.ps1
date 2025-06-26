# Get the current IPv4 addresses (excluding loopback)
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -ne '0.0.0.0'
} | Select-Object -ExpandProperty IPAddress

Write-Host "Current IPv4 address(es):" -ForegroundColor Cyan
$ipAddresses | ForEach-Object { Write-Host " - $_" }

# Check Firewall status for each profile
Write-Host "`nFirewall status:" -ForegroundColor Cyan
Get-NetFirewallProfile | ForEach-Object {
    $profile = $_.Name
    $enabled = if ($_.Enabled) { "Enabled" } else { "Disabled" }
    Write-Host " - $profile profile: $enabled"
}

# List firewall rules related to current IPs
Write-Host "`nFirewall rules related to current IP addresses:" -ForegroundColor Cyan

foreach ($ip in $ipAddresses) {
    # Filter rules that contain the IP in Local or Remote addresses
    $rules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
        $rule = $_
        $props = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule
        $props.LocalAddress -contains $ip -or $props.RemoteAddress -contains $ip
    }
    if ($rules) {
        Write-Host "`nRules for IP $ip :`n" -ForegroundColor Yellow
        $rules | Select-Object DisplayName, Enabled, Direction, Action | Format-Table -AutoSize
    }
    else {
        Write-Host "`nNo specific firewall rules found for IP $ip." -ForegroundColor Yellow
    }
}
# This Tool shows rules applied on Windows setting, not on Powershell.
