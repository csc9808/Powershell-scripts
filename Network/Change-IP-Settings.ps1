# Set adapter name (change if needed)
$adapterName = "Wi-Fi"

# Static IP Configuration
New-NetIPAddress `
    -InterfaceAlias $adapterName `
    -IPAddress "192.168.121.115" `
    -PrefixLength 24 `
    -DefaultGateway "192.168.121.1"

# Set DNS servers
Set-DnsClientServerAddress `
    -InterfaceAlias $adapterName `
    -ServerAddresses ("10.1.224.100", "202.31.7.100")

Write-Host "Static IP and DNS settings applied successfully." -ForegroundColor Green
