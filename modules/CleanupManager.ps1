# CleanupManager.ps1
# Handles cleanup operations and provides trap-based safety net

function Initialize-CleanupTrap {
    <#
    .SYNOPSIS
        Sets up a global trap for Ctrl+C and unexpected termination to ensure cleanup.
    .DESCRIPTION
        Registers cleanup paths that will be removed if the script is interrupted.
    #>
    param(
        [string]$DestinationPath,
        [string]$MountDir,
        [string]$LogFilePath,
        [string]$TranscriptPath
    )

    # Store cleanup info in script-scope variables
    $script:CleanupPaths = @{
        DestinationPath = $DestinationPath
        MountDir = $MountDir
        LogFilePath = $LogFilePath
        TranscriptPath = $TranscriptPath
    }

    $script:CleanupRegistered = $true
}

function Invoke-SafeCleanup {
    <#
    .SYNOPSIS
        Performs safe cleanup of temporary files and mounted images.
    .DESCRIPTION
        Attempts to dismount any mounted images and remove temporary directories.
        Designed to be called from trap blocks or normal cleanup flow.
    #>
    param(
        [string]$DestinationPath,
        [string]$MountDir,
        [string]$LogFilePath,
        [string]$TranscriptPath,
        [switch]$IsInterrupt
    )

    if ($IsInterrupt) {
        Write-Host "`n`nScript interrupted! Performing emergency cleanup..." -ForegroundColor Red
        Write-Log -msg "Script interrupted - performing emergency cleanup"
    }

    # Try to dismount any mounted WIM images
    try {
        if ($MountDir -and (Test-Path "$MountDir\Windows")) {
            Write-Host "  Dismounting WIM image..." -ForegroundColor Yellow
            dism /unmount-image /mountdir:$MountDir /discard 2>&1 | Out-Null
            Write-Log -msg "Emergency dismount of WIM image"
        }
    }
    catch {
        Write-Log -msg "Emergency dismount failed: $($_.Exception.Message)"
    }

    # Unload any loaded registry hives
    $hivePrefixes = @("z", "x")
    $hiveNames = @("SOFTWARE", "SYSTEM", "NTUSER", "DEFAULT", "COMPONENTS", "CBS_SOFTWARE")
    foreach ($prefix in $hivePrefixes) {
        foreach ($hive in $hiveNames) {
            reg unload "HKLM\${prefix}${hive}" 2>&1 | Out-Null
        }
    }

    # Remove temporary directories
    if ($DestinationPath -and (Test-Path $DestinationPath)) {
        Remove-Item -Path $DestinationPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log -msg "Removed: $DestinationPath"
    }
    if ($MountDir -and (Test-Path $MountDir)) {
        Remove-Item -Path $MountDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log -msg "Removed: $MountDir"
    }

    $widTemp = "$env:SystemDrive\WIDTemp"
    if (Test-Path $widTemp) {
        Remove-Item -Path $widTemp -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log -msg "Removed: $widTemp"
    }

    # Handle transcript
    try {
        Stop-Transcript -ErrorAction SilentlyContinue 2>&1 | Out-Null
        if ($TranscriptPath -and (Test-Path $TranscriptPath)) {
            if ($LogFilePath) {
                $content = Get-Content $TranscriptPath -ErrorAction SilentlyContinue | Where-Object {
                    $_ -notmatch "^(Windows PowerShell transcript|Start time:|Username:|RunAs User:|Configuration|Host Application:|Process ID:|PS[A-Z]|BuildVersion:|CLRVersion:|WSManStackVersion:|SerializationVersion:|Transcript started|PS C:\\|^\*{10,}|End time:)" -and $_.Trim()
                }
                if ($content) {
                    Add-Content $LogFilePath -Value ("`n" + "="*50 + "`nTerminal Snapshot - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" + "`n" + "="*50 + "`n" + ($content -join "`n"))
                }
            }
            Remove-Item $TranscriptPath -Force -ErrorAction SilentlyContinue
        }
    }
    catch {}

    if ($IsInterrupt) {
        Write-Host "  Cleanup completed." -ForegroundColor Yellow
        Write-Log -msg "Emergency cleanup completed"
    }
}

function Clear-StaleMounts {
    <#
    .SYNOPSIS
        Detects and cleans up orphaned/stale WIM mounts left by a previous crashed run.
    .DESCRIPTION
        A crashed run can leave an image registered with DISM as "mounted for read/write",
        which blocks all future runs with error 0xc1420127. This dismounts any such mounts,
        runs a mount cleanup, and removes leftover mount directories.
    #>
    param(
        [string]$MountDir
    )

    $hadStale = $false

    try {
        $mountInfo = & dism /Get-MountedImageInfo 2>&1 | Out-String
        if ($mountInfo -match "Mount Dir") {
            $hadStale = $true
            Write-Host "  Found stale WIM mount(s) from a previous run. Cleaning up..." -ForegroundColor Yellow
            Write-Log -msg "Stale WIM mount detected - cleaning up before start"

            # Try to discard each mounted directory reported by DISM
            $dirMatches = [regex]::Matches($mountInfo, "Mount Dir\s*:\s*(.+)")
            foreach ($m in $dirMatches) {
                $dir = $m.Groups[1].Value.Trim()
                if ($dir) {
                    Write-Host "    Discarding mount: $dir" -ForegroundColor DarkGray
                    & dism /Unmount-Image /MountDir:"$dir" /Discard 2>&1 | Out-Null
                    Write-Log -msg "Discarded stale mount: $dir"
                }
            }
        }
    }
    catch {
        Write-Log -msg "Stale mount detection failed: $($_.Exception.Message)"
    }

    # Also discard the known mount dir explicitly (in case DISM listing missed it)
    if ($MountDir -and (Test-Path "$MountDir\Windows")) {
        & dism /Unmount-Image /MountDir:"$MountDir" /Discard 2>&1 | Out-Null
        $hadStale = $true
    }

    # Run global mount cleanup to clear any corrupted mount state
    if ($hadStale) {
        & dism /Cleanup-Mountpoints 2>&1 | Out-Null
        Write-Log -msg "Ran dism /Cleanup-Mountpoints"
    }

    # Remove leftover WIDTemp working directory so a fresh copy can start
    $widTemp = "$env:SystemDrive\WIDTemp"
    if (Test-Path $widTemp) {
        Remove-Item -Path $widTemp -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $widTemp) {
            # Some files may be locked; try once more after cleanup
            Start-Sleep -Seconds 1
            Remove-Item -Path $widTemp -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Log -msg "Removed leftover WIDTemp directory"
    }

    if ($hadStale) {
        Write-Host "  [OK] Stale mount cleanup completed." -ForegroundColor Green
    }
}

function Get-DiskSpaceCheck {
    <#
    .SYNOPSIS
        Checks if there's enough disk space for the operation.
    .PARAMETER DriveLetter
        The drive letter to check.
    .PARAMETER RequiredGB
        Minimum required free space in GB.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$DriveLetter,
        [double]$RequiredGB = 15.0
    )

    $drive = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue
    if ($drive) {
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        if ($freeGB -lt $RequiredGB) {
            Write-Host "Warning: Low disk space on ${DriveLetter}: drive ($freeGB GB free, $RequiredGB GB recommended)" -ForegroundColor Yellow
            Write-Log -msg "Low disk space warning: $freeGB GB free on ${DriveLetter}:"
            return $false
        }
        return $true
    }
    return $true
}
