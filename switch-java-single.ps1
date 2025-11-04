# ==============================
# Switch Java Version (Console)
# ==============================


# === SINGLE SCRIPT VERSION ===


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


# --- Function: Prompt the user for JAVA_ROOT ---
function Read-JavaRoot {
	$script:envJavaRoot = Read-Host "Please enter your JAVA_ROOT path"
	while ([string]::IsNullOrWhiteSpace($script:envJavaRoot) -or -not (Test-Path $script:envJavaRoot)) {
		Write-Host "The specified path does not exist." -ForegroundColor Red
		if (-not (Read-YesNoQuestion "Do you wish to try again?")) {
			Exit-Script -WaitForUser:$true
		}
		$script:envJavaRoot = Read-Host "Please enter your JAVA_ROOT path"
	}
}


# --- Function: Set environment variable ---
function Set-EnvironmentVariable {
	param(
		[Parameter(Mandatory = $true)] [string]$Name,
		[Parameter(Mandatory = $true)] [string]$Value,
		[Parameter(Mandatory = $true)] [string]$Scope
	)
	[Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
}


# --- Function: Get available Java versions ---
function Get-AvailableJavaVersions {
	return @(
		Get-ChildItem -Directory -Path $script:envJavaRoot |
		Where-Object { $_.Name -match '^(?i)(jdk|jre)' } |
		Sort-Object Name |
		Select-Object -ExpandProperty Name
	)
}

# --- Function: Add JAVA_HOME\bin to PATH if missing ---
function Set-JavaHomeInPath {
	param(
		[ValidateSet("User", "Machine")]
		[string]$Scope
	)

	$path = [Environment]::GetEnvironmentVariable("Path", $Scope)
	if ([string]::IsNullOrWhiteSpace($path)) {
		$pathParts = @()
	}
	else {
		$pathParts = $path -split ';' | Where-Object { $_ }
	}
	# Filter out any preexisting paths in JAVA_ROOT
	$pathParts = $pathParts | Where-Object {
		($_ -notlike "$script:envJavaRoot\jdk*") -and
		($_ -notlike "$script:envJavaRoot\jre*") -and
		($_ -notlike "%JAVA_HOME%\bin")
	}
	# Add the new JAVA_HOME to Path
	$pathParts = @("%JAVA_HOME%\bin") + $pathParts
	$path = ($pathParts -join ';').TrimEnd(';')
	if ($Scope -eq 'Machine') {
		setx Path "$path" /M | Out-Null
	}
	else {
		setx Path "$path" | Out-Null
	}
}


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


# === START OF THE SCRIPT ===

$ReasonForAdminPrivileges = @"
Java environment versions are usually stored in system-level variables.
Without admin privileges, this script will only modify the user-level javapath,
which will be overridden if a system-level javapath is present.
If you still prefer to run this script in user mode, please verify no javapath
is already present in your system environment.
"@

# Determine privilege level
$isAdmin = Test-AdminPrivileges -Reason $ReasonForAdminPrivileges `
		-ScriptPath $PSCommandPath -ScriptRoot $PSScriptRoot
if ($isAdmin) {
	$scope = "Machine"
}
else {
	$scope = "User"
}
Write-Host "Running with $scope-level privileges..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# --- Get current JAVA_HOME ---
$script:envJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", $scope)
if ([string]::IsNullOrWhiteSpace($script:envJavaHome) -or -not (Test-Path $script:envJavaHome)) {
	$currentJavaVersion = $null
} else {
	$currentJavaVersion = Split-Path $script:envJavaHome -Leaf
}

# --- Get JAVA_ROOT ---
$script:envJavaRoot = [Environment]::GetEnvironmentVariable("JAVA_ROOT", $scope)
if ([string]::IsNullOrWhiteSpace($script:envJavaRoot) -or -not (Test-Path $script:envJavaRoot)) {
	Write-Host 'JAVA_ROOT environment variable not found or invalid.' -ForegroundColor Yellow
	Write-Host 'It should point to the directory containing all your Java versions (e.g., C:\Program Files\Java).'
	Read-JavaRoot
	Set-EnvironmentVariable "JAVA_ROOT" $script:envJavaRoot $scope
}

# --- Get available Java versions ---
$javaVersions = Get-AvailableJavaVersions
while ($javaVersions.Count -eq 0) {
	Write-Host "No Java versions found in $script:envJavaRoot." -ForegroundColor Yellow
	if (Read-YesNoQuestion "Would you like to change your JAVA_ROOT directory?") {
		Read-JavaRoot
		Set-EnvironmentVariable "JAVA_ROOT" $script:envJavaRoot $scope
		$javaVersions = Get-AvailableJavaVersions
	} else {
		Exit-Script -WaitForUser:$true
	}
}

# --- Show interactive menu ---
$menuOptions = @($javaVersions) + "Exit"
$drawMenuScript = {
    param($index)
    Show-JavaSwitchMenu "Select the new version:" $menuOptions $index $currentJavaVersion
}
$choiceIndex = Get-SelectMenuChoice -Options $menuOptions -DisplayScript $drawMenuScript

# --- Handle exiting logic ---
if ($choiceIndex -eq -1) {
	Exit-Script -WaitForUser:$true
}
$selection = $menuOptions[$choiceIndex]
if ($selection -eq "Exit") {
	Exit-Script -WaitForUser:$true
}
if ($selection -eq $currentJavaVersion) {
	Write-Host "The selected version is already active." -ForegroundColor Yellow
	Exit-Script -WaitForUser:$true
}

# --- Apply new JAVA_HOME ---
$script:envJavaHome = Join-Path $script:envJavaRoot $selection
Write-Host "Switching to $selection..." -ForegroundColor Yellow
if ($scope -eq "Machine") {
	# FIXME Non aggiorna le variabili di sistema
	setx JAVA_HOME "$script:envJavaHome" /M | Out-Null
} else {
	setx JAVA_HOME "$script:envJavaHome" | Out-Null
}
Set-EnvironmentVariable "JAVA_HOME" $script:envJavaHome $scope
Set-JavaHomeInPath -Scope $scope

# --- Inform the user and exit ---
Write-Host "Done! Java version switched to $script:envJavaHome" -ForegroundColor Green
Write-Host "Open a new terminal for changes to take effect." -ForegroundColor Cyan
Exit-Script -WaitForUser:$true
