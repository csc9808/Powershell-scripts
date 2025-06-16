# Encryption.ps1
# Prompts user for input, encrypts it, saves encrypted content and metadata

function Get-AESKey {
    param (
        [string]$Password,
        [byte[]]$Salt
    )
    $keyGenerator = New-Object System.Security.Cryptography.Rfc2898DeriveBytes ([Text.Encoding]::UTF8.GetBytes($Password), $Salt, 10000)
    return $keyGenerator.GetBytes(32)
}

function Encrypt-Message {
    param (
        [string]$PlainText,
        [string]$Password
    )

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = 'CBC'
    $aes.Padding = 'PKCS7'

    $salt = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
    $aes.GenerateIV()
    $iv = $aes.IV
    $key = Get-AESKey -Password $Password -Salt $salt
    $aes.Key = $key

    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [Text.Encoding]::UTF8.GetBytes($PlainText)
    $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

    return @{ Salt = $salt; IV = $iv; Cipher = $cipherBytes; Method = "AES-CBC" }
}

# Main script
$folderPath = "C:\Encryption"
if (-not (Test-Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

$message = Read-Host "Enter your secret message"
$password = Read-Host "Enter encryption password"

$result = Encrypt-Message -PlainText $message -Password $password
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = "$folderPath\encrypted_$timestamp.log"

$logContent = [Convert]::ToBase64String($result.Salt + $result.IV + $result.Cipher)
$methodLine = "Method=$($result.Method)"

Set-Content -Path $logPath -Value @("$methodLine", "$logContent")
Write-Host "Message encrypted and saved to: $logPath"
