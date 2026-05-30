# GUI-Launcher.ps1
# Simple, clean WPF GUI for Windows ISO Debloater.
# Tabs: Build | Tweaks | Apps | Log. Script runs hidden in the background,
# output streams into the Log tab. Selected WinGet apps are baked into the ISO.
# Self-elevates so the background process inherits admin rights.

$ErrorActionPreference = 'Stop'
$guiErrorLog = Join-Path ([System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)) "gui-error.log"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Administrator rights are required. UAC was cancelled.", "Windows ISO Debloater") | Out-Null
    }
    Exit
}

try {

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

try {
    $cw = Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name WinApi -Namespace Native -PassThru
    $hwnd = $cw::GetConsoleWindow()
    if ($hwnd -ne [IntPtr]::Zero) { $cw::ShowWindow($hwnd, 0) | Out-Null }
} catch {}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path $scriptRoot "modules\Win11DebloatTweaks.ps1")
. (Join-Path $scriptRoot "modules\AdvancedTweaks.ps1")
. (Join-Path $scriptRoot "modules\AppCatalog.ps1")
$win11Tweaks = Get-AvailableWin11Tweaks
$advTweaks   = Get-AvailableAdvancedTweaks
$appCatalog  = Get-AppCatalog

$recommendedAdv = @("DisableActivityHistory","DisableAdvertisingID","DisableTailoredExperiences",
    "DisableConsumerFeatures","DisableBingSearch","DisableBackgroundApps","DisableHibernation",
    "SetVisualEffectsPerformance","EnableUltimatePerformance")

$UI = @{
    EN = @{
        TabBuild="Build"; TabTweaks="Tweaks"; TabApps="Apps"; TabLog="Log"
        Source="ISO file:"; Browse="Browse..."; Profile="Profile:"; OutName="Output name:"; Lang="Language:"
        Removal="Removal"; Appx="Remove bloatware apps"; Caps="Remove unnecessary features"
        OneDrive="Remove OneDrive"; Edge="Remove Microsoft Edge"; AI="Remove AI / Copilot"
        Core="Options"; CleanStart="Clear Start Menu pins"; TPM="Bypass TPM / hardware checks"
        Drivers="Integrate Intel RST/VMD drivers"; ESD="Compress ISO (ESD)"; UserFolders="Enable user folders"
        Win11Group="Win11Debloat tweaks (privacy / UI)"; AdvGroup="Advanced tweaks (services / performance)"
        SelectAll="All"; SelectNone="None"; SelectRec="Recommended"
        AppsHint="Selected apps are baked into the ISO and auto-install on first boot via WinGet (needs internet)."
        CustomApps="Custom WinGet IDs"; CustomAppsLbl="Enter WinGet package IDs (comma or new line separated):"
        CustomAppsEg="e.g.  Mozilla.Firefox, 7zip.7zip, VideoLAN.VLC"
        DryRun="Dry Run"; Build="Build ISO"; Cancel="Cancel"; Clear="Clear"; OpenFolder="Open Folder"
        Ready="Ready. Select an ISO and click Build ISO."
        NoIso="Please select a valid ISO file first."
        Running="Working... script is running in the background."
        Done="Done! ISO created successfully."; Failed="Failed. See the Log tab."
        Cancelled="Cancelled by user."
        Confirm="Confirm"; ConfirmMsg="Start building the ISO now? This can take 10-30 minutes."
    }
    LT = @{
        TabBuild="Kurimas"; TabTweaks="Pataisymai"; TabApps="Programos"; TabLog="Zurnalas"
        Source="ISO failas:"; Browse="Narsyti..."; Profile="Profilis:"; OutName="Pavadinimas:"; Lang="Kalba:"
        Removal="Salinimas"; Appx="Pasalinti bloatware programas"; Caps="Pasalinti nereikalingas funkcijas"
        OneDrive="Pasalinti OneDrive"; Edge="Pasalinti Microsoft Edge"; AI="Pasalinti AI / Copilot"
        Core="Parinktys"; CleanStart="Isvalyti Start meniu"; TPM="Apeiti TPM / aparatines patikras"
        Drivers="Integruoti Intel RST/VMD tvarkykles"; ESD="Suspausti ISO (ESD)"; UserFolders="Ijungti vartotojo aplankus"
        Win11Group="Win11Debloat pataisymai (privatumas / UI)"; AdvGroup="Papildomi pataisymai (servisai / nasumas)"
        SelectAll="Visus"; SelectNone="Nieko"; SelectRec="Rekomenduojami"
        AppsHint="Pazymetos programos idedamos i ISO ir idiegiamos po pirmo paleidimo per WinGet (reikia interneto)."
        CustomApps="Savos WinGet ID"; CustomAppsLbl="Iveskite WinGet paketu ID (atskirti kableliais ar nauja eilute):"
        CustomAppsEg="pvz.  Mozilla.Firefox, 7zip.7zip, VideoLAN.VLC"
        DryRun="Bandymas"; Build="Kurti ISO"; Cancel="Atsaukti"; Clear="Valyti"; OpenFolder="Atidaryti aplanka"
        Ready="Pasiruose. Pasirinkite ISO ir spauskite Kurti ISO."
        NoIso="Pirma pasirinkite tinkama ISO faila."
        Running="Vykdoma... skriptas dirba fone."
        Done="Atlikta! ISO sekmingai sukurtas."; Failed="Nepavyko. Ziurekite Zurnalo skirtuka."
        Cancelled="Atsaukta vartotojo."
        Confirm="Patvirtinimas"; ConfirmMsg="Pradeti kurti ISO dabar? Tai gali uztrukti 10-30 min."
    }
    RU = @{
        TabBuild="Sborka"; TabTweaks="Tviki"; TabApps="Programmy"; TabLog="Zhurnal"
        Source="ISO fajl:"; Browse="Obzor..."; Profile="Profil:"; OutName="Imya:"; Lang="Yazyk:"
        Removal="Udalenie"; Appx="Udalit bloatware prilozheniya"; Caps="Udalit nenuzhnye funkcii"
        OneDrive="Udalit OneDrive"; Edge="Udalit Microsoft Edge"; AI="Udalit AI / Copilot"
        Core="Parametry"; CleanStart="Ochistit menyu Pusk"; TPM="Obojti proverki TPM / oborudovaniya"
        Drivers="Integrirovat drajvery Intel RST/VMD"; ESD="Szhat ISO (ESD)"; UserFolders="Vklyuchit polzovatelskie papki"
        Win11Group="Tviki Win11Debloat (privatnost / UI)"; AdvGroup="Rasshirennye tviki (sluzhby / proizvod.)"
        SelectAll="Vse"; SelectNone="Nichego"; SelectRec="Rekomenduemye"
        AppsHint="Vybrannye prilozheniya vstraivayutsya v ISO i ustanavlivayutsya pri pervom zapuske cherez WinGet (nuzhen internet)."
        CustomApps="Svoi WinGet ID"; CustomAppsLbl="Vvedite ID paketov WinGet (cherez zapyatuyu ili s novoj stroki):"
        CustomAppsEg="napr.  Mozilla.Firefox, 7zip.7zip, VideoLAN.VLC"
        DryRun="Probnyj"; Build="Sozdat ISO"; Cancel="Otmena"; Clear="Ochistit"; OpenFolder="Otkryt papku"
        Ready="Gotovo. Vyberite ISO i nazhmite Sozdat ISO."
        NoIso="Sperva vyberite korrektnyj ISO fajl."
        Running="Vypolnyaetsya... skript rabotaet v fone."
        Done="Gotovo! ISO uspeshno sozdan."; Failed="Neudacha. Smotrite vkladku Zhurnal."
        Cancelled="Otmeneno polzovatelem."
        Confirm="Podtverzhdenie"; ConfirmMsg="Nachat sozdanie ISO? Eto mozhet zanyat 10-30 minut."
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows ISO Debloater" Height="640" Width="780"
        WindowStartupLocation="CenterScreen" MinHeight="540" MinWidth="680"
        FontFamily="Segoe UI" FontSize="13">
    <DockPanel Margin="10">

        <!-- Top bar: title + language -->
        <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
            <TextBlock Text="Windows ISO Debloater" FontSize="16" FontWeight="Bold" VerticalAlignment="Center"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                <TextBlock Name="lblLang" Text="Language:" VerticalAlignment="Center" Margin="0,0,6,0"/>
                <ComboBox Name="cmbLang" Width="120">
                    <ComboBoxItem Content="English" IsSelected="True"/>
                    <ComboBoxItem Content="Lietuviu"/>
                    <ComboBoxItem Content="Russkij"/>
                </ComboBox>
            </StackPanel>
        </Grid>

        <!-- Bottom action bar -->
        <Border DockPanel.Dock="Bottom" BorderBrush="#DDDDDD" BorderThickness="0,1,0,0" Padding="0,8,0,0" Margin="0,8,0,0">
            <Grid>
                <TextBlock Name="txtStatus" VerticalAlignment="Center" Text="Ready" TextTrimming="CharacterEllipsis" Margin="2,0,8,0"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="btnCancel" Content="Cancel" Width="90" Height="30" Margin="3,0" IsEnabled="False"/>
                    <Button Name="btnDryRun" Content="Dry Run" Width="100" Height="30" Margin="3,0"/>
                    <Button Name="btnStart" Content="Build ISO" Width="120" Height="30" Margin="3,0" FontWeight="Bold"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Progress bar above the action bar -->
        <ProgressBar Name="prog" DockPanel.Dock="Bottom" Height="6" Margin="0,6,0,0" IsIndeterminate="False"/>

        <!-- Main tabs -->
        <TabControl Name="tabs">
            <TabItem Name="tabBuild" Header="Build">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="6">
                    <StackPanel>
                        <GroupBox Name="grpSource" Header="ISO file" Padding="8" Margin="0,4,0,8">
                            <StackPanel>
                                <DockPanel>
                                    <Button Name="btnBrowse" Content="Browse..." DockPanel.Dock="Right" Width="90" Height="28" Margin="6,0,0,0"/>
                                    <TextBox Name="txtISOPath" Height="28" VerticalContentAlignment="Center"/>
                                </DockPanel>
                                <Grid Margin="0,8,0,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel Grid.Column="0" Orientation="Horizontal" Margin="0,0,8,0">
                                        <TextBlock Name="lblProfile" Text="Profile:" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                        <ComboBox Name="cmbProfile" Width="150">
                                            <ComboBoxItem Content="(None - Manual)" IsSelected="True"/>
                                            <ComboBoxItem Content="minimal"/>
                                            <ComboBoxItem Content="gaming"/>
                                            <ComboBoxItem Content="office"/>
                                        </ComboBox>
                                    </StackPanel>
                                    <StackPanel Grid.Column="1" Orientation="Horizontal">
                                        <TextBlock Name="lblOutName" Text="Output name:" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                        <TextBox Name="txtOutName" Width="170" Height="26" Text="Debloated_Windows" VerticalContentAlignment="Center"/>
                                    </StackPanel>
                                </Grid>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox Name="grpRemoval" Header="Removal" Padding="8" Margin="0,0,0,8">
                            <StackPanel>
                                <CheckBox Name="chkAppx" Content="Remove bloatware apps" IsChecked="True" Margin="2,4"/>
                                <CheckBox Name="chkCapabilities" Content="Remove unnecessary features" IsChecked="True" Margin="2,4"/>
                                <CheckBox Name="chkOneDrive" Content="Remove OneDrive" IsChecked="True" Margin="2,4"/>
                                <CheckBox Name="chkEdge" Content="Remove Microsoft Edge" IsChecked="True" Margin="2,4"/>
                                <CheckBox Name="chkAI" Content="Remove AI / Copilot" IsChecked="True" Margin="2,4"/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox Name="grpCore" Header="Options" Padding="8">
                            <StackPanel>
                                <CheckBox Name="chkCleanStart" Content="Clear Start Menu pins" IsChecked="True" Margin="2,4"/>
                                <CheckBox Name="chkUserFolders" Content="Enable user folders" IsChecked="True" Margin="2,4"/>
                                <CheckBox Name="chkTPMBypass" Content="Bypass TPM / hardware checks" IsChecked="False" Margin="2,4"/>
                                <CheckBox Name="chkDrivers" Content="Integrate Intel RST/VMD drivers" IsChecked="False" Margin="2,4"/>
                                <CheckBox Name="chkESD" Content="Compress ISO (ESD)" IsChecked="False" Margin="2,4"/>
                            </StackPanel>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Name="tabTweaks" Header="Tweaks">
                <DockPanel>
                    <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="6,6,6,0">
                        <Button Name="btnSelRec" Content="Recommended" Width="120" Height="26" Margin="0,0,4,0"/>
                        <Button Name="btnSelAll" Content="All" Width="60" Height="26" Margin="0,0,4,0"/>
                        <Button Name="btnSelNone" Content="None" Width="60" Height="26"/>
                    </StackPanel>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="6">
                        <StackPanel>
                            <GroupBox Name="grpWin11" Header="Win11Debloat tweaks" Padding="8" Margin="0,4,0,8">
                                <StackPanel Name="panelWin11"/>
                            </GroupBox>
                            <GroupBox Name="grpAdv" Header="Advanced tweaks" Padding="8">
                                <StackPanel Name="panelAdv"/>
                            </GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                </DockPanel>
            </TabItem>

            <TabItem Name="tabApps" Header="Apps">
                <DockPanel>
                    <TextBlock Name="lblAppsHint" DockPanel.Dock="Top" Margin="8,8,8,4" TextWrapping="Wrap" Foreground="#555555"
                               Text="Selected apps are baked into the ISO and auto-install on first boot via WinGet (needs internet)."/>
                    <GroupBox Name="grpCustomApps" DockPanel.Dock="Bottom" Header="Custom WinGet IDs" Padding="8" Margin="6,4,6,6">
                        <StackPanel>
                            <TextBlock Name="lblCustomApps" TextWrapping="Wrap" Foreground="#555555" Margin="0,0,0,4"
                                       Text="Enter WinGet package IDs (comma or new line separated):"/>
                            <TextBox Name="txtCustomApps" Height="54" AcceptsReturn="True" TextWrapping="Wrap"
                                     VerticalScrollBarVisibility="Auto"/>
                            <TextBlock Name="lblCustomAppsEg" Foreground="#999999" FontSize="11" Margin="0,3,0,0"
                                       Text="e.g.  Mozilla.Firefox, 7zip.7zip, VideoLAN.VLC"/>
                        </StackPanel>
                    </GroupBox>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="6">
                        <StackPanel Name="panelApps"/>
                    </ScrollViewer>
                </DockPanel>
            </TabItem>

            <TabItem Name="tabLog" Header="Log">
                <TextBox Name="txtLog" Margin="4" FontFamily="Consolas" FontSize="12" IsReadOnly="True"
                         Background="#1E1E1E" Foreground="#D4D4D4" BorderThickness="0"
                         VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>
            </TabItem>
        </TabControl>
    </DockPanel>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$ctrl = @{}
"lblLang","cmbLang","tabs","tabBuild","tabTweaks","tabApps","tabLog",
"grpSource","btnBrowse","txtISOPath","lblProfile","cmbProfile","lblOutName","txtOutName",
"grpRemoval","chkAppx","chkCapabilities","chkOneDrive","chkEdge","chkAI",
"grpCore","chkCleanStart","chkUserFolders","chkTPMBypass","chkDrivers","chkESD",
"btnSelAll","btnSelNone","btnSelRec","grpWin11","panelWin11","grpAdv","panelAdv",
"lblAppsHint","panelApps","grpCustomApps","lblCustomApps","txtCustomApps","lblCustomAppsEg","txtLog","prog",
"txtStatus","btnDryRun","btnStart","btnCancel" | ForEach-Object {
    $ctrl[$_] = $window.FindName($_)
}

# Build tweak checkboxes from module catalogs
$script:win11Checks = @{}
$script:advChecks = @{}
foreach ($tw in $win11Tweaks) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $tw.Description; $cb.ToolTip = $tw.Name; $cb.Margin = "2,3"; $cb.IsChecked = $true
    $ctrl.panelWin11.Children.Add($cb) | Out-Null
    $script:win11Checks[$tw.Name] = $cb
}
foreach ($tw in $advTweaks) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $tw.Description; $cb.ToolTip = $tw.Name; $cb.Margin = "2,3"
    $cb.IsChecked = ($recommendedAdv -contains $tw.Name)
    $ctrl.panelAdv.Children.Add($cb) | Out-Null
    $script:advChecks[$tw.Name] = $cb
}

# Build app checkboxes from catalog (grouped by category)
$script:appChecks = @{}
foreach ($category in $appCatalog.Keys) {
    $gb = New-Object System.Windows.Controls.GroupBox
    $gb.Header = $category; $gb.Padding = 6; $gb.Margin = "0,4,0,6"
    $wrap = New-Object System.Windows.Controls.WrapPanel
    foreach ($app in $appCatalog[$category]) {
        if ($script:appChecks.ContainsKey($app.Id)) { continue }
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $app.Name; $cb.ToolTip = $app.Id; $cb.Width = 220; $cb.Margin = "2,4"; $cb.IsChecked = $false
        $wrap.Children.Add($cb) | Out-Null
        $script:appChecks[$app.Id] = $cb
    }
    $gb.Content = $wrap
    $ctrl.panelApps.Children.Add($gb) | Out-Null
}

# State
$script:lang = "EN"; $script:proc = $null; $script:running = $false; $script:buildResult = $null
$script:logQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$script:timer = New-Object System.Windows.Threading.DispatcherTimer
$script:timer.Interval = [TimeSpan]::FromMilliseconds(150)
$script:timer.Add_Tick({ Update-FromQueue })

# Helpers
function Set-Language {
    param([string]$code)
    $script:lang = $code
    $t = $UI[$code]
    $ctrl.lblLang.Text = $t.Lang
    $ctrl.tabBuild.Header = $t.TabBuild; $ctrl.tabTweaks.Header = $t.TabTweaks
    $ctrl.tabApps.Header = $t.TabApps; $ctrl.tabLog.Header = $t.TabLog
    $ctrl.grpSource.Header = $t.Source; $ctrl.btnBrowse.Content = $t.Browse
    $ctrl.lblProfile.Text = $t.Profile; $ctrl.lblOutName.Text = $t.OutName
    $ctrl.grpRemoval.Header = $t.Removal
    $ctrl.chkAppx.Content = $t.Appx; $ctrl.chkCapabilities.Content = $t.Caps
    $ctrl.chkOneDrive.Content = $t.OneDrive; $ctrl.chkEdge.Content = $t.Edge; $ctrl.chkAI.Content = $t.AI
    $ctrl.grpCore.Header = $t.Core
    $ctrl.chkCleanStart.Content = $t.CleanStart; $ctrl.chkUserFolders.Content = $t.UserFolders
    $ctrl.chkTPMBypass.Content = $t.TPM; $ctrl.chkDrivers.Content = $t.Drivers; $ctrl.chkESD.Content = $t.ESD
    $ctrl.grpWin11.Header = $t.Win11Group; $ctrl.grpAdv.Header = $t.AdvGroup
    $ctrl.btnSelAll.Content = $t.SelectAll; $ctrl.btnSelNone.Content = $t.SelectNone; $ctrl.btnSelRec.Content = $t.SelectRec
    $ctrl.lblAppsHint.Text = $t.AppsHint
    $ctrl.grpCustomApps.Header = $t.CustomApps; $ctrl.lblCustomApps.Text = $t.CustomAppsLbl; $ctrl.lblCustomAppsEg.Text = $t.CustomAppsEg
    $ctrl.btnDryRun.Content = $t.DryRun; $ctrl.btnStart.Content = $t.Build; $ctrl.btnCancel.Content = $t.Cancel
    if (-not $script:running) { $ctrl.txtStatus.Text = $t.Ready }
}

function Add-Log { param([string]$text); if ($null -eq $text) { return }; $ctrl.txtLog.AppendText($text + "`r`n"); $ctrl.txtLog.ScrollToEnd() }

function Set-Running {
    param([bool]$on)
    $script:running = $on
    $ctrl.btnStart.IsEnabled = -not $on; $ctrl.btnDryRun.IsEnabled = -not $on; $ctrl.btnBrowse.IsEnabled = -not $on
    $ctrl.btnCancel.IsEnabled = $on; $ctrl.cmbLang.IsEnabled = -not $on; $ctrl.cmbProfile.IsEnabled = -not $on
    $ctrl.prog.IsIndeterminate = $on
}

function Get-CheckedNames { param([hashtable]$checks); $n=@(); foreach ($k in $checks.Keys) { if ($checks[$k].IsChecked) { $n += $k } }; return $n }

function Get-ScriptArgs {
    param([bool]$DryRun)
    $a = @("-noPrompt")
    if ($DryRun) { $a += "-dryRun" }
    $a += @("-isoPath", $ctrl.txtISOPath.Text)
    $a += @("-winEdition", "Windows 11 Pro")
    $outName = $ctrl.txtOutName.Text.Trim(); if (-not $outName) { $outName = "Debloated_Windows" }
    $a += @("-outputISO", $outName)
    $a += @("-Language", $script:lang)
    $prof = $ctrl.cmbProfile.SelectedItem.Content
    if ($prof -and $prof -ne "(None - Manual)") { $a += @("-profile", $prof) }
    if (-not $DryRun) {
        $yn = { param($c) if ($c) { "yes" } else { "no" } }
        $a += @("-AppxRemove",        (& $yn $ctrl.chkAppx.IsChecked))
        $a += @("-CapabilitiesRemove",(& $yn $ctrl.chkCapabilities.IsChecked))
        $a += @("-OnedriveRemove",    (& $yn $ctrl.chkOneDrive.IsChecked))
        $a += @("-EDGERemove",        (& $yn $ctrl.chkEdge.IsChecked))
        $a += @("-AIRemove",          (& $yn $ctrl.chkAI.IsChecked))
        $a += @("-TPMBypass",         (& $yn $ctrl.chkTPMBypass.IsChecked))
        $a += @("-UserFoldersEnable", (& $yn $ctrl.chkUserFolders.IsChecked))
        $a += @("-DriverIntegrate",   (& $yn $ctrl.chkDrivers.IsChecked))
        $a += @("-ESDConvert",        (& $yn $ctrl.chkESD.IsChecked))
        $a += @("-CleanStartMenu",    (& $yn $ctrl.chkCleanStart.IsChecked))
        $w = Get-CheckedNames $script:win11Checks
        if ($w.Count -gt 0) { $a += @("-Win11Tweaks","yes"); $a += @("-Win11TweaksList", ($w -join ",")) } else { $a += @("-Win11Tweaks","no") }
        $adv = Get-CheckedNames $script:advChecks
        if ($adv.Count -gt 0) { $a += @("-AdvancedTweaks","yes"); $a += @("-AdvancedTweaksList", ($adv -join ",")) }
        $apps = @(Get-CheckedNames $script:appChecks)
        # Merge in any manually-typed WinGet IDs (comma or newline separated)
        $custom = $ctrl.txtCustomApps.Text
        if ($custom) {
            $customIds = $custom -split "[,`r`n]" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            foreach ($id in $customIds) { if ($apps -notcontains $id) { $apps += $id } }
        }
        if ($apps.Count -gt 0) { $a += @("-WinGetApps", ($apps -join ",")) }
    }
    return $a
}

function Start-Build {
    param([bool]$DryRun)
    $t = $UI[$script:lang]
    if (-not $ctrl.txtISOPath.Text -or -not (Test-Path $ctrl.txtISOPath.Text)) {
        $ctrl.txtStatus.Text = $t.NoIso; $ctrl.txtStatus.Foreground = "Red"; return
    }
    if (-not $DryRun) {
        $res = [System.Windows.MessageBox]::Show($t.ConfirmMsg, $t.Confirm, 'YesNo', 'Question')
        if ($res -ne 'Yes') { return }
    }
    $scriptPath = Join-Path $scriptRoot "isoDebloaterScript.ps1"
    $argLine = (Get-ScriptArgs -DryRun $DryRun | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"','\"') + '"' } else { $_ }
    }) -join ' '

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argLine"
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true; $psi.WorkingDirectory = $scriptRoot

    $script:proc = New-Object System.Diagnostics.Process
    $script:proc.StartInfo = $psi; $script:proc.EnableRaisingEvents = $true
    Register-ObjectEvent -InputObject $script:proc -EventName OutputDataReceived -MessageData $script:logQueue -Action {
        if ($null -ne $EventArgs.Data) { $Event.MessageData.Enqueue($EventArgs.Data) } } | Out-Null
    Register-ObjectEvent -InputObject $script:proc -EventName ErrorDataReceived -MessageData $script:logQueue -Action {
        if ($null -ne $EventArgs.Data) { $Event.MessageData.Enqueue($EventArgs.Data) } } | Out-Null

    $script:buildResult = $null
    $ctrl.txtLog.Clear()
    Add-Log ("Launching: isoDebloaterScript.ps1 " + $argLine)
    Add-Log ("-" * 70)
    Set-Running $true
    $ctrl.tabs.SelectedItem = $ctrl.tabLog
    $ctrl.txtStatus.Text = $t.Running; $ctrl.txtStatus.Foreground = "Black"
    $script:proc.Start() | Out-Null
    $script:proc.BeginOutputReadLine(); $script:proc.BeginErrorReadLine()
    $script:timer.Start()
}

function Update-FromQueue {
    $line = $null
    while ($script:logQueue.TryDequeue([ref]$line)) {
        if ($line -match 'WID_DONE_SUCCESS') { $script:buildResult = 'success' }
        elseif ($line -match 'WID_DONE_FAILED') { $script:buildResult = 'failed' }
        Add-Log $line
    }
    if ($script:proc -and $script:proc.HasExited) {
        if ($script:logQueue.Count -gt 0) { return }
        $script:timer.Stop(); Set-Running $false
        $tt = $UI[$script:lang]
        if ($script:buildResult -eq 'success') { $ctrl.txtStatus.Text = $tt.Done; $ctrl.txtStatus.Foreground = "Green" }
        elseif ($script:buildResult -eq 'cancelled') { $ctrl.txtStatus.Text = $tt.Cancelled; $ctrl.txtStatus.Foreground = "DarkOrange" }
        else { $ctrl.txtStatus.Text = $tt.Failed; $ctrl.txtStatus.Foreground = "Red" }
    }
}

function Stop-Build {
    if ($script:proc -and -not $script:proc.HasExited) {
        $script:buildResult = 'cancelled'
        try { Start-Process -FilePath "taskkill.exe" -ArgumentList "/PID $($script:proc.Id) /T /F" -WindowStyle Hidden -Wait } catch {}
        $script:logQueue.Enqueue(""); $script:logQueue.Enqueue("--- Cancelled by user ---")
    }
}

# Events
$ctrl.cmbLang.Add_SelectionChanged({ switch ($ctrl.cmbLang.SelectedIndex) { 0 { Set-Language "EN" } 1 { Set-Language "LT" } 2 { Set-Language "RU" } } })
$ctrl.btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO files (*.iso)|*.iso"; $dlg.Title = $UI[$script:lang].Browse
    $localIso = Join-Path $scriptRoot "Windows.iso"
    if (Test-Path $localIso) { $dlg.InitialDirectory = $scriptRoot } else { $dlg.InitialDirectory = [Environment]::GetFolderPath("Desktop") }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ctrl.txtISOPath.Text = $dlg.FileName }
})
$ctrl.btnSelAll.Add_Click({ foreach ($k in $script:win11Checks.Keys) { $script:win11Checks[$k].IsChecked = $true }; foreach ($k in $script:advChecks.Keys) { $script:advChecks[$k].IsChecked = $true } })
$ctrl.btnSelNone.Add_Click({ foreach ($k in $script:win11Checks.Keys) { $script:win11Checks[$k].IsChecked = $false }; foreach ($k in $script:advChecks.Keys) { $script:advChecks[$k].IsChecked = $false } })
$ctrl.btnSelRec.Add_Click({ foreach ($k in $script:win11Checks.Keys) { $script:win11Checks[$k].IsChecked = $true }; foreach ($k in $script:advChecks.Keys) { $script:advChecks[$k].IsChecked = ($recommendedAdv -contains $k) } })
$ctrl.btnStart.Add_Click({ Start-Build -DryRun $false })
$ctrl.btnDryRun.Add_Click({ Start-Build -DryRun $true })
$ctrl.btnCancel.Add_Click({ Stop-Build })
$window.Add_Closing({
    if ($script:running) {
        $r = [System.Windows.MessageBox]::Show("A build is still running. Cancel it and exit?", "Windows ISO Debloater", 'YesNo', 'Warning')
        if ($r -ne 'Yes') { $_.Cancel = $true; return }
        Stop-Build
    }
})

$localIso = Join-Path $scriptRoot "Windows.iso"
if (Test-Path $localIso) { $ctrl.txtISOPath.Text = $localIso }

Set-Language "EN"
$window.ShowDialog() | Out-Null

}
catch {
    $msg = "GUI failed to start:`n`n$($_.Exception.Message)`n`nAt: $($_.InvocationInfo.PositionMessage)"
    try { $msg | Out-File -FilePath $guiErrorLog -Encoding UTF8 } catch {}
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show($msg, "Windows ISO Debloater - Error") | Out-Null
    } catch {}
}
