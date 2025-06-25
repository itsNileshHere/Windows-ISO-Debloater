# Helper script to generate release files

try {
    # Generate isoDebloater.ps1
    $isoDebloaterPs1 = @'
param(
    [switch]$noPrompt,
    [string]$isoPath = "",
    [string]$winEdition = "",
    [string]$outputISO = "",
    [ValidateSet("yes", "no")]$AppxRemove = "",
    [ValidateSet("yes", "no")]$CapabilitiesRemove = "",
    [ValidateSet("yes", "no")]$OnedriveRemove = "",
    [ValidateSet("yes", "no")]$EDGERemove = "",
    [ValidateSet("yes", "no")]$TPMBypass = "",
    [ValidateSet("yes", "no")]$UserFoldersEnable = "",
    [ValidateSet("yes", "no")]$ESDConvert = "",
    [ValidateSet("yes", "no")]$useOscdimg = ""
)

$scriptUrl = "https://itsnileshhere.github.io/Windows-ISO-Debloater/isoDebloaterScript.ps1"
$autounattendXmlUrl = "https://itsnileshhere.github.io/Windows-ISO-Debloater/autounattend.xml"

$scriptDirectory = "$env:SystemDrive\scriptdir"

if (-not (Test-Path -Path $scriptDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $scriptDirectory > $null 2>&1
}

$scriptPath = Join-Path -Path $scriptDirectory -ChildPath "isoDebloaterScript.ps1"
$XmlPath = Join-Path -Path $scriptDirectory -ChildPath "autounattend.xml"

Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
Invoke-WebRequest -Uri $autounattendXmlUrl -OutFile $XmlPath

$params = @()
$PSBoundParameters.GetEnumerator() | ForEach-Object {
    if ($_.Value -is [switch] -and $_.Value) { $params += "-$($_.Key)" }
    elseif ($_.Value -is [string] -and $_.Value) { $params += "-$($_.Key)", "`"$($_.Value)`"" }
}

$paramString = if ($params.Count -gt 0) { " $($params -join ' ')" } else { "" }
$argumentList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"$paramString"

if (Test-Path "$env:LocalAppData\Microsoft\WindowsApps\wt.exe") {
    Start-Process -FilePath "$env:LocalAppData\Microsoft\WindowsApps\wt.exe" -ArgumentList "powershell $argumentList" -Verb RunAs
} else {
    Start-Process -FilePath "PowerShell" -ArgumentList $argumentList -Verb RunAs
}
Start-Sleep -Milliseconds 200
Exit
'@

    # Generate isoDebloater.bat
    $isoDebloaterBat = @'
@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit /b
# $scriptUrl = "https://raw.githubusercontent.com/itsNileshHere/Windows-ISO-Debloater/main/isoDebloaterScript.ps1"
$scriptUrl = "https://itsnileshhere.github.io/Windows-ISO-Debloater/isoDebloaterScript.ps1"
$autounattendXmlUrl = "https://itsnileshhere.github.io/Windows-ISO-Debloater/autounattend.xml"

$scriptDirectory = "$env:SystemDrive\scriptdir"

if (-not (Test-Path -Path $scriptDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $scriptDirectory > $null 2>&1
}

$scriptPath = Join-Path -Path $scriptDirectory -ChildPath "isoDebloaterScript.ps1"
$XmlPath = Join-Path -Path $scriptDirectory -ChildPath "autounattend.xml"

Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
Invoke-WebRequest -Uri $autounattendXmlUrl -OutFile $XmlPath

function Test-WindowsTerminalInstalled {
    $terminalPath = "$env:LocalAppData\Microsoft\WindowsApps\wt.exe"
    return (Test-Path -Path $terminalPath)
}

if (Test-WindowsTerminalInstalled) {
    Start-Process -FilePath "$env:LocalAppData\Microsoft\WindowsApps\wt.exe" -ArgumentList "powershell -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
} else {
    Start-Process -FilePath "PowerShell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
}
Start-Sleep -Milliseconds 200
Exit
'@

    # Write files to disk
    Set-Content -Path "isoDebloater.ps1" -Value $isoDebloaterPs1
    Set-Content -Path "isoDebloater.bat" -Value $isoDebloaterBat -NoNewline
}
catch {
    Write-Error "Error generating release files: $_"
    exit 1
} 