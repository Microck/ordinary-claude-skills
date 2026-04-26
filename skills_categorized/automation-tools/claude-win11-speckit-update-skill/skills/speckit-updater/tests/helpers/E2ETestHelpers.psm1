<#
.MODULE NAME
    E2ETestHelpers

.SYNOPSIS
    Reusable helper functions for end-to-end smart merge testing

.DESCRIPTION
    Provides business logic for E2E testing of the smart merge system including:
    - Version stratification across timeframes
    - Test project management and isolation
    - Dad joke content injection for preservation testing
    - Validation of merged files (semantic correctness and data preservation)
    - Comprehensive test reporting

.NOTES
    Author: SpecKit Update Skill
    Date: 2025-10-24
    Version: 1.0

    Design Principles:
    - Stateless functions (all state passed via parameters)
    - No dependencies on other modules (test file manages imports)
    - Deterministic behavior (fixed seed 42 for reproducibility)
    - Fail-fast error handling (throw on unrecoverable errors)
#>

#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================
# VERSION STRATIFICATION
# ============================================================

function Get-StratifiedVersions {
    <#
    .SYNOPSIS
        Selects stratified SpecKit versions for comprehensive merge testing.

    .DESCRIPTION
        Analyzes the fingerprints database and selects 10 versions distributed across
        three timeframes (old, middle, recent) using date-based boundaries. Ensures
        temporal diversity in test coverage.

    .PARAMETER FingerprintsData
        Parsed JSON object from data/speckit-fingerprints.json containing version metadata.

    .PARAMETER Seed
        Random number generator seed for reproducible selection (default: 42).

    .PARAMETER TotalVersions
        Total number of versions to select (default: 10, distributed as 3-3-4).

    .OUTPUTS
        string[] Array of version strings (e.g., "v0.0.50", "v0.0.79")

    .EXAMPLE
        $fingerprintsData = Get-Content "data/speckit-fingerprints.json" | ConvertFrom-Json
        $versions = Get-StratifiedVersions -FingerprintsData $fingerprintsData
        # Returns: @("v0.0.5", "v0.0.12", ..., "v0.0.79")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$FingerprintsData,

        [int]$Seed = 42,

        [int]$TotalVersions = 10
    )

    Write-Verbose "Stratifying versions from fingerprints database (seed: $Seed, total: $TotalVersions)"

    # Validate input
    if (-not $FingerprintsData.versions) {
        throw "FingerprintsData missing 'versions' property"
    }

    # Parse versions with release dates
    $allVersions = $FingerprintsData.versions.PSObject.Properties | ForEach-Object {
        [PSCustomObject]@{
            Version = $_.Name
            ReleaseDate = [datetime]$_.Value.release_date
        }
    } | Sort-Object ReleaseDate

    Write-Verbose "Found $($allVersions.Count) versions in database"

    if ($allVersions.Count -eq 0) {
        throw "No versions found in fingerprints database"
    }

    # Calculate date range boundaries (divide total range into 3 equal time periods)
    $oldestDate = $allVersions[0].ReleaseDate
    $newestDate = $allVersions[-1].ReleaseDate
    $totalDays = ($newestDate - $oldestDate).TotalDays
    $daysPerGroup = $totalDays / 3

    Write-Verbose "Date range: $oldestDate to $newestDate ($totalDays days)"
    Write-Verbose "Days per group: $daysPerGroup"

    # Group versions by timeframe
    $oldGroup = $allVersions | Where-Object {
        ($_.ReleaseDate - $oldestDate).TotalDays -lt $daysPerGroup
    }

    $middleGroup = $allVersions | Where-Object {
        $days = ($_.ReleaseDate - $oldestDate).TotalDays
        $days -ge $daysPerGroup -and $days -lt ($daysPerGroup * 2)
    }

    $recentGroup = $allVersions | Where-Object {
        ($_.ReleaseDate - $oldestDate).TotalDays -ge ($daysPerGroup * 2)
    }

    Write-Verbose "Old group: $($oldGroup.Count) versions"
    Write-Verbose "Middle group: $($middleGroup.Count) versions"
    Write-Verbose "Recent group: $($recentGroup.Count) versions"

    # Determine selection counts (3-3-4 distribution)
    $oldCount = [Math]::Min(3, $oldGroup.Count)
    $middleCount = [Math]::Min(3, $middleGroup.Count)
    $recentCount = [Math]::Min(4, $recentGroup.Count)

    # Warn if any group has fewer than desired count
    if ($oldGroup.Count -lt 3) {
        Write-Warning "Old group has only $($oldGroup.Count) versions (desired: 3)"
    }
    if ($middleGroup.Count -lt 3) {
        Write-Warning "Middle group has only $($middleGroup.Count) versions (desired: 3)"
    }
    if ($recentGroup.Count -lt 4) {
        Write-Warning "Recent group has only $($recentGroup.Count) versions (desired: 4)"
    }

    # Check if we have enough versions total
    $actualTotal = $oldCount + $middleCount + $recentCount
    if ($actualTotal -lt $TotalVersions) {
        Write-Warning "Database has only $actualTotal versions (desired: $TotalVersions)"
    }

    # Select random versions from each group (deterministic with seed)
    $selectedVersions = @()

    if ($oldCount -gt 0) {
        $selectedVersions += ($oldGroup | Get-Random -Count $oldCount -SetSeed $Seed).Version
    }

    if ($middleCount -gt 0) {
        $selectedVersions += ($middleGroup | Get-Random -Count $middleCount -SetSeed ($Seed + 1)).Version
    }

    if ($recentCount -gt 0) {
        $selectedVersions += ($recentGroup | Get-Random -Count $recentCount -SetSeed ($Seed + 2)).Version
    }

    Write-Verbose "Selected versions: $($selectedVersions -join ', ')"

    return $selectedVersions
}

function Get-RandomMergePairs {
    <#
    .SYNOPSIS
        Generates random upgrade pairs from provided SpecKit versions.

    .DESCRIPTION
        Creates all possible upgrade pairs (older → newer) from input versions, then
        randomly selects a subset for testing. Ensures only valid upgrade paths.

    .PARAMETER Versions
        Array of SpecKit version strings (e.g., @("v0.0.50", "v0.0.79")).

    .PARAMETER Count
        Number of merge pairs to select (default: 18).

    .PARAMETER Seed
        Random number generator seed for reproducible selection (default: 42).

    .OUTPUTS
        PSCustomObject[] Array of {From, To} objects representing upgrade paths.

    .EXAMPLE
        $versions = @("v0.0.50", "v0.0.60", "v0.0.70", "v0.0.79")
        $pairs = Get-RandomMergePairs -Versions $versions -Count 3
        # Returns: @({From='v0.0.50'; To='v0.0.79'}, {From='v0.0.60'; To='v0.0.70'}, ...)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Versions,

        [int]$Count = 18,

        [int]$Seed = 42
    )

    Write-Verbose "Generating merge pairs from $($Versions.Count) versions (count: $Count, seed: $Seed)"

    # Validate input
    if ($null -eq $Versions -or $Versions.Count -eq 0) {
        throw "Versions array is null or empty"
    }

    # Generate all possible upgrade pairs (older → newer)
    $allPairs = @()

    for ($i = 0; $i -lt $Versions.Count; $i++) {
        for ($j = $i + 1; $j -lt $Versions.Count; $j++) {
            # Parse version numbers (remove 'v' prefix)
            $v1String = $Versions[$i] -replace '^v', ''
            $v2String = $Versions[$j] -replace '^v', ''

            try {
                $v1 = [version]$v1String
                $v2 = [version]$v2String

                # Only create pair if v1 < v2 (valid upgrade path)
                if ($v1 -lt $v2) {
                    $allPairs += [PSCustomObject]@{
                        From = $Versions[$i]
                        To = $Versions[$j]
                    }
                }
                elseif ($v2 -lt $v1) {
                    # Reverse pair (ensure From is always older than To)
                    $allPairs += [PSCustomObject]@{
                        From = $Versions[$j]
                        To = $Versions[$i]
                    }
                }
                # If v1 == v2, skip (no upgrade needed)
            }
            catch {
                Write-Warning "Failed to parse version: $($Versions[$i]) or $($Versions[$j])"
            }
        }
    }

    Write-Verbose "Generated $($allPairs.Count) possible upgrade pairs"

    # If Count is greater than available pairs, return all pairs
    $actualCount = [Math]::Min($Count, $allPairs.Count)

    if ($actualCount -lt $Count) {
        Write-Warning "Only $actualCount pairs available (requested: $Count)"
    }

    # Randomly select pairs (deterministic with seed)
    if ($actualCount -eq $allPairs.Count) {
        # Return all pairs if we're selecting everything
        $selectedPairs = $allPairs
    }
    else {
        # Random selection
        $selectedPairs = $allPairs | Get-Random -Count $actualCount -SetSeed $Seed
    }

    Write-Verbose "Selected $($selectedPairs.Count) merge pairs"

    return $selectedPairs
}

# ============================================================
# TEST PROJECT MANAGEMENT
# ============================================================

function New-E2ETestProject {
    <#
    .SYNOPSIS
        Creates isolated test directory for merge testing.

    .DESCRIPTION
        Generates a unique directory name using GUID to prevent conflicts between
        parallel test executions. Creates directory in specified root path.

    .PARAMETER Version
        SpecKit version being tested (used in directory name for debugging).

    .PARAMETER Root
        Root directory for test environments (e.g., C:\Temp\e2e-tests).

    .OUTPUTS
        string Absolute path to created test directory.

    .EXAMPLE
        $testDir = New-E2ETestProject -Version "v0.0.79" -Root "C:\Temp\tests"
        # Returns: "C:\Temp\tests\test-v0.0.79-a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$Root
    )

    Write-Verbose "Creating test project for version $Version in $Root"

    # Validate root directory exists
    if (-not (Test-Path $Root)) {
        throw "Root directory does not exist: $Root"
    }

    # Generate unique directory name with GUID
    $guid = [System.Guid]::NewGuid().ToString()
    $dirName = "test-$Version-$guid"
    $testDir = Join-Path $Root $dirName

    # Create directory
    try {
        $null = New-Item -Path $testDir -ItemType Directory -Force -ErrorAction Stop
        Write-Verbose "Created test directory: $testDir"
    }
    catch {
        throw "Failed to create test directory: $($_.Exception.Message)"
    }

    return $testDir
}

function Install-SpecKitVersion {
    <#
    .SYNOPSIS
        Downloads and installs SpecKit templates from GitHub release.

    .DESCRIPTION
        Fetches specified SpecKit version from GitHub Releases API, downloads template
        archive, extracts to test project directory. Uses mutex for API coordination.

    .PARAMETER ProjectRoot
        Absolute path to test project directory.

    .PARAMETER Version
        SpecKit version to install (e.g., "v0.0.79").

    .OUTPUTS
        hashtable {Success, TemplatePath, ErrorMessage}

    .EXAMPLE
        $result = Install-SpecKitVersion -ProjectRoot "C:\Temp\test-123" -Version "v0.0.79"
        if ($result.Success) {
            Write-Host "Installed to: $($result.TemplatePath)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [string]$Version
    )

    Write-Verbose "Installing SpecKit $Version to $ProjectRoot"

    # Validate project root exists
    if (-not (Test-Path $ProjectRoot)) {
        return @{
            Success = $false
            TemplatePath = $null
            ErrorMessage = "Project root does not exist: $ProjectRoot"
        }
    }

    # Mutex for GitHub API coordination (prevents rate limiting in parallel execution)
    $mutex = $null

    try {
        # Acquire mutex for exclusive API access
        $mutex = New-Object System.Threading.Mutex($false, "Global\SpecKitE2EGitHubAPI")
        $null = $mutex.WaitOne()

        Write-Verbose "Acquired GitHub API mutex"

        # Add delay to respect rate limits (500ms)
        Start-Sleep -Milliseconds 500

        # Fetch release metadata from GitHub API
        $apiUrl = "https://api.github.com/repos/github/spec-kit/releases/tags/$Version"

        # Check for GitHub token
        $headers = @{}
        if ($env:GITHUB_PAT) {
            $headers['Authorization'] = "Bearer $env:GITHUB_PAT"
            Write-Verbose "Using GitHub PAT for authentication"
        }

        Write-Verbose "Fetching release from: $apiUrl"

        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        }
        catch {
            return @{
                Success = $false
                TemplatePath = $null
                ErrorMessage = "GitHub API error: $($_.Exception.Message)"
            }
        }

        # Get template archive URL
        $archiveUrl = $response.zipball_url
        if (-not $archiveUrl) {
            return @{
                Success = $false
                TemplatePath = $null
                ErrorMessage = "No zipball_url found in release metadata"
            }
        }

        Write-Verbose "Archive URL: $archiveUrl"

        # Download template archive
        $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "speckit-$Version-$([guid]::NewGuid()).zip"

        try {
            Invoke-WebRequest -Uri $archiveUrl -OutFile $tempZip -Headers $headers -ErrorAction Stop
            Write-Verbose "Downloaded template to: $tempZip"
        }
        catch {
            return @{
                Success = $false
                TemplatePath = $null
                ErrorMessage = "Failed to download archive: $($_.Exception.Message)"
            }
        }

        # Validate ZIP integrity
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
            $zip.Dispose()
            Write-Verbose "ZIP integrity validated"
        }
        catch {
            return @{
                Success = $false
                TemplatePath = $null
                ErrorMessage = "Corrupted template - ZIP integrity validation failed"
            }
        }

        # Extract to project root
        $extractPath = Join-Path $ProjectRoot ".specify-temp"

        try {
            Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force -ErrorAction Stop
            Write-Verbose "Extracted archive to: $extractPath"
        }
        catch {
            return @{
                Success = $false
                TemplatePath = $null
                ErrorMessage = "Failed to extract archive: $($_.Exception.Message)"
            }
        }

        # GitHub zipball creates a nested directory (github-spec-kit-{commit})
        # Find the extracted directory
        $extractedDirs = Get-ChildItem -Path $extractPath -Directory
        if ($extractedDirs.Count -eq 0) {
            return @{
                Success = $false
                TemplatePath = $null
                ErrorMessage = "No directory found in extracted archive"
            }
        }

        $sourceDir = $extractedDirs[0].FullName
        Write-Verbose "Source directory: $sourceDir"

        # Move .specify directory to project root
        $specifySource = Join-Path $sourceDir ".specify"
        $specifyDest = Join-Path $ProjectRoot ".specify"

        if (Test-Path $specifySource) {
            Copy-Item -Path $specifySource -Destination $specifyDest -Recurse -Force -ErrorAction Stop
            Write-Verbose "Copied .specify to project root"
        }
        else {
            return @{
                Success = $false
                TemplatePath = $null
                ErrorMessage = ".specify directory not found in archive"
            }
        }

        # Copy .claude directory to project root
        $claudeSource = Join-Path $sourceDir ".claude"
        $claudeDest = Join-Path $ProjectRoot ".claude"

        if (Test-Path $claudeSource) {
            Copy-Item -Path $claudeSource -Destination $claudeDest -Recurse -Force -ErrorAction Stop
            Write-Verbose "Copied .claude to project root"
        }

        # Cleanup temporary files
        Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue

        return @{
            Success = $true
            TemplatePath = $specifyDest
            ErrorMessage = $null
        }
    }
    catch {
        return @{
            Success = $false
            TemplatePath = $null
            ErrorMessage = "Unexpected error: $($_.Exception.Message)"
        }
    }
    finally {
        # Always release mutex
        if ($mutex) {
            try {
                $mutex.ReleaseMutex()
                $mutex.Dispose()
                Write-Verbose "Released GitHub API mutex"
            }
            catch {
                Write-Warning "Failed to release mutex: $($_.Exception.Message)"
            }
        }
    }
}

# ============================================================
# CONTENT INJECTION
# ============================================================

function Get-DadJokeDatabase {
    <#
    .SYNOPSIS
        Returns array of dad jokes for test content injection.

    .DESCRIPTION
        Provides embedded database of 50 dad jokes used as distinguishable test content.

    .OUTPUTS
        string[] Array of 50 dad jokes.

    .EXAMPLE
        $jokes = Get-DadJokeDatabase
        # Returns: @("Why don't scientists...", "I'm reading a book...", ...)
    #>
    [CmdletBinding()]
    param()

    # Embedded database of 50 dad jokes for test content injection
    # These jokes serve as distinguishable test content to validate data preservation
    return @(
        "Why don't scientists trust atoms? Because they make up everything!",
        "I'm reading a book about anti-gravity. It's impossible to put down!",
        "Why did the scarecrow win an award? He was outstanding in his field!",
        "I used to be a baker, but I couldn't make enough dough.",
        "What do you call a fake noodle? An impasta!",
        "Why did the bicycle fall over? It was two-tired!",
        "What do you call cheese that isn't yours? Nacho cheese!",
        "Why don't eggs tell jokes? They'd crack each other up!",
        "What did the ocean say to the beach? Nothing, it just waved!",
        "Why do seagulls fly over the sea? Because if they flew over the bay, they'd be bagels!",
        "What's orange and sounds like a parrot? A carrot!",
        "Why did the math book look so sad? Because it had too many problems!",
        "What do you call a bear with no teeth? A gummy bear!",
        "Why can't you hear a pterodactyl using the bathroom? Because the P is silent!",
        "What did one wall say to the other wall? I'll meet you at the corner!",
        "Why don't skeletons fight each other? They don't have the guts!",
        "What do you call a fish wearing a bowtie? Sofishticated!",
        "How does a penguin build its house? Igloos it together!",
        "Why did the coffee file a police report? It got mugged!",
        "What do you call a sleeping bull? A bulldozer!",
        "Why don't scientists trust stairs? Because they're always up to something!",
        "What did the grape do when he got stepped on? He let out a little wine!",
        "Why did the golfer bring two pairs of pants? In case he got a hole in one!",
        "What do you call a parade of rabbits hopping backwards? A receding hare-line!",
        "Why don't oysters donate to charity? Because they're shellfish!",
        "What do you call a dinosaur that crashes his car? Tyrannosaurus Wrecks!",
        "Why did the tomato turn red? Because it saw the salad dressing!",
        "What do you call a can opener that doesn't work? A can't opener!",
        "Why don't calendars ever win races? They only have dates!",
        "What did the janitor say when he jumped out of the closet? Supplies!",
        "Why did the cookie go to the doctor? Because it felt crumbly!",
        "What do you call a belt made of watches? A waist of time!",
        "Why did the stadium get hot after the game? All the fans left!",
        "What do you call a snowman with a six-pack? An abdominal snowman!",
        "Why don't programmers like nature? It has too many bugs!",
        "What did the left eye say to the right eye? Between you and me, something smells!",
        "Why did the invisible man turn down the job offer? He couldn't see himself doing it!",
        "What do you call a pig that does karate? A pork chop!",
        "Why did the gym close down? It just didn't work out!",
        "What do you call a factory that makes okay products? A satisfactory!",
        "Why don't trees use computers? They prefer to log in naturally!",
        "What did the buffalo say when his son left? Bison!",
        "Why did the student eat his homework? Because the teacher said it was a piece of cake!",
        "What do you call a boomerang that won't come back? A stick!",
        "Why don't mountains ever get cold? They wear snow caps!",
        "What did one hat say to the other? You stay here, I'll go on ahead!",
        "Why did the computer go to the doctor? It had a virus!",
        "What do you call a group of musical whales? An orca-stra!",
        "Why don't eggs work out at the gym? They'd crack under pressure!",
        "What did the zero say to the eight? Nice belt!"
    )
}

function Add-DadJokesToFile {
    <#
    .SYNOPSIS
        Injects dad jokes into markdown file for preservation testing.

    .DESCRIPTION
        Parses markdown file to identify safe insertion points (body paragraphs), avoiding
        headers, code blocks, and front matter. Randomly selects and inserts jokes.

    .PARAMETER FilePath
        Absolute path to markdown file.

    .PARAMETER MinJokes
        Minimum number of jokes to inject (default: 5).

    .PARAMETER MaxJokes
        Maximum number of jokes to inject (default: 10).

    .PARAMETER JokeDatabase
        Array of available dad jokes to select from.

    .OUTPUTS
        hashtable {Jokes, Locations, Count}

    .EXAMPLE
        $jokes = Get-DadJokeDatabase
        $result = Add-DadJokesToFile -FilePath "file.md" -JokeDatabase $jokes
        # Returns: @{Jokes=@("Why don't..."); Locations=@(42, 87); Count=7}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [int]$MinJokes = 5,

        [int]$MaxJokes = 10,

        [Parameter(Mandatory)]
        [string[]]$JokeDatabase
    )

    Write-Verbose "Injecting dad jokes into $FilePath (min: $MinJokes, max: $MaxJokes)"

    # Validate inputs
    if (-not (Test-Path $FilePath)) {
        throw "File does not exist: $FilePath"
    }

    if ($JokeDatabase.Count -eq 0) {
        throw "JokeDatabase is empty"
    }

    # Read file content as lines
    $lines = @(Get-Content -Path $FilePath -ErrorAction Stop)

    # Handle empty files
    if ($null -eq $lines -or $lines.Count -eq 0) {
        Write-Warning "File is empty: $FilePath"
        return @{
            Jokes = @()
            Locations = @()
            Count = 0
        }
    }

    # Identify safe insertion points (avoid headers, code blocks, front matter, empty lines)
    $safeLines = @()
    $inCodeBlock = $false
    $inFrontMatter = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Track front matter (first occurrence of --- delimiters within first 10 lines)
        if ($line -match '^---\s*$' -and $i -lt 10) {
            $inFrontMatter = !$inFrontMatter
            continue
        }

        # Track code blocks
        if ($line -match '^```') {
            $inCodeBlock = !$inCodeBlock
            continue
        }

        # Skip unsafe locations
        if ($inCodeBlock -or $inFrontMatter) { continue }
        if ($line -match '^#+\s') { continue }  # Headers
        if ($line.Trim() -eq '') { continue }   # Empty lines

        # This is a safe insertion point
        $safeLines += $i
    }

    Write-Verbose "Found $($safeLines.Count) safe insertion points"

    # Determine joke count (random between min and max)
    $random = New-Object System.Random(42)
    $jokeCount = $random.Next($MinJokes, $MaxJokes + 1)

    # Adjust if fewer safe lines than minimum jokes
    if ($safeLines.Count -lt $jokeCount) {
        $jokeCount = $safeLines.Count
        Write-Warning "File has only $($safeLines.Count) safe insertion points (requested: $MinJokes-$MaxJokes)"
    }

    if ($jokeCount -eq 0) {
        Write-Warning "No safe insertion points found in $FilePath"
        return @{
            Jokes = @()
            Locations = @()
            Count = 0
        }
    }

    # Randomly select insertion points and jokes
    $selectedLines = @($safeLines | Get-Random -Count $jokeCount -SetSeed 42)
    $selectedJokes = @($JokeDatabase | Get-Random -Count $jokeCount -SetSeed 42)

    # Sort lines in descending order (insert from bottom to top to preserve line numbers)
    $selectedLines = @($selectedLines | Sort-Object -Descending)

    # Insert jokes into content
    $modifiedLines = [System.Collections.ArrayList]::new($lines)

    for ($i = 0; $i -lt $selectedLines.Count; $i++) {
        $lineNum = $selectedLines[$i]
        $joke = $selectedJokes[$i]

        # Insert joke after the safe line
        $modifiedLines.Insert($lineNum + 1, $joke)

        Write-Verbose "Inserted joke at line $($lineNum + 1): $($joke.Substring(0, [Math]::Min(50, $joke.Length)))..."
    }

    # Write modified content back to file
    $modifiedLines | Set-Content -Path $FilePath -Force

    Write-Verbose "Successfully injected $jokeCount jokes into $FilePath"

    return @{
        Jokes = $selectedJokes
        Locations = $selectedLines
        Count = $jokeCount
    }
}

# ============================================================
# VALIDATION
# ============================================================

function Assert-AllJokesPreserved {
    <#
    .SYNOPSIS
        Validates all dad jokes preserved after merge (zero tolerance).

    .DESCRIPTION
        Checks that every injected dad joke appears in merged file content. Throws
        if any jokes missing (100% preservation required per FR-005).

    .PARAMETER FilePath
        Absolute path to merged file.

    .PARAMETER ExpectedJokes
        Array of dad jokes that were injected before merge.

    .PARAMETER MergedContent
        Content of merged file (read as -Raw string).

    .OUTPUTS
        None (throws on failure, returns nothing on success).

    .EXAMPLE
        $content = Get-Content -Path "merged.md" -Raw
        Assert-AllJokesPreserved -FilePath "merged.md" `
                                  -ExpectedJokes @("Why don't...") `
                                  -MergedContent $content
        # Throws if any jokes missing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$ExpectedJokes,

        [Parameter(Mandatory)]
        [string]$MergedContent
    )

    Write-Verbose "Validating joke preservation in $FilePath (expected: $($ExpectedJokes.Count))"

    # Track missing jokes
    $missingJokes = @()

    # Check each expected joke
    foreach ($joke in $ExpectedJokes) {
        # Use regex escape to handle special characters in jokes
        $escapedJoke = [regex]::Escape($joke)

        if ($MergedContent -notmatch $escapedJoke) {
            $missingJokes += $joke
            Write-Verbose "MISSING JOKE: $joke"
        }
        else {
            Write-Verbose "Found joke: $($joke.Substring(0, [Math]::Min(50, $joke.Length)))..."
        }
    }

    # Throw if any jokes missing (zero tolerance per FR-005)
    if ($missingJokes.Count -gt 0) {
        $jokePreview = $missingJokes | ForEach-Object {
            $_.Substring(0, [Math]::Min(60, $_.Length)) + "..."
        }

        $errorMessage = "MERGE FAILURE: $($missingJokes.Count) dad joke(s) lost in $FilePath`n"
        $errorMessage += "Missing jokes: $($jokePreview -join '; ')"

        throw $errorMessage
    }

    Write-Verbose "All $($ExpectedJokes.Count) dad jokes preserved successfully"
}

function Test-MergedFileValidity {
    <#
    .SYNOPSIS
        Performs 9-point semantic validation on merged file.

    .DESCRIPTION
        Validates merged file for integrity, markdown syntax, required sections,
        conflict markers, and dad joke preservation. Returns detailed results.

    .PARAMETER FilePath
        Absolute path to merged file.

    .PARAMETER OriginalJokes
        Hashtable from Add-DadJokesToFile with Jokes, Locations, Count.

    .OUTPUTS
        hashtable {Valid, Errors, Warnings, JokesFound, JokesExpected}

    .EXAMPLE
        $result = Test-MergedFileValidity -FilePath "merged.md" -OriginalJokes $jokes
        if (-not $result.Valid) {
            Write-Host "Errors: $($result.Errors -join '; ')"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [hashtable]$OriginalJokes
    )

    Write-Verbose "Validating merged file: $FilePath (9-point checklist)"

    $errors = @()
    $warnings = @()

    # 1. File integrity (exists, non-empty, reasonable size)
    if (-not (Test-Path $FilePath)) {
        $errors += "File does not exist: $FilePath"
        return @{
            Valid = $false
            Errors = $errors
            Warnings = $warnings
            JokesFound = 0
            JokesExpected = $OriginalJokes.Count
        }
    }

    $fileInfo = Get-Item $FilePath
    if ($fileInfo.Length -eq 0) {
        $errors += "File is empty: $FilePath"
    }

    if ($fileInfo.Length -gt 10MB) {
        $warnings += "File unusually large: $([Math]::Round($fileInfo.Length / 1MB, 1))MB"
    }

    # Read file content
    $content = Get-Content -Path $FilePath -Raw
    $lines = Get-Content -Path $FilePath

    # 2. Markdown syntax validation (basic checks)
    $inCodeBlock = $false
    foreach ($line in $lines) {
        if ($line -match '^```') {
            $inCodeBlock = !$inCodeBlock
        }
    }

    if ($inCodeBlock) {
        $errors += "Unclosed code block (odd number of ``` markers)"
    }

    # 3. Front matter validation (YAML structure)
    if ($content -match '^---\r?\n(.+?)\r?\n---') {
        $frontMatter = $matches[1]
        # Basic YAML validation
        if ($frontMatter -match ':\s*$') {
            $warnings += "Possible malformed YAML (empty values in front matter)"
        }
    }

    # 4. Required SpecKit sections present (for command files)
    if ($FilePath -match '\.claude\\commands\\') {
        $requiredSections = @('User Scenarios', 'Requirements', 'Success Criteria')
        foreach ($section in $requiredSections) {
            if ($content -notmatch "##\s+$section") {
                $warnings += "Missing expected section: $section"
            }
        }
    }

    # 5. Orphaned conflict markers check
    $conflictStarts = ([regex]::Matches($content, '^<<<<<<<', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $conflictMids = ([regex]::Matches($content, '^=======', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $conflictEnds = ([regex]::Matches($content, '^>>>>>>>', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count

    if ($conflictStarts -ne $conflictEnds) {
        $errors += "Orphaned conflict markers (start: $conflictStarts, end: $conflictEnds)"
    }

    if ($conflictStarts -gt 0) {
        $warnings += "File contains $conflictStarts unresolved conflict marker(s)"
    }

    # 6. Duplicate sections detection
    $headers = $lines | Where-Object { $_ -match '^##\s+(.+)$' } | ForEach-Object {
        if ($_ -match '^##\s+(.+)$') { $matches[1].Trim() }
    }

    $duplicates = $headers | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($duplicates) {
        $warnings += "Duplicate sections: $($duplicates.Name -join ', ')"
    }

    # 7. Section order logical (skip - too subjective without domain knowledge)

    # 8. Dad jokes preservation (100% requirement)
    $jokesFound = 0
    $jokesMissing = @()

    foreach ($joke in $OriginalJokes.Jokes) {
        $escapedJoke = [regex]::Escape($joke)
        if ($content -match $escapedJoke) {
            $jokesFound++
        }
        else {
            $jokesMissing += $joke
        }
    }

    if ($jokesMissing.Count -gt 0) {
        $errors += "Missing $($jokesMissing.Count) dad joke(s)"
    }

    # 9. No file corruption (valid encoding)
    try {
        $null = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($FilePath))
    }
    catch {
        $errors += "File encoding corruption: $($_.Exception.Message)"
    }

    Write-Verbose "Validation complete: $($errors.Count) errors, $($warnings.Count) warnings, $jokesFound/$($OriginalJokes.Count) jokes preserved"

    return @{
        Valid = ($errors.Count -eq 0)
        Errors = $errors
        Warnings = $warnings
        JokesFound = $jokesFound
        JokesExpected = $OriginalJokes.Count
    }
}

function Test-MergedCommandExecution {
    <#
    .SYNOPSIS
        Tests merged command file for execution readiness.

    .DESCRIPTION
        Validates command structure (front matter, markdown sections, syntax).
        Fallback to structural validation (actual execution not feasible in tests).

    .PARAMETER CommandPath
        Absolute path to merged command file.

    .PARAMETER ProjectRoot
        Test project root directory (for context).

    .OUTPUTS
        hashtable {Executable, StructureValid, ErrorMessage}

    .EXAMPLE
        $result = Test-MergedCommandExecution -CommandPath "speckit.specify.md" -ProjectRoot $testDir
        if ($result.StructureValid) {
            Write-Host "Command structure valid"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandPath,

        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    Write-Verbose "Testing command execution readiness: $CommandPath"

    # Use structural validation (Option A from research)
    # Actual execution (Option C) would require Claude Code runtime integration
    return Test-CommandStructure -CommandPath $CommandPath
}

function Test-CommandStructure {
    <#
    .SYNOPSIS
        Helper function for structural validation of command files.

    .DESCRIPTION
        Validates command file structure (front matter, sections, syntax).
        Called by Test-MergedCommandExecution as fallback mechanism.

    .PARAMETER CommandPath
        Absolute path to command file.

    .OUTPUTS
        hashtable {Executable, StructureValid, ErrorMessage}

    .EXAMPLE
        $result = Test-CommandStructure -CommandPath "speckit.specify.md"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandPath
    )

    Write-Verbose "Validating command structure: $CommandPath"

    $errors = @()

    # Validate file exists
    if (-not (Test-Path $CommandPath)) {
        return @{
            Executable = $false
            StructureValid = $false
            ErrorMessage = "File does not exist: $CommandPath"
        }
    }

    # Read content
    $content = Get-Content -Path $CommandPath -Raw
    $lines = Get-Content -Path $CommandPath

    # 1. Front matter validation (required for Claude Code commands)
    if ($content -notmatch '^---\r?\n(.+?)\r?\n---') {
        $errors += "Missing front matter (required for Claude Code commands)"
    }
    else {
        $frontMatter = $matches[1]

        # Check for required front matter fields (minimal check)
        if ($frontMatter -notmatch 'name\s*:') {
            $errors += "Front matter missing 'name' field"
        }

        if ($frontMatter -notmatch 'description\s*:') {
            $errors += "Front matter missing 'description' field"
        }
    }

    # 2. Markdown sections present
    $hasSections = $lines | Where-Object { $_ -match '^##\s+' }

    if (-not $hasSections) {
        $errors += "No markdown sections found (expected ## headers)"
    }

    # 3. No unclosed code blocks
    $codeBlockCount = ([regex]::Matches($content, '^```', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count

    if ($codeBlockCount % 2 -ne 0) {
        $errors += "Unclosed code block (odd number of ``` markers: $codeBlockCount)"
    }

    # 4. No orphaned conflict markers
    $conflictStarts = ([regex]::Matches($content, '^<<<<<<<', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    $conflictEnds = ([regex]::Matches($content, '^>>>>>>>', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count

    if ($conflictStarts -ne $conflictEnds) {
        $errors += "Orphaned conflict markers (start: $conflictStarts, end: $conflictEnds)"
    }

    if ($conflictStarts -gt 0) {
        $errors += "Unresolved conflict markers present ($conflictStarts markers)"
    }

    # Build result
    $structureValid = ($errors.Count -eq 0)

    Write-Verbose "Structure validation: $(if ($structureValid) { 'VALID' } else { 'INVALID' }) - $($errors.Count) error(s)"

    return @{
        Executable = $false  # Not actually executed (structural validation only)
        StructureValid = $structureValid
        ErrorMessage = if ($errors.Count -gt 0) { $errors -join '; ' } else { $null }
    }
}

# ============================================================
# REPORTING
# ============================================================

function Write-E2ETestReport {
    <#
    .SYNOPSIS
        Generates comprehensive test report with statistics.

    .DESCRIPTION
        Creates formatted report with summary statistics, per-merge details, and
        aggregate metrics. Writes to stdout for Pester output capture.

    .PARAMETER TestResults
        Array of Test Scenario objects from parallel execution.

    .OUTPUTS
        None (writes formatted report to stdout).

    .EXAMPLE
        Write-E2ETestReport -TestResults $results
        # Outputs formatted report to console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$TestResults
    )

    Write-Verbose "Generating E2E test report for $($TestResults.Count) tests"

    # Calculate aggregate statistics
    $totalTests = $TestResults.Count
    $passed = ($TestResults | Where-Object { $_.Status -eq 'Completed' }).Count
    $failed = ($TestResults | Where-Object { $_.Status -eq 'Failed' }).Count
    $skipped = ($TestResults | Where-Object { $_.Status -eq 'Skipped' }).Count
    $timeout = ($TestResults | Where-Object { $_.Status -eq 'Timeout' }).Count

    # Calculate joke preservation statistics
    $totalJokes = ($TestResults | Measure-Object -Property TotalJokes -Sum).Sum
    $preservedJokes = ($TestResults | Measure-Object -Property JokesPreserved -Sum).Sum
    $lostJokes = $totalJokes - $preservedJokes
    $preservationRate = if ($totalJokes -gt 0) { ($preservedJokes / $totalJokes) * 100 } else { 0 }

    # Calculate performance metrics
    $durations = $TestResults | Where-Object { $_.Duration -and $_.Duration.TotalSeconds -gt 0 } |
                                Select-Object -ExpandProperty Duration

    if ($durations.Count -gt 0) {
        $avgDuration = [TimeSpan]::FromSeconds(($durations | Measure-Object -Property TotalSeconds -Average).Average)
        $fastestTest = $TestResults | Where-Object { $_.Duration -and $_.Duration.TotalSeconds -gt 0 } |
                                      Sort-Object -Property Duration | Select-Object -First 1
        $slowestTest = $TestResults | Where-Object { $_.Duration -and $_.Duration.TotalSeconds -gt 0 } |
                                      Sort-Object -Property Duration -Descending | Select-Object -First 1
        $totalDuration = [TimeSpan]::FromSeconds(($durations | Measure-Object -Property TotalSeconds -Sum).Sum)
    } else {
        $avgDuration = [TimeSpan]::Zero
        $fastestTest = $null
        $slowestTest = $null
        $totalDuration = [TimeSpan]::Zero
    }

    # Generate report header
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "End-to-End Smart Merge Test Report" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    # Summary section
    Write-Host "Summary:" -ForegroundColor White
    Write-Host "  Total Tests: $totalTests" -ForegroundColor Gray
    Write-Host "  Passed: $passed ($([math]::Round(($passed / $totalTests) * 100, 1))%)" -ForegroundColor $(if ($passed -eq $totalTests) { 'Green' } else { 'Yellow' })
    Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "  Skipped: $skipped" -ForegroundColor $(if ($skipped -gt 0) { 'Yellow' } else { 'Gray' })
    Write-Host "  Timeout: $timeout" -ForegroundColor $(if ($timeout -gt 0) { 'Red' } else { 'Gray' })

    if ($totalDuration.TotalSeconds -gt 0) {
        Write-Host "  Total Duration: $($totalDuration.ToString('mm\:ss'))" -ForegroundColor Gray
    }
    Write-Host ""

    # Dad joke preservation section
    Write-Host "Dad Joke Preservation:" -ForegroundColor White
    Write-Host "  Total Injected: $($totalJokes.ToString('N0'))" -ForegroundColor Gray
    Write-Host "  Total Preserved: $($preservedJokes.ToString('N0')) ($([math]::Round($preservationRate, 1))%)" -ForegroundColor $(if ($preservationRate -eq 100) { 'Green' } else { 'Red' })
    Write-Host "  Data Loss: $lostJokes jokes" -ForegroundColor $(if ($lostJokes -eq 0) { 'Green' } else { 'Red' })
    Write-Host ""

    # Semantic validation section (if results available)
    $semanticPassed = ($TestResults | Measure-Object -Property SemanticValidationPassed -Sum).Sum
    $semanticFailed = ($TestResults | Measure-Object -Property SemanticValidationFailed -Sum).Sum
    $commandPassed = ($TestResults | Measure-Object -Property CommandValidationPassed -Sum).Sum
    $commandFailed = ($TestResults | Measure-Object -Property CommandValidationFailed -Sum).Sum

    if ($semanticPassed -gt 0 -or $semanticFailed -gt 0 -or $commandPassed -gt 0 -or $commandFailed -gt 0) {
        Write-Host "Advanced Validation:" -ForegroundColor White

        if ($semanticPassed -gt 0 -or $semanticFailed -gt 0) {
            $semanticTotal = $semanticPassed + $semanticFailed
            $semanticRate = if ($semanticTotal -gt 0) { ($semanticPassed / $semanticTotal) * 100 } else { 0 }
            Write-Host "  Semantic (9-point checklist):" -ForegroundColor Gray
            Write-Host "    Passed: $semanticPassed / $semanticTotal ($([math]::Round($semanticRate, 1))%)" -ForegroundColor $(if ($semanticRate -eq 100) { 'Green' } else { 'Yellow' })
            if ($semanticFailed -gt 0) {
                Write-Host "    Failed: $semanticFailed" -ForegroundColor Red
            }
        }

        if ($commandPassed -gt 0 -or $commandFailed -gt 0) {
            $commandTotal = $commandPassed + $commandFailed
            $commandRate = if ($commandTotal -gt 0) { ($commandPassed / $commandTotal) * 100 } else { 0 }
            Write-Host "  Command Execution:" -ForegroundColor Gray
            Write-Host "    Passed: $commandPassed / $commandTotal ($([math]::Round($commandRate, 1))%)" -ForegroundColor $(if ($commandRate -eq 100) { 'Green' } else { 'Yellow' })
            if ($commandFailed -gt 0) {
                Write-Host "    Failed: $commandFailed" -ForegroundColor Red
            }
        }

        Write-Host ""
    }

    # Performance section
    if ($avgDuration.TotalSeconds -gt 0) {
        Write-Host "Performance:" -ForegroundColor White
        Write-Host "  Average Merge Time: $($avgDuration.ToString('ss\.f'))s" -ForegroundColor Gray

        if ($fastestTest) {
            Write-Host "  Fastest: $($fastestTest.SourceVersion) → $($fastestTest.TargetVersion) ($($fastestTest.Duration.ToString('ss\.f'))s)" -ForegroundColor Gray
        }

        if ($slowestTest) {
            Write-Host "  Slowest: $($slowestTest.SourceVersion) → $($slowestTest.TargetVersion) ($($slowestTest.Duration.ToString('ss\.f'))s)" -ForegroundColor Gray
        }
        Write-Host ""
    }

    # Per-merge details
    Write-Host "Per-Merge Details:" -ForegroundColor White

    $index = 1
    foreach ($result in $TestResults) {
        $statusColor = switch ($result.Status) {
            'Completed' { 'Green' }
            'Failed' { 'Red' }
            'Timeout' { 'Red' }
            'Skipped' { 'Yellow' }
            default { 'Gray' }
        }

        $durationStr = if ($result.Duration) { $result.Duration.ToString('ss\.f') + "s" } else { "N/A" }
        $filesStr = if ($result.PSObject.Properties.Name -contains 'FilesProcessed') { $result.FilesProcessed } else { "N/A" }
        $jokesStr = if ($result.PSObject.Properties.Name -contains 'JokesPreserved' -and
                         $result.PSObject.Properties.Name -contains 'TotalJokes') {
            "$($result.JokesPreserved)/$($result.TotalJokes)"
        } else {
            "N/A"
        }

        $statusText = $result.Status.ToUpper()
        Write-Host "  [$($index.ToString('D2'))/$($totalTests.ToString('D2'))] " -NoNewline -ForegroundColor Gray
        Write-Host "$($result.SourceVersion) → $($result.TargetVersion): " -NoNewline -ForegroundColor Gray
        Write-Host "$statusText " -NoNewline -ForegroundColor $statusColor
        Write-Host "($durationStr) - Files: $filesStr, Jokes: $jokesStr" -ForegroundColor Gray

        # Show error message if failed
        if ($result.Status -in @('Failed', 'Timeout') -and $result.ErrorMessage) {
            Write-Host "      Error: $($result.ErrorMessage)" -ForegroundColor Red
        }

        $index++
    }
    Write-Host ""

    # Final result
    Write-Host "============================================================" -ForegroundColor Cyan

    if ($passed -eq $totalTests -and $lostJokes -eq 0) {
        Write-Host "Result: ALL TESTS PASSED ✓" -ForegroundColor Green
    } elseif ($failed -gt 0 -or $timeout -gt 0) {
        Write-Host "Result: TESTS FAILED ✗" -ForegroundColor Red
    } else {
        Write-Host "Result: TESTS COMPLETED WITH WARNINGS" -ForegroundColor Yellow
    }

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-MergePairStatistics {
    <#
    .SYNOPSIS
        Extracts statistics from Test Scenario object.

    .DESCRIPTION
        Parses Test Scenario and returns formatted statistics hashtable.

    .PARAMETER TestResult
        Test Scenario object from merge test execution.

    .OUTPUTS
        hashtable {Duration, FilesProcessed, JokesPreserved, ValidationsPassed}

    .EXAMPLE
        $stats = Get-MergePairStatistics -TestResult $scenario
        # Returns: @{Duration=42.3s; FilesProcessed=12; ...}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$TestResult
    )

    Write-Verbose "Extracting statistics from test result: $($TestResult.SourceVersion) → $($TestResult.TargetVersion)"

    # Extract duration (ensure it's a TimeSpan)
    $duration = if ($TestResult.Duration -is [TimeSpan]) {
        $TestResult.Duration
    } elseif ($TestResult.Duration -is [double] -or $TestResult.Duration -is [int]) {
        [TimeSpan]::FromSeconds($TestResult.Duration)
    } else {
        [TimeSpan]::Zero
    }

    # Extract files processed
    $filesProcessed = if ($TestResult.PSObject.Properties.Name -contains 'FilesProcessed') {
        $TestResult.FilesProcessed
    } else {
        0
    }

    # Extract jokes preserved
    $jokesPreserved = if ($TestResult.PSObject.Properties.Name -contains 'JokesPreserved') {
        $TestResult.JokesPreserved
    } else {
        0
    }

    # Extract total jokes
    $totalJokes = if ($TestResult.PSObject.Properties.Name -contains 'TotalJokes') {
        $TestResult.TotalJokes
    } else {
        0
    }

    # Extract validation status
    $validationsPassed = if ($TestResult.PSObject.Properties.Name -contains 'ValidationResults') {
        $TestResult.ValidationResults.Valid -eq $true
    } else {
        $false
    }

    return @{
        Duration = $duration
        FilesProcessed = $filesProcessed
        JokesPreserved = $jokesPreserved
        TotalJokes = $totalJokes
        ValidationsPassed = $validationsPassed
        Status = $TestResult.Status
    }
}

# ============================================================
# MODULE EXPORTS
# ============================================================

Export-ModuleMember -Function @(
    'Get-StratifiedVersions',
    'Get-RandomMergePairs',
    'New-E2ETestProject',
    'Install-SpecKitVersion',
    'Add-DadJokesToFile',
    'Get-DadJokeDatabase',
    'Assert-AllJokesPreserved',
    'Test-MergedFileValidity',
    'Test-MergedCommandExecution',
    'Test-CommandStructure',
    'Write-E2ETestReport',
    'Get-MergePairStatistics'
)
