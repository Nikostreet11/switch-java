# ==============================
# Switch Java Version (Console)
# ==============================

. "$PSScriptRoot\switch-java\exit-script.ps1"
. "$PSScriptRoot\switch-java\read-yes-no-question.ps1"
. "$PSScriptRoot\switch-java\test-admin-privileges.ps1"
. "$PSScriptRoot\switch-java\java-env-helpers.ps1"
. "$PSScriptRoot\switch-java\java-switch-menu.ps1"
. "$PSScriptRoot\switch-java\select-menu.ps1"

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
