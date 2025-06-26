# Define adapter name
$adapterName = "Wi-Fi"

# Enable DHCP for IP address
Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled

# Reset DNS servers to obtain automatically
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses

Write-Host "Wi-Fi adapter has been set to use DHCP for IP and DNS." -ForegroundColor Green
