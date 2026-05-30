# ProgressTracker.ps1
# Provides progress tracking and display for long-running operations

function Show-OperationProgress {
    <#
    .SYNOPSIS
        Displays a progress bar for multi-step operations.
    .PARAMETER Activity
        Description of the current activity.
    .PARAMETER Status
        Current status message.
    .PARAMETER PercentComplete
        Completion percentage (0-100).
    .PARAMETER CurrentStep
        Current step number.
    .PARAMETER TotalSteps
        Total number of steps.
    #>
    param(
        [string]$Activity = "Processing",
        [string]$Status = "",
        [int]$PercentComplete = 0,
        [int]$CurrentStep = 0,
        [int]$TotalSteps = 0
    )

    if ($TotalSteps -gt 0 -and $CurrentStep -gt 0) {
        $PercentComplete = [math]::Round(($CurrentStep / $TotalSteps) * 100)
        $Status = "Step $CurrentStep of $TotalSteps"
    }

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

function Show-TextProgressBar {
    <#
    .SYNOPSIS
        Displays a text-based progress bar in the console (for non-interactive terminals).
    .PARAMETER Percent
        Completion percentage (0-100).
    .PARAMETER Width
        Width of the progress bar in characters.
    .PARAMETER Label
        Label to show before the bar.
    #>
    param(
        [int]$Percent = 0,
        [int]$Width = 40,
        [string]$Label = ""
    )

    $filled = [math]::Round($Width * $Percent / 100)
    $empty = $Width - $filled
    $bar = "[" + ("#" * $filled) + ("-" * $empty) + "]"

    Write-Host "`r  $Label $bar $Percent% " -NoNewline -ForegroundColor Cyan
}

function Complete-TextProgressBar {
    <#
    .SYNOPSIS
        Completes and clears the text progress bar.
    #>
    param([string]$Message = "Done")

    Write-Host "`r  $Message".PadRight(70) -ForegroundColor Green
}

function New-OperationTracker {
    <#
    .SYNOPSIS
        Creates a new operation tracker for multi-phase operations.
    .PARAMETER Phases
        Array of phase names.
    #>
    param([Parameter(Mandatory=$true)][string[]]$Phases)

    return @{
        Phases = $Phases
        CurrentPhase = 0
        TotalPhases = $Phases.Count
        StartTime = Get-Date
        PhaseStartTime = Get-Date
    }
}

function Update-OperationPhase {
    <#
    .SYNOPSIS
        Advances to the next phase and displays progress.
    .PARAMETER Tracker
        The operation tracker hashtable.
    .PARAMETER PhaseName
        Override phase name (optional).
    #>
    param(
        [Parameter(Mandatory=$true)][hashtable]$Tracker,
        [string]$PhaseName = ""
    )

    $Tracker.CurrentPhase++
    $Tracker.PhaseStartTime = Get-Date

    $phase = if ($PhaseName) { $PhaseName } else { $Tracker.Phases[$Tracker.CurrentPhase - 1] }
    $pct = [math]::Round(($Tracker.CurrentPhase / $Tracker.TotalPhases) * 100)

    $elapsed = (Get-Date) - $Tracker.StartTime
    $elapsedStr = "{0}m {1}s" -f [math]::Floor($elapsed.TotalMinutes), $elapsed.Seconds

    Write-Host ""
    Write-Host "  [$($Tracker.CurrentPhase)/$($Tracker.TotalPhases)] $phase ($elapsedStr elapsed)" -ForegroundColor White

    Write-Progress -Activity "Windows ISO Debloater" -Status "$phase" -PercentComplete $pct

    return $Tracker
}

function Complete-OperationTracker {
    <#
    .SYNOPSIS
        Completes the operation tracker and shows final timing.
    .PARAMETER Tracker
        The operation tracker hashtable.
    #>
    param([Parameter(Mandatory=$true)][hashtable]$Tracker)

    Write-Progress -Activity "Windows ISO Debloater" -Completed
    $total = (Get-Date) - $Tracker.StartTime
    Write-Log -msg "All phases completed in $([math]::Floor($total.TotalMinutes))m $($total.Seconds)s"
}
