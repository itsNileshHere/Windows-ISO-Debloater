# ISOMetrics.ps1
# Tracks and displays ISO modification metrics (size diff, what was removed)

function Start-ISOMetrics {
    param([Parameter(Mandatory=$true)][string]$WimPath)

    $script:MetricsStartTime = Get-Date
    $script:OriginalWimSize = if (Test-Path $WimPath) { (Get-Item $WimPath).Length } else { 0 }

    return @{
        StartTime = $script:MetricsStartTime
        OriginalWimSize = $script:OriginalWimSize
    }
}

function Show-ISOMetrics {
    param(
        [long]$OriginalWimSize = 0,
        [string]$FinalISOPath = "",
        [string]$WimPath = "",
        [datetime]$StartTime = (Get-Date)
    )

    $elapsed = (Get-Date) - $StartTime
    $finalWimSize = if ($WimPath -and (Test-Path $WimPath)) { (Get-Item $WimPath).Length } else { 0 }
    $isoSize = if ($FinalISOPath -and (Test-Path $FinalISOPath)) { (Get-Item $FinalISOPath).Length } else { 0 }

    Write-Host ""
    Write-Host "========== ISO MODIFICATION SUMMARY ==========" -ForegroundColor DarkCyan

    if ($OriginalWimSize -gt 0 -and $finalWimSize -gt 0) {
        $savedBytes = $OriginalWimSize - $finalWimSize
        $savedMB = [math]::Round($savedBytes / 1MB, 1)
        $savedPercent = [math]::Round(($savedBytes / $OriginalWimSize) * 100, 1)
        $origGB = [math]::Round($OriginalWimSize / 1GB, 2)
        $finalGB = [math]::Round($finalWimSize / 1GB, 2)

        Write-Host "  Original WIM:  $origGB GB" -ForegroundColor White
        Write-Host "  Final WIM:     $finalGB GB" -ForegroundColor White
        Write-Host "  Saved:         $savedMB MB ($savedPercent pct)" -ForegroundColor Green
    }

    if ($isoSize -gt 0) {
        $isoGB = [math]::Round($isoSize / 1GB, 2)
        Write-Host "  Final ISO:     $isoGB GB" -ForegroundColor White
    }

    $mins = [math]::Floor($elapsed.TotalMinutes)
    $secs = $elapsed.Seconds
    Write-Host "  Time elapsed:  ${mins}m ${secs}s" -ForegroundColor White
    Write-Host "================================================" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Log -msg "=== ISO METRICS ==="
    if ($OriginalWimSize -gt 0) { Write-Log -msg "Original WIM: $([math]::Round($OriginalWimSize/1GB,2)) GB" }
    if ($finalWimSize -gt 0) { Write-Log -msg "Final WIM: $([math]::Round($finalWimSize/1GB,2)) GB" }
    if ($isoSize -gt 0) { Write-Log -msg "Final ISO: $([math]::Round($isoSize/1GB,2)) GB" }
    Write-Log -msg "Time elapsed: ${mins}m ${secs}s"
}
