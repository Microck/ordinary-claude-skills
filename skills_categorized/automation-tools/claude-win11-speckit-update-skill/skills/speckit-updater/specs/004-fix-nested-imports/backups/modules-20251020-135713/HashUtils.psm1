#Requires -Version 7.0

<#
.SYNOPSIS
    Hash utilities for normalized file comparison in SpecKit Safe Update.

.DESCRIPTION
    Provides normalized hash computation for detecting file customizations.
    Normalizes line endings, trailing whitespace, and BOM to ensure accurate
    content comparison across different editors and platforms.

.NOTES
    Module Name: HashUtils
    Author: SpecKit Safe Update Team
    Version: 1.0
#>

function Get-NormalizedHash {
    <#
    .SYNOPSIS
        Computes normalized SHA-256 hash of a file.

    .DESCRIPTION
        Reads file content and computes SHA-256 hash after normalizing:
        - Line endings (CRLF → LF)
        - Trailing whitespace per line
        - BOM (Byte Order Mark) removal

        This ensures files with identical content but different formatting
        produce the same hash, allowing accurate detection of meaningful changes.

    .PARAMETER FilePath
        Path to the file to hash. Must be a valid file path.

    .OUTPUTS
        String
        Hash in format "sha256:HEXSTRING" (e.g., "sha256:ABC123...")

    .EXAMPLE
        Get-NormalizedHash -FilePath "C:\project\.claude\commands\speckit.plan.md"
        Returns: "sha256:A1B2C3D4..."

    .EXAMPLE
        $hash1 = Get-NormalizedHash -FilePath "file-with-crlf.txt"
        $hash2 = Get-NormalizedHash -FilePath "file-with-lf.txt"
        # If content is identical, $hash1 -eq $hash2 will be $true

    .NOTES
        Normalization Algorithm:
        1. Read file as UTF-8 text
        2. Convert CRLF → LF
        3. Trim trailing whitespace from each line
        4. Remove BOM if present (0xFEFF)
        5. Compute SHA-256 hash
        6. Return as "sha256:HEXSTRING"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    try {
        # Validate file exists
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "File not found: $FilePath"
        }

        # Test file accessibility (handles locked files)
        try {
            $fileStream = [System.IO.File]::Open($FilePath, 'Open', 'Read', 'Read')
            $fileStream.Close()
        }
        catch [System.UnauthorizedAccessException] {
            throw "Permission denied: Cannot read file '$FilePath'"
        }
        catch [System.IO.IOException] {
            throw "File is locked or inaccessible: $FilePath"
        }

        # Read file as UTF-8 text
        $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)

        # Normalize line endings: CRLF → LF
        $normalized = $content -replace "`r`n", "`n"

        # Trim trailing whitespace from each line
        $lines = $normalized -split "`n"
        $trimmedLines = $lines | ForEach-Object { $_.TrimEnd() }
        $normalized = $trimmedLines -join "`n"

        # Remove BOM if present
        if ($normalized.Length -gt 0 -and $normalized[0] -eq [char]0xFEFF) {
            $normalized = $normalized.Substring(1)
        }

        # Compute SHA-256 hash
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $sha256.ComputeHash($bytes)
            $hashString = ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToUpperInvariant()

            return "sha256:$hashString"
        }
        finally {
            $sha256.Dispose()
        }
    }
    catch {
        # Re-throw with context
        throw "Failed to compute normalized hash for '$FilePath': $($_.Exception.Message)"
    }
}

function Compare-FileHashes {
    <#
    .SYNOPSIS
        Compares two file hash strings for equality.

    .DESCRIPTION
        Compares two hash strings (typically from Get-NormalizedHash).
        Performs case-insensitive comparison as hash hex values are
        conventionally uppercase but may vary by implementation.

    .PARAMETER Hash1
        First hash string to compare (e.g., "sha256:ABC123...")

    .PARAMETER Hash2
        Second hash string to compare (e.g., "sha256:DEF456...")

    .OUTPUTS
        Boolean
        $true if hashes are equal, $false otherwise

    .EXAMPLE
        $original = "sha256:A1B2C3..."
        $current = Get-NormalizedHash -FilePath "file.txt"
        $isUnchanged = Compare-FileHashes -Hash1 $original -Hash2 $current

    .EXAMPLE
        if (Compare-FileHashes -Hash1 $hash1 -Hash2 $hash2) {
            Write-Host "Files are identical"
        }

    .NOTES
        Comparison is case-insensitive to handle hash format variations.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Hash1,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Hash2
    )

    try {
        # Case-insensitive comparison
        return $Hash1.ToLowerInvariant() -eq $Hash2.ToLowerInvariant()
    }
    catch {
        throw "Failed to compare hashes: $($_.Exception.Message)"
    }
}

# Export module members
Export-ModuleMember -Function Get-NormalizedHash, Compare-FileHashes
