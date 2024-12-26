# Windows ISO Debloater
# Author: itsNileshHere
# Date: 2023-11-21
# Description: A simple PSscript to modify windows iso file. For more info check README.md

# Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process -FilePath PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    Exit
}
$asciiArt = @"
 _       ___           __                      _________ ____     ____       __    __            __           
| |     / (_)___  ____/ /___ _      _______   /  _/ ___// __ \   / __ \___  / /_  / /___  ____ _/ /____  _____
| | /| / / / __ \/ __  / __ \ | /| / / ___/   / / \__ \/ / / /  / / / / _ \/ __ \/ / __ \/ __ `/ __/ _ \/ ___/
| |/ |/ / / / / / /_/ / /_/ / |/ |/ (__  )  _/ / ___/ / /_/ /  / /_/ /  __/ /_/ / / /_/ / /_/ / /_/  __/ /    
|__/|__/_/_/ /_/\__,_/\____/|__/|__/____/  /___//____/\____/  /_____/\___/_.___/_/\____/\__,_/\__/\___/_/     
                                                                                        -By itsNileshHere                                                                                                  
"@

Write-Host $asciiArt -ForegroundColor Cyan
Start-Sleep -Milliseconds 1200
Write-Host "Starting Windows ISO Debloater Script..." -ForegroundColor Green
Start-Sleep -Milliseconds 1500
Write-Host "`n*Importent Notes: " -ForegroundColor Yellow
Write-Host "    1. There will be some prompts for the user." -ForegroundColor White
Write-Host "    2. Ensure that you have administrative privileges to run this script." -ForegroundColor White
Write-Host "    3. Review the script before execution to understand its actions." -ForegroundColor White
Write-Host "    4. If you want to whitelist any package, just open the script and comment out the Packagename." -ForegroundColor White
Start-Sleep -Milliseconds 1500

$scriptDirectory = "$PSScriptRoot"
$logFilePath = Join-Path -Path $scriptDirectory -ChildPath 'script_log.txt'
function Write-LogMessage {
    param (
        [string]$message
    )
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    Add-Content -Path "$logFilePath" -Value $logEntry
}

function CleanupTemp {
    Remove-Item -Path $destinationPath -Recurse -Force > $null 2>&1
    Remove-Item -Path $mountDirectory -Recurse -Force > $null 2>&1
    Remove-Item -Path "$env:SystemDrive\WIDTemp" -Recurse -Force > $null 2>&1
}

Write-LogMessage "Script started"
Write-Host

Add-Type -AssemblyName System.Windows.Forms
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
$openFileDialog.Filter = "ISO files (*.iso)|*.iso"
$openFileDialog.Title = "Select Windows ISO File"

if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $isoFilePath = $openFileDialog.FileName
    Write-Host "Selected ISO file: $isoFilePath"
    Write-LogMessage "ISO Path: $isoFilePath"
    $mountResult = Mount-DiskImage -ImagePath $isoFilePath -PassThru
    if ($mountResult) {
        $sourceDriveLetter = ($mountResult | Get-Volume).DriveLetter
        if ($sourceDriveLetter) {
            Write-LogMessage "Mounted ISO file to drive: $sourceDriveLetter`:"
        }
    }
    else {
        Write-Host "Failed to mount the ISO file."
        Write-LogMessage "Failed to mount the ISO file."
        Exit
    }
}
else {
    Write-Host "No file selected. Exiting Script"
    Write-LogMessage "No file selected"
    Exit
}

$sourceDrive = "${sourceDriveLetter}:\"
$destinationPath = "$env:SystemDrive\WIDTemp\winlite"
$mountDirectory = "$env:SystemDrive\WIDTemp\mountdir"
$OscdimgPath = "$env:SystemDrive\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
$Oscdimg = Join-Path -Path $OscdimgPath -ChildPath 'oscdimg.exe'
$autounattendXmlPath = Join-Path -Path $scriptDirectory -ChildPath "Autounattend.xml"

# Comment out the package don't wanna remove
$packagesToRemove = @(
    'Microsoft.Microsoft3DViewer*', # 3DViewer
    'Microsoft.WindowsAlarms*', # Alarms
    'Microsoft.BingNews*', # Bing News
    'Microsoft.BingWeather*', # Bing Weather
    'Clipchamp.Clipchamp*', # Clipchamp
    'Microsoft.549981C3F5F10*', # Cortana
    'Microsoft.Windows.DevHome*', # DevHome
    'MicrosoftCorporationII.MicrosoftFamily*', # Family
    'Microsoft.WindowsFeedbackHub*', # FeedbackHub
    'Microsoft.GetHelp*', # GetHelp
    'Microsoft.Getstarted*', # GetStarted
    'Microsoft.WindowsCommunicationsapps*', # Mail
    'Microsoft.WindowsMaps*', # Maps
    'Microsoft.MixedReality.Portal*', # MixedReality
    'Microsoft.ZuneMusic*', # Music
    'Microsoft.MicrosoftOfficeHub*', # OfficeHub
    'Microsoft.Office.OneNote*', # OneNote
    'Microsoft.OutlookForWindows*', # Outlook
    'Microsoft.MSPaint*', # Paint3D(Windows10)
    'Microsoft.People*', # People
    'Microsoft.YourPhone*', # Phone
    'Microsoft.PowerAutomateDesktop*', # PowerAutomate
    'MicrosoftCorporationII.QuickAssist*', # QuickAssist
    'Microsoft.SkypeApp*', # Skype
    'Microsoft.MicrosoftSolitaireCollection*', # SolitaireCollection
    # 'Microsoft.WindowsSoundRecorder*', # SoundRecorder
    'MicrosoftTeams*', # Teams_old
    'MSTeams*', # Teams
    'Microsoft.Todos*', # Todos
    'Microsoft.ZuneVideo*', # Video
    'Microsoft.Wallet*', # Wallet
    'Microsoft.GamingApp*', # Xbox
    'Microsoft.XboxApp*', # Xbox(Win10)
    'Microsoft.XboxGameOverlay*', # XboxGameOverlay
    'Microsoft.XboxGamingOverlay*', # XboxGamingOverlay
    'Microsoft.XboxSpeechToTextOverlay*', # XboxSpeechToTextOverlay
    'Microsoft.Xbox.TCUI*', # XboxTCUI
    # 'Microsoft.SecHealthUI*',
    'MicrosoftWindows.CrossDevice*'
)

$featuresToRemove = @(
    'Browser.InternetExplorer~~~~0.0.11.0',
    'Internet-Explorer-Optional-amd64',
    'App.StepsRecorder~~~~0.0.1.0',
    'Language.Handwriting~~~en-US~0.0.1.0',
    'Language.OCR~~~en-US~0.0.1.0',
    'Language.Speech~~~en-US~0.0.1.0',
    'Language.TextToSpeech~~~en-US~0.0.1.0',
    'Microsoft.Windows.WordPad~~~~0.0.1.0',
    'MathRecognizer~~~~0.0.1.0',
    'Media.WindowsMediaPlayer~~~~0.0.12.0'
)

# Copy Files
Write-Host "`nCopying files from $sourceDrive to $destinationPath"
Write-LogMessage "Copying files from $sourceDrive to $destinationPath"
$null = New-Item -ItemType Directory -Path $destinationPath
$null = xcopy.exe $sourceDrive $destinationPath /E /I /H /R /Y /J
Dismount-DiskImage -ImagePath $isoFilePath > $null 2>&1

# Check files availability
$installWimPath = Join-Path $destinationPath "sources\install.wim"
$installEsdPath = Join-Path $destinationPath "sources\install.esd"
New-Item -ItemType Directory -Path $mountDirectory > $null 2>&1

if (-not (Test-Path $installWimPath)) {
    Write-Host "`ninstall.wim not found. Searching for install.esd..."
    Start-Sleep -Milliseconds 500
    if (Test-Path $installEsdPath) {
        Write-Host "`ninstall.esd found at $installEsdPath."
        Write-LogMessage "install.esd found. Converting..."
        Start-Sleep -Milliseconds 500
        try {
            dism /Get-WimInfo /wimfile:$installEsdPath
            Write-Host
            $EsdIndex = Read-Host -Prompt "Enter the index to convert and mount"
            Write-LogMessage "Converting and Mounting image: $EsdIndex"
            dism /Export-Image /SourceImageFile:$installEsdPath /SourceIndex:$EsdIndex /DestinationImageFile:$installWimPath /Compress:max /CheckIntegrity
            Remove-Item $installEsdPath -Force
            dism /mount-image /imagefile:$installWimPath /index:1 /mountdir:$mountDirectory
        }
        catch {
            Write-LogMessage "Failed to mount image: $_"
            Exit
        }
    }
    else {
        Write-Host "Neither install.wim nor install.esd found. Make sure to mount the correct ISO"
        Exit
    }
}
else {
    Write-LogMessage "Getting image info"
    Start-Sleep -Milliseconds 500
    try {
        dism /Get-WimInfo /wimfile:$installWimPath
        Write-Host
        $WimIndex = Read-Host -Prompt "Enter the index to mount"
        Write-LogMessage "Mounting image: $WimIndex"
        dism /mount-image /imagefile:$installWimPath /index:$WimIndex /mountdir:$mountDirectory
    }
    catch {
        Write-LogMessage "Failed to mount image: $_"
        Exit
    }
}

if (-not (Test-Path "$mountDirectory\Windows")) {
    Write-Host "Error while mounting image. Try again."
    Write-LogMessage "Mounted image not found. Exiting"
    CleanupTemp
    Exit 
}

# Remove Packages
Write-LogMessage "Removing provisioned packages"
Write-Host "`nRemoving Packages..."
Start-Sleep -Milliseconds 1500
foreach ($packageName in $packagesToRemove) {
    try {
        Write-Host $packageName.TrimEnd('*')
        $provisionedPackages = Get-ProvisionedAppxPackage -Path $mountDirectory | Where-Object { $_.PackageName -like $packageName }
        foreach ($package in $provisionedPackages) {
            $packageNameToRemove = $package.PackageName
            try {
                dism /image:$mountDirectory /Remove-ProvisionedAppxPackage /PackageName:$packageNameToRemove > $null
            }
            catch {
                Write-LogMessage "Removing $packageNameToRemove failed: $_"
            }
        }
    }
    catch {
        Write-LogMessage "Failed to remove provisioned package '$packageName': $_"
    }
}

# Remove useless Features
Write-LogMessage "Removing useless features"
Write-Host "`nRemoving Useless Features..."
Start-Sleep -Milliseconds 1500
foreach ($feature in $featuresToRemove) {
    try {
        Write-Host "$feature"
        dism /image:$mountDirectory /Remove-Capability /CapabilityName:$feature > $null
    }
    catch {
        Write-LogMessage "Removing $feature failed: $_"
    }
}

# Setting Persmission
function Enable-Privilege {
    param([ValidateSet("SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege", "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege", "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege", "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege", "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege", "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege", "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege", "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege", "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege", "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege", "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]$Privilege, $ProcessId = $pid, [Switch]$Disable)$definition = @'
using System;using System.Runtime.InteropServices;public class AdjPriv{[DllImport("advapi32.dll",ExactSpelling=true,SetLastError=true)]internal static extern bool AdjustTokenPrivileges(IntPtr htok,bool disall,ref TokPriv1Luid newst,int len,IntPtr prev,IntPtr relen);[DllImport("advapi32.dll",ExactSpelling=true,SetLastError=true)]internal static extern bool OpenProcessToken(IntPtr h,int acc,ref IntPtr phtok);[DllImport("advapi32.dll",SetLastError=true)]internal static extern bool LookupPrivilegeValue(string host,string name,ref long pluid);[StructLayout(LayoutKind.Sequential,Pack=1)]internal struct TokPriv1Luid{public int Count;public long Luid;public int Attr;}internal const int SE_PRIVILEGE_ENABLED=0x00000002;internal const int SE_PRIVILEGE_DISABLED=0x00000000;internal const int TOKEN_QUERY=0x00000008;internal const int TOKEN_ADJUST_PRIVILEGES=0x00000020;public static bool EnablePrivilege(long processHandle,string privilege,bool disable){bool retVal;TokPriv1Luid tp;IntPtr hproc=new IntPtr(processHandle);IntPtr htok=IntPtr.Zero;retVal=OpenProcessToken(hproc,TOKEN_ADJUST_PRIVILEGES|TOKEN_QUERY,ref htok);tp.Count=1;tp.Luid=0;tp.Attr=disable?SE_PRIVILEGE_DISABLED:SE_PRIVILEGE_ENABLED;retVal=LookupPrivilegeValue(null,privilege,ref tp.Luid);retVal=AdjustTokenPrivileges(htok,false,ref tp,0,IntPtr.Zero,IntPtr.Zero);return retVal;}}
'@
    $processHandle = (Get-Process -id $ProcessId).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
}

Enable-Privilege SeTakeOwnershipPrivilege

# Remove OneDrive
Start-Sleep -Milliseconds 1500
Write-Host "`nRemoving OneDrive..."
Start-Sleep -Milliseconds 1500
Write-LogMessage "Defining OneDrive Setup file paths"
$oneDriveSetupPath1 = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\OneDriveSetup.exe'
$oneDriveSetupPath2 = Join-Path -Path $mountDirectory -ChildPath 'Windows\SysWOW64\OneDriveSetup.exe'
$oneDriveSetupPath3Pattern = Join-Path -Path $mountDirectory -ChildPath 'Windows\WinSxS\*microsoft-windows-onedrive-setup*\OneDriveSetup.exe'
$oneDriveSetupPath3 = Get-Item -ErrorAction SilentlyContinue $oneDriveSetupPath3Pattern | Select-Object -ExpandProperty FullName
$oneDriveShortcut = Join-Path -Path $mountDirectory -ChildPath 'Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'
function Remove-OneDriveItem {
    param (
        [string]$Path
    )
    if (Test-Path $Path) {
        takeown /F "$Path" /A > $null 2>&1
        icacls "$Path" /grant:R Administrators:F /T /C > $null 2>&1
        Remove-Item -Path "$Path" -Recurse -Force > $null 2>&1
    }
}
Write-LogMessage "Removing OneDrive"
Remove-OneDriveItem -Path $oneDriveSetupPath1
Remove-OneDriveItem -Path $oneDriveSetupPath2
Remove-OneDriveItem -Path $oneDriveShortcut
if ($null -ne $oneDriveSetupPath3) {
    foreach ($file in $oneDriveSetupPath3) {
        Remove-OneDriveItem -Path $file
    }
}
Get-ChildItem "$mountDirectory\Windows\WinSxS\amd64_microsoft-windows-onedrive-setup*" -Directory | ForEach-Object { takeown /f  $_.FullName /R /D Y; icacls $_.FullName /grant:R Administrators:F /T /C /Q; Remove-Item $_.FullName -Recurse -Force } > $null 2>&1

Write-Host "OneDrive Removed"

# Remove EDGE
Start-Sleep -Milliseconds 1500
Write-Host
$EdgeConfirm = Read-Host "Remove Microsoft Edge? (Y/N)"

if ($EdgeConfirm -eq 'Y' -or $EdgeConfirm -eq 'y') {
    Write-LogMessage "Removing EDGE"
    Remove-Item -Path "$mountDirectory\Program Files (x86)\Microsoft\Edge" -Recurse -Force > $null 2>&1
    Remove-Item -Path "$mountDirectory\Program Files (x86)\Microsoft\EdgeCore" -Recurse -Force > $null 2>&1
    Remove-Item -Path "$mountDirectory\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force > $null 2>&1
    Remove-Item -Path "$mountDirectory\Program Files (x86)\Microsoft\EdgeWebView" -Recurse -Force > $null 2>&1
    Remove-Item -Path "$mountDirectory\ProgramData\Microsoft\EdgeUpdate" -Recurse -Force > $null 2>&1
    Get-ChildItem "$mountDirectory\ProgramData\Microsoft\Windows\AppRepository\Packages\Microsoft.MicrosoftEdge.Stable*" -Directory | ForEach-Object { takeown /f  $_.FullName /R /D Y; icacls $_.FullName /grant:R Administrators:F /T /C /Q; Remove-Item $_.FullName -Recurse -Force } > $null 2>&1
    Get-ChildItem "$mountDirectory\ProgramData\Microsoft\Windows\AppRepository\Packages\Microsoft.MicrosoftEdgeDevToolsClient*" -Directory | ForEach-Object { takeown /f  $_.FullName /R /D Y; icacls $_.FullName /grant:R Administrators:F /T /C /Q; Remove-Item $_.FullName -Recurse -Force } > $null 2>&1
    Get-ChildItem "$mountDirectory\Windows\WinSxS\amd64_microsoft-edge-webview*" -Directory | ForEach-Object { takeown /f  $_.FullName /R /D Y; icacls $_.FullName /grant:R Administrators:F /T /C /Q; Remove-Item $_.FullName -Recurse -Force } > $null 2>&1

    $edgeStablePackages = Get-ProvisionedAppxPackage -Path $mountDirectory | Where-Object { $_.PackageName -like "Microsoft.MicrosoftEdge.Stable*" }
    foreach ($edgeStablePackage in $edgeStablePackages) {
        $edgeRemove = $edgeStablePackage.PackageName
        dism /image:$mountDirectory /Remove-ProvisionedAppxPackage /PackageName:$edgeRemove > $null
    }

    # Remove Web-Experience Package
    $webExperiencePackages = Get-ProvisionedAppxPackage -Path $mountDirectory | Where-Object { $_.PackageName -like "MicrosoftWindows.Client.WebExperience*" }
    foreach ($webExperiencePackage in $webExperiencePackages) {
        $webExperienceRemove = $webExperiencePackage.PackageName
        dism /image:$mountDirectory /Remove-ProvisionedAppxPackage /PackageName:$webExperienceRemove > $null
    }

    # Remove WebViewHost Package
    $WebViewHostPattern = Join-Path -Path $mountDirectory -ChildPath 'Windows\SystemApps\Microsoft.Win32WebViewHost*'
    $WebViewHost = (Get-Item $WebViewHostPattern).FullName
    takeown /F $WebViewHost /R /D y > $null 2>&1
    icacls $WebViewHost /grant:R Administrators:F /T /C > $null 2>&1
    Remove-Item -Path $WebViewHost -Recurse -Force > $null 2>&1

    # Remove EdgeDevToolsClient Package
    $EdgeDevToolsClientPattern = Join-Path -Path $mountDirectory -ChildPath 'Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient*'
    $EdgeDevToolsClient = (Get-Item $EdgeDevToolsClientPattern).FullName
    takeown /F $EdgeDevToolsClient /R /D y > $null 2>&1
    icacls $EdgeDevToolsClient /grant:R Administrators:F /T /C > $null 2>&1
    Remove-Item -Path $EdgeDevToolsClient -Recurse -Force > $null 2>&1

    # Modifying reg keys
    $softwarePath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\config\SOFTWARE'
    $systemPath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\config\SYSTEM'
    $ntuserPath = Join-Path -Path $mountDirectory -ChildPath 'Users\Default\ntuser.dat'

    reg load HKLM\zSOFTWARE $softwarePath > $null 2>&1
    reg load HKLM\zSYSTEM $systemPath > $null 2>&1
    reg load HKLM\zNTUSER $ntuserPath > $null 2>&1

    reg delete "HKLM\zSOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f > $null 2>&1
    reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Edge" /f > $null 2>&1
    reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f > $null 2>&1
    reg delete "HKLM\zSYSTEM\CurrentControlSet\Services\edgeupdate" /f > $null 2>&1
    reg delete "HKLM\zSYSTEM\ControlSet001\Services\edgeupdate" /f > $null 2>&1
    reg delete "HKLM\zSYSTEM\CurrentControlSet\Services\edgeupdatem" /f > $null 2>&1
    reg delete "HKLM\zSYSTEM\ControlSet001\Services\edgeupdatem" /f > $null 2>&1
    reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f > $null 2>&1
    reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f > $null 2>&1

    $registryKeys = @(
        "HKLM\zSOFTWARE\Microsoft\EdgeUpdate",
        "HKLM\zSOFTWARE\Policies\Microsoft\EdgeUpdate",
        "HKLM\zNTUSER\Software\Microsoft\EdgeUpdate",
        "HKLM\zNTUSER\Software\Policies\Microsoft\EdgeUpdate"
    )
    foreach ($key in $registryKeys) {
        reg add "$key" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d "1" /f > $null 2>&1
        reg add "$key" /v "UpdaterExperimentationAndConfigurationServiceControl" /t REG_DWORD /d "1" /f > $null 2>&1
        reg add "$key" /v "InstallDefault" /t REG_DWORD /d "1" /f > $null 2>&1
    }    

    reg add "HKLM\zSOFTWARE\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zNTUSER\Software\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zNTUSER\Software\Policies\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zNTUSER\Software\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zNTUSER\Software\Policies\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\EdgeUpdate" /v "UpdateDefault" /t REG_DWORD /d "0" /f > $null 2>&1
    
    reg unload HKLM\zSOFTWARE > $null 2>&1
    reg unload HKLM\zSYSTEM > $null 2>&1
    reg unload HKLM\zNTUSER > $null 2>&1

    # Removing EDGE-Task
    $edgeTask = Get-ChildItem -Path "$mountDirectory\Windows\System32\Tasks\MicrosoftEdge*"
    if ($null -ne $edgeTask) {
        foreach ($file in $edgeTask) {
            takeown /F $file /R /D y > $null 2>&1
            icacls $file /grant:R Administrators:F /T /C > $null 2>&1
            Remove-Item -Path $file -Recurse -Force > $null 2>&1
        }
    }

    # For Windows 10 (Legacy EDGE)
    $edge = Get-ChildItem -Path "$mountDirectory\Windows\SystemApps\Microsoft.MicrosoftEdge*"
    if ($null -ne $edge) {
        foreach ($file in $edge) {
            takeown /F $file /R /D y > $null 2>&1
            icacls $file /grant:R Administrators:F /T /C > $null 2>&1
            Remove-Item -Path $file -Recurse -Force > $null 2>&1
        }
    }
    Write-Host "Microsoft Edge has been removed."
}
else {
    Write-Host "Microsoft Edge removal cancelled."
    Write-LogMessage "Edge removal cancelled"
}

Start-Sleep -Milliseconds 1800
Write-Host "`nLoading Registry..."
Write-LogMessage "Defining registry paths"
$componentsPath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\config\COMPONENTS'
$defaultPath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\config\default'
$ntuserPath = Join-Path -Path $mountDirectory -ChildPath 'Users\Default\ntuser.dat'
$softwarePath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\config\SOFTWARE'
$systemPath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\config\SYSTEM'

# Load registry
Write-LogMessage "Loading registry"
reg load HKLM\zCOMPONENTS $componentsPath > $null 2>&1
reg load HKLM\zDEFAULT $defaultPath > $null 2>&1
reg load HKLM\zNTUSER $ntuserPath > $null 2>&1
reg load HKLM\zSOFTWARE $softwarePath > $null 2>&1
reg load HKLM\zSYSTEM $systemPath > $null 2>&1

# Setting Permissions
$sid = (New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")).Translate([System.Security.Principal.SecurityIdentifier])
$rule = New-Object System.Security.AccessControl.RegistryAccessRule("Administrators", "FullControl","ContainerInherit","None","Allow")

foreach ($keyPath in @("zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications", "zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks", "zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows")) {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
    $acl = $key.GetAccessControl()
    $acl.SetOwner($sid)
    $key.SetAccessControl($acl)
    $key.Close()

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
    $acl = $key.GetAccessControl()
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
    $key.Close()
}

# Modify registry settings
Start-Sleep -Milliseconds 1000
Write-Host "`nPerforming Registry Tweaks..."

# Disable Sponsored Apps
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "ConfigureStartPins" /t REG_SZ /d '{\"pinnedList\": [{}]}' /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_SZ /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
# Disable Telemetry
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" /v "HasAccepted" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice" /v "Start" /t REG_DWORD /d "4" /f > $null 2>&1
# Disable privacy review in OOBE
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OOBE" /v "DisablePrivacyExperience" /t REG_DWORD /d "1" /f > $null 2>&1
# Disable Meet Now icon
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "AllowOnlineTips" /t REG_DWORD /d "0" /f > $null 2>&1
# Disable ad tailoring
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
# Disable GameBar
reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
# Disable Cortana
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d "0" /f > $null 2>&1
# Disables autosync to OneDrive
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableLibrariesDefaultSaveToOneDrive" /t REG_DWORD /d "0" /f > $null 2>&1
# Changes MenuShowDelay from 400 to 200
reg add "HKLM\zNTUSER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "200" /f > $null 2>&1
# Disable everytime MRT download through Win Update
reg add "HKLM\zSOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUAU" /t REG_DWORD /d "1" /f > $null 2>&1
# Disable OneDrive Sync
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSOFTWARE\Policies\Microsoft\OneDrive" /v "KFMBlockOptIn" /t REG_DWORD /d "1" /f > $null 2>&1
# Disable GameDVR
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zNTUSER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f > $null 2>&1
# Enabling Local Account Creation
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" /t REG_DWORD /d "1" /f > $null 2>&1
Copy-Item -Path $autounattendXmlPath -Destination $destinationPath -Force
# Disable TPM CHeck
reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassDiskCheck" /t REG_DWORD /d "1" /f > $null 2>&1
reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d "1" /f > $null 2>&1
# Prevents Dev Home Installation
reg delete "HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate" /f > $null 2>&1
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate" /v "workCompleted" /t REG_DWORD /d "1" /f > $null 2>&1
# Prevents New Outlook for Windows Installation
reg delete "HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" /f > $null 2>&1
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate" /v "workCompleted" /t REG_DWORD /d "1" /f > $null 2>&1
# Prevents Chat Auto Installation
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v "ConfigureChatAutoInstall" /t REG_DWORD /d "0" /f > $null 2>&1
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t REG_DWORD /d "3" /f > $null 2>&1
# Onedrive junk
reg delete "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f > $null 2>&1

Write-Host "`nDisabling Scheduled Tasks..."
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{4738DE7A-BCC1-4E2D-B1B0-CADB044BFA81}" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{6FAC31FA-4A85-4E64-BFD5-2154FF4594B3}" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FC931F16-B50A-472E-B061-B6F79A71EF59}" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\PcaPatchDbTask" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\MareBackup" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Autochk\Proxy" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /f > $null 2>&1
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /f > $null 2>&1

Write-Host
$expConfirm = Read-Host "Windows 11 disables 'User Folders' in This PC. Enable those again? (Y/N)"
if ($expConfirm -eq 'Y' -or $expConfirm -eq 'y') {
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /f
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /f
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /f
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f

    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f > $null 2>&1

    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f > $null 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f > $null 2>&1
}

Start-Sleep -Milliseconds 1500
Write-Host "`nUnloading Registry..."
Write-LogMessage "Unloading registry"
reg unload HKLM\zCOMPONENTS > $null 2>&1
reg unload HKLM\zDEFAULT > $null 2>&1
reg unload HKLM\zNTUSER > $null 2>&1
reg unload HKLM\zSOFTWARE > $null 2>&1
reg unload HKLM\zSYSTEM > $null 2>&1

Start-Sleep -Milliseconds 1000
Write-Host "`nCleaning up image..."
Write-LogMessage "Cleaning up image"
dism /image:$mountDirectory /Cleanup-Image /StartComponentCleanup /ResetBase > $null

Start-Sleep -Milliseconds 1000
Write-Host "`nUnmounting and Exporting image..."
Write-LogMessage "Unmounting image"
try {
    $unmountProcess = Start-Process -FilePath "dism" -ArgumentList "/unmount-image", "/mountdir:$mountDirectory", "/commit" -PassThru -Wait -NoNewWindow
    if ($unmountProcess.ExitCode -ne 0) {
        $errorMessage = "Failed to unmount image. Exit code: $($unmountProcess.ExitCode)"
        Write-LogMessage $errorMessage
        Write-Host "`nFailed to Unmount the Image. Check Logs for more info."
        Write-Host "Close all the Folders opened in the mountdir to complete the Script."
        Write-Host "Run the following code in Powershell(as admin) to unmount the broken image: "
        Write-Host "dism /unmount-image /mountdir:$mountDirectory /discard"
        Read-Host -Prompt "Press Enter to exit"
        Write-LogMessage "Exiting Script"
        Exit
    }
}
catch {
    Write-LogMessage "Failed to unmount image: $_"
    Exit
}

Write-LogMessage "Exporting image"
$SourceIndex = if (Test-Path $installWimPath) { $WimIndex } else { 1 }
Write-Host
$convertToEsd = Read-Host "Compress install.wim to install.esd? (Y/N)"
if ($convertToEsd -eq 'Y' -or $convertToEsd -eq 'y') {
    dism /Export-Image /SourceImageFile:$destinationPath\sources\install.wim /SourceIndex:$SourceIndex /DestinationImageFile:$destinationPath\sources\install.esd /compress:recovery
    Remove-Item -Path "$destinationPath\sources\install.wim" -Force
    Write-Host "`nConversion to ESD completed"
    Write-LogMessage "Conversion to ESD completed"
} else {
    Write-Host "Conversion to ESD skipped"
    dism /Export-Image /SourceImageFile:$destinationPath\sources\install.wim /SourceIndex:$SourceIndex /DestinationImageFile:$destinationPath\sources\install2.wim /compress:max
    Remove-Item -Path "$destinationPath\sources\install.wim" -Force
    Rename-Item -Path "$destinationPath\sources\install2.wim" -NewName "install.wim" -Force
}

Write-LogMessage "Specifying boot data"
$bootData = '2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$destinationPath\boot\etfsboot.com", "$destinationPath\efi\Microsoft\boot\efisys.bin"
Write-LogMessage "Boot data set: $bootData"

Write-LogMessage "Checking required files"
Write-Host
$ISOFileName = Read-Host -Prompt "Enter the name for the ISO file (without extension)"
$ISOFile = Join-Path -Path $scriptDirectory -ChildPath "$ISOFileName.iso"

if (-not (Test-Path -Path $Oscdimg)) {
    Write-LogMessage "Oscdimg.exe not found at '$Oscdimg'"
    Write-Host "`nOscdimg.exe not found at '$Oscdimg'."
    Start-Sleep -Milliseconds 1800
    Write-Host "`nTrying to Download oscdimg.exe..."

    # Function to check internet connection
    function Test-InternetConnection {
        param (
            [int]$maxAttempts = 3,
            [int]$retryDelaySeconds = 5
        )
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            if (Test-Connection -ComputerName google.com -Count 1 -ErrorAction SilentlyContinue) {
                return $true
            } else {
                Write-Host "`nInternet connection not available, Trying in $retryDelaySeconds seconds..."
                Start-Sleep -Seconds $retryDelaySeconds
            }
        }
        Write-Host "Internet connection not available after $maxAttempts attempts. Exiting the script."
        CleanupTemp
        Exit
    }
    
    Test-InternetConnection

    # Downloading Oscdimg.exe
    $adkUrl = "https://go.microsoft.com/fwlink/?linkid=2243390"
    $downloadPath = "$scriptDirectory\ADKInstaller.exe"

    Invoke-WebRequest -Uri $adkUrl -OutFile $downloadPath

    Write-Host "`nInstalling ADK Setup. This may take some time. Do not exit the Script..."

    # Installing Deployment Tools only
    Start-Process -FilePath $downloadPath -ArgumentList "/quiet /norestart /features OptionId.DeploymentTools" -Wait
    Remove-Item -Path $downloadPath -Force
}
Start-Sleep -Milliseconds 1000


# Generate ISO
Write-Host "`nGenerating ISO..."
Write-LogMessage "Generating ISO"
try {
    $null = Start-Process -FilePath "$Oscdimg" -ArgumentList @("-bootdata:$BootData", '-m', '-o', '-u2', '-udfver102', $destinationPath , "$ISOFile") -PassThru -Wait -NoNewWindow
    Write-LogMessage "ISO successfully created"
}
catch {
    Write-LogMessage "Failed to generate ISO with exit code: $_"
}

# Remove temporary files
Write-Host "`nRemoving temporary files..."
Write-LogMessage "Removing temporary files"
try {
    CleanupTemp
}
catch {
    Write-LogMessage "Failed to remove temporary files: $_"
}
finally {
    Write-LogMessage "Script completed"
}

Start-Sleep -Milliseconds 1500
Write-Host "`nScript Completed. Can find the ISO in `"$scriptDirectory"`"
Read-Host -Prompt "Done. Press Enter to exit"
