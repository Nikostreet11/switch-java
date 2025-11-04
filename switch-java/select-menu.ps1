# --- Function: Display an interactive menu ---
function Show-SelectMenu {
	param(
		[string]$MenuTitle,
		[string[]]$Options,
		[int]$Selected
	)

	Write-Host ""
	Write-Host $MenuTitle -ForegroundColor Cyan
	Write-Host ""
	for ($i = 0; $i -lt $Options.Count; $i++) {
		if ($i -eq $Selected) {
			Write-Host "[x] $($Options[$i])" -ForegroundColor Yellow
		}
		else {
			Write-Host "[ ] $($Options[$i])"
		}
	}
	Write-Host ""
}

# --- Function: Handle the user's input ---
function Get-SelectMenuChoice {
	param(
		[Parameter(Mandatory = $true)]
		[string[]]$Options,

		[Parameter(Mandatory = $true)]
		[scriptblock]$DisplayScript
	)

	$selected = 0
	$maxIndex = $Options.Count - 1
	while ($true) {
		& $DisplayScript $selected
		$key = [System.Console]::ReadKey($true)
		switch ($key.Key) {
			'UpArrow' { if ($selected -gt 0) { $selected-- } }
			'DownArrow' { if ($selected -lt $maxIndex) { $selected++ } }
			'Enter' { return $selected }
			'Escape' { return -1 }
		}
	}
}