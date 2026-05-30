# Win11DebloatTweaks.ps1
# Additional registry tweaks inspired by Raphire/Win11Debloat
# These are adapted for offline WIM image modification (registry hive-based)
# Source: https://github.com/Raphire/Win11Debloat (MIT License)

function Apply-Win11DebloatTweaks {
    <#
    .SYNOPSIS
        Applies additional Win11Debloat-style tweaks to the mounted WIM image.
    .PARAMETER MountPath
        Path to the mounted Windows image.
    .PARAMETER Tweaks
        Array of tweak names to apply. Use "All" for everything.
    .PARAMETER StatusColumn
        Column width for status display alignment.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$MountPath,
        [string[]]$Tweaks = @("All"),
        [int]$StatusColumn = 60
    )

    $allTweaks = @(
        "DisableSearchHighlights",
        "DisableSuggestions",
        "DisableLocationServices",
        "DisableFindMyDevice",
        "DisableFastStartup",
        "DisableStorageSense",
        "DisableUpdateASAP",
        "PreventUpdateAutoReboot",
        "DisableDeliveryOptimization",
        "DisableEdgeAds",
        "DisableCopilotCompletely",
        "DisableWidgets",
        "DisableSnapAssist",
        "RevertContextMenu",
        "ShowKnownFileExt",
        "ShowHiddenFolders",
        "HideTaskview",
        "TaskbarAlignLeft",
        "EnableDarkMode",
        "EnableEndTask",
        "HideSearchTb",
        "HideGallery",
        "DisableStickyKeys",
        "DisableDesktopSpotlight",
        "DisableReservedStorage",
        "DisablePushToInstall",
        "RemoveScheduledTaskFiles"
    )

    if ($Tweaks -contains "All") { $Tweaks = $allTweaks }

    Write-Host "`n[INFO] Applying Win11Debloat tweaks..." -ForegroundColor Cyan
    Write-Log -msg "Applying Win11Debloat-style tweaks: $($Tweaks -join ', ')"

    foreach ($tweak in $Tweaks) {
        $displayName = "  $tweak"
        Write-Host -NoNewline ($displayName.PadRight($StatusColumn))

        try {
            switch ($tweak) {
                "DisableSearchHighlights" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableSuggestions" {
                    # Disable Windows suggestions, tips and tricks notifications
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    # Disable "Get the most out of Windows" nag
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310091Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableLocationServices" {
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocationScripting" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f 2>&1 | Write-Log
                }
                "DisableFindMyDevice" {
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\FindMyDevice" /v "AllowFindMyDevice" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableFastStartup" {
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableStorageSense" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableUpdateASAP" {
                    reg add "HKLM\zSOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "IsContinuousInnovationOptedIn" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "PreventUpdateAutoReboot" {
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableDeliveryOptimization" {
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableEdgeAds" {
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Edge" /v "PersonalizationReportingEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Edge" /v "ShowRecommendationsEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Edge" /v "HideFirstRunExperience" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Edge" /v "NewTabPageContentEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Edge" /v "NewTabPageQuickLinksEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Edge" /v "DiagnosticData" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableCopilotCompletely" {
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableWidgets" {
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableSnapAssist" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapAssist" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "RevertContextMenu" {
                    # Restore classic Windows 10 context menu
                    reg add "HKLM\zSOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f 2>&1 | Write-Log
                }
                "ShowKnownFileExt" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "ShowHiddenFolders" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "HideTaskview" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "TaskbarAlignLeft" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "EnableDarkMode" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "EnableEndTask" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v "TaskbarEndTask" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "HideSearchTb" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "HideGallery" {
                    reg add "HKLM\zNTUSER\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableStickyKeys" {
                    reg add "HKLM\zNTUSER\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f 2>&1 | Write-Log
                }
                "DisableDesktopSpotlight" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableSpotlightCollectionOnDesktop" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableReservedStorage" {
                    # From tiny11builder: Disable Reserved Storage to save ~7GB
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v "ShippedWithReserves" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisablePushToInstall" {
                    # From tiny11builder: Disable Push-to-Install service
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall" /v "DisablePushToInstall" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    # Disable FeatureManagement auto-install
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "RemoveScheduledTaskFiles" {
                    # From tiny11builder: Physically remove scheduled task definition files
                    $tasksBasePath = "$MountPath\Windows\System32\Tasks"
                    $taskFilesToRemove = @(
                        "$tasksBasePath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
                        "$tasksBasePath\Microsoft\Windows\Application Experience\ProgramDataUpdater",
                        "$tasksBasePath\Microsoft\Windows\Customer Experience Improvement Program",
                        "$tasksBasePath\Microsoft\Windows\Chkdsk\Proxy",
                        "$tasksBasePath\Microsoft\Windows\Windows Error Reporting\QueueReporting"
                    )
                    foreach ($taskPath in $taskFilesToRemove) {
                        if (Test-Path $taskPath) {
                            Remove-Item -Path $taskPath -Recurse -Force -ErrorAction SilentlyContinue
                            Write-Log -msg "Removed task file: $taskPath"
                        }
                    }
                }
                default {
                    Write-Host "[SKIPPED]" -ForegroundColor DarkGray
                    Write-Log -msg "Unknown tweak: $tweak"
                    continue
                }
            }
            Write-Host "[DONE]" -ForegroundColor Green
            Write-Log -msg "Applied tweak: $tweak"
        }
        catch {
            Write-Host "[ERROR]" -ForegroundColor Red
            Write-Log -msg "Failed to apply tweak $tweak`: $_"
        }
    }

    Write-Host ("[OK] Win11Debloat tweaks applied") -ForegroundColor Green
    Write-Log -msg "Win11Debloat tweaks completed"
}

function Get-AvailableWin11Tweaks {
    <#
    .SYNOPSIS
        Returns a list of available Win11Debloat tweaks with descriptions.
    #>
    return @(
        @{ Name = "DisableSearchHighlights"; Description = "Disable search highlights and dynamic content" }
        @{ Name = "DisableSuggestions"; Description = "Disable tips, tricks & suggested content" }
        @{ Name = "DisableLocationServices"; Description = "Disable Windows location services" }
        @{ Name = "DisableFindMyDevice"; Description = "Disable Find My Device tracking" }
        @{ Name = "DisableFastStartup"; Description = "Disable fast start-up (hibernation boot)" }
        @{ Name = "DisableStorageSense"; Description = "Disable automatic disk cleanup" }
        @{ Name = "DisableUpdateASAP"; Description = "Prevent getting updates as soon as available" }
        @{ Name = "PreventUpdateAutoReboot"; Description = "Prevent auto-restart after updates" }
        @{ Name = "DisableDeliveryOptimization"; Description = "Disable P2P update sharing" }
        @{ Name = "DisableEdgeAds"; Description = "Disable ads and suggestions in Edge" }
        @{ Name = "DisableCopilotCompletely"; Description = "Fully disable Microsoft Copilot" }
        @{ Name = "DisableWidgets"; Description = "Disable widgets on taskbar & lock screen" }
        @{ Name = "DisableSnapAssist"; Description = "Disable snap assist suggestions" }
        @{ Name = "RevertContextMenu"; Description = "Restore classic Win10 context menu" }
        @{ Name = "ShowKnownFileExt"; Description = "Show file extensions for known types" }
        @{ Name = "ShowHiddenFolders"; Description = "Show hidden files and folders" }
        @{ Name = "HideTaskview"; Description = "Hide Task View button from taskbar" }
        @{ Name = "TaskbarAlignLeft"; Description = "Align taskbar icons to the left" }
        @{ Name = "EnableDarkMode"; Description = "Enable dark theme for system and apps" }
        @{ Name = "EnableEndTask"; Description = "Show End Task in taskbar right-click" }
        @{ Name = "HideSearchTb"; Description = "Hide search from taskbar" }
        @{ Name = "HideGallery"; Description = "Hide Gallery from File Explorer" }
        @{ Name = "DisableStickyKeys"; Description = "Disable Sticky Keys shortcut" }
        @{ Name = "DisableDesktopSpotlight"; Description = "Disable Windows Spotlight on desktop" }
        @{ Name = "DisableReservedStorage"; Description = "Disable Reserved Storage (~7GB saved)" }
        @{ Name = "DisablePushToInstall"; Description = "Disable Push-to-Install and FeatureManagement" }
        @{ Name = "RemoveScheduledTaskFiles"; Description = "Remove telemetry scheduled task files" }
    )
}
