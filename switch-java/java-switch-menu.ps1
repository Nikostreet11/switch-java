. "$PSScriptRoot\select-menu.ps1"

# --- Function: Display an interactive menu to switch the java version ---
function Show-JavaSwitchMenu {
	param(
		[string]$Title,
		[string[]]$Options,
		[int]$Selected,
		[string]$CurrentJavaVersion
	)

	Clear-Host
	Write-Host "=== Java Version Switcher ===" -ForegroundColor Cyan
	if ($CurrentJavaVersion) {
		if ($script:envJavaHome -notlike "$script:envJavaRoot*") {
			Write-Host "Active version: $CurrentJavaVersion (not in JAVA_ROOT)" -ForegroundColor Yellow
		}
		else {
			Write-Host "Active version: $CurrentJavaVersion"
		}
	}
	else {
		Write-Host "Active version: none"
	}
	Show-SelectMenu -MenuTitle $Title -Options $Options -Selected $Selected
}
