# Windows ISO Debloater
# Author: itsNileshHere
# Date: 2023-11-21
# Description: A simple PSscript to modify windows iso file. For more info check README.md

param(
    [switch]$noprompt,
    [string]$isopath = "",
    [string]$wimImage = "",
    [string]$outputiso = "",
    [ValidateSet("yes", "no")]$AppxRemove = "",
    [ValidateSet("yes", "no")]$CapabilitiesRemove = "",
    [ValidateSet("yes", "no")]$OnedriveRemove = "",
    [ValidateSet("yes", "no")]$EDGERemove = "",
    [ValidateSet("yes", "no")]$TPMBypass = "",
    [ValidateSet("yes", "no")]$UserFoldersEnable = "",
    [ValidateSet("yes", "no")]$ESDConvert = "",
    [ValidateSet("yes", "no")]$useOscdimg = ""
)

# If -noprompt is used, ensure required parameters are provided
if ($noprompt) {
    $missing = @("isopath","wimImage","outputiso") | Where-Object { [string]::IsNullOrWhiteSpace((Get-Variable $_).Value) }
    if ($missing) { Write-Error "When using -noprompt, these parameters are required: $($missing -join ', ')"; exit 1 }
}

# Disable Pause if -noprompt is used
if ($noprompt) { function Pause { } }
else { function Pause { Read-Host "Press Enter to continue..." } }

# Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator. Re-launching with elevated privileges..." -ForegroundColor Yellow
    $argss = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if (Get-Command wt -ErrorAction SilentlyContinue) { Start-Process wt "PowerShell $argss" -Verb RunAs } else { Start-Process PowerShell $argss -Verb RunAs }
    Exit
}
Clear-Host
$asciiArt = @"
 _       ___           __                      _________ ____     ____       __    __            __           
| |     / (_)___  ____/ /___ _      _______   /  _/ ___// __ \   / __ \___  / /_  / /___  ____ _/ /____  _____
| | /| / / / __ \/ __  / __ \ | /| / / ___/   / / \__ \/ / / /  / / / / _ \/ __ \/ / __ \/ __ `/ __/ _ \/ ___/
| |/ |/ / / / / / /_/ / /_/ / |/ |/ (__  )  _/ / ___/ / /_/ /  / /_/ /  __/ /_/ / / /_/ / /_/ / /_/  __/ /    
|__/|__/_/_/ /_/\__,_/\____/|__/|__/____/  /___//____/\____/  /_____/\___/_.___/_/\____/\__,_/\__/\___/_/     
                                                                                        -By itsNileshHere                                                                                                  
"@

Write-Host $asciiArt -ForegroundColor Cyan
Start-Sleep -Milliseconds 1000
Write-Host "Starting Windows ISO Debloater Script..." -ForegroundColor Green
Start-Sleep -Milliseconds 800
Write-Host "`n*Important Notes: " -ForegroundColor Yellow
Write-Host "  1. Some prompts will appear during the process."
Write-Host "  2. Administrative privileges are required to run this script."
Write-Host "  3. Review the script beforehand to understand its actions."
Write-Host "  4. To whitelist a package, open the script and comment out the corresponding Packagename."
Write-Host "  5. Select the ISO to proceed."
Start-Sleep -Milliseconds 800

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$scriptDirectory = "$PSScriptRoot"
$logFilePath = Join-Path -Path $scriptDirectory -ChildPath 'script_log.txt'

# Initialize log file
"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Script started" | Out-File -FilePath $logFilePath

# Log File
function Write-Log {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline=$true)][object]$InputObj, [string]$msg, [switch]$Raw, [string]$Sep = " || ")
    process {
        $content = if ($msg) { $msg } elseif ($null -ne $InputObj) { if ($InputObj -is [string]) { $InputObj } else { $InputObj | Out-String } } else { return }
        if (-not $Raw -and $content.Trim()) {
            $lines = @($content -split '\n' | Where-Object { $_.Trim() })
            if ($lines.Count -gt 1) {
                $processedLines = @()
                foreach ($line in $lines) {
                    $trimmed = $line.Trim()
                    if ($trimmed -match '^At\s+(.+)') { $processedLines += "At $($matches[1])" }
                    elseif ($trimmed -match '^\s*\+\s*(.+)') { $processedLines += ("+ " + ($matches[1] -replace '\s{2,}', ' ')) }
                    elseif ($trimmed -match '^\s*\+?\s*(\w+\w+)\s*:\s*(.+)') { $processedLines += "$($matches[1]): $($matches[2])" }
                    elseif ($trimmed -notmatch '^-{4,}' -and $trimmed) { $processedLines += ($trimmed -replace '\s{2,}', ' ') }
                }
                $content = $processedLines -join $Sep
            } else { $content = ($content.Trim() -replace '\s{2,}', ' ') }
        }
        if ($content -and $content.Trim()) { Add-Content -Path "$logFilePath" -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $($content.Trim())" }
    }
}

# Confirmation Function
function Get-Confirmation { 
    param([string]$Question, [bool]$DefaultValue = $true, [string]$Description = "") 
    $defaultText = if ($DefaultValue) { "Y" } else { "N" }
    $optionsText = if ($DefaultValue) { "Y/n" } else { "y/N" }
    do { 
        Write-Host "$Question" -ForegroundColor Cyan -NoNewline
        if ($Description) { Write-Host " - $Description" -ForegroundColor DarkGray -NoNewline }
        Write-Host " ($optionsText): " -ForegroundColor White -NoNewline
        $answer = Read-Host 
        if ([string]::IsNullOrWhiteSpace($answer)) {
            Write-Host "Using default: $defaultText" -ForegroundColor Yellow
            return $DefaultValue
        }
        $answer = $answer.ToUpper()
        if ($answer -eq 'Y') { return $true }
        if ($answer -eq 'N') { return $false }
        Write-Host "Invalid input. Enter 'Y' for Yes, 'N' for No, or Enter for default ($defaultText)." -ForegroundColor Yellow 
    } while ($true) 
}

# Parameter Value Validation Function
function Get-ParameterValue {
    param( [string]$ParameterValue, [bool]$DefaultValue, [string]$Question, [string]$Description )
    # If noprompt is enabled, use default
    if ($noprompt) {
        if ($ParameterValue -ne "") { return $ParameterValue -eq "yes" }
        else { return $DefaultValue }
    }
    # If noprompt is null but param was provided, use the provided value
    if ($ParameterValue -ne "") { return $ParameterValue -eq "yes" }
    # If neither noprompt nor param was provided, prompt the user
    return Get-Confirmation -Question $Question -DefaultValue $DefaultValue -Description $Description
}

# Cleanup Function
function Remove-TempFiles {
    Remove-Item -Path $destinationPath -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path $installMountDir -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$env:SystemDrive\WIDTemp" -Recurse -Force 2>&1 | Write-Log
}

# Force Remove Function
function Set-OwnAndRemove {
    param([Parameter(Mandatory)][string]$Path)
    
    try {
        $FullPath = Resolve-Path -Path $Path -ErrorAction Stop
        if (-not (Test-Path -Path $FullPath)) { return $true }

        # ACL method
        try {
            $IsFolder = (Get-Item $FullPath).PSIsContainer
            $Acl = Get-Acl $FullPath
            $Acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
            $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            
            if ($IsFolder) { $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($CurrentUser, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow") }
            else { $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($CurrentUser, "FullControl", "Allow") }
            
            $Acl.SetAccessRule($AccessRule)
            Set-Acl -Path $FullPath -AclObject $Acl
            
            # Apply to child items if folder
            if ($IsFolder) {
                Get-ChildItem -Path $FullPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        $ChildAcl = Get-Acl $_.FullName
                        $ChildAcl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
                        $ChildAcl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($CurrentUser, "FullControl", "Allow")))
                        Set-Acl -Path $_.FullName -AclObject $ChildAcl
                    } catch {}
                }
            }
            
            Remove-Item -Path $FullPath -Force -Recurse -ErrorAction Stop
            "Removed with ACL: $FullPath" | Write-Log
            return $true
        } catch {}
        
        # icacls fallback
        try {
            if($IsFolder) { takeown /F "$FullPath" /R /D Y 2>&1 | Write-Log } else { takeown /F "$FullPath" /A 2>&1 | Write-Log }
            
            foreach ($Perm in @("*S-1-5-32-544:F", "System:F", "Administrators:F", "$CurrentUser`:F")) {
                if($IsFolder) { icacls "$FullPath" /grant:R "$Perm" /T /C 2>&1 | Write-Log } else { icacls "$FullPath" /grant:R "$Perm" 2>&1 | Write-Log }
                if ($LASTEXITCODE -eq 0) { break }
            }
            
            Remove-Item -Path $FullPath -Force -Recurse -ErrorAction Stop
            "Removed with icacls: $FullPath" | Write-Log
            return $true
        } catch {}
        
        "Failed to remove: $FullPath" | Write-Log
        return $false
    }
    catch {
        "Error: $Path - $($_.Exception.Message)" | Write-Log
        return $false
    }
}

# Image Info Function
function Get-WimDetails {
    param ( [Parameter(Mandatory = $true)][string]$MountPath )
    try {
        $out = dism /Image:$MountPath /Get-Intl /English | Out-String
        Write-Log -msg "DISM Output for Get-WimDetails:`n$out"
        $buildMatch = [regex]::Match($out, "Image Version: \d+\.\d+\.(\d+)\.\d+")
        $langMatch = [regex]::Match($out, "(?i)Default\s+system\s+UI\s+language\s*:\s*([a-z]{2}-[A-Z]{2})")
        [PSCustomObject]@{
            BuildNumber = if ($buildMatch.Success) { $buildMatch.Groups[1].Value } else { $null }
            Language = if ($langMatch.Success) { $langMatch.Groups[1].Value } else { $null }
        }
    }
    catch {
        Write-Host "Failed to get WIM info: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Get Image Index Function
function Get-ImageIndex {
    param ( [Parameter(Mandatory = $true)][string]$ImagePath )
    try {
        $out = & dism.exe /get-wiminfo /wimfile:$ImagePath /english 2>$null
        Write-Log -msg "DISM Output for Get-ImageIndex:`n$out"
        if ($LASTEXITCODE -ne 0) { throw "DISM failed to read image file: $ImagePath" }
        $images = @()
        $indexPattern = "Index\s*:\s*(\d+)"
        $namePattern = "Name\s*:\s*(.+)"
        for ($i = 0; $i -lt $out.Count; $i++) {
            if ($out[$i] -match $indexPattern) {
                $index = $matches[1]
                for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $out.Count); $j++) {
                    if ($out[$j] -match $namePattern) {
                        $name = $matches[1].Trim()
                        $images += [PSCustomObject]@{
                            Index = [int]$index
                            ImageName = $name
                        }
                        break
                    }
                }
            }
        }
        return $images
    }
    catch {
        Write-Log -msg "Failed to get image information: $($_.Exception.Message)"
        return $null
    }
}

# Oscdimg Path
$OscdimgPath = "$env:SystemDrive\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
$Oscdimg = Join-Path -Path $OscdimgPath -ChildPath 'oscdimg.exe'

# Autounattend.xml Path
$autounattendXmlPath = Join-Path -Path $scriptDirectory -ChildPath "Autounattend.xml"

# Download Autounattend.xml if not exists
if (-not (Test-Path $autounattendXmlPath)) {
    $ProgressPreference = 'SilentlyContinue'
    try { Invoke-WebRequest "https://itsnileshhere.github.io/Windows-ISO-Debloater/autounattend.xml" -OutFile $autounattendXmlPath -UseBasicParsing }
    catch { Write-Log -msg "Warning: Unable to download Autounattend.xml" }
    finally { $ProgressPreference = 'Continue' }
}

# Mount ISO Dialog
function Select-ISOFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.Title = "Select Windows ISO File"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    } else {
        return $null
    }
}

if ($isopath) {$isoFilePath = $isopath}     # If ISO path is provided as parameter
else {$isoFilePath = Select-ISOFile}        # Prompt user to select ISO file
if ($null -eq $isoFilePath) {
    Write-Host "No file selected. Exiting Script" -ForegroundColor Red
    Write-Log -msg "No file selected"
    Pause
    Exit
}

Write-Host "`nSelected ISO file: " -NoNewline -ForegroundColor Cyan; Write-Host "$isoFilePath"
Write-Log -msg "ISO Path: $isoFilePath"

# Mounting ISO File
$mountResult = Mount-DiskImage -ImagePath "$isoFilePath" -PassThru
if ($mountResult) {
    $sourceDriveLetter = ($mountResult | Get-Volume).DriveLetter
    if ($sourceDriveLetter) {
        Write-Log -msg "Mounted ISO file to drive: $sourceDriveLetter`:"
    }
}
else {
    Write-Host "Failed to mount the ISO file." -ForegroundColor Red
    Write-Log -msg "Failed to mount the ISO file."
    Pause
    Exit
}

$sourceDrive = "${sourceDriveLetter}:\" # Source Drive of ISO
$destinationPath = "$env:SystemDrive\WIDTemp\winlite"   # Destination Path
$installMountDir = "$env:SystemDrive\WIDTemp\mountdir\installWIM"   # Mount Directory

# Copy Files
Write-Host "`nCopying files from " -NoNewline; Write-Host "`"$sourceDrive`"" -ForegroundColor Yellow -NoNewline; Write-Host " to " -NoNewline; Write-Host "`"$destinationPath`"" -ForegroundColor Yellow; Write-Log -msg "Copying files from $sourceDrive to $destinationPath"
try {
    if (-not (Test-Path $destinationPath)) { New-Item -ItemType Directory -Path $destinationPath -Force -EA Stop | Out-Null }
    Write-Log -msg "Starting file copy operation..."
    
    # Using Robocopy to copy files
    $robocopyOutput = & robocopy.exe $sourceDrive $destinationPath /E /COPY:DAT /R:3 /W:5 /MT:8 /NFL /NDL /NP 2>&1
    $robocopyExitCode = $LASTEXITCODE
    $robocopyOutput | Write-Log
    if ($robocopyExitCode -le 7) { 
        Write-Host "Copy completed successfully." -ForegroundColor Green
        Write-Log -msg "Copy completed (Exit: $robocopyExitCode)"
        Write-Log -msg "Removing read-only attributes..."
        Get-ChildItem -Path $destinationPath -Recurse | ForEach-Object { $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly) } | Out-Null
    }
    else { throw "Robocopy failed: $robocopyExitCode" }
} catch { Write-Log -msg "Copy failed: $($_.Exception.Message)"; throw }

try { if (Test-Path $isoFilePath) { Dismount-DiskImage -ImagePath $isoFilePath -EA Stop | Out-Null} }
catch { Write-Log -msg "Dismount failed: $($_.Exception.Message)" }

# Check files availability
$installWimPath = Join-Path $destinationPath "sources\install.wim"
$installEsdPath = Join-Path $destinationPath "sources\install.esd"
New-Item -ItemType Directory -Path $installMountDir 2>&1 | Write-Log

# Handling install.wim and install.esd
if (-not (Test-Path $installWimPath)) {
    Write-Host "`ninstall.wim not found. Searching for install.esd..."
    if (Test-Path $installEsdPath) {
        Write-Host "`ninstall.esd found at " -NoNewline -ForegroundColor Cyan; Write-Host "$installEsdPath"
        Write-Log -msg "install.esd found. Converting..."
        Write-Host "Details for image: " -NoNewline -ForegroundColor Cyan; Write-Host "$installEsdPath"
        try {
            # Get image info from install.esd
            $esdInfo = Get-ImageIndex -ImagePath $installEsdPath
            if (-not $esdInfo) { 
                Write-Host "Error: Could not retrieve image info from WIM file" -ForegroundColor Red
                Remove-TempFiles
                Pause
                Exit
            }
            # Print image details from install.esd
            foreach ($image in $esdInfo) {
                Write-Host "$($image.Index). $($image.ImageName)"
            }
            # If wimImage is specified, find the index; else prompt user
            if ($wimImage) {
                $matchedImage = $esdInfo | Where-Object { $_.ImageName -ieq $wimImage }
                if ($matchedImage) { $sourceIndex = $matchedImage.Index }
                else { $sourceIndex = 1 }
            }
            else { $sourceIndex = Read-Host -Prompt "`nEnter the index to convert and mount" }
            # Check if the index is valid, print selected "ImageIndex - ImageName"
            $selectedImage = $esdInfo | Where-Object { $_.Index -eq [int]$sourceIndex }
            if ($selectedImage) {
                Write-Host "`nMounting image: " -NoNewline -ForegroundColor Cyan; Write-Host "$sourceIndex. $($selectedImage.ImageName)"
                Write-Log -msg "Converting and Mounting image: $sourceIndex. $($selectedImage.ImageName)"
            }

            # Convert ESD to WIM
            Export-WindowsImage -SourceImagePath $installEsdPath -SourceIndex $sourceIndex -DestinationImagePath $installWimPath -CompressionType Maximum -CheckIntegrity 2>&1 | Write-Log
            # Remove the ESD file after conversion
            Remove-Item $installEsdPath -Force
            # Mount the converted WIM with SourceIndex 1
            Mount-WindowsImage -ImagePath $installWimPath -Index 1 -Path $installMountDir 2>&1 | Write-Log
            $sourceIndex = 1  # After conversion, the new WIM will have only one image
        }
        catch {
            Write-Host "Failed to convert or mount the ESD image: $_" -ForegroundColor Red
            Write-Log -msg "Failed to mount image: $_"
            Pause
            Exit
        }
    }
    else {
        Write-Host "Neither install.wim nor install.esd found. Make sure to mount the correct ISO" -ForegroundColor Red
        Write-Log -msg "Neither install.wim nor install.esd found"
        Pause
        Exit
    }
}
else {
    Write-Host "`nDetails for image: " -NoNewline -ForegroundColor Cyan; Write-Host "$installWimPath"
    Write-Log -msg "Getting image info"
    try {
        # Get image info from install.wim
        $wimInfo = Get-ImageIndex -ImagePath $installWimPath
        if (-not $wimInfo) { 
            Write-Host "Error: Could not retrieve image info from WIM file" -ForegroundColor Red
            Remove-TempFiles
            Pause
            Exit
        }
        # Print image details from install.wim
        foreach ($image in $wimInfo) {
            Write-Host "$($image.Index). $($image.ImageName)"
        }
        # If wimImage is specified, find the index; else prompt user
        if ($wimImage) {
            $matchedImage = $wimInfo | Where-Object { $_.ImageName -ieq $wimImage }
            if ($matchedImage) { $sourceIndex = $matchedImage.Index }
            else { $sourceIndex = 1 }
        }
        else { $sourceIndex = Read-Host -Prompt "`nEnter the index to mount" }
        # Check if the index is valid, print selected "ImageIndex - ImageName"
        $selectedImage = $wimInfo | Where-Object { $_.Index -eq [int]$sourceIndex }
        if ($selectedImage) {
            Write-Host "`nMounting image: " -NoNewline -ForegroundColor Cyan; Write-Host "$sourceIndex. $($selectedImage.ImageName)"
            Write-Log -msg "Mounting image: $sourceIndex. $($selectedImage.ImageName)"
        }

        Mount-WindowsImage -ImagePath $installWimPath -Index $sourceIndex -Path $installMountDir 2>&1 | Write-Log
    }
    catch {
        Write-Host "Failed to mount the image: $_" -ForegroundColor Red
        Write-Log -msg "Failed to mount image: $_"
        Pause
        Exit
    }
}

# Check if wim-mount was successful
if (-not (Test-Path "$installMountDir\Windows")) {
    Write-Host "Error while mounting image. Try again." -ForegroundColor Red
    Write-Log -msg "Mounted image not found. Exiting"
    Remove-TempFiles
    Pause
    Exit 
}

# Resolve Image Info
$WimDetails = Get-WimDetails -MountPath $installMountDir
if (-not $WimDetails -or -not $WimDetails.BuildNumber -or -not $WimDetails.Language) {
    Write-Host "Error: Could not retrieve WIM information from mounted path" -ForegroundColor Red
    Remove-TempFiles
    Pause
    Exit
}
$langCode = $WimDetails.Language; Write-Log -msg "Detected Language: $langCode"
$buildNumber = $WimDetails.BuildNumber; Write-Log -msg "Detected Build Number: $buildNumber"

Write-Host
$DoAppxRemove = Get-ParameterValue -ParameterValue $AppxRemove -DefaultValue $true -Question "Remove unnecessary packages?" -Description "Recommended: Removes bloatware apps"
$DoCapabilitiesRemove = Get-ParameterValue -ParameterValue $CapabilitiesRemove -DefaultValue $true -Question "Remove unnecessary features?" -Description "Recommended: Removes optional Windows features"
$DoOnedriveRemove = Get-ParameterValue -ParameterValue $OnedriveRemove -DefaultValue $true -Question "Remove OneDrive?" -Description "Optional: Completely removes OneDrive"
$DoEDGERemove = Get-ParameterValue -ParameterValue $EDGERemove -DefaultValue $true -Question "Remove Microsoft Edge?" -Description "Optional: Removes Edge browser"
$DoTPMBypass = Get-ParameterValue -ParameterValue $TPMBypass -DefaultValue $false -Question "Bypass TPM check?" -Description "Only if needed for older hardware"
$DoUserFoldersEnable = Get-ParameterValue -ParameterValue $UserFoldersEnable -DefaultValue $true -Question "Enable user folders?" -Description "Recommended: Enables Desktop, Documents, etc."
$DoESDConvert = Get-ParameterValue -ParameterValue $ESDConvert -DefaultValue $false -Question "Compress the ISO?" -Description "Recommended but slow: Reduces ISO file size"
$DoUseOscdimg = Get-ParameterValue -ParameterValue $useOscdimg -DefaultValue $true -Question "Use Oscdimg for ISO creation?" -Description "Recommended: Oscdimg is more reliable"

# Comment out the package don't wanna remove
$appxPatternsToRemove = @(
    "Microsoft.Microsoft3DViewer*",             # 3DViewer
    "Microsoft.WindowsAlarms*",                 # Alarms
    "Microsoft.BingNews*",                      # Bing News
    "Microsoft.BingWeather*",                   # Bing Weather
    "Clipchamp.Clipchamp*",                     # Clipchamp
    "Microsoft.549981C3F5F10*",                 # Cortana
    "Microsoft.Windows.DevHome*",               # DevHome
    "MicrosoftCorporationII.MicrosoftFamily*",  # Family
    "Microsoft.WindowsFeedbackHub*",            # FeedbackHub
    "Microsoft.GetHelp*",                       # GetHelp
    "Microsoft.Getstarted*",                    # GetStarted
    "Microsoft.WindowsCommunicationsapps*",     # Mail
    "Microsoft.WindowsMaps*",                   # Maps
    "Microsoft.MixedReality.Portal*",           # MixedReality
    "Microsoft.ZuneMusic*",                     # Music
    "Microsoft.MicrosoftOfficeHub*",            # OfficeHub
    "Microsoft.Office.OneNote*",                # OneNote
    "Microsoft.OutlookForWindows*",             # Outlook
    "Microsoft.MSPaint*",                       # Paint3D(Windows10)
    "Microsoft.People*",                        # People
    "Microsoft.YourPhone*",                     # Phone
    "Microsoft.PowerAutomateDesktop*",          # PowerAutomate
    "MicrosoftCorporationII.QuickAssist*",      # QuickAssist
    "Microsoft.SkypeApp*",                      # Skype
    "Microsoft.MicrosoftSolitaireCollection*",  # SolitaireCollection
    # "Microsoft.WindowsSoundRecorder*",          # SoundRecorder
    "MicrosoftTeams*",                          # Teams_old
    "MSTeams*",                                 # Teams
    "Microsoft.Todos*",                         # Todos
    "Microsoft.ZuneVideo*",                     # Video
    "Microsoft.Wallet*",                        # Wallet
    "Microsoft.GamingApp*",                     # Xbox
    "Microsoft.XboxApp*",                       # Xbox(Win10)
    "Microsoft.XboxGameOverlay*",               # XboxGameOverlay
    "Microsoft.XboxGamingOverlay*",             # XboxGamingOverlay
    "Microsoft.XboxSpeechToTextOverlay*",       # XboxSpeechToTextOverlay
    "Microsoft.Xbox.TCUI*",                     # XboxTCUI
    # "Microsoft.SecHealthUI*",                   # Windows Security
    "MicrosoftWindows.CrossDevice*",            # CrossDevice
    "Microsoft.Windows.PeopleExperienceHost*",  # PeopleExperienceHost
    "Windows.CBSPreview*",                      # CBS Preview
    "Microsoft.BingSearch*"                     # Bing Search
)

$capabilitiesToRemove = @(
    "Browser.InternetExplorer*",
    "Internet-Explorer*",
    "App.StepsRecorder*",
    "Language.Handwriting~~~$langCode*",
    "Language.OCR~~~$langCode*",
    "Language.Speech~~~$langCode*",
    "Language.TextToSpeech~~~$langCode*",
    "Microsoft.Windows.WordPad*",
    "MathRecognizer*",
    "Media.WindowsMediaPlayer*",
    "Microsoft.Windows.PowerShell.ISE*"
)

$windowsPackagesToRemove = @(
    "Microsoft-Windows-InternetExplorer-Optional-Package*",
    "Microsoft-Windows-LanguageFeatures-Handwriting-$langCode-Package*",
    "Microsoft-Windows-LanguageFeatures-OCR-$langCode-Package*",
    "Microsoft-Windows-LanguageFeatures-Speech-$langCode-Package*",
    "Microsoft-Windows-LanguageFeatures-TextToSpeech-$langCode-Package*",
    "Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package*",
    "Microsoft-Windows-WordPad-FoD-Package*",
    "Microsoft-Windows-MediaPlayer-Package*",
    "Microsoft-Windows-TabletPCMath-Package*",
    "Microsoft-Windows-StepsRecorder-Package*"
)

function Remove-Packages {
    param( [string[]]$Patterns, [string]$SectionTitle, [string]$PackageType, [string]$MountPath, [int]$StartIndex = 1, [int]$TotalCount, [int]$StatusColumn )
    
    # Package configurations
    $config = @{
        'AppX' = @{
            GetCommand = { Get-ProvisionedAppxPackage -Path $MountPath }
            FilterProperty = 'PackageName'
            RemoveCommand = { param($item) Remove-ProvisionedAppxPackage -Path $MountPath -PackageName $item.PackageName }
            LogPrefix = 'AppX package'
        }
        'Capability' = @{
            GetCommand = { Get-WindowsCapability -Path $MountPath }
            FilterProperty = 'Name'
            RemoveCommand = { param($item) Remove-WindowsCapability -Path $MountPath -Name $item.Name }
            LogPrefix = 'capability'
        }
        'WindowsPackage' = @{
            GetCommand = { Get-WindowsPackage -Path $MountPath }
            FilterProperty = 'PackageName'
            RemoveCommand = { param($item) Remove-WindowsPackage -Path $MountPath -PackageName $item.PackageName }
            LogPrefix = 'Windows package'
        }
    }
    if ($SectionTitle) { Write-Host "`n$SectionTitle" -ForegroundColor Cyan; Write-Log -msg $SectionTitle }
    
    # Validate Package Type
    $cfg = $config[$PackageType]
    $filterProp = $cfg.FilterProperty
    
    for ($i = 0; $i -lt $Patterns.Count; $i++) {
        $pattern = $Patterns[$i]
        $displayName = $pattern.TrimEnd('*')
        $counter = "[{0}/{1}]" -f ($StartIndex + $i), $TotalCount
        $initialOutput = "  $counter $displayName"

        Write-Host $initialOutput -NoNewline    # Display initial output
        try {
            $items = & $cfg.GetCommand | Where-Object { $_.$filterProp -like $pattern }
            $itemsRemoved = 0
            foreach ($item in $items) {
                try {
                    & $cfg.RemoveCommand $item 2>&1 | Write-Log
                    $itemsRemoved++
                }
                catch {
                    $itemName = $item.$filterProp
                    Write-Log -msg "Removing $($cfg.LogPrefix) $itemName failed: $_"
                }
            }
            
            # Show status
            $padding = $StatusColumn - $initialOutput.Length
            $spaces = ' ' * $padding
            if ($itemsRemoved -gt 0) { Write-Host "$spaces[REMOVED]" -ForegroundColor Green }
            else { Write-Host "$spaces[NOT FOUND]" -ForegroundColor Yellow }
        }
        catch {
            Write-Log -msg "Failed to remove $PackageType matching '$pattern': $_"
            $padding = $StatusColumn - $initialOutput.Length
            Write-Host "$(' ' * $padding)[ERROR]" -ForegroundColor Red
        }
    }
}

$allPatterns = $appxPatternsToRemove + $capabilitiesToRemove + $windowsPackagesToRemove
$maxLength = ($allPatterns | ForEach-Object { $_.TrimEnd('*').Length } | Measure-Object -Maximum).Maximum
$statusColumn = $maxLength + 18

if ($DoAppxRemove) {
    # Remove AppX Packages
    Remove-Packages -Patterns $appxPatternsToRemove -SectionTitle "Removing provisioned Packages:" -PackageType "AppX" -MountPath $installMountDir -TotalCount $appxPatternsToRemove.Count -StatusColumn $statusColumn
} else {
    Write-Log -msg "Skipped Package Removal"
}

if ($DoCapabilitiesRemove) {
    # Remove Capabilities and Windows Packages
    $capabilitiesAndPackagesTotal = $capabilitiesToRemove.Count + $windowsPackagesToRemove.Count
    Remove-Packages -Patterns $capabilitiesToRemove -SectionTitle "Removing Unnecessary Windows Features:" -PackageType "Capability" -MountPath $installMountDir -TotalCount $capabilitiesAndPackagesTotal -StatusColumn $statusColumn
    Remove-Packages -Patterns $windowsPackagesToRemove -SectionTitle "" -PackageType "WindowsPackage" -MountPath $installMountDir -StartIndex ($capabilitiesToRemove.Count + 1) -TotalCount $capabilitiesAndPackagesTotal -StatusColumn $statusColumn
} else {
    Write-Log -msg "Skipped Features Removal"
}

# # Remove Recall (Have conflict with Explorer)
# Write-Host "`nRemoving Recall..."
# Write-Log -msg "Removing Recall"
# dism /image:$installMountDir /Disable-Feature /FeatureName:'Recall' /Remove 2>&1 | Write-Log
# Write-Host "Done"

# # Remove OutlookPWA
# Write-Host "`nRemoving Outlook..." -ForegroundColor Cyan
# Write-Log -msg "Removing OutlookPWA"
# Get-ChildItem "$installMountDir\Windows\WinSxS\amd64_microsoft-windows-outlookpwa*" -Directory | ForEach-Object { Set-OwnAndRemove -Path $_.FullName } 2>&1 | Write-Log
# Write-Host "Done" -ForegroundColor Green

# Setting Permissions
function Enable-Privilege {
    param([ValidateSet('SeAssignPrimaryTokenPrivilege', 'SeAuditPrivilege', 'SeBackupPrivilege', 'SeChangeNotifyPrivilege', 'SeCreateGlobalPrivilege', 'SeCreatePagefilePrivilege', 'SeCreatePermanentPrivilege', 'SeCreateSymbolicLinkPrivilege', 'SeCreateTokenPrivilege', 'SeDebugPrivilege', 'SeEnableDelegationPrivilege', 'SeImpersonatePrivilege', 'SeIncreaseBasePriorityPrivilege', 'SeIncreaseQuotaPrivilege', 'SeIncreaseWorkingSetPrivilege', 'SeLoadDriverPrivilege', 'SeLockMemoryPrivilege', 'SeMachineAccountPrivilege', 'SeManageVolumePrivilege', 'SeProfileSingleProcessPrivilege', 'SeRelabelPrivilege', 'SeRemoteShutdownPrivilege', 'SeRestorePrivilege', 'SeSecurityPrivilege', 'SeShutdownPrivilege', 'SeSyncAgentPrivilege', 'SeSystemEnvironmentPrivilege', 'SeSystemProfilePrivilege', 'SeSystemtimePrivilege', 'SeTakeOwnershipPrivilege', 'SeTcbPrivilege', 'SeTimeZonePrivilege', 'SeTrustedCredManAccessPrivilege', 'SeUndockPrivilege', 'SeUnsolicitedInputPrivilege')]$Privilege, $ProcessId = $pid, [Switch]$Disable)
    $def = @'
    using System;using System.Runtime.InteropServices;public class AdjPriv{[DllImport("advapi32.dll",ExactSpelling=true,SetLastError=true)]internal static extern bool AdjustTokenPrivileges(IntPtr htok,bool disall,ref TokPriv1Luid newst,int len,IntPtr prev,IntPtr relen);[DllImport("advapi32.dll",ExactSpelling=true,SetLastError=true)]internal static extern bool OpenProcessToken(IntPtr h,int acc,ref IntPtr phtok);[DllImport("advapi32.dll",SetLastError=true)]internal static extern bool LookupPrivilegeValue(string host,string name,ref long pluid);[StructLayout(LayoutKind.Sequential,Pack=1)]internal struct TokPriv1Luid{public int Count;public long Luid;public int Attr;}public static bool EnablePrivilege(long processHandle,string privilege,bool disable){var tp=new TokPriv1Luid();tp.Count=1;tp.Attr=disable?0:2;IntPtr htok=IntPtr.Zero;if(!OpenProcessToken(new IntPtr(processHandle),0x28,ref htok))return false;if(!LookupPrivilegeValue(null,privilege,ref tp.Luid))return false;return AdjustTokenPrivileges(htok,false,ref tp,0,IntPtr.Zero,IntPtr.Zero);}}
'@
    (Add-Type $def -PassThru -EA SilentlyContinue)[0]::EnablePrivilege((Get-Process -id $ProcessId).Handle, $Privilege, $Disable)
}
Enable-Privilege SeTakeOwnershipPrivilege | Out-Null

if ($DoOnedriveRemove) {
    # Remove OneDrive
    Write-Host ("`n[INFO] Removing OneDrive...") -ForegroundColor Cyan
    Write-Log -msg "Defining OneDrive Setup file paths"
    $oneDriveSetupPath1 = Join-Path -Path $installMountDir -ChildPath 'Windows\System32\OneDriveSetup.exe'
    $oneDriveSetupPath2 = Join-Path -Path $installMountDir -ChildPath 'Windows\SysWOW64\OneDriveSetup.exe'
    # $oneDriveSetupPath3 = (Join-Path -Path $installMountDir -ChildPath 'Windows\WinSxS\*microsoft-windows-onedrive-setup*\OneDriveSetup.exe' | Get-Item -ErrorAction SilentlyContinue).FullName
    # $oneDriveSetupPath4 = (Get-ChildItem "$installMountDir\Windows\WinSxS\amd64_microsoft-windows-onedrive-setup*" -Directory).FullName
    $oneDriveShortcut = Join-Path -Path $installMountDir -ChildPath 'Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'

    Write-Log -msg "Removing OneDrive"
    Set-OwnAndRemove -Path $oneDriveSetupPath1 | Out-Null
    Set-OwnAndRemove -Path $oneDriveSetupPath2 | Out-Null
    # $oneDriveSetupPath3 | Where-Object { $_ } | ForEach-Object { Set-OwnAndRemove -Path $_ } 2>&1 | Write-Log
    # $oneDriveSetupPath4 | Where-Object { $_ } | ForEach-Object { Set-OwnAndRemove -Path $_ } 2>&1 | Write-Log
    Set-OwnAndRemove -Path $oneDriveShortcut | Out-Null

    Write-Host ("[OK] OneDrive Removed") -ForegroundColor Green
    Write-Log -msg "OneDrive removed successfully"
} else {
    Write-Log -msg "OneDrive removal skipped"
}

if ($DoEDGERemove) {
    # Remove EDGE
    Write-Host ("`n[INFO] Removing EDGE...") -ForegroundColor Cyan
    Write-Log -msg "Removing EDGE"
    
    # Edge Patterns
    $EDGEpatterns = @(
        "Microsoft.MicrosoftEdge.Stable*",
        "Microsoft.MicrosoftEdgeDevToolsClient*", 
        "Microsoft.Win32WebViewHost*",
        "MicrosoftWindows.Client.WebExperience*"
    )

    # Remove Edge Packages
    foreach ($pattern in $EDGEpatterns) {
        $matchedPackages = Get-ProvisionedAppxPackage -Path $installMountDir | 
        Where-Object { $_.PackageName -like $pattern }
        foreach ($package in $matchedPackages) {
            Remove-ProvisionedAppxPackage -Path $installMountDir -PackageName $package.PackageName 2>&1 | Write-Log
        }
    }

    # Modifying reg keys
    try {
        reg load HKLM\zSOFTWARE "$installMountDir\Windows\System32\config\SOFTWARE" 2>&1 | Write-Log
        reg load HKLM\zSYSTEM "$installMountDir\Windows\System32\config\SYSTEM" 2>&1 | Write-Log
        reg load HKLM\zNTUSER "$installMountDir\Users\Default\ntuser.dat" 2>&1 | Write-Log
        reg load HKLM\zDEFAULT "$installMountDir\Windows\System32\config\default" 2>&1 | Write-Log
          
        # Registry operations
        reg delete "HKLM\zSOFTWARE\Microsoft\EdgeUpdate" /f 2>&1 | Write-Log
        reg delete "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f 2>&1 | Write-Log
        reg delete "HKLM\zDEFAULT\Software\Microsoft\EdgeUpdate" /f 2>&1 | Write-Log
        reg delete "HKLM\zNTUSER\Software\Microsoft\EdgeUpdate" /f 2>&1 | Write-Log
        reg delete "HKLM\zSOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f 2>&1 | Write-Log
        reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Edge" /f 2>&1 | Write-Log
        reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f 2>&1 | Write-Log
        reg delete "HKLM\zSYSTEM\CurrentControlSet\Services\edgeupdate" /f 2>&1 | Write-Log
        reg delete "HKLM\zSYSTEM\ControlSet001\Services\edgeupdate" /f 2>&1 | Write-Log
        reg delete "HKLM\zSYSTEM\CurrentControlSet\Services\edgeupdatem" /f 2>&1 | Write-Log
        reg delete "HKLM\zSYSTEM\ControlSet001\Services\edgeupdatem" /f 2>&1 | Write-Log
        reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f 2>&1 | Write-Log
        reg delete "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zNTUSER\Software\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zNTUSER\Software\Policies\Microsoft\MicrosoftEdge\Main" /v "AllowPrelaunch" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zNTUSER\Software\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zNTUSER\Software\Policies\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Policies\Microsoft\EdgeUpdate" /v "UpdateDefault" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        
        # Disable Edge updates and installation
        $registryKeys = @(
            "HKLM\zSOFTWARE\Microsoft\EdgeUpdate",
            "HKLM\zSOFTWARE\Policies\Microsoft\EdgeUpdate",
            "HKLM\zSOFTWARE\WOW6432Node\Microsoft\EdgeUpdate",
            "HKLM\zNTUSER\Software\Microsoft\EdgeUpdate",
            "HKLM\zNTUSER\Software\Policies\Microsoft\EdgeUpdate"
        )
        foreach ($key in $registryKeys) {
            reg add "$key" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
            reg add "$key" /v "UpdaterExperimentationAndConfigurationServiceControl" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
            reg add "$key" /v "InstallDefault" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        }
    }
    catch {
        Write-Log -msg "Error modifying registry: $_"
    }
    finally {
        # Always unload registry hives regardless of errors
        reg unload HKLM\zSOFTWARE 2>&1 | Write-Log
        reg unload HKLM\zSYSTEM 2>&1 | Write-Log
        reg unload HKLM\zNTUSER 2>&1 | Write-Log
        reg unload HKLM\zDEFAULT 2>&1 | Write-Log
    }

    # Remove EDGE files
    Remove-Item -Path "$installMountDir\Program Files\Microsoft\Edge" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\Program Files\Microsoft\EdgeCore" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\Program Files\Microsoft\EdgeUpdate" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\Program Files\Microsoft\EdgeWebView" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\Program Files (x86)\Microsoft\Edge" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\Program Files (x86)\Microsoft\EdgeCore" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\Program Files (x86)\Microsoft\EdgeWebView" -Recurse -Force 2>&1 | Write-Log
    Remove-Item -Path "$installMountDir\ProgramData\Microsoft\EdgeUpdate" -Recurse -Force 2>&1 | Write-Log
    Get-ChildItem "$installMountDir\ProgramData\Microsoft\Windows\AppRepository\Packages\Microsoft.MicrosoftEdge.Stable*" -Directory | ForEach-Object { Set-OwnAndRemove -Path $_.FullName } 2>&1 | Write-Log
    Get-ChildItem "$installMountDir\ProgramData\Microsoft\Windows\AppRepository\Packages\Microsoft.MicrosoftEdgeDevToolsClient*" -Directory | ForEach-Object { Set-OwnAndRemove -Path $_.FullName } 2>&1 | Write-Log
    # Get-ChildItem "$installMountDir\Windows\WinSxS\*microsoft-edge-webview*" -Directory | ForEach-Object { Set-OwnAndRemove -Path $_.FullName } 2>&1 | Write-Log
    Set-OwnAndRemove -Path (Join-Path -Path $installMountDir -ChildPath 'Windows\System32\Microsoft-Edge-WebView') | Out-Null
    Set-OwnAndRemove -Path (Join-Path -Path $installMountDir -ChildPath 'Windows\SystemApps\Microsoft.Win32WebViewHost*' | Get-Item -ErrorAction SilentlyContinue).FullName | Out-Null

    # Removing EDGE-Task
    Get-ChildItem -Path "$installMountDir\Windows\System32\Tasks\MicrosoftEdge*" | Where-Object { $_ } | ForEach-Object { Set-OwnAndRemove -Path $_ } 2>&1 | Write-Log
    
    # For Windows 10 (Legacy EDGE)
    if ($buildNumber -lt 22000) {
        Get-ChildItem -Path "$installMountDir\Windows\SystemApps\Microsoft.MicrosoftEdge*" | Where-Object { $_ } | ForEach-Object { Set-OwnAndRemove -Path $_ } 2>&1 | Write-Log
    }
    
    Write-Host ("[OK] EDGE has been removed") -ForegroundColor Green
    Write-Log -msg "Microsoft Edge removal completed"
} else {
    Write-Log -msg "Edge removal cancelled"
}

# Registry Tweaks
Write-Host ("`n[INFO] Loading Registry...") -ForegroundColor Cyan
Write-Log -msg "Loading registry"
reg load HKLM\zCOMPONENTS "$installMountDir\Windows\System32\config\COMPONENTS" 2>&1 | Write-Log
reg load HKLM\zDEFAULT "$installMountDir\Windows\System32\config\default" 2>&1 | Write-Log
reg load HKLM\zNTUSER "$installMountDir\Users\Default\ntuser.dat" 2>&1 | Write-Log
reg load HKLM\zSOFTWARE "$installMountDir\Windows\System32\config\SOFTWARE" 2>&1 | Write-Log
reg load HKLM\zSYSTEM "$installMountDir\Windows\System32\config\SYSTEM" 2>&1 | Write-Log

# Setting Permissions
try {
    $sid = (New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")).Translate([System.Security.Principal.SecurityIdentifier])
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule("Administrators", "FullControl", "ContainerInherit", "None", "Allow")

    foreach ($keyPath in @("zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications", "zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks", "zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows", "zSOFTWARE\Microsoft\WindowsRuntime\Server\Windows.Gaming.GameBar.Internal.PresenceWriterServer")) {
        try {
            $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
            if ($key) {
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
        }
        catch {}
    }
}
catch {}
Write-Host ("[OK] Registry loaded") -ForegroundColor Green

# Modify registry settings
Write-Host ("`nPerforming Registry Tweaks...") -ForegroundColor Cyan

# Disable Sponsored Apps
Write-Host -NoNewline ("  Disabling Sponsored Apps".PadRight($statusColumn))
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "ConfigureStartPins" /t REG_SZ /d '{\"pinnedList\": [{}]}' /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_SZ /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg delete "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions" /f 2>&1 | Write-Log
reg delete "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable Telemetry
Write-Host -NoNewline ("  Disabling Telemetry".PadRight($statusColumn))
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" /v "HasAccepted" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice" /v "Start" /t REG_DWORD /d "4" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable Recall on first logon
if ($buildNumber -ge 22000) {
    Write-Host -NoNewline ("  Disabling Recall".PadRight($statusColumn))
    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "DisableRecall" /t REG_SZ /d "dism.exe /online /disable-feature /FeatureName:recall" /f 2>&1 | Write-Log
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f 2>&1 | Write-Log
    Write-Host "[DONE]" -ForegroundColor Green
}

# Disable Mouse Acceleration
Write-Host -NoNewline ("  Disabling Mouse Acceleration".PadRight($statusColumn))
reg add "HKLM\zNTUSER\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable Meet Now icon
Write-Host -NoNewline ("  Disabling Meet".PadRight($statusColumn))
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "AllowOnlineTips" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable Ads and Stuffs
Write-Host -NoNewline ("  Disabling Ads and Stuffs".PadRight($statusColumn))
# Disable ad tailoring
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
# Disable cloud-based content
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableConsumerAccountStateContent" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
# Disable Start Menu Suggestions
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
# Disable News and Interest
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
# Remove Spotlight icon from Desktop
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
# Disable Cortana
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
# Changes MenuShowDelay from 400 to 200
reg add "HKLM\zNTUSER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "200" /f 2>&1 | Write-Log
# Disable everytime MRT download through Win Update
reg add "HKLM\zSOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUAU" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable Bitlocker
Write-Host -NoNewline ("  Disabling Bitlocker Encryption".PadRight($statusColumn))
reg add "HKLM\zSYSTEM\ControlSet001\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable OneDrive Stuffs
Write-Host -NoNewline ("  Removing OneDrive Junks".PadRight($statusColumn))
reg delete "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableLibrariesDefaultSaveToOneDrive" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Policies\Microsoft\OneDrive" /v "KFMBlockOptIn" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable GameDVR
Write-Host -NoNewline ("  Disabling GameDVR and Components".PadRight($statusColumn))
reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zNTUSER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f 2>&1 | Write-Log
reg add "HKLM\zSYSTEM\ControlSet001\Services\BcastDVRUserService" /v "Start" /t REG_DWORD /d 4 /f 2>&1 | Write-Log
reg add "HKLM\zSYSTEM\ControlSet001\Services\GameBarPresenceWriter" /v "Start" /t REG_DWORD /d 4 /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Remove Gamebar Popup
# Courtesy: https://pastebin.com/EAABLssA by aveyo
Write-Host -NoNewline ("  Removing Gamebar Popup".PadRight($statusColumn))
reg add "HKLM\zNTUSER\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f 2>&1 | Write-Log
# Rest added as post install script. Somehow, implementing it directly on the image was causing corruption
Write-Host "[DONE]" -ForegroundColor Green

# # Configure GameBarFTServer (NA)
# $packageKey = "HKLM\zSOFTWARE\Classes\PackagedCom\ClassIndex\{FD06603A-2BDF-4BB1-B7DF-5DC68F353601}"
# $app = (Get-Item "Registry::$packageKey").PSChildName
# reg add "HKLM\zSOFTWARE\Classes\PackagedCom\Package\$app\Server\0" /v "Executable" /t REG_SZ /d "systray.exe" /f 2>&1 | Write-Log

# Enabling Local Account Creation
Write-Host -NoNewline ("  Tweaking OOBE Settings".PadRight($statusColumn))
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OOBE" /v "DisablePrivacyExperience" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNROGatherOptions" /t REG_DWORD /d "1" /f 2>&1 | Write-Log

# Check if Autounattend.xml exists before copying
if (Test-Path -Path $autounattendXmlPath) {
    Write-Log -msg "Copying Autounattend.xml"
    Copy-Item -Path $autounattendXmlPath -Destination $destinationPath -Force
} else {
    Write-Host "Warning: Autounattend.xml not found at $autounattendXmlPath" -ForegroundColor Yellow
    Write-Log -msg "Warning: Autounattend.xml not found at $autounattendXmlPath"
}
Write-Host "[DONE]" -ForegroundColor Green

# Prevents Dev Home Installation
Write-Host -NoNewline ("  Disabling useless junks".PadRight($statusColumn))
reg delete "HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate" /v "workCompleted" /t REG_DWORD /d "1" /f 2>&1 | Write-Log

# Prevents New Outlook for Windows Installation
reg delete "HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate" /v "workCompleted" /t REG_DWORD /d "1" /f 2>&1 | Write-Log

# Prevents Chat Auto Installation
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v "ConfigureChatAutoInstall" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t REG_DWORD /d "3" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable Scheduled Tasks
Write-Host -NoNewline ("  Disabling Scheduled Tasks".PadRight($statusColumn))
$win24H2 = (Get-ItemProperty -Path 'Registry::HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name DisplayVersion).DisplayVersion -eq '24H2'
if ($win24H2) {
    # Customer Experience Improvement Program
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{780E487D-C62F-4B55-AF84-0E38116AFE07}" /f 2>&1 | Write-Log
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FD607F42-4541-418A-B812-05C32EBA8626}" /f 2>&1 | Write-Log
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{E4FED5BC-D567-4044-9642-2EDADF7DE108}" /f 2>&1 | Write-Log
    # Program Data Updater
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{E292525C-72F1-482C-8F35-C513FAA98DAE}" /f 2>&1 | Write-Log
    # Application Compatibility Appraiser
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{3047C197-66F1-4523-BA92-6C955FEF9E4E}" /f 2>&1 | Write-Log
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{A0C71CB8-E8F0-498A-901D-4EDA09E07FF4}" /f 2>&1 | Write-Log
}
else {
    # Customer Experience Improvement Program
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{4738DE7A-BCC1-4E2D-B1B0-CADB044BFA81}" /f 2>&1 | Write-Log
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{6FAC31FA-4A85-4E64-BFD5-2154FF4594B3}" /f 2>&1 | Write-Log
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FC931F16-B50A-472E-B061-B6F79A71EF59}" /f 2>&1 | Write-Log
    # Program Data Updater
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0671EB05-7D95-4153-A32B-1426B9FE61DB}" /f 2>&1 | Write-Log
    # Application Compatibility Appraiser
    reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0600DD45-FAF2-4131-A006-0B17509B9F78}" /f 2>&1 | Write-Log
}
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\PcaPatchDbTask" /f 2>&1 | Write-Log
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\MareBackup" /f 2>&1 | Write-Log
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /f 2>&1 | Write-Log
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Autochk\Proxy" /f 2>&1 | Write-Log
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /f 2>&1 | Write-Log
reg delete "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /f 2>&1 | Write-Log
Write-Host "[DONE]" -ForegroundColor Green

# Disable TPM CHeck

if ($DoTPMBypass) {
    Write-Host ("`n[INFO] Disabling TPM Check...") -ForegroundColor Cyan
    Write-Log -msg "Disabling TPM Check"
    reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
    reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
    reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
    reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
    reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
    reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassDiskCheck" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
    reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
    
    # Disable Unsupported Hardware Watermark
    reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
    reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
    reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
    reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        $bootWimPath = Join-Path $destinationPath "sources\boot.wim"
        $bootMountDir = "$env:SystemDrive\WIDTemp\mountdir\bootWIM"
        New-Item -ItemType Directory -Path $bootMountDir 2>&1 | Write-Log
        Mount-WindowsImage -ImagePath $bootWimPath -Index 2 -Path $bootMountDir 2>&1 | Write-Log

        reg load HKLM\xDEFAULT "$bootMountDir\Windows\System32\config\default" 2>&1 | Write-Log
        reg load HKLM\xNTUSER "$bootMountDir\Users\Default\ntuser.dat" 2>&1 | Write-Log
        reg load HKLM\xSYSTEM "$bootMountDir\Windows\System32\config\SYSTEM" 2>&1 | Write-Log

        reg add "HKLM\xSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d 1 /f 2>&1 | Write-Log
        reg add "HKLM\xSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d 1 /f 2>&1 | Write-Log
        reg add "HKLM\xSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d 1 /f 2>&1 | Write-Log
        reg add "HKLM\xSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d 1 /f 2>&1 | Write-Log
        reg add "HKLM\xSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d 1 /f 2>&1 | Write-Log
        reg add "HKLM\xSYSTEM\Setup\LabConfig" /v "BypassDiskCheck" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
        reg add "HKLM\xSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d 1 /f 2>&1 | Write-Log
        reg add "HKLM\xDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\xDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f 2>&1 | Write-Log

        reg unload HKLM\xDEFAULT 2>&1 | Write-Log
        reg unload HKLM\xNTUSER 2>&1 | Write-Log
        reg unload HKLM\xSYSTEM 2>&1 | Write-Log

        Dismount-WindowsImage -Path $bootMountDir -Save 2>&1 | Write-Log
        Write-Host ("[OK] TPM Bypass Successful") -ForegroundColor Green
        Write-Log -msg "Successfully modified boot.wim for TPM Bypass"
    }
    catch {
        Write-Log -msg "Failed to mount boot.wim: $_"
    }
    finally {
        $ProgressPreference = 'Continue'
    }
}
else {
    Write-Log -msg "TPM Bypass cancelled"
}

# Bring back user folders
if ($buildNumber -ge 22000) {
    if ($DoUserFoldersEnable) {
        Write-Host ("`n[INFO] Restoring User Folders...") -ForegroundColor Cyan

        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f 2>&1 | Write-Log

        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /v "HideIfEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log

        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /v "HiddenByDefault" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
        
        Write-Host ("[OK] User Folders Restored") -ForegroundColor Green
        Write-Log -msg "User folders restored successfully"
    } else {
        Write-Log -msg "User folders restoration cancelled"
    }
}

Write-Host ("`n[INFO] Unloading Registry...") -ForegroundColor Cyan
Write-Log -msg "Unloading registry"
reg unload HKLM\zCOMPONENTS 2>&1 | Write-Log
reg unload HKLM\zDEFAULT 2>&1 | Write-Log
reg unload HKLM\zNTUSER 2>&1 | Write-Log
reg unload HKLM\zSOFTWARE 2>&1 | Write-Log
reg unload HKLM\zSYSTEM 2>&1 | Write-Log
Write-Host ("[OK] Success") -ForegroundColor Green

# Unmounting and cleaning up the image
Write-Host ("`n[INFO] Cleaning up image...") -ForegroundColor Cyan
Write-Log -msg "Cleaning up image"
Repair-WindowsImage -Path $installMountDir -StartComponentCleanup -ResetBase 2>&1 | Write-Log

Write-Host ("`n[INFO] Unmounting and Exporting image...") -ForegroundColor Cyan
Write-Log -msg "Unmounting image"
try {
    Dismount-WindowsImage -Path $installMountDir -Save 2>&1 | Write-Log
    Write-Log -msg "Image unmounted successfully"
}
catch {
    Write-Host "`n`nFailed to Unmount the Image. Check Logs for more info." -ForegroundColor Red
    Write-Host "Close all the Folders opened in the mountdir to complete the Script."
    Write-Host "Run the following code in Powershell(as admin) to unmount the broken image: "
    Write-Host "Dismount-WindowsImage -Path $installMountDir -Discard" -ForegroundColor Yellow
    Write-Log -msg "Failed to unmount image: $_"
    Pause
    Exit
}

Write-Log -msg "Exporting image"
$tempWimPath = "$destinationPath\sources\install_temp.wim"
$exportSuccess = $false

if ($DoESDConvert) {
    Write-Host ("`n[INFO] Compressing image to esd...") -ForegroundColor Cyan
    try {        
        $process = Start-Process -FilePath "dism.exe" -ArgumentList "/Export-Image /SourceImageFile:`"$destinationPath\sources\install.wim`" /SourceIndex:$sourceIndex /DestinationImageFile:`"$tempWimPath`" /Compress:Recovery /CheckIntegrity" -Wait -NoNewWindow -PassThru
        if ($process.ExitCode -eq 0 -and (Test-Path $tempWimPath)) {
            $exportSuccess = $true
            Write-Host ("[OK] Compression completed") -ForegroundColor Green
            Write-Log -msg "Compression completed"
        } else {
            Write-Host "Compression failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            Write-Log -msg "Compression failed with exit code: $($process.ExitCode)"
        }
    } catch {
        Write-Host "Compression failed with error: $_" -ForegroundColor Red
        Write-Log -msg "Compression failed with error: $_"
    }
}
else {
    Write-Host ("`n[INFO] Exporting image to wim...") -ForegroundColor Cyan
    try {
        Export-WindowsImage -SourceImagePath "$destinationPath\sources\install.wim" -SourceIndex $sourceIndex -DestinationImagePath $tempWimPath -CompressionType Maximum -CheckIntegrity 2>&1 | Write-Log
        if (Test-Path $tempWimPath) {
            $exportSuccess = $true
            Write-Host ("[OK] Export completed successfully") -ForegroundColor Green
            Write-Log -msg "Export completed successfully"
        } else {
            Write-Host "Export failed - temp WIM not found" -ForegroundColor Red
            Write-Log -msg "Export failed - temp WIM not found"
        }
    } catch {
        Write-Host "Export failed with error: $_" -ForegroundColor Red
        Write-Log -msg "Export failed with error: $_"
    }
}

if ($exportSuccess) {
    Remove-Item -Path "$destinationPath\sources\install.wim" -Force
    Move-Item -Path $tempWimPath -Destination "$destinationPath\sources\install.wim" -Force
   
    if (-not (Test-Path "$destinationPath\sources\install.wim")) {
        Write-Host "Error: Unable to create the WIM file. Check logs for details." -ForegroundColor Red
        Write-Log -msg "Final install.wim missing"
        Pause
        Exit
    } else {
        Write-Log -msg "WIM file successfully replaced"
    }
} else {
    Write-Host "Error: Unable to export modified WIM file. Check logs for details." -ForegroundColor Yellow
    Write-Log -msg "WIM export failed, original WIM file preserved"
    Pause
    Exit
}

# Verify the WIM file is accessible and valid
try {
    $wimPath = Get-WindowsImage -ImagePath "$destinationPath\sources\install.wim" -ErrorAction Stop
    if ($wimPath) {
        Write-Host ("[OK] WIM file validation successful: $($wimPath.Count) images found") -ForegroundColor Green
        Write-Log -msg "WIM validation passed: $($wimPath.Count) images found"
        
        # Force a filesystem sync to ensure all changes are written to disk
        [System.IO.File]::OpenWrite("$destinationPath\sources\install.wim").Close()
        # Add a small delay to ensure file operations are complete
        Start-Sleep -Seconds 3
    } else {
        Write-Host "Warning: WIM file validation returned no images" -ForegroundColor Yellow
        Write-Log -msg "WIM validation warning: No images returned"
    }
} catch {
    Write-Host "Error: WIM file validation failed - $($_)" -ForegroundColor Red
    Write-Log -msg "WIM validation failed: $_"
}

Write-Log -msg "Checking required files"
if ($outputiso) { $ISOFileName = [System.IO.Path]::GetFileNameWithoutExtension($outputiso) }
else { $ISOFileName = Read-Host -Prompt "`nEnter the name for the ISO file (without extension)" }
$ISOFile = Join-Path -Path $scriptDirectory -ChildPath "$ISOFileName.iso"

if ($DoUseOscdimg) {
    if (-not (Test-Path -Path $Oscdimg)) {
        Write-Log -msg "Oscdimg.exe not found at '$Oscdimg'"
        Write-Host "`nOscdimg.exe not found at '$Oscdimg'." -ForegroundColor Red
        Write-Host "`nTrying to Download oscdimg.exe..." -ForegroundColor Cyan

        # Function to check internet connection
        function Test-InternetConnection {
            param (
                [int]$maxAttempts = 3,
                [int]$retryDelay = 5,
                [string]$hostname = "1.1.1.1", # Cloudflare DNS
                [int]$port = 53,
                [int]$timeout = 5000
            )
            for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
                try {
                    $client = [Net.Sockets.TcpClient]::new()
                    if ($client.ConnectAsync($hostname, $port).Wait($timeout)) {
                        $client.Close(); return $true
                    }
                    $client.Close()
                } catch {}
                Write-Host "Internet connection not available, Trying in $retryDelay seconds..."
                Start-Sleep -Seconds $retryDelay
            }  
            Write-Host "`nInternet connection not available after $maxAttempts attempts." -ForegroundColor Red
            Write-Host "A working internet connection is required to download oscdimg.exe."
            Write-Host "Check your connection and try again."

            while ($true) {
                $internetChoice = Read-Host -Prompt "`nPress 't' to try again or 'q' to quit"
                switch ($internetChoice.ToLower()) {
                    't' { return Test-InternetConnection @PSBoundParameters }
                    'q' {
                        Remove-TempFiles
                        Exit
                    }
                    default { Write-Host "Invalid input. Enter 't' or 'q'." }
                }
            }
        }
        
        Test-InternetConnection

        # Downloading Oscdimg.exe
        # Courtesy: https://github.com/p0w3rsh3ll/ADK
        $ADKfolder = "$scriptDirectory\ADKDownload"
        $CabFileName = "5d984200acbde182fd99cbfbe9bad133.cab"
        $ExtractedFileName = "fil720cc132fbb53f3bed2e525eb77bdbc1"

        New-Item -ItemType Directory -Path $OscdimgPath -Force 2>&1 | Write-Log
        New-Item -ItemType Directory -Path $ADKfolder -Force 2>&1 | Write-Log
        
        # Resolve the URL
        $RedirectResponse = Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2290227" -MaximumRedirection 0 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($RedirectResponse.StatusCode -eq 302) {
            $BaseURL = $RedirectResponse.Headers.Location.TrimEnd('/') + "/"
            $CabURL = "$BaseURL`Installers/$CabFileName"
            $CabFilePath = "$ADKfolder\$CabFileName"
        
            Write-Log -msg "Downloading CAB file from: $CabURL"
            Invoke-WebRequest -Uri $CabURL -OutFile $CabFilePath -UseBasicParsing
        
            # Extract the CAB file
            Write-Log -msg "Extracting CAB file..."
            expand.exe -F:* $CabFilePath $ADKfolder 2>&1 | Write-Log
        
            # Move the required file
            $ExtractedFilePath = "$ADKfolder\$ExtractedFileName"
            $FinalFilePath = "$OscdimgPath\oscdimg.exe"
        
            if (Test-Path $ExtractedFilePath) {
                Move-Item -Path $ExtractedFilePath -Destination $FinalFilePath -Force 2>&1 | Write-Log
                Write-Host "Oscdimg.exe downloaded successfully" -ForegroundColor Green
                Write-Log -msg "Oscdimg.exe successfully placed in: $OscdimgPath"
            }
            else {
                Write-Log -msg "Error: Extracted file not found!"
            }
        }
        else {
            Write-Host "Error: Failed to download Oscdimg.exe" -ForegroundColor Red
            Write-Log -msg "Failed to resolve ADK download link. HTTP Status: $($RedirectResponse.StatusCode)"
            Remove-TempFiles
            Pause
            Exit
        }
    }

    # Generate ISO
    Write-Host ("`n[INFO] Generating ISO...") -ForegroundColor Cyan
    Write-Log -msg "Generating ISO using OSCDIMG"
    try {
        $etfsbootPath = "$destinationPath\boot\etfsboot.com"
        $efisysPath = "$destinationPath\efi\Microsoft\boot\efisys.bin"
        $bootData = "2#p0,e,b`"$etfsbootPath`"#pEF,e,b`"$efisysPath`""
        Write-Log -msg "Boot data set: $bootData"
        
        $oscdimgArgs = @(
            "-bootdata:$bootData",
            "-m",               # Ignore maximum size limit
            "-o",               # Optimize for space
            "-h",               # Show hidden files
            "-u2",              # UDF 2.0
            "-udfver102",       # UDF version 1.02
            "-l$ISOFileName",   # Set volume label
            "`"$destinationPath`"",
            "`"$ISOFile`""
        )
        
        Write-Log -msg "OSCDIMG command: $Oscdimg $($oscdimgArgs -join ' ')"
        $oscdimgProcess = Start-Process -FilePath "$Oscdimg" -ArgumentList $oscdimgArgs -PassThru -Wait -NoNewWindow
        
        if ($oscdimgProcess.ExitCode -eq 0) {
            Write-Host ("[OK] ISO creation successful") -ForegroundColor Green
            Write-Log -msg "ISO successfully created with exit code 0"
        } else {
            Write-Host "Warning: ISO creation finished with errors" -ForegroundColor Yellow
            Write-Log -msg "OSCDIMG exited with code: $($oscdimgProcess.ExitCode)"
        }
    }
    catch {
        Write-Log -msg "Failed to generate ISO with exit code: $_"
    }
}
else {
    Write-Host "`n[INFO] Preparing ISO creation..." -ForegroundColor Cyan
    Write-Log -msg "Preparing ISO creation"

    # ISOWriter class
    # More Here: https://learn.microsoft.com/en-us/windows/win32/api/_imapi/
    if (!('ISOWriter' -as [Type])) {
        Add-Type -TypeDefinition @'
        using System;
        using System.Runtime.InteropServices;
        using System.Runtime.InteropServices.ComTypes;

        public class ISOWriter {
            [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, ExactSpelling = true, PreserveSig = false)]
            private static extern void SHCreateStreamOnFileEx(string fileName, uint mode, uint attributes, bool create, IStream streamNull, out IStream stream);
            public static bool Create(string filePath, ref object imageStream, int blockSize, int totalBlocks) {IStream resultStream = (IStream)imageStream, imageFile; SHCreateStreamOnFileEx(filePath, 0x1001, 0x80, true, null, out imageFile); const int bufferSize = 1024; int remainingBlocks = totalBlocks;
                while (remainingBlocks > 0) { int blocksToWrite = Math.Min(remainingBlocks, bufferSize); resultStream.CopyTo(imageFile, blocksToWrite * blockSize, IntPtr.Zero, IntPtr.Zero); remainingBlocks -= blocksToWrite;}
                imageFile.Commit(0);
                return true;}
        }
'@
    }

    try {
        $comObjects = @()

        # Initialize boot configuration
        $bootStream = New-Object -ComObject ADODB.Stream -Property @{ Type = 1 }
        $comObjects += $bootStream
        $bootStream.Open()
        $bootStream.LoadFromFile("$destinationPath\efi\Microsoft\boot\efisys.bin")
        # $bootStream.LoadFromFile("$destinationPath\efi\Microsoft\boot\efisys_noprompt.bin")

        # Configure boot and filesystem
        $bootOptions = New-Object -ComObject IMAPI2FS.BootOptions -Property @{
            PlatformId = 0xEF
            Manufacturer = "Microsoft"
            Emulation = 0
        }
        $comObjects += $bootOptions
        $bootOptions.AssignBootImage($bootStream)

        $FSImage = New-Object -ComObject IMAPI2FS.MsftFileSystemImage -Property @{
            FileSystemsToCreate = 4
            UDFRevision = 0x102
            FreeMediaBlocks = 0
            VolumeName = $ISOFileName
        }
        $comObjects += $FSImage
        
        Write-Log -msg "Creating ISO structure"
        $FSImage.Root.AddTree($destinationPath, $false)
        $FSImage.BootImageOptions = $bootOptions
        
        Write-Host "[INFO] Generating ISO..." -ForegroundColor Cyan
        Write-Log -msg "Generating ISO using ISOWriter"
        $resultImage = $FSImage.CreateResultImage()
        $comObjects += $resultImage

        [ISOWriter]::Create($ISOFile, [ref]$resultImage.ImageStream, $resultImage.BlockSize, $resultImage.TotalBlocks) | Out-Null
        
        if ((Get-Item $ISOFile).Length -eq ($resultImage.BlockSize * $resultImage.TotalBlocks)) {
            Write-Log -msg "ISO successfully created at: $ISOFile"
        }
    }
    catch {
        Write-Log -msg "ISO creation failed: $_" -Type Error
    }
    finally {
        foreach ($obj in $comObjects) {
            if ($obj) { 
                while ([Runtime.InteropServices.Marshal]::ReleaseComObject($obj) -gt 0) { }
            }
        }
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        Write-Host "[OK] ISO creation successful" -ForegroundColor Green
    }
}

# ISO verification
if (Test-Path -Path $ISOFile) {
    try {
        $verifyMntResult = Mount-DiskImage -ImagePath "$ISOFile" -PassThru
        $verifyDrive = ($verifyMntResult | Get-Volume).DriveLetter
        $isoMountPoint = "${verifyDrive}:\"
        $reqFiles = @("sources\install.wim", "sources\boot.wim", "boot\bcd", "boot\boot.sdi", "bootmgr", "bootmgr.efi", "efi\microsoft\boot\efisys.bin")
        $missingFiles = $reqFiles | Where-Object { -not (Test-Path (Join-Path $isoMountPoint $_)) }

        Dismount-DiskImage -ImagePath "$ISOFile" 2>&1 | Write-Log

        if ($missingFiles) {
            Write-Host "`nError: Created ISO is missing critical files" -ForegroundColor Red
            Write-Log -msg "ISO verification failed - missing files: $($missingFiles -join ', ')"
        }
        else {
            Write-Host "`nScript Completed. Can find the ISO in `"$scriptDirectory`"" -ForegroundColor Green
            Write-Log -msg "ISO verification successful"
        }
    }
    catch {
        Write-Host "`nUnable to verify ISO integrity" -ForegroundColor Yellow
        Write-Log -msg "Failed to verify ISO: $_"
    }
} else {
    Write-Host "`nError: ISO file wasn't created" -ForegroundColor Red
    Write-Log -msg "ISO file wasn't created"
}

# Remove temporary files
Write-Log -msg "Removing temporary files"
try {
    Remove-TempFiles
}
catch {
    Write-Log -msg "Failed to remove temporary files: $_"
}
finally {
    Write-Log -msg "Script completed"
}

Write-Host
Pause