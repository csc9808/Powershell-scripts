<#
.SYNOPSIS
    Retrieves the last 5 print job event logs for each specified printer server.

.DESCRIPTION
    Queries the PrintService Operational event log on remote print servers to get recent print job history
    and logs the information.

.NOTES
    Author: Luke Cho
    Date: 2025-06-10
#>

# -------------------- CONFIGURATION --------------------
$printerServers = @(
    "192.168.121.34",
    "192.168.121.30",
    "192.168.121.31"
)

$logFolder = "C:\Scripts\Logs"
if (!(Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

$logFile = "$logFolder\PrinterJobHistory-$(Get-Date -Format yyyyMMdd_HHmm).log"

# -------------------- FUNCTION TO GET PRINT JOB EVENTS --------------------
function Get-PrintJobHistory {
    param(
        [string]$serverIP
    )

    Write-Host "`nRetrieving last 5 print job events from $serverIP ..." -ForegroundColor Cyan

    try {
        # Check if PrintService Operational log exists and is enabled
        $logExists = Get-WinEvent -ListLog "Microsoft-Windows-PrintService/Operational" -ComputerName $serverIP -ErrorAction Stop
        if (-not $logExists.IsEnabled) {
            Write-Warning "PrintService Operational log is not enabled on $serverIP."
            return "PrintService Operational log not enabled on $serverIP.`n"
        }

        # Get the last 5 print job events (EventID 307 = Print job completed)
        $events = Get-WinEvent -ComputerName $serverIP -LogName "Microsoft-Windows-PrintService/Operational" `
            -FilterHashtable @{Id=307} -MaxEvents 5 | Sort-Object TimeCreated -Descending

        if (-not $events) {
            Write-Host "No recent print job events found on $serverIP." -ForegroundColor Yellow
            return "No recent print job events found on $serverIP.`n"
        }

        $output = @()
        foreach ($event in $events) {
            # Parse event message for details like Document Name, Printer Name, User, Pages printed
            $msg = $event.Message
            # Example Message lines to parse:
            # Document Name: TestDoc
            # User: DOMAIN\UserName
            # Printer Name: HP LaserJet
            # Pages Printed: 3

            $docName = ($msg | Select-String "Document Name: (.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }) -join ''
            $user = ($msg | Select-String "User: (.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }) -join ''
            $printerName = ($msg | Select-String "Printer Name: (.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }) -join ''
            $pages = ($msg | Select-String "Pages Printed: (.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }) -join ''

            $line = "[$($event.TimeCreated)] Printer: $printerName, Document: $docName, User: $user, Pages: $pages"
            $output += $line
            Write-Host $line
        }

        return $output
    }
    catch {
        $errorMsg = "Error retrieving print job history from $serverIP : $_"
        Write-Host $errorMsg -ForegroundColor Red
        return $errorMsg
    }
}

# -------------------- MAIN SCRIPT --------------------
$finalLog = @()
foreach ($server in $printerServers) {
    $finalLog += "=== Print Job History for $server ==="
    $history = Get-PrintJobHistory -serverIP $server
    $finalLog += $history
    $finalLog += "`n"
}

# Write to log file
$finalLog | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "`n✅ Done! Log saved to $logFile" -ForegroundColor Green
