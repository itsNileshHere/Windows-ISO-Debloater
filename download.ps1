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
