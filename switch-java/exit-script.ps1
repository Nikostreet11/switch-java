# --- Function: Exit the script with options to sleep or wait for the user ---
function Exit-Script {
	param (
		[bool]$WaitForUser = $false,
		[int]$Pause = 2
	)
	if ($WaitForUser) {
		Write-Host ""
		Read-Host "Press Enter to exit..." | Out-Null
	} else {
		Write-Host "Exiting..." -ForegroundColor Yellow
		Start-Sleep -Seconds $Pause
	}
	exit
}