# HashVerification.ps1
# Provides file hash verification for downloaded files

function Test-FileHash {
    <#
    .SYNOPSIS
        Verifies the SHA256 hash of a downloaded file.
    .PARAMETER FilePath
        Path to the file to verify.
    .PARAMETER ExpectedHash
        Expected SHA256 hash string.
    .PARAMETER Algorithm
        Hash algorithm to use (default: SHA256).
    .RETURNS
        $true if hash matches, $false otherwise.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string]$ExpectedHash,
        [string]$Algorithm = "SHA256"
    )

    if (-not (Test-Path $FilePath)) {
        Write-Log -msg "Hash verification failed: File not found at $FilePath"
        return $false
    }

    try {
        $actualHash = (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash
        $match = $actualHash -eq $ExpectedHash.ToUpper()

        if ($match) {
            Write-Log -msg "Hash verification passed for: $FilePath"
        } else {
            Write-Log -msg "Hash verification FAILED for: $FilePath"
            Write-Log -msg "  Expected: $ExpectedHash"
            Write-Log -msg "  Actual:   $actualHash"
            Write-Host "  Warning: File hash mismatch! The downloaded file may be corrupted or tampered with." -ForegroundColor Red
        }

        return $match
    }
    catch {
        Write-Log -msg "Hash verification error: $($_.Exception.Message)"
        return $false
    }
}

function Get-FileHashValue {
    <#
    .SYNOPSIS
        Gets the hash of a file for logging/display purposes.
    .PARAMETER FilePath
        Path to the file.
    .PARAMETER Algorithm
        Hash algorithm (default: SHA256).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string]$Algorithm = "SHA256"
    )

    if (-not (Test-Path $FilePath)) { return $null }

    try {
        return (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash
    }
    catch {
        return $null
    }
}
