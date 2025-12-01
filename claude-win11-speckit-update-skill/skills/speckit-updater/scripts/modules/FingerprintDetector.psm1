<#
.SYNOPSIS
    Detects installed SpecKit version via fingerprint matching.

.DESCRIPTION
    The FingerprintDetector module provides automatic version detection for
    SpecKit installations by comparing normalized file hashes against a
    pre-computed fingerprint database. This enables frictionless onboarding
    for first-time users without an existing manifest.

    Key Features:
    - Fast signature check (3 files) covers 95%+ of cases
    - Full fingerprint matching (12 files) as fallback
    - Confidence scoring (High: 95-100%, Medium: 70-94%, Low: <70%)
    - Offline operation (database committed to repo)
    - Caching for performance

.NOTES
    Module: FingerprintDetector
    Author: SpecKit Safe Update Skill
    Version: 1.0.0
    Related Issue: #25
#>

# Requires HashUtils module for Get-NormalizedHash
# (Imported by orchestrator - no nested imports allowed per architecture)

$script:DatabaseCache = $null
$script:DatabasePath = $null

<#
.SYNOPSIS
    Loads the fingerprint database from the repository.

.DESCRIPTION
    Loads and caches the fingerprint database from data/speckit-fingerprints.json.
    The database is cached in memory for subsequent calls.

.PARAMETER Force
    Forces reload of the database even if already cached.

.OUTPUTS
    PSCustomObject
    The loaded fingerprint database with schema_version, versions, tracked_files, etc.

.EXAMPLE
    $db = Get-FingerprintDatabase
    Write-Host "Database contains $($db.total_versions) versions"
#>
function Get-FingerprintDatabase {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )

    try {
        # Return cached database if available
        if ($script:DatabaseCache -and -not $Force) {
            Write-Verbose "Using cached fingerprint database"
            return $script:DatabaseCache
        }

        # Determine database path (relative to module location)
        if (-not $script:DatabasePath) {
            $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            $script:DatabasePath = Join-Path $moduleRoot "data" "speckit-fingerprints.json"
        }

        Write-Verbose "Loading fingerprint database from: $script:DatabasePath"

        # Verify database exists
        if (-not (Test-Path $script:DatabasePath)) {
            throw "Fingerprint database not found at: $script:DatabasePath"
        }

        # Load and parse JSON
        $json = Get-Content -Path $script:DatabasePath -Raw -Encoding UTF8
        $database = $json | ConvertFrom-Json

        # Validate schema
        if (-not $database.schema_version) {
            throw "Invalid database: missing schema_version"
        }

        if ($database.schema_version -ne "1.0") {
            Write-Warning "Database schema version $($database.schema_version) may not be compatible with this module version"
        }

        # Cache and return
        $script:DatabaseCache = $database
        Write-Verbose "Loaded database with $($database.total_versions) versions (latest: $($database.latest_version))"

        return $database
    }
    catch {
        Write-Error "Failed to load fingerprint database: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Performs fast signature check using 3 core files.

.DESCRIPTION
    Quickly checks if the specified version matches by comparing hashes of
    3 signature files (.claude/commands/speckit.specify.md, speckit.plan.md,
    and .specify/memory/constitution.md). This covers 95%+ of cases.

.PARAMETER Version
    The version object from the database to check against.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project to check.

.OUTPUTS
    Boolean
    True if all 3 signature files match, false otherwise.

.EXAMPLE
    if (Test-VersionSignature -Version $versionObj -ProjectRoot $pwd) {
        Write-Host "Signature match!"
    }
#>
function Test-VersionSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Version,

        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    try {
        $database = Get-FingerprintDatabase

        # Check all signature files
        $matchCount = 0
        foreach ($file in $database.signature_files) {
            $filePath = Join-Path $ProjectRoot $file

            # File must exist
            if (-not (Test-Path $filePath)) {
                Write-Verbose "Signature file missing: $file"
                return $false
            }

            # Compute hash
            $actualHash = Get-NormalizedHash -FilePath $filePath
            $expectedHash = $Version.fingerprints.$file

            if ($actualHash -eq $expectedHash) {
                $matchCount++
                Write-Verbose "Signature match: $file"
            }
            else {
                Write-Verbose "Signature mismatch: $file (expected: $expectedHash, actual: $actualHash)"
                return $false
            }
        }

        # All signature files must match
        $signatureCount = $database.signature_files.Count
        Write-Verbose "Signature check: $matchCount/$signatureCount files matched"
        return ($matchCount -eq $signatureCount)
    }
    catch {
        Write-Error "Signature check failed: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Finds the best matching version using full fingerprint comparison.

.DESCRIPTION
    Compares all tracked files in the project against all versions in the
    database to find the best match. Returns the version with the highest
    match percentage.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project to check.

.OUTPUTS
    PSCustomObject
    Object with version_name, confidence, matched_files, total_files, match_percentage.

.EXAMPLE
    $match = Find-MatchingVersion -ProjectRoot $pwd
    if ($match.confidence -eq "High") {
        Write-Host "Detected version: $($match.version_name)"
    }
#>
function Find-MatchingVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    try {
        $database = Get-FingerprintDatabase
        $bestMatch = $null
        $bestMatchPercentage = 0

        Write-Verbose "Starting full fingerprint scan across $($database.total_versions) versions"

        # Iterate through all versions (newest to oldest)
        # Get version names and sort them
        $versionNames = @()
        foreach ($prop in $database.versions.PSObject.Properties) {
            $versionNames += $prop.Name
        }
        $sortedVersionNames = $versionNames | Sort-Object { [version]($_ -replace '^v', '') } -Descending

        foreach ($versionName in $sortedVersionNames) {
            $versionData = $database.versions.$versionName

            # Skip versions with no fingerprints (failed during generation)
            if ($versionData.files_tracked -eq 0) {
                Write-Verbose "Skipping $versionName (no fingerprints available)"
                continue
            }

            Write-Verbose "Checking $versionName..."

            # Try fast signature check first
            if (Test-VersionSignature -Version $versionData -ProjectRoot $ProjectRoot) {
                Write-Verbose "✓ Signature match for $versionName (100% confidence)"
                return [PSCustomObject]@{
                    version_name = $versionName
                    confidence = "High"
                    matched_files = $database.signature_files.Count
                    total_files = $database.signature_files.Count
                    match_percentage = 100
                    detection_method = "signature"
                }
            }

            # Fall back to full fingerprint comparison
            $matchedFiles = 0
            $totalFiles = 0

            foreach ($fileProperty in $versionData.fingerprints.PSObject.Properties) {
                $file = $fileProperty.Name
                $expectedHash = $fileProperty.Value
                $filePath = Join-Path $ProjectRoot $file

                $totalFiles++

                # Skip if file doesn't exist
                if (-not (Test-Path $filePath)) {
                    Write-Verbose "  File missing: $file"
                    continue
                }

                # Compute and compare hash
                $actualHash = Get-NormalizedHash -FilePath $filePath
                if ($actualHash -eq $expectedHash) {
                    $matchedFiles++
                }
            }

            # Calculate match percentage
            $matchPercentage = if ($totalFiles -gt 0) {
                [math]::Round(($matchedFiles / $totalFiles) * 100, 1)
            } else {
                0
            }

            Write-Verbose "  Match: $matchedFiles/$totalFiles files ($matchPercentage%)"

            # Track best match
            if ($matchPercentage -gt $bestMatchPercentage) {
                $bestMatchPercentage = $matchPercentage
                $bestMatch = [PSCustomObject]@{
                    version_name = $versionName
                    matched_files = $matchedFiles
                    total_files = $totalFiles
                    match_percentage = $matchPercentage
                    detection_method = "full"
                }
            }

            # Short-circuit if we found a perfect match
            if ($matchPercentage -eq 100) {
                Write-Verbose "✓ Perfect match found: $versionName"
                break
            }
        }

        # Assign confidence level based on match percentage
        if ($bestMatch) {
            $bestMatch | Add-Member -MemberType NoteProperty -Name confidence -Value $(
                if ($bestMatch.match_percentage -ge 95) { "High" }
                elseif ($bestMatch.match_percentage -ge 70) { "Medium" }
                else { "Low" }
            ) -Force

            Write-Verbose "Best match: $($bestMatch.version_name) with $($bestMatch.match_percentage)% confidence"
        }
        else {
            Write-Verbose "No matching version found"
        }

        return $bestMatch
    }
    catch {
        Write-Error "Version detection failed: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Detects the installed SpecKit version in a project.

.DESCRIPTION
    Main entry point for version detection. Analyzes SpecKit files in the
    project directory and identifies the installed version using fingerprint
    matching. Returns detection results with confidence scoring.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project to analyze. Defaults to current directory.

.PARAMETER UseSignatureOnly
    Only perform fast signature check (3 files). Skip full scan if signature doesn't match.

.OUTPUTS
    PSCustomObject
    Detection results with version_name, confidence, matched_files, detection_method.

.EXAMPLE
    $result = Get-InstalledSpecKitVersion -ProjectRoot $pwd
    if ($result.confidence -eq "High") {
        Write-Host "Detected SpecKit version: $($result.version_name)"
    }

.EXAMPLE
    # Fast check only (signature files)
    $result = Get-InstalledSpecKitVersion -UseSignatureOnly
    if ($result) {
        Write-Host "Quick match: $($result.version_name)"
    }
#>
function Get-InstalledSpecKitVersion {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter()]
        [switch]$UseSignatureOnly
    )

    try {
        Write-Verbose "Detecting SpecKit version in: $ProjectRoot"

        # Validate project structure
        $specifyDir = Join-Path $ProjectRoot ".specify"
        if (-not (Test-Path $specifyDir)) {
            throw "Not a SpecKit project: .specify/ directory not found"
        }

        $database = Get-FingerprintDatabase

        # Try signature-based detection first (fast path)
        Write-Verbose "Attempting signature-based detection..."

        # Get version names and sort them
        $versionNames = @()
        foreach ($prop in $database.versions.PSObject.Properties) {
            $versionNames += $prop.Name
        }
        $sortedVersionNames = $versionNames | Sort-Object { [version]($_ -replace '^v', '') } -Descending

        foreach ($versionName in $sortedVersionNames) {
            $versionData = $database.versions.$versionName

            if ($versionData.files_tracked -eq 0) {
                continue
            }

            if (Test-VersionSignature -Version $versionData -ProjectRoot $ProjectRoot) {
                Write-Verbose "✓ Version detected via signature: $versionName"
                return [PSCustomObject]@{
                    version_name = $versionName
                    confidence = "High"
                    matched_files = $database.signature_files.Count
                    total_files = $database.signature_files.Count
                    match_percentage = 100
                    detection_method = "signature"
                    release_date = $versionData.release_date
                    release_url = $versionData.release_url
                }
            }
        }

        # If signature-only mode, return null
        if ($UseSignatureOnly) {
            Write-Verbose "Signature-only mode: No match found"
            return $null
        }

        # Fall back to full fingerprint scan
        Write-Verbose "Signature detection failed. Performing full fingerprint scan..."
        $match = Find-MatchingVersion -ProjectRoot $ProjectRoot

        if ($match) {
            # Enrich with release metadata
            $versionData = $database.versions.($match.version_name)
            $match | Add-Member -MemberType NoteProperty -Name release_date -Value $versionData.release_date -Force
            $match | Add-Member -MemberType NoteProperty -Name release_url -Value $versionData.release_url -Force

            Write-Verbose "✓ Version detected via full scan: $($match.version_name) ($($match.confidence) confidence)"
            return $match
        }

        Write-Warning "Could not detect SpecKit version. No matching fingerprints found."
        return $null
    }
    catch {
        Write-Error "Version detection failed: $($_.Exception.Message)"
        throw
    }
}

# Export public functions
Export-ModuleMember -Function @(
    'Get-FingerprintDatabase'
    'Get-InstalledSpecKitVersion'
    'Find-MatchingVersion'
    'Test-VersionSignature'
)
