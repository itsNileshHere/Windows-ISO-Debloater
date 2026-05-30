# ISODownloader.ps1
# Auto-download Windows ISO using Microsoft's Fido script or direct links

function Get-WindowsISO {
    <#
    .SYNOPSIS
        Downloads a Windows ISO automatically using various methods.
    .PARAMETER OutputPath
        Directory where the ISO will be saved.
    .PARAMETER Edition
        Windows edition: "11" or "10"
    .PARAMETER Language
        Language code (e.g., "lt-LT", "en-US")
    .PARAMETER Method
        Download method: "MediaCreationTool", "Fido", "Direct"
    #>
    param(
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [string]$Edition = "11",
        [string]$Language = "en-US",
        [string]$Method = "Fido"
    )

    Write-Host "`n[INFO] Downloading Windows $Edition ISO..." -ForegroundColor Cyan
    Write-Host "  Language: $Language" -ForegroundColor DarkGray
    Write-Host "  Method: $Method" -ForegroundColor DarkGray
    Write-Log -msg "Starting ISO download: Windows $Edition, $Language, method=$Method"

    switch ($Method) {
        "Fido" {
            return Get-ISOViaFido -OutputPath $OutputPath -Edition $Edition -Language $Language
        }
        "MediaCreationTool" {
            return Get-ISOViaMediaCreationTool -OutputPath $OutputPath -Edition $Edition
        }
        "Direct" {
            return Get-ISOViaDirect -OutputPath $OutputPath -Edition $Edition -Language $Language
        }
        default {
            Write-Host "  Unknown download method: $Method" -ForegroundColor Red
            return $null
        }
    }
}

function Get-ISOViaFido {
    <#
    .SYNOPSIS
        Downloads Windows ISO using the Fido PowerShell script (github.com/pbatard/Fido).
    #>
    param(
        [string]$OutputPath,
        [string]$Edition = "11",
        [string]$Language = "en-US"
    )

    $fidoUrl = "https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1"
    $fidoScript = Join-Path $env:TEMP "Fido.ps1"

    try {
        Write-Host "  Downloading Fido script..." -ForegroundColor DarkGray
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $fidoUrl -OutFile $fidoScript -UseBasicParsing -ErrorAction Stop
        $ProgressPreference = 'Continue'

        if (-not (Test-Path $fidoScript)) {
            Write-Host "  Failed to download Fido script" -ForegroundColor Red
            return $null
        }

        Write-Host "  Running Fido to get download URL..." -ForegroundColor DarkGray
        Write-Host "  This will open a selection window." -ForegroundColor Yellow

        # Run Fido with parameters
        $isoFile = & powershell -ExecutionPolicy Bypass -File $fidoScript -Win $Edition -Lang $Language -GetUrl 2>$null

        if ($isoFile -and $isoFile -match "^https?://") {
            $isoFileName = "Windows${Edition}_${Language}.iso"
            $isoPath = Join-Path $OutputPath $isoFileName
            Write-Host "  Downloading ISO (this may take a while)..." -ForegroundColor DarkGray
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $isoFile -OutFile $isoPath -UseBasicParsing
            $ProgressPreference = 'Continue'

            if (Test-Path $isoPath) {
                $sizeGB = [math]::Round((Get-Item $isoPath).Length / 1GB, 2)
                Write-Host "  [OK] ISO downloaded: $isoPath ($sizeGB GB)" -ForegroundColor Green
                Write-Log -msg "ISO downloaded via Fido: $isoPath ($sizeGB GB)"
                return $isoPath
            }
        }

        Write-Host "  Fido did not return a valid URL" -ForegroundColor Red
        return $null
    }
    catch {
        Write-Host "  Fido download failed: $_" -ForegroundColor Red
        Write-Log -msg "Fido download failed: $_"
        return $null
    }
    finally {
        Remove-Item $fidoScript -Force -ErrorAction SilentlyContinue
    }
}

function Get-ISOViaMediaCreationTool {
    <#
    .SYNOPSIS
        Guides user to use Media Creation Tool for ISO download.
    #>
    param(
        [string]$OutputPath,
        [string]$Edition = "11"
    )

    $mctUrl = if ($Edition -eq "11") {
        "https://www.microsoft.com/software-download/windows11"
    } else {
        "https://www.microsoft.com/software-download/windows10"
    }

    Write-Host ""
    Write-Host "  Media Creation Tool method requires manual download:" -ForegroundColor Yellow
    Write-Host "  1. Go to: $mctUrl" -ForegroundColor White
    Write-Host "  2. Download the ISO file" -ForegroundColor White
    Write-Host "  3. Save it to: $OutputPath" -ForegroundColor White
    Write-Host ""

    # Try to open the URL in browser
    try { Start-Process $mctUrl } catch {}

    $isoPath = Read-Host "Enter the full path to the downloaded ISO file"
    if ($isoPath -and (Test-Path $isoPath)) {
        return $isoPath
    }
    return $null
}

function Get-ISOViaDirect {
    <#
    .SYNOPSIS
        Attempts direct download from Microsoft's servers.
    #>
    param(
        [string]$OutputPath,
        [string]$Edition = "11",
        [string]$Language = "en-US"
    )

    Write-Host "  Direct download method - attempting to get download link..." -ForegroundColor DarkGray

    # Microsoft's download page session-based approach
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $headers = @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    try {
        $productId = if ($Edition -eq "11") { "2935" } else { "2618" }
        $url = "https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=cfa9e580-a81e-4a4b-a846-7b21bf4e2e5b&host=www.microsoft.com&segments=software-download,windows$Edition&query=&action=getskuinformationbyproductedition&productEditionId=$productId"

        Write-Host "  Note: Direct download may not work due to Microsoft's session requirements." -ForegroundColor Yellow
        Write-Host "  Consider using -Method Fido instead." -ForegroundColor Yellow
        return $null
    }
    catch {
        Write-Host "  Direct download failed: $_" -ForegroundColor Red
        return $null
    }
}

function Show-DownloadOptions {
    <#
    .SYNOPSIS
        Shows available ISO download options to the user.
    #>
    Write-Host ""
    Write-Host "ISO Download Options:" -ForegroundColor Cyan
    Write-Host "  1. Fido (Recommended) - Automated download from Microsoft servers" -ForegroundColor White
    Write-Host "  2. Media Creation Tool - Opens Microsoft download page" -ForegroundColor White
    Write-Host "  3. Manual - You provide the ISO path" -ForegroundColor White
    Write-Host ""
}
