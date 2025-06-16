Import-Module BurntToast

# Optional hero image path
$heroImagePath = "C:\image\lunch_hero.png"  # Update path as needed

if (Test-Path $heroImagePath) {
    $heroImage = New-BTHeroImage -Source $heroImagePath
} else {
    $heroImage = $null
}

# Notification lines: include title as first text line for better visibility
$messageLines = @(
    "🍱 Time to Refuel!🍱",
    "⏰⏰It's 12:00! Time to Eat Lunch!⏰⏰ Would you like to log out now?"
)

# Buttons
$yesArguments = "powershell.exe -NoProfile -WindowStyle Hidden -Command `"shutdown.exe /l /f`""
$noArguments = "powershell.exe -NoProfile -WindowStyle Hidden -Command `"exit`""

$buttonYes = New-BTButton -Content "Yes" -Arguments $yesArguments -ActivationType Protocol
$buttonNo = New-BTButton -Content "No" -Arguments $noArguments -ActivationType Protocol

# Show toast notification without header, but with multiple text lines
if ($heroImage) {
    New-BurntToastNotification -Text $messageLines -HeroImage $heroImage -Button $buttonYes, $buttonNo -Sound Reminder
} else {
    New-BurntToastNotification -Text $messageLines -Button $buttonYes, $buttonNo -Sound Reminder
}
