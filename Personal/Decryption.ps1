# Decryption.ps1
# Allows user to pick a log file and decrypts its content

function Get-AESKey {
    param (
        [string]$Password,
        [byte[]]$Salt
    )
    $keyGenerator = New-Object System.Security.Cryptography.Rfc2898DeriveBytes ([Text.Encoding]::UTF8.GetBytes($Password), $Salt, 10000)
    return $keyGenerator.GetBytes(32)
}

function Decrypt-Message {
    param (
        [string]$Encoded,
        [string]$Password,
        [string]$Method
    )

    $fullBytes = [Convert]::FromBase64String($Encoded)
    $salt = $fullBytes[0..15]
    $iv = $fullBytes[16..31]
    $cipherText = $fullBytes[32..($fullBytes.Length - 1)]

    if ($Method -ne "AES-CBC") {
        throw "Unsupported encryption method: $Method"
    }

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = 'CBC'
    $aes.Padding = 'PKCS7'
    $key = Get-AESKey -Password $Password -Salt $salt
    $aes.Key = $key
    $aes.IV = $iv

    $decryptor = $aes.CreateDecryptor()
    $plainBytes = $decryptor.TransformFinalBlock($cipherText, 0, $cipherText.Length)
    return [Text.Encoding]::UTF8.GetString($plainBytes)
}

# Main decryption script
$folderPath = "C:\Encryption"
if (-not (Test-Path $folderPath)) {
    Write-Host "Encryption folder not found at $folderPath"
    exit
}

$files = Get-ChildItem -Path $folderPath -Filter "encrypted_*.log"
if ($files.Count -eq 0) {
    Write-Host "No encrypted files found."
    exit
}

Write-Host "Select a file to decrypt:"
for ($i = 0; $i -lt $files.Count; $i++) {
    Write-Host "$i. $($files[$i].Name)"
}
$choice = Read-Host "Enter the number of the file"
if ($choice -notmatch '^\d+$' -or [int]$choice -ge $files.Count) {
    Write-Host "Invalid selection."
    exit
}

$selectedFile = $files[$choice]
$content = Get-Content -Path $selectedFile.FullName
$method = ($content[0] -replace "Method=", "").Trim()
$encoded = $content[1]
$password = Read-Host "Enter the password used for encryption"

try {
    $decrypted = Decrypt-Message -Encoded $encoded -Password $password -Method $method
    Write-Host "`nDecrypted Message:`n$decrypted"
} catch {
    Write-Host "Decryption failed: $_"
}
