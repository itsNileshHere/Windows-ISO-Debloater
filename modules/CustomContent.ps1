# CustomContent.ps1
# Handles custom wallpaper, Start Menu layout, and other content injection

function Set-CustomWallpaper {
    <#
    .SYNOPSIS
        Replaces the default Windows wallpaper in the mounted image.
    .PARAMETER MountPath
        Path to the mounted Windows image.
    .PARAMETER WallpaperPath
        Path to the custom wallpaper image file (jpg/png).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$MountPath,
        [Parameter(Mandatory=$true)][string]$WallpaperPath
    )

    if (-not (Test-Path $WallpaperPath)) {
        Write-Host "  Wallpaper file not found: $WallpaperPath" -ForegroundColor Red
        Write-Log -msg "Custom wallpaper not found: $WallpaperPath"
        return
    }

    Write-Host "  Setting custom wallpaper..." -ForegroundColor DarkGray

    # Default wallpaper location
    $defaultWallpaperDir = Join-Path $MountPath "Windows\Web\Wallpaper\Windows"
    $default4kDir = Join-Path $MountPath "Windows\Web\4K\Wallpaper\Windows"

    # Copy wallpaper as img0.jpg (default wallpaper)
    $ext = [System.IO.Path]::GetExtension($WallpaperPath)
    $destFile = Join-Path $defaultWallpaperDir "img0$ext"

    if (Test-Path $defaultWallpaperDir) {
        Copy-Item -Path $WallpaperPath -Destination $destFile -Force
        Write-Log -msg "Custom wallpaper set: $destFile"
    }

    # Also set as lockscreen
    $lockscreenDir = Join-Path $MountPath "Windows\Web\Screen"
    if (Test-Path $lockscreenDir) {
        Copy-Item -Path $WallpaperPath -Destination (Join-Path $lockscreenDir "img100$ext") -Force
        Write-Log -msg "Custom lockscreen set"
    }

    Write-Host "  [OK] Custom wallpaper applied" -ForegroundColor Green
}

function Set-CleanStartMenu {
    <#
    .SYNOPSIS
        Injects a clean Start Menu layout with no pinned apps.
    .PARAMETER MountPath
        Path to the mounted Windows image.
    #>
    param([Parameter(Mandatory=$true)][string]$MountPath)

    Write-Host "  Clearing Start Menu pins..." -ForegroundColor DarkGray

    # Empty start menu layout JSON for Windows 11
    $startLayout = @'
{
    "pinnedList": []
}
'@

    # For all existing users and default profile
    $layoutPath = Join-Path $MountPath "Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"

    if (-not (Test-Path $layoutPath)) {
        New-Item -ItemType Directory -Path $layoutPath -Force | Out-Null
    }

    $startLayout | Out-File -FilePath (Join-Path $layoutPath "start2.bin") -Encoding UTF8 -Force
    Write-Log -msg "Clean Start Menu layout injected"

    # Also set via registry policy
    reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "ConfigureStartPins" /t REG_SZ /d $startLayout /f 2>&1 | Write-Log
    reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "ConfigureStartPins_ProviderSet" /t REG_DWORD /d "1" /f 2>&1 | Write-Log

    Write-Host "  [OK] Start Menu cleared" -ForegroundColor Green
}

function Set-CustomUnattend {
    <#
    .SYNOPSIS
        Generates a custom autounattend.xml with specified settings.
    .PARAMETER DestinationPath
        Path to the ISO working directory.
    .PARAMETER ComputerName
        Computer name to set (optional).
    .PARAMETER TimeZone
        Time zone string (optional).
    .PARAMETER Locale
        System locale (optional).
    .PARAMETER SkipOOBE
        Skip all OOBE screens.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$DestinationPath,
        [string]$ComputerName = "",
        [string]$TimeZone = "",
        [string]$Locale = "",
        [switch]$SkipOOBE
    )

    Write-Host "  Generating custom autounattend.xml..." -ForegroundColor DarkGray

    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <HideLocalAccountScreen>false</HideLocalAccountScreen>
                <HideEULAPage>$(if ($SkipOOBE) {'true'} else {'false'})</HideEULAPage>
                <NetworkLocation>Home</NetworkLocation>
                <SkipMachineOOBE>$(if ($SkipOOBE) {'true'} else {'false'})</SkipMachineOOBE>
                <SkipUserOOBE>$(if ($SkipOOBE) {'true'} else {'false'})</SkipUserOOBE>
            </OOBE>
$(if ($ComputerName) { "            <ComputerName>$ComputerName</ComputerName>" })
$(if ($TimeZone) { "            <TimeZone>$TimeZone</TimeZone>" })
        </component>
    </settings>
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <UserData>
                <ProductKey>
                    <Key></Key>
                    <WillShowUI>Always</WillShowUI>
                </ProductKey>
                <AcceptEula>true</AcceptEula>
            </UserData>
$(if ($Locale) { "            <UILanguage>$Locale</UILanguage>" })
        </component>
    </settings>
</unattend>
"@

    $unattendPath = Join-Path $DestinationPath "autounattend.xml"
    $xml | Out-File -FilePath $unattendPath -Encoding UTF8 -Force
    Write-Log -msg "Custom autounattend.xml generated at: $unattendPath"
    Write-Host "  [OK] Custom autounattend.xml created" -ForegroundColor Green
}
