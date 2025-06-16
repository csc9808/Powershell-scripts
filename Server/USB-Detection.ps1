$logFile = "$env:USERPROFILE\Documents\USB_Detection_Log.txt"
$seenDrives = @{}
$fileWatchers = @{}
$usbSnapshots = @{}

Write-Output "Starting USB monitor..."

while ($true) {
    $currentUSBs = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    $currentDriveIDs = $currentUSBs.DeviceID

    # Detect newly connected drives
    foreach ($drive in $currentUSBs) {
        if (-not $seenDrives.ContainsKey($drive.DeviceID)) {
            $volume = Get-Volume -DriveLetter $drive.DeviceID.Replace(":", "")

            # Check for USB log file on USB root to get last connected time
            $usbLogFilePath = Join-Path $drive.DeviceID "USB_LastConnected.txt"
            $lastConnectedStr = "Never"
            if (Test-Path $usbLogFilePath) {
                try {
                    $lastConnectedStr = Get-Content $usbLogFilePath -ErrorAction Stop | Select-Object -First 1
                } catch {
                    $lastConnectedStr = "Error reading"
                }
            }

            # Write current connection time to USB log file (overwrite)
            try {
                (Get-Date).ToString() | Out-File -FilePath $usbLogFilePath -Encoding UTF8 -Force
            } catch {
                # Ignore errors writing to USB log file
            }

            # Prompt user to include hidden files or not
            $showHidden = $false
            $answer = Read-Host "Show hidden files on USB $($drive.DeviceID)? (Y/N)"
            Write-Host ""
            if ($answer.Trim().ToUpper() -eq 'Y') {
                $showHidden = $true
            }

            # Get and sort files from USB
            try {
                $files = Get-ChildItem -Path ($drive.DeviceID + "\") -Recurse -File -Force:$showHidden -ErrorAction SilentlyContinue
                $files = $files | Sort-Object Length -Descending
            } catch {
                $files = @()
            }

            # Log USB connected info
            $logEntry = @"
====================== USB Connected ======================
Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Drive Letter: $($drive.DeviceID)
Label: $($volume.FileSystemLabel)
File System: $($volume.FileSystem)
Size (GB): {0:N2}
Free Space (GB): {1:N2}
Last Connected Time on this USB: $lastConnectedStr
===========================================================
"@ -f ($drive.Size / 1GB), ($drive.FreeSpace / 1GB)

            Write-Output $logEntry
            Add-Content -Path $logFile -Value $logEntry

            # Display file table header with fixed widths
            $colWidths = @{
                'LastWrite' = 20
                'Size'      = 12
                'Type'      = 8
                'Name'      = 50
            }

            $header = "{0,-$($colWidths['LastWrite'])} {1,-$($colWidths['Size'])} {2,-$($colWidths['Type'])} {3,-$($colWidths['Name'])}" -f "Last Write Time", "Size", "Type", "File Name"
            Write-Host $header -ForegroundColor Cyan
            Add-Content -Path $logFile -Value $header

            foreach ($file in $files) {
                $sizeBytes = $file.Length

                if ($sizeBytes -lt 1MB) {
                    $sizeDisplay = "{0:N0} B" -f $sizeBytes
                } elseif ($sizeBytes -lt 100MB) {
                    $sizeDisplay = "{0:N2} MB" -f ($sizeBytes / 1MB)
                } else {
                    $sizeDisplay = "{0:N2} GB" -f ($sizeBytes / 1GB)
                }

                if ($sizeBytes -ge 1GB) {
                    $color = "Red"
                } elseif ($sizeBytes -ge 500MB) {
                    $color = "Yellow"
                } else {
                    $color = "Green"
                }

                $lastWriteStr = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                $typeStr = $file.Extension.TrimStart('.').ToLower()
                $fileNameStr = $file.Name

                # Build formatted line string with fixed widths
                $lineStr = "{0,-$($colWidths['LastWrite'])} {1,-$($colWidths['Size'])} {2,-$($colWidths['Type'])} {3,-$($colWidths['Name'])}" -f $lastWriteStr, $sizeDisplay, $typeStr, $fileNameStr

                # Output with size colored only
                Write-Host ($lineStr.Substring(0, $colWidths['LastWrite'] + 1)) -NoNewline
                Write-Host ($lineStr.Substring($colWidths['LastWrite'] + 1, $colWidths['Size'])) -ForegroundColor $color -NoNewline
                Write-Host ($lineStr.Substring($colWidths['LastWrite'] + 1 + $colWidths['Size'], $colWidths['Type'])) -NoNewline
                Write-Host ($lineStr.Substring($colWidths['LastWrite'] + 1 + $colWidths['Size'] + $colWidths['Type']))

                # Log without color
                Add-Content -Path $logFile -Value $lineStr
            }

            # Take snapshot for disconnect detection
            $snapshot = $files | Select-Object FullName, LastWriteTime, Length
            $usbSnapshots[$drive.DeviceID] = $snapshot

            $seenDrives[$drive.DeviceID] = $true
        }
    }

    # Detect disconnected drives
    foreach ($driveID in @($seenDrives.Keys)) {
        if (-not ($currentDriveIDs -contains $driveID)) {
            $logEntry = @"
==================== USB Disconnected =====================
Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Drive Letter: $driveID
===========================================================
"@
            Write-Host $logEntry -ForegroundColor Red
            Add-Content -Path $logFile -Value $logEntry

            # Compare snapshots
            if ($usbSnapshots.ContainsKey($driveID)) {
                $previousSnapshot = $usbSnapshots[$driveID]

                if ($previousSnapshot -ne $null) {
                    $currentSnapshot = @()
                    try {
                        $currentSnapshot = Get-ChildItem -Path ($driveID + "\") -Recurse -File -ErrorAction SilentlyContinue |
                            Select-Object FullName, LastWriteTime, Length
                    } catch {
                        # USB is already gone
                    }

                    $diffs = Compare-Object -ReferenceObject $previousSnapshot -DifferenceObject $currentSnapshot -Property FullName, LastWriteTime, Length

                    foreach ($diff in $diffs) {
                        $changeType = switch ($diff.SideIndicator) {
                            '=>' { 'New or Modified' }
                            '<=' { 'Deleted' }
                        }
                        $log = "$changeType File: $($diff.FullName) | Last Write: $($diff.LastWriteTime) | Size: $($diff.Length) bytes | Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
                        Add-Content -Path $logFile -Value $log
                    }
                }
                $usbSnapshots.Remove($driveID)
            }

            $seenDrives.Remove($driveID)
        }
    }

    Start-Sleep -Seconds 5
}
