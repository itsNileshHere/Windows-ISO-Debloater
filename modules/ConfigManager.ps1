# ConfigManager.ps1
# Handles loading configuration from config.json and applying profiles

function Get-ScriptConfig {
    <#
    .SYNOPSIS
        Loads and returns the configuration from config.json.
    .PARAMETER ConfigPath
        Path to the config.json file.
    .PARAMETER LangCode
        Language code to substitute in package patterns.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath,
        [string]$LangCode = "en-US"
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Configuration file not found at: $ConfigPath" -ForegroundColor Yellow
        Write-Host "Using built-in defaults." -ForegroundColor Yellow
        return $null
    }

    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

        # Substitute language code in patterns
        $config.capabilitiesToRemove = $config.capabilitiesToRemove | ForEach-Object { $_ -replace '\{langCode\}', $LangCode }
        $config.windowsPackagesToRemove = $config.windowsPackagesToRemove | ForEach-Object { $_ -replace '\{langCode\}', $LangCode }

        return $config
    }
    catch {
        Write-Host "Error reading config.json: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Using built-in defaults." -ForegroundColor Yellow
        return $null
    }
}

function Get-ProfileSettings {
    <#
    .SYNOPSIS
        Returns settings for a named profile from config.
    .PARAMETER Config
        The loaded configuration object.
    .PARAMETER ProfileName
        Name of the profile to load.
    #>
    param(
        [Parameter(Mandatory=$true)]$Config,
        [Parameter(Mandatory=$true)][string]$ProfileName
    )

    if (-not $Config.profiles.PSObject.Properties[$ProfileName]) {
        Write-Host "Profile '$ProfileName' not found. Available profiles:" -ForegroundColor Red
        $Config.profiles.PSObject.Properties | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.Value.description)" -ForegroundColor Cyan
        }
        return $null
    }

    return $Config.profiles.$ProfileName
}

function Show-AvailableProfiles {
    <#
    .SYNOPSIS
        Displays available profiles to the user.
    #>
    param([Parameter(Mandatory=$true)]$Config)

    Write-Host "`nAvailable Profiles:" -ForegroundColor Cyan
    $Config.profiles.PSObject.Properties | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Green -NoNewline
        Write-Host " - $($_.Value.description)" -ForegroundColor Gray
    }
}
