# MultiEdition.ps1
# Handles processing multiple Windows editions from a single ISO

function Get-AllEditions {
    <#
    .SYNOPSIS
        Returns all available editions from a WIM/ESD file.
    .PARAMETER ImagePath
        Path to install.wim or install.esd.
    #>
    param([Parameter(Mandatory=$true)][string]$ImagePath)

    $images = @()
    $out = & dism.exe /get-wiminfo /wimfile:$ImagePath /english 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }

    $indexPattern = "Index\s*:\s*(\d+)"
    $namePattern = "Name\s*:\s*(.+)"
    $sizePattern = "Size\s*:\s*([\d\s]+)\s*bytes"

    for ($i = 0; $i -lt $out.Count; $i++) {
        if ($out[$i] -match $indexPattern) {
            $index = $matches[1]
            $name = ""
            $size = 0
            for ($j = $i + 1; $j -lt [Math]::Min($i + 10, $out.Count); $j++) {
                if ($out[$j] -match $namePattern) { $name = $matches[1].Trim() }
                if ($out[$j] -match $sizePattern) { $size = [long]($matches[1] -replace '\s','') }
            }
            $images += [PSCustomObject]@{
                Index = [int]$index
                Name = $name
                SizeGB = [math]::Round($size / 1GB, 2)
            }
        }
    }
    return $images
}

function Export-MultipleEditions {
    <#
    .SYNOPSIS
        Exports multiple editions from a WIM file into a new multi-edition WIM.
    .PARAMETER SourceWimPath
        Path to the source install.wim.
    .PARAMETER DestinationWimPath
        Path for the output install.wim.
    .PARAMETER Indexes
        Array of edition indexes to include.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$SourceWimPath,
        [Parameter(Mandatory=$true)][string]$DestinationWimPath,
        [Parameter(Mandatory=$true)][int[]]$Indexes
    )

    Write-Host "`n[INFO] Exporting $($Indexes.Count) editions..." -ForegroundColor Cyan
    Write-Log -msg "Multi-edition export: indexes $($Indexes -join ', ')"

    foreach ($idx in $Indexes) {
        Write-Host "  Exporting index $idx..." -ForegroundColor DarkGray -NoNewline
        try {
            $args = "/Export-Image /SourceImageFile:`"$SourceWimPath`" /SourceIndex:$idx /DestinationImageFile:`"$DestinationWimPath`" /Compress:max /CheckIntegrity"
            $proc = Start-Process -FilePath "dism.exe" -ArgumentList $args -Wait -NoNewWindow -PassThru
            if ($proc.ExitCode -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                Write-Log -msg "Exported index $idx successfully"
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Log -msg "Failed to export index $idx (exit: $($proc.ExitCode))"
            }
        }
        catch {
            Write-Host " [ERROR]" -ForegroundColor Red
            Write-Log -msg "Export error for index $idx`: $_"
        }
    }
}
