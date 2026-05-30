# RegistryHelper.ps1
# Helper module for registry hive load/unload operations with retry logic

function Invoke-WithLoadedHives {
    <#
    .SYNOPSIS
        Loads registry hives, executes a script block, and safely unloads them with retry logic.
    .PARAMETER MountPath
        Path to the mounted Windows image.
    .PARAMETER HiveSet
        Which set of hives to load. Options: "Full", "Software", "SoftwareSystem", "SoftwareSystemUser", "Boot"
    .PARAMETER HivePrefix
        Prefix for hive names (default: "z"). Use different prefix for nested operations.
    .PARAMETER ScriptBlock
        The script block to execute while hives are loaded.
    .PARAMETER MaxRetries
        Maximum number of retry attempts for unloading hives (default: 5).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$MountPath,
        [Parameter(Mandatory=$true)][ValidateSet("Full", "Software", "SoftwareSystem", "SoftwareSystemUser", "Boot")][string]$HiveSet,
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
        [string]$HivePrefix = "z",
        [int]$MaxRetries = 5
    )

    # Define hive mappings
    $hiveMappings = @{
        "SOFTWARE" = "$MountPath\Windows\System32\config\SOFTWARE"
        "SYSTEM"   = "$MountPath\Windows\System32\config\SYSTEM"
        "NTUSER"   = "$MountPath\Users\Default\ntuser.dat"
        "DEFAULT"  = "$MountPath\Windows\System32\config\default"
        "COMPONENTS" = "$MountPath\Windows\System32\config\COMPONENTS"
    }

    # Determine which hives to load based on HiveSet
    $hivesToLoad = switch ($HiveSet) {
        "Full"                  { @("SOFTWARE", "SYSTEM", "NTUSER", "DEFAULT", "COMPONENTS") }
        "Software"              { @("SOFTWARE") }
        "SoftwareSystem"        { @("SOFTWARE", "SYSTEM") }
        "SoftwareSystemUser"    { @("SOFTWARE", "SYSTEM", "NTUSER") }
        "Boot"                  { @("SOFTWARE", "SYSTEM", "NTUSER", "DEFAULT") }
    }

    $loadedHives = @()

    try {
        # Load hives
        foreach ($hive in $hivesToLoad) {
            $hiveName = "HKLM\${HivePrefix}${hive}"
            $hivePath = $hiveMappings[$hive]

            if (Test-Path $hivePath) {
                $result = reg load $hiveName $hivePath 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $loadedHives += $hiveName
                    Write-Log -msg "Loaded hive: $hiveName from $hivePath"
                } else {
                    Write-Log -msg "Failed to load hive: $hiveName - $result"
                }
            } else {
                Write-Log -msg "Hive file not found: $hivePath"
            }
        }

        # Execute the script block
        & $ScriptBlock
    }
    catch {
        Write-Log -msg "Error in Invoke-WithLoadedHives: $($_.Exception.Message)"
        throw
    }
    finally {
        # Unload hives with retry logic
        # Run garbage collection first to release any handles
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        Start-Sleep -Milliseconds 500

        foreach ($hiveName in $loadedHives) {
            $unloaded = $false
            for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
                $result = reg unload $hiveName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $unloaded = $true
                    Write-Log -msg "Unloaded hive: $hiveName"
                    break
                }
                Write-Log -msg "Retry $attempt/$MaxRetries unloading hive: $hiveName"
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
                Start-Sleep -Seconds (1 * $attempt)
            }
            if (-not $unloaded) {
                Write-Log -msg "WARNING: Failed to unload hive after $MaxRetries attempts: $hiveName"
                Write-Host "  Warning: Could not unload registry hive $hiveName" -ForegroundColor Yellow
            }
        }
    }
}
