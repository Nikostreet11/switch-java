# --- Function: Ask a Yes/No question ---
function Read-YesNoQuestion {
	param ([string]$Question)

	while ($true) {
		$response = Read-Host "$Question (Y/N)"
		switch -Regex ($response) {
			'^(?i)y' { return $true }
			'^(?i)n' { return $false }
			default { Write-Host "Invalid response. Please enter Y or N." -ForegroundColor Yellow }
		}
	}
}
