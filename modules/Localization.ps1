# Localization.ps1
# Multi-language support for Windows ISO Debloater (EN/LT/RU)

$script:CurrentLanguage = "EN"

$script:Strings = @{
    EN = @{
        # General
        ScriptStarting = "Starting Windows ISO Debloater Script..."
        ImportantNotes = "*Important Notes:"
        Note1 = "  1. Some prompts will appear during the process."
        Note2 = "  2. Administrative privileges are required to run this script."
        Note3 = "  3. Review the script beforehand to understand its actions."
        Note4 = "  4. To whitelist a package, edit config.json."
        Note5 = "  5. Select the ISO to proceed."
        SelectISO = "Select Windows ISO File"
        NoFileSelected = "No file selected. Exiting Script"
        SelectedISO = "Selected ISO file: "
        MountingISO = "Mounting ISO..."
        MountFailed = "Failed to mount the ISO file."
        CopyingFiles = "Copying files from"
        CopyTo = "to"
        CopyComplete = "Copy completed successfully."
        CopyFailed = "Copy failed"
        SearchingAlternatives = "install.wim not found. Searching for alternatives..."
        ESDFound = "install.esd found. Converting..."
        SWMFound = "install.swm (Split WIM) found. Merging..."
        NeitherFound = "Neither install.wim, install.esd, nor install.swm found."
        MountCorrectISO = "Make sure to mount the correct ISO"
        EnterIndex = "Enter the index to mount"
        MountingImage = "Mounting image: "
        DetectedLanguage = "Detected Language"
        DetectedBuild = "Detected Build Number"

        # Prompts
        PromptAppxRemove = "Remove unnecessary packages?"
        PromptCapabilities = "Remove unnecessary features?"
        PromptOneDrive = "Remove OneDrive?"
        PromptEdge = "Remove Microsoft Edge?"
        PromptAI = "Remove AI Components?"
        PromptTPM = "Bypass TPM check?"
        PromptUserFolders = "Enable user folders?"
        PromptDrivers = "Integrate Intel RST/VMD drivers?"
        PromptESD = "Compress the ISO?"
        PromptOscdimg = "Use Oscdimg for ISO creation?"
        PromptWin11Tweaks = "Apply Win11Debloat tweaks?"
        PromptLanguage = "Select language / Pasirinkite kalba / Vyberi yazyk"

        # Descriptions
        DescAppx = "Recommended: Removes bloatware apps"
        DescCapabilities = "Recommended: Removes optional Windows features"
        DescOneDrive = "Optional: Completely removes OneDrive"
        DescEdge = "Optional: Removes Edge components (Breaks Widgets)"
        DescAI = "Optional: Removes everything related to AI"
        DescTPM = "Only if needed for older hardware"
        DescUserFolders = "Recommended: Enables Desktop, Documents, etc."
        DescDrivers = "Optional: Helps with Intel VMD storage controllers"
        DescESD = "Recommended but slow: Reduces ISO file size"
        DescOscdimg = "Recommended: Oscdimg is more reliable"
        DescWin11Tweaks = "Recommended: Extra privacy/UI tweaks from Win11Debloat"

        # Status
        Removing = "Removing"
        Removed = "[REMOVED]"
        NotFound = "[NOT FOUND]"
        Error = "[ERROR]"
        Done = "[DONE]"
        Skipped = "[SKIPPED]"
        OK = "[OK]"
        Failed = "[FAILED]"

        # Sections
        RemovingPackages = "Removing provisioned Packages:"
        RemovingFeatures = "Removing Unnecessary Windows Features:"
        RemovingOneDrive = "Removing OneDrive..."
        RemovingEdge = "Removing EDGE..."
        RemovingAI = "Removing AI components..."
        LoadingRegistry = "Loading Registry..."
        PerformingTweaks = "Performing Registry Tweaks..."
        ApplyingWin11Tweaks = "Applying Win11Debloat tweaks..."
        UnloadingRegistry = "Unloading Registry..."
        CleaningImage = "Cleaning up image..."
        UnmountingImage = "Unmounting and Exporting image..."
        GeneratingISO = "Generating ISO..."
        ISOCreated = "ISO creation successful"
        ScriptCompleted = "Script Completed. Can find the ISO in"
        DiskSpaceWarning = "Warning: Low disk space"
        ContinueAnyway = "Continue anyway? (y/N)"

        # Profiles
        AvailableProfiles = "Available Profiles:"
        ProfileHint = "  (Use -profile <name> to auto-apply, or continue with manual selection)"

        # Metrics
        MetricsSummary = "ISO MODIFICATION SUMMARY"
        MetricsOriginal = "Original WIM:"
        MetricsFinal = "Final WIM:"
        MetricsSaved = "Saved:"
        MetricsISO = "Final ISO:"
        MetricsTime = "Time elapsed:"
    }

    LT = @{
        ScriptStarting = "Paleidziamas Windows ISO Debloater skriptas..."
        ImportantNotes = "*Svarbios pastabos:"
        Note1 = "  1. Proceso metu bus rodomi klausimai."
        Note2 = "  2. Reikalingos administratoriaus teises."
        Note3 = "  3. Perziurekite skripta pries paleidziant."
        Note4 = "  4. Norint palikti paketa, redaguokite config.json."
        Note5 = "  5. Pasirinkite ISO faila."
        SelectISO = "Pasirinkite Windows ISO faila"
        NoFileSelected = "Failas nepasirinktas. Skriptas baigiamas"
        SelectedISO = "Pasirinktas ISO failas: "
        MountingISO = "Montuojamas ISO..."
        MountFailed = "Nepavyko primontuoti ISO failo."
        CopyingFiles = "Kopijuojami failai is"
        CopyTo = "i"
        CopyComplete = "Kopijavimas baigtas sekmingai."
        CopyFailed = "Kopijavimas nepavyko"
        SearchingAlternatives = "install.wim nerastas. Ieskoma alternatyvu..."
        ESDFound = "install.esd rastas. Konvertuojama..."
        SWMFound = "install.swm (Split WIM) rastas. Jungiama..."
        NeitherFound = "Nerastas nei install.wim, nei install.esd, nei install.swm."
        MountCorrectISO = "Isitikinkite kad pasirinkote teisinga ISO"
        EnterIndex = "Iveskite indeksa montavimui"
        MountingImage = "Montuojamas vaizdas: "
        DetectedLanguage = "Aptikta kalba"
        DetectedBuild = "Aptiktas Build numeris"

        PromptAppxRemove = "Pasalinti nereikalingus paketus?"
        PromptCapabilities = "Pasalinti nereikalingas funkcijas?"
        PromptOneDrive = "Pasalinti OneDrive?"
        PromptEdge = "Pasalinti Microsoft Edge?"
        PromptAI = "Pasalinti AI komponentus?"
        PromptTPM = "Apeiti TPM patikra?"
        PromptUserFolders = "Ijungti vartotojo aplankus?"
        PromptDrivers = "Integruoti Intel RST/VMD tvarkykles?"
        PromptESD = "Suspausti ISO?"
        PromptOscdimg = "Naudoti Oscdimg ISO kurima?"
        PromptWin11Tweaks = "Taikyti Win11Debloat pataisymus?"
        PromptLanguage = "Select language / Pasirinkite kalba / Vyberi yazyk"

        DescAppx = "Rekomenduojama: Pasalina bloatware programas"
        DescCapabilities = "Rekomenduojama: Pasalina nebereikalingas Windows funkcijas"
        DescOneDrive = "Neprivaloma: Pilnai pasalina OneDrive"
        DescEdge = "Neprivaloma: Pasalina Edge (sugadina Widgets)"
        DescAI = "Neprivaloma: Pasalina viska susijusi su AI"
        DescTPM = "Tik senesne aparaturai"
        DescUserFolders = "Rekomenduojama: Ijungia Desktop, Documents ir kt."
        DescDrivers = "Neprivaloma: Padeda su Intel VMD valdikliais"
        DescESD = "Rekomenduojama bet letas: Sumazina ISO dydi"
        DescOscdimg = "Rekomenduojama: Oscdimg patikimesnis"
        DescWin11Tweaks = "Rekomenduojama: Papildomi privatumo/UI pataisymai"

        Removing = "Salinama"
        Removed = "[PASALINTA]"
        NotFound = "[NERASTA]"
        Error = "[KLAIDA]"
        Done = "[ATLIKTA]"
        Skipped = "[PRALEISTA]"
        OK = "[OK]"
        Failed = "[NEPAVYKO]"

        RemovingPackages = "Salinami provisioned paketai:"
        RemovingFeatures = "Salinamos nereikalingos Windows funkcijos:"
        RemovingOneDrive = "Salinamas OneDrive..."
        RemovingEdge = "Salinamas EDGE..."
        RemovingAI = "Salinami AI komponentai..."
        LoadingRegistry = "Ikraunamas registras..."
        PerformingTweaks = "Atliekami registro pakeitimai..."
        ApplyingWin11Tweaks = "Taikomi Win11Debloat pataisymai..."
        UnloadingRegistry = "Iskraunamas registras..."
        CleaningImage = "Valomas vaizdas..."
        UnmountingImage = "Atjungiamas ir eksportuojamas vaizdas..."
        GeneratingISO = "Generuojamas ISO..."
        ISOCreated = "ISO sukurtas sekmingai"
        ScriptCompleted = "Skriptas baigtas. ISO galite rasti"
        DiskSpaceWarning = "Ispejimas: Mazai vietos diske"
        ContinueAnyway = "Testi vis tiek? (t/N)"

        AvailableProfiles = "Galimi profiliai:"
        ProfileHint = "  (Naudokite -profile <pavadinimas> arba rinkites rankiniu budu)"

        MetricsSummary = "ISO MODIFIKACIJOS SANTRAUKA"
        MetricsOriginal = "Pradinis WIM:"
        MetricsFinal = "Galutinis WIM:"
        MetricsSaved = "Sutaupyta:"
        MetricsISO = "Galutinis ISO:"
        MetricsTime = "Trukme:"
    }

    RU = @{
        ScriptStarting = "Zapusk skripta Windows ISO Debloater..."
        ImportantNotes = "*Vazhnye zamechaniya:"
        Note1 = "  1. V processe budut poyavlyatsya zaprosy."
        Note2 = "  2. Trebuutsya prava administratora."
        Note3 = "  3. Prosmotrte skript pered zapuskom."
        Note4 = "  4. Dlya belogo spiska paketov redaktirujte config.json."
        Note5 = "  5. Vyberite ISO fajl."
        SelectISO = "Vyberite Windows ISO fajl"
        NoFileSelected = "Fajl ne vybran. Zavershenie skripta"
        SelectedISO = "Vybrannyj ISO fajl: "
        MountingISO = "Montirovanie ISO..."
        MountFailed = "Ne udalos smontirovat ISO fajl."
        CopyingFiles = "Kopirovanie fajlov iz"
        CopyTo = "v"
        CopyComplete = "Kopirovanie zaversheno uspeshno."
        CopyFailed = "Kopirovanie ne udalos"
        SearchingAlternatives = "install.wim ne najden. Poisk alternativ..."
        ESDFound = "install.esd najden. Konvertaciya..."
        SWMFound = "install.swm (Split WIM) najden. Obedinenie..."
        NeitherFound = "Ne najden ni install.wim, ni install.esd, ni install.swm."
        MountCorrectISO = "Ubedites chto vybran pravilnyj ISO"
        EnterIndex = "Vvedite indeks dlya montirovaniya"
        MountingImage = "Montirovanie obraza: "
        DetectedLanguage = "Obnaruzhennyj yazyk"
        DetectedBuild = "Obnaruzhennyj nomer sborki"

        PromptAppxRemove = "Udalit nenuzhnye pakety?"
        PromptCapabilities = "Udalit nenuzhnye funkcii?"
        PromptOneDrive = "Udalit OneDrive?"
        PromptEdge = "Udalit Microsoft Edge?"
        PromptAI = "Udalit AI komponenty?"
        PromptTPM = "Obojti proverku TPM?"
        PromptUserFolders = "Vklyuchit polzovatelskie papki?"
        PromptDrivers = "Integrirovat drajvery Intel RST/VMD?"
        PromptESD = "Szhat ISO?"
        PromptOscdimg = "Ispolzovat Oscdimg dlya sozdaniya ISO?"
        PromptWin11Tweaks = "Primenit tviki Win11Debloat?"
        PromptLanguage = "Select language / Pasirinkite kalba / Vyberi yazyk"

        DescAppx = "Rekomenduetsya: Udalyaet bloatware"
        DescCapabilities = "Rekomenduetsya: Udalyaet neobazatelnye funkcii Windows"
        DescOneDrive = "Neobazatelno: Polnostyu udalyaet OneDrive"
        DescEdge = "Neobazatelno: Udalyaet Edge (lomaet Widgets)"
        DescAI = "Neobazatelno: Udalyaet vse svyazannoe s AI"
        DescTPM = "Tolko dlya starogo oborudovaniya"
        DescUserFolders = "Rekomenduetsya: Vklyuchaet Desktop, Documents i dr."
        DescDrivers = "Neobazatelno: Pomogaet s kontrollerami Intel VMD"
        DescESD = "Rekomenduetsya no medlenno: Umenshaet razmer ISO"
        DescOscdimg = "Rekomenduetsya: Oscdimg nadezhnee"
        DescWin11Tweaks = "Rekomenduetsya: Dopolnitelnye tviki privatnosti/UI"

        Removing = "Udalenie"
        Removed = "[UDALENO]"
        NotFound = "[NE NAJDENO]"
        Error = "[OSHIBKA]"
        Done = "[GOTOVO]"
        Skipped = "[PROPUSHCHENO]"
        OK = "[OK]"
        Failed = "[NEUDACHA]"

        RemovingPackages = "Udalenie provisioned paketov:"
        RemovingFeatures = "Udalenie nenuzhnykh funkcij Windows:"
        RemovingOneDrive = "Udalenie OneDrive..."
        RemovingEdge = "Udalenie EDGE..."
        RemovingAI = "Udalenie AI komponentov..."
        LoadingRegistry = "Zagruzka reestra..."
        PerformingTweaks = "Vypolnenie izmenenij reestra..."
        ApplyingWin11Tweaks = "Primenenie tvikov Win11Debloat..."
        UnloadingRegistry = "Vygruzka reestra..."
        CleaningImage = "Ochistka obraza..."
        UnmountingImage = "Otmontirovanie i eksport obraza..."
        GeneratingISO = "Generaciya ISO..."
        ISOCreated = "ISO uspeshno sozdan"
        ScriptCompleted = "Skript zavershen. ISO mozhno najti v"
        DiskSpaceWarning = "Preduprezhdenie: Malo mesta na diske"
        ContinueAnyway = "Prodolzhit v lyubom sluchae? (d/N)"

        AvailableProfiles = "Dostupnye profili:"
        ProfileHint = "  (Ispolzujte -profile <imya> ili vyberite vruchnuyu)"

        MetricsSummary = "SVODKA MODIFIKACII ISO"
        MetricsOriginal = "Ishodnyj WIM:"
        MetricsFinal = "Itogovyj WIM:"
        MetricsSaved = "Sekonomleno:"
        MetricsISO = "Itogovyj ISO:"
        MetricsTime = "Vremya:"
    }
}

function Set-ScriptLanguage {
    <#
    .SYNOPSIS
        Sets the active language for the script.
    .PARAMETER Language
        Language code: EN, LT, or RU
    #>
    param([Parameter(Mandatory=$true)][ValidateSet("EN","LT","RU")][string]$Language)
    $script:CurrentLanguage = $Language
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -msg "Language set to: $Language"
    }
}

function Get-LocalizedString {
    <#
    .SYNOPSIS
        Returns a localized string by key.
    .PARAMETER Key
        The string key to look up.
    #>
    param([Parameter(Mandatory=$true)][string]$Key)

    $lang = $script:CurrentLanguage
    if ($script:Strings[$lang] -and $script:Strings[$lang][$Key]) {
        return $script:Strings[$lang][$Key]
    }
    # Fallback to English
    if ($script:Strings["EN"][$Key]) {
        return $script:Strings["EN"][$Key]
    }
    return $Key
}

function Show-LanguageSelection {
    <#
    .SYNOPSIS
        Shows language selection prompt and returns selected language.
    #>
    Write-Host ""
    Write-Host "  [1] English" -ForegroundColor White
    Write-Host "  [2] Lietuviu (Lithuanian)" -ForegroundColor White
    Write-Host "  [3] Russkij (Russian)" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "  Select / Pasirinkite / Vyberite (1/2/3)"

    switch ($choice) {
        "1" { return "EN" }
        "2" { return "LT" }
        "3" { return "RU" }
        default { return "EN" }
    }
}

# Shortcut alias
function L {
    param([string]$Key)
    return Get-LocalizedString -Key $Key
}
