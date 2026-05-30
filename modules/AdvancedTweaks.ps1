# AdvancedTweaks.ps1
# Advanced system tweaks for offline WIM modification
# Includes: Services, Power, Network, Defender, Hibernation, Notifications

function Apply-AdvancedTweaks {
    <#
    .SYNOPSIS
        Applies advanced system tweaks to the mounted WIM image.
    .PARAMETER MountPath
        Path to the mounted Windows image.
    .PARAMETER Tweaks
        Array of tweak names to apply.
    .PARAMETER StatusColumn
        Column width for status display alignment.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$MountPath,
        [string[]]$Tweaks = @(),
        [int]$StatusColumn = 60
    )

    Write-Host "`n[INFO] Applying Advanced tweaks..." -ForegroundColor Cyan
    Write-Log -msg "Applying Advanced tweaks: $($Tweaks -join ', ')"

    foreach ($tweak in $Tweaks) {
        $displayName = "  $tweak"
        Write-Host -NoNewline ($displayName.PadRight($StatusColumn))

        try {
            switch ($tweak) {
                "DisableServices" {
                    # Disable unnecessary services for performance
                    $servicesToDisable = @(
                        "DiagTrack",                    # Connected User Experiences and Telemetry
                        "dmwappushservice",             # WAP Push Message Routing Service
                        "SysMain",                      # Superfetch (can cause high disk usage)
                        "WSearch",                      # Windows Search indexer
                        "MapsBroker",                   # Downloaded Maps Manager
                        "lfsvc",                        # Geolocation Service
                        "RetailDemo",                   # Retail Demo Service
                        "wisvc"                         # Windows Insider Service
                    )
                    foreach ($svc in $servicesToDisable) {
                        reg add "HKLM\zSYSTEM\ControlSet001\Services\$svc" /v "Start" /t REG_DWORD /d "4" /f 2>&1 | Write-Log
                    }
                }
                "DisableDefenderRealtime" {
                    # Disable Windows Defender real-time protection via policy
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpynetReporting" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d "2" /f 2>&1 | Write-Log
                }
                "DisableHibernation" {
                    # Disable hibernation (saves RAM-size space on disk)
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\Power" /v "HiberFileSizePercent" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    # Also add RunOnce to delete hiberfil.sys on first boot
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "DisableHibernation" /t REG_SZ /d "powercfg /h off" /f 2>&1 | Write-Log
                }
                "SetDNSCloudflare" {
                    # Pre-configure Cloudflare DNS (1.1.1.1) via RunOnce
                    $dnsCmd = 'powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq ''Up''} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses (''1.1.1.1'',''1.0.0.1'',''2606:4700:4700::1111'',''2606:4700:4700::1001'') }"'
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "SetDNS" /t REG_SZ /d $dnsCmd /f 2>&1 | Write-Log
                }
                "SetDNSGoogle" {
                    # Pre-configure Google DNS (8.8.8.8) via RunOnce
                    $dnsCmd = 'powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq ''Up''} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses (''8.8.8.8'',''8.8.4.4'',''2001:4860:4860::8888'',''2001:4860:4860::8844'') }"'
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "SetDNS" /t REG_SZ /d $dnsCmd /f 2>&1 | Write-Log
                }
                "SetDNSQuad9" {
                    # Pre-configure Quad9 DNS (9.9.9.9 - blocks malicious domains)
                    $dnsCmd = 'powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq ''Up''} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses (''9.9.9.9'',''149.112.112.112'',''2620:fe::fe'',''2620:fe::9'') }"'
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "SetDNS" /t REG_SZ /d $dnsCmd /f 2>&1 | Write-Log
                }
                "SetDNSAdGuard" {
                    # Pre-configure AdGuard DNS (blocks ads & trackers)
                    $dnsCmd = 'powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq ''Up''} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses (''94.140.14.14'',''94.140.15.15'',''2a10:50c0::ad1:ff'',''2a10:50c0::ad2:ff'') }"'
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "SetDNS" /t REG_SZ /d $dnsCmd /f 2>&1 | Write-Log
                }
                "SetDNSOpenDNS" {
                    # Pre-configure OpenDNS
                    $dnsCmd = 'powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq ''Up''} | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses (''208.67.222.222'',''208.67.220.220'') }"'
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "SetDNS" /t REG_SZ /d $dnsCmd /f 2>&1 | Write-Log
                }
                "DisableIPv6" {
                    # Disable IPv6 on all adapters
                    reg add "HKLM\zSYSTEM\ControlSet001\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d "255" /f 2>&1 | Write-Log
                }
                "EnableUltimatePerformance" {
                    # Enable Ultimate Performance power plan on first boot
                    $powerCmd = "powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61"
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "UltimatePerformance" /t REG_SZ /d $powerCmd /f 2>&1 | Write-Log
                }
                "DisableNotifications" {
                    # Disable notification center and toast notifications
                    reg add "HKLM\zNTUSER\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    # Disable focus assist
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default`$windows.data.notifications.quiethourssettings\windows.data.notifications.quiethourssettings" /v "Data" /t REG_BINARY /d "" /f 2>&1 | Write-Log
                }
                "CompactOS" {
                    # Enable Compact OS on first boot to save disk space
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "CompactOS" /t REG_SZ /d "compact /compactos:always" /f 2>&1 | Write-Log
                }
                "DisableWindowsUpdate" {
                    # Disable Windows Update service completely (risky!)
                    reg add "HKLM\zSYSTEM\ControlSet001\Services\wuauserv" /v "Start" /t REG_DWORD /d "4" /f 2>&1 | Write-Log
                    reg add "HKLM\zSYSTEM\ControlSet001\Services\UsoSvc" /v "Start" /t REG_DWORD /d "4" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                # ---- Winutil / Winhance inspired tweaks (offline-safe) ----
                "DisableActivityHistory" {
                    # Winutil: erase activity feed / timeline
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableAdvertisingID" {
                    # Stop apps from using advertising ID
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableTailoredExperiences" {
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableWifiSense" {
                    # Winutil: disable Wi-Fi Sense hotspot sharing/reporting
                    reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v "value" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v "value" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableBackgroundApps" {
                    # Winutil: stop UWP apps running in background
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f 2>&1 | Write-Log
                }
                "DisableWPBT" {
                    # Winutil: block Windows Platform Binary Table (OEM injected binaries)
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\Session Manager" /v "DisableWpbtExecution" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableTeredo" {
                    # Winutil: disable Teredo IPv6 tunneling
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\TCPIP\v6Transition" /v "Teredo_State" /t REG_SZ /d "Disabled" /f 2>&1 | Write-Log
                    reg add "HKLM\zSYSTEM\ControlSet001\Services\iphlpsvc\Teredo" /v "Type" /t REG_DWORD /d "4" /f 2>&1 | Write-Log
                }
                "SetVisualEffectsPerformance" {
                    # Winhance/Winutil: adjust for best performance
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "2" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f 2>&1 | Write-Log
                }
                "DisableFullscreenOptimizations" {
                    # Winutil: better fullscreen game/app behaviour
                    reg add "HKLM\zNTUSER\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d "2" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f 2>&1 | Write-Log
                }
                "DisableWallpaperCompression" {
                    # Winhance: keep desktop wallpaper at full quality
                    reg add "HKLM\zNTUSER\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f 2>&1 | Write-Log
                }
                "SetTimeUTC" {
                    # Winutil: store hardware clock as UTC (dual-boot with Linux)
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\TimeZoneInformation" /v "RealTimeIsUniversal" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "VerboseStartupMessages" {
                    # Winutil: show detailed status during boot/shutdown
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "VerboseStatus" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "EnableDetailedBSOD" {
                    # Winutil: show detailed BSOD info
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\CrashControl" /v "DisplayParameters" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "EnableLongPaths" {
                    # Allow >260 char file paths
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisablePowerShell7Telemetry" {
                    # Winutil: opt out of PowerShell 7 telemetry
                    reg add "HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Environment" /v "POWERSHELL_TELEMETRY_OPTOUT" /t REG_SZ /d "1" /f 2>&1 | Write-Log
                }
                "SetServicesManual" {
                    # Winutil approach: set non-essential services to Manual (3) instead of
                    # fully disabling - safer, services still start on demand.
                    $manualServices = @(
                        "BITS","wisvc","WbioSrvc","TabletInputService","RemoteRegistry",
                        "RemoteAccess","SharedAccess","WMPNetworkSvc","Fax","PhoneSvc",
                        "WpcMonSvc","SCardSvr","ScDeviceEnum","SCPolicySvc","wlpasvc",
                        "SEMgrSvc","PimIndexMaintenanceSvc","MessagingService","OneSyncSvc",
                        "WalletService","RetailDemo","DiagTrack","diagnosticshub.standardcollector.service"
                    )
                    foreach ($svc in $manualServices) {
                        reg add "HKLM\zSYSTEM\ControlSet001\Services\$svc" /v "Start" /t REG_DWORD /d "3" /f 2>&1 | Write-Log
                    }
                }
                "LowerUAC" {
                    # Winhance: lower UAC prompt level (SECURITY TRADE-OFF - opt-in only)
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableHPET" {
                    # Winhance: disable High Precision Event Timer (can improve FPS/latency)
                    $hpetCmd = "cmd /c bcdedit /deletevalue useplatformclock & bcdedit /set disabledynamictick yes & bcdedit /set useplatformtick no"
                    reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "DisableHPET" /t REG_SZ /d $hpetCmd /f 2>&1 | Write-Log
                }
                "DisableSearchIndexing" {
                    # Winhance: turn off Windows Search indexer service
                    reg add "HKLM\zSYSTEM\ControlSet001\Services\WSearch" /v "Start" /t REG_DWORD /d "4" /f 2>&1 | Write-Log
                }
                "DisableConsumerFeatures" {
                    # Winutil: stop auto-install of suggested store apps/games
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableConsumerAccountStateContent" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableBingSearch" {
                    # Winutil: remove Bing web results from Start menu search
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableStartMenuRecommendations" {
                    # Winutil: hide the recommended section in Start menu
                    reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableCrossDeviceResume" {
                    # Winutil: disable cross-device "resume from phone" feature
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" /v "IsResumeAllowed" /t REG_DWORD /d "0" /f 2>&1 | Write-Log
                }
                "DisableMouseAcceleration" {
                    # Winutil: turn off mouse acceleration (raw input for gaming)
                    reg add "HKLM\zNTUSER\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f 2>&1 | Write-Log
                }
                "NumLockOnStartup" {
                    # Winutil: enable Num Lock at boot/login
                    reg add "HKLM\zNTUSER\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f 2>&1 | Write-Log
                    reg add "HKLM\zDEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f 2>&1 | Write-Log
                }
                "EnableGameMode" {
                    # Winutil: enable Windows Game Mode
                    reg add "HKLM\zNTUSER\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                    reg add "HKLM\zNTUSER\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "ShowBatteryPercentage" {
                    # Winutil: show numeric battery percentage in tray
                    reg add "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IsBatteryPercentageEnabled" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                "DisableLoginAcrylicBlur" {
                    # Winutil: remove acrylic blur on the logon screen (snappier)
                    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\System" /v "DisableAcrylicBackgroundOnLogon" /t REG_DWORD /d "1" /f 2>&1 | Write-Log
                }
                default {
                    Write-Host "[SKIPPED]" -ForegroundColor DarkGray
                    Write-Log -msg "Unknown advanced tweak: $tweak"
                    continue
                }
            }
            Write-Host "[DONE]" -ForegroundColor Green
            Write-Log -msg "Applied advanced tweak: $tweak"
        }
        catch {
            Write-Host "[ERROR]" -ForegroundColor Red
            Write-Log -msg "Failed to apply advanced tweak $tweak`: $_"
        }
    }

    Write-Host ("[OK] Advanced tweaks applied") -ForegroundColor Green
    Write-Log -msg "Advanced tweaks completed"
}

function Get-AvailableAdvancedTweaks {
    <#
    .SYNOPSIS
        Returns available advanced tweaks with descriptions.
    #>
    return @(
        @{ Name = "DisableServices"; Description = "Disable telemetry/bloat services (DiagTrack, SysMain, etc.)" }
        @{ Name = "SetServicesManual"; Description = "Set non-essential services to Manual (safer than disable)" }
        @{ Name = "DisableDefenderRealtime"; Description = "Disable Defender real-time scan (gaming perf)" }
        @{ Name = "DisableHibernation"; Description = "Disable hibernation (saves RAM-size disk space)" }
        @{ Name = "SetDNSCloudflare"; Description = "Pre-configure Cloudflare DNS (1.1.1.1)" }
        @{ Name = "SetDNSGoogle"; Description = "Pre-configure Google DNS (8.8.8.8)" }
        @{ Name = "SetDNSQuad9"; Description = "Pre-configure Quad9 DNS (9.9.9.9, blocks malware)" }
        @{ Name = "SetDNSAdGuard"; Description = "Pre-configure AdGuard DNS (blocks ads/trackers)" }
        @{ Name = "SetDNSOpenDNS"; Description = "Pre-configure OpenDNS (208.67.222.222)" }
        @{ Name = "DisableIPv6"; Description = "Disable IPv6 on all network adapters" }
        @{ Name = "DisableTeredo"; Description = "Disable Teredo IPv6 tunneling" }
        @{ Name = "EnableUltimatePerformance"; Description = "Enable Ultimate Performance power plan" }
        @{ Name = "DisableNotifications"; Description = "Disable notification center and toasts" }
        @{ Name = "CompactOS"; Description = "Enable Compact OS on first boot (~2GB saved)" }
        @{ Name = "DisableWindowsUpdate"; Description = "Fully disable Windows Update (risky!)" }
        # Winutil / Winhance inspired
        @{ Name = "DisableActivityHistory"; Description = "Disable activity feed / timeline tracking" }
        @{ Name = "DisableAdvertisingID"; Description = "Disable advertising ID for apps" }
        @{ Name = "DisableTailoredExperiences"; Description = "Disable tailored experiences (ads from diagnostics)" }
        @{ Name = "DisableWifiSense"; Description = "Disable Wi-Fi Sense hotspot sharing" }
        @{ Name = "DisableBackgroundApps"; Description = "Stop UWP apps running in background" }
        @{ Name = "DisableWPBT"; Description = "Block OEM injected binaries (WPBT)" }
        @{ Name = "SetVisualEffectsPerformance"; Description = "Adjust visual effects for best performance" }
        @{ Name = "DisableFullscreenOptimizations"; Description = "Disable fullscreen optimizations (gaming)" }
        @{ Name = "DisableWallpaperCompression"; Description = "Keep desktop wallpaper at full quality" }
        @{ Name = "SetTimeUTC"; Description = "Store hardware clock as UTC (Linux dual-boot)" }
        @{ Name = "VerboseStartupMessages"; Description = "Show detailed boot/shutdown status" }
        @{ Name = "EnableDetailedBSOD"; Description = "Show detailed BSOD information" }
        @{ Name = "EnableLongPaths"; Description = "Allow file paths longer than 260 chars" }
        @{ Name = "DisablePowerShell7Telemetry"; Description = "Opt out of PowerShell 7 telemetry" }
        @{ Name = "DisableSearchIndexing"; Description = "Turn off Windows Search indexer (SSD perf)" }
        @{ Name = "DisableConsumerFeatures"; Description = "Stop auto-install of suggested store apps" }
        @{ Name = "DisableBingSearch"; Description = "Remove Bing web results from Start search" }
        @{ Name = "DisableStartMenuRecommendations"; Description = "Hide recommended section in Start menu" }
        @{ Name = "DisableCrossDeviceResume"; Description = "Disable resume-from-phone feature" }
        @{ Name = "DisableMouseAcceleration"; Description = "Disable mouse acceleration (raw input)" }
        @{ Name = "NumLockOnStartup"; Description = "Enable Num Lock at boot/login" }
        @{ Name = "EnableGameMode"; Description = "Enable Windows Game Mode" }
        @{ Name = "ShowBatteryPercentage"; Description = "Show battery percentage in system tray" }
        @{ Name = "DisableLoginAcrylicBlur"; Description = "Remove blur on logon screen (snappier)" }
        @{ Name = "DisableHPET"; Description = "Disable High Precision Event Timer (latency)" }
        @{ Name = "LowerUAC"; Description = "Lower UAC prompts (SECURITY TRADE-OFF)" }
    )
}
