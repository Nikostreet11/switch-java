. "$PSScriptRoot\read-yes-no-question.ps1"

# --- Function: Check for admin privileges and ask for elevation ---
function Test-AdminPrivileges {
	param (
		[string]$Reason,
		[string]$ScriptPath,
        [string]$ScriptRoot
	)

	$isAdmin = ([Security.Principal.WindowsPrincipal] `
		[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole( `
		[Security.Principal.WindowsBuiltinRole]::Administrator)

	if (-not $isAdmin) {
		Clear-Host
		Write-Host ""
		Write-Host " ╔═════════════════════════════════════════════════╗"
		Write-Host " ║        (!) ADMIN PRIVILEGES REQUIRED (!)        ║"
		Write-Host " ╚═════════════════════════════════════════════════╝"
		Write-Host ""
		Write-Host "Non-admin session detected. This script requires admin privileges." -ForegroundColor Yellow
		Write-Host "It may still run in user mode, but it is advisable not doing so." -ForegroundColor Yellow
		if (-not [string]::IsNullOrWhiteSpace($Reason)) {
			Write-Host ""
			Write-Host "Reason:"
			Write-Host "$Reason"
		}
		Write-Host ""
		$elevate = Read-YesNoQuestion "Do you wish to elevate to admin-level?"
		if ($elevate) {
			$commandToRun = "Push-Location -LiteralPath '$ScriptRoot'; & '$ScriptPath'"
			$argList = @(
				"-NoExit",
				"-NoProfile",
				"-ExecutionPolicy", "Bypass",
				"-Command", $commandToRun
			)
			Write-Host "Prompting for admin privileges..."
			Start-Sleep -Seconds 1
			try {
				Start-Process PowerShell -ArgumentList $argList -Verb RunAs
			} catch {
				Write-Error "Elevation cancelled or failed: $_"
				exit
			}
			Write-Host "A new window has been opened. You can safely close this one."
			exit
		}
		return $false
	}
	return $true
}
