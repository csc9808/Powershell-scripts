# Path to the registry key
$regPath = "HKCU:\Software\Microsoft\Office\16.0\Common\SignIn"
# Name of the value to change
$valueName = "SignInOptions"
# New value to set (DWORD 0)
$newValue = 0

# Set the registry value
Set-ItemProperty -Path $regPath -Name $valueName -Value $newValue -Type DWord

Write-Output "Registry value '$valueName' updated to $newValue at $regPath"
