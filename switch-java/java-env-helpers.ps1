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
