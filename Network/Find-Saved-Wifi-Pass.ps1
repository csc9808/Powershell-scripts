# Get all saved Wi-Fi profiles
$profiles = netsh wlan show profiles | ForEach-Object {
    if ($_ -match "All User Profile\s*:\s*(.+)") {
        $matches[1].Trim()
    }
}

# Initialize list to store Wi-Fi credentials
$wifiPasswords = @()

# Loop through each profile and extract the password
foreach ($profile in $profiles) {
    $details = netsh wlan show profile name="$profile" key=clear
    $passwordLine = $details | Where-Object { $_ -match "Key Content\s*:\s*(.+)" }

    if ($passwordLine) {
        $password = ($passwordLine -split ":\s*", 2)[1].Trim()
    } else {
        $password = "N/A"
    }

    $wifiPasswords += [PSCustomObject]@{
        WiFi_Profile = $profile
        Password     = $password
    }
}

# Display result in table
$wifiPasswords | Format-Table -AutoSize

