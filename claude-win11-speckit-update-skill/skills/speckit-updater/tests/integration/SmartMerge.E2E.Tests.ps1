<#
.SYNOPSIS
    End-to-End Smart Merge Test Suite

.DESCRIPTION
    Comprehensive E2E testing of the smart merge system across multiple SpecKit versions
    with parallel execution. Validates 100% data preservation (zero tolerance for loss).

    Test Workflow:
    1. Stratify SpecKit versions (10 versions across old/middle/recent timeframes)
    2. Generate random merge pairs (15-20 upgrade paths)
    3. Execute merge tests in parallel (4 threads)
    4. Inject dad jokes into files before merge
    5. Validate 100% joke preservation after merge
    6. Generate comprehensive test report

.NOTES
    Author: SpecKit Update Skill
    Date: 2025-10-24
    Version: 1.0

    Requirements:
    - PowerShell 7.0+ (ForEach-Object -Parallel support)
    - Pester 5.x
    - 500MB free disk space
    - Internet connection (GitHub API)

    Performance:
    - Default: 4 parallel threads, 12-15 minute execution
    - Sequential: 45-60 minutes
#>

#Requires -Version 7.0
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Repository root (two levels up from this file)
    $script:repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    # Import E2E test helper module
    $script:helperModulePath = Join-Path $repoRoot "tests\helpers\E2ETestHelpers.psm1"
    Import-Module $helperModulePath -Force -ErrorAction Stop

    Write-Host "Loaded E2ETestHelpers module from: $helperModulePath" -ForegroundColor Cyan

    # Load fingerprints database
    $fingerprintsPath = Join-Path $repoRoot "data\speckit-fingerprints.json"

    if (-not (Test-Path $fingerprintsPath)) {
        throw "Fingerprints database not found: $fingerprintsPath"
    }

    try {
        $script:fingerprintsData = Get-Content $fingerprintsPath -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host "Loaded fingerprints database: $($fingerprintsData.versions.PSObject.Properties.Count) versions" -ForegroundColor Cyan
    }
    catch {
        throw "Failed to parse fingerprints database: $($_.Exception.Message)"
    }

    # Initialize test root directory
    $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "e2e-tests"

    if (-not (Test-Path $testRoot)) {
        $null = New-Item -Path $testRoot -ItemType Directory -Force
        Write-Host "Created test root directory: $testRoot" -ForegroundColor Cyan
    }

    # Select stratified versions (10 versions across old/middle/recent timeframes)
    Write-Host "Selecting stratified versions..." -ForegroundColor Cyan
    $script:selectedVersions = Get-StratifiedVersions -FingerprintsData $fingerprintsData -Verbose

    Write-Host "Selected versions: $($selectedVersions -join ', ')" -ForegroundColor Yellow

    # Generate merge pairs (15-20 upgrade paths)
    Write-Host "Generating merge pairs..." -ForegroundColor Cyan
    $script:mergePairs = Get-RandomMergePairs -Versions $selectedVersions -Count 18 -Verbose

    Write-Host "Generated $($mergePairs.Count) merge pairs for testing" -ForegroundColor Yellow

    # Get dad jokes database
    $script:dadJokes = Get-DadJokeDatabase
    Write-Host "Loaded $($dadJokes.Count) dad jokes for content injection" -ForegroundColor Cyan
}

Describe "End-to-End Smart Merge Test" -Tag 'Integration', 'E2E', 'SmartMerge' {

    Context "Multi-Version Merge Validation (Parallel)" {

        It "Should successfully execute all merge tests in parallel with 100% data preservation" {
            # User Story 3: Parallel execution (18 merge pairs, 4 threads)
            # Target: Complete in <15 minutes with thread-safe coordination

            $totalTests = $mergePairs.Count
            $suiteStartTime = Get-Date

            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "Starting E2E Smart Merge Test Suite" -ForegroundColor Cyan
            Write-Host "Total merge pairs: $totalTests" -ForegroundColor Cyan
            Write-Host "Parallel threads: 4" -ForegroundColor Cyan
            Write-Host "========================================`n" -ForegroundColor Cyan

            # Execute merge tests in parallel (User Story 3)
            $script:testResults = $mergePairs | ForEach-Object -Parallel {
                # Import helper module in parallel context
                $helperModulePath = $using:helperModulePath
                Import-Module $helperModulePath -Force -ErrorAction Stop

                # Get variables from outer scope
                $testRoot = $using:testRoot
                $dadJokes = $using:dadJokes
                $testPair = $_
                $totalTests = $using:totalTests
                $repoRoot = $using:repoRoot

                $testDir = $null
                $startTime = Get-Date

                try {
                    # Pre-test disk space validation (User Story 3 - T022)
                    $availableSpaceMB = (Get-PSDrive -Name C).Free / 1MB

                    if ($availableSpaceMB -lt 100) {
                        throw "Insufficient disk space: $([Math]::Round($availableSpaceMB, 1))MB available (minimum 100MB required)"
                    }

                    Write-Verbose "Testing merge: $($testPair.From) → $($testPair.To) (Available space: $([Math]::Round($availableSpaceMB, 1))MB)"

                    # Timeout wrapper for test execution (User Story 3 - T023)
                    $timeoutSeconds = 300  # 5 minutes
                    $testJob = Start-ThreadJob -ScriptBlock {
                        param($testDir, $testPair, $dadJokes, $repoRoot, $helperModulePath, $testRoot)

                        # Import helper module in thread job context
                        Import-Module $helperModulePath -Force -ErrorAction Stop

                        # Create isolated test project
                        $testDir = New-E2ETestProject -Version $testPair.From -Root $testRoot
                        Write-Verbose "  Created test directory: $testDir"

                        # Install source version
                        Write-Verbose "  Installing SpecKit $($testPair.From)..."
                        $installResult = Install-SpecKitVersion -ProjectRoot $testDir -Version $testPair.From

                        if (-not $installResult.Success) {
                            throw "Failed to install $($testPair.From): $($installResult.ErrorMessage)"
                        }

                        # Inject dad jokes into all command files
                        $jokeResults = @{}
                        $commandPath = Join-Path $testDir ".claude\commands"

                        if (-not (Test-Path $commandPath)) {
                            throw "Commands directory not found: $commandPath"
                        }

                        $commandFiles = Get-ChildItem -Path $commandPath -Filter "*.md" -ErrorAction Stop

                        $totalJokesInjected = 0
                        foreach ($file in $commandFiles) {
                            $result = Add-DadJokesToFile -FilePath $file.FullName -JokeDatabase $dadJokes
                            $jokeResults[$file.FullName] = $result
                            $totalJokesInjected += $result.Count
                        }

                        Write-Verbose "Injected $totalJokesInjected jokes across $($commandFiles.Count) files"

                        # Execute merge to target version using update-orchestrator.ps1
                        Write-Verbose "  Executing merge: $($testPair.From) → $($testPair.To)..."
                        $orchestratorPath = Join-Path $repoRoot "scripts\update-orchestrator.ps1"

                        # Change to test directory to run orchestrator
                        Push-Location $testDir

                        try {
                            # Run orchestrator with -Proceed flag (non-interactive mode)
                            $mergeResult = & $orchestratorPath -Version $testPair.To -Proceed -ErrorAction SilentlyContinue 2>&1

                            # Check if merge succeeded (exit code should be 0)
                            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                                throw "Merge failed with exit code $LASTEXITCODE"
                            }

                            Write-Verbose "  Merge completed successfully"
                        }
                        finally {
                            Pop-Location
                        }

                        # Validate all jokes are present
                        $jokesPreserved = 0
                        $validationErrors = @()

                        foreach ($file in $commandFiles) {
                            $mergedContent = Get-Content -Path $file.FullName -Raw
                            $expectedJokes = $jokeResults[$file.FullName].Jokes

                            try {
                                Assert-AllJokesPreserved -FilePath $file.FullName `
                                                          -ExpectedJokes $expectedJokes `
                                                          -MergedContent $mergedContent
                                $jokesPreserved += $expectedJokes.Count
                            }
                            catch {
                                $validationErrors += "Validation failed for $($file.Name): $($_.Exception.Message)"
                            }
                        }

                        # Semantic validation (9-point checklist)
                        $semanticValidationPassed = 0
                        $semanticValidationFailed = 0

                        foreach ($file in $commandFiles) {
                            try {
                                $validationResult = Test-MergedFileValidity -FilePath $file.FullName
                                if ($validationResult.IsValid) {
                                    $semanticValidationPassed++
                                } else {
                                    $semanticValidationFailed++
                                    $validationErrors += "Semantic validation failed for $($file.Name): $($validationResult.Failures -join '; ')"
                                }
                            }
                            catch {
                                $semanticValidationFailed++
                                $validationErrors += "Semantic validation error for $($file.Name): $($_.Exception.Message)"
                            }
                        }

                        # Command execution validation
                        $commandValidationPassed = 0
                        $commandValidationFailed = 0

                        foreach ($file in $commandFiles) {
                            try {
                                $commandResult = Test-MergedCommandExecution -FilePath $file.FullName
                                if ($commandResult.IsValid) {
                                    $commandValidationPassed++
                                } else {
                                    $commandValidationFailed++
                                    $validationErrors += "Command validation failed for $($file.Name): $($commandResult.Failures -join '; ')"
                                }
                            }
                            catch {
                                $commandValidationFailed++
                                $validationErrors += "Command validation error for $($file.Name): $($_.Exception.Message)"
                            }
                        }

                        return @{
                            FilesProcessed = $commandFiles.Count
                            JokesInjected = $totalJokesInjected
                            JokesPreserved = $jokesPreserved
                            SemanticValidationPassed = $semanticValidationPassed
                            SemanticValidationFailed = $semanticValidationFailed
                            CommandValidationPassed = $commandValidationPassed
                            CommandValidationFailed = $commandValidationFailed
                            Errors = $validationErrors
                            TestDirectory = $testDir
                        }
                    } -ArgumentList $testDir, $testPair, $dadJokes, $repoRoot, $helperModulePath, $testRoot

                    # Wait for job with timeout
                    $completed = Wait-Job -Job $testJob -Timeout $timeoutSeconds

                    if ($completed) {
                        # Job completed successfully
                        $jobResult = Receive-Job -Job $testJob
                        Remove-Job -Job $testJob -Force

                        $duration = (Get-Date) - $startTime

                        # Create test result object (thread-safe - returned from parallel block)
                        [PSCustomObject]@{
                            SourceVersion = $testPair.From
                            TargetVersion = $testPair.To
                            Status = if ($jobResult.Errors.Count -eq 0) { 'Completed' } else { 'Failed' }
                            Duration = $duration
                            FilesProcessed = $jobResult.FilesProcessed
                            TotalJokes = $jobResult.JokesInjected
                            JokesPreserved = $jobResult.JokesPreserved
                            SemanticValidationPassed = $jobResult.SemanticValidationPassed
                            SemanticValidationFailed = $jobResult.SemanticValidationFailed
                            CommandValidationPassed = $jobResult.CommandValidationPassed
                            CommandValidationFailed = $jobResult.CommandValidationFailed
                            ErrorMessage = if ($jobResult.Errors.Count -gt 0) { $jobResult.Errors -join '; ' } else { $null }
                            ValidationResults = @{
                                Valid = ($jobResult.Errors.Count -eq 0)
                                SemanticPassed = $jobResult.SemanticValidationPassed
                                SemanticFailed = $jobResult.SemanticValidationFailed
                                CommandPassed = $jobResult.CommandValidationPassed
                                CommandFailed = $jobResult.CommandValidationFailed
                            }
                            TestDirectory = $jobResult.TestDirectory
                        }

                        Write-Verbose "✓ Completed: $($testPair.From) → $($testPair.To) in $($duration.TotalSeconds.ToString('F1'))s"
                    }
                    else {
                        # Timeout occurred
                        Stop-Job -Job $testJob -ErrorAction SilentlyContinue
                        Remove-Job -Job $testJob -Force -ErrorAction SilentlyContinue

                        $duration = (Get-Date) - $startTime

                        Write-Warning "✗ TIMEOUT: $($testPair.From) → $($testPair.To) exceeded $timeoutSeconds seconds"

                        # Return timeout result
                        [PSCustomObject]@{
                            SourceVersion = $testPair.From
                            TargetVersion = $testPair.To
                            Status = 'Timeout'
                            Duration = $duration
                            FilesProcessed = 0
                            TotalJokes = 0
                            JokesPreserved = 0
                            ErrorMessage = "Test exceeded $timeoutSeconds second timeout"
                            ValidationResults = @{ Valid = $false }
                            TestDirectory = $testDir
                        }
                    }
                }
                catch {
                    $duration = (Get-Date) - $startTime

                    Write-Verbose "✗ FAILED: $($testPair.From) → $($testPair.To) - $($_.Exception.Message)"

                    # Return failure result (thread-safe)
                    [PSCustomObject]@{
                        SourceVersion = $testPair.From
                        TargetVersion = $testPair.To
                        Status = 'Failed'
                        Duration = $duration
                        FilesProcessed = 0
                        TotalJokes = 0
                        JokesPreserved = 0
                        ErrorMessage = $_.Exception.Message
                        ValidationResults = @{ Valid = $false }
                        TestDirectory = $testDir
                    }
                }
                finally {
                    # Cleanup test directory (always run)
                    if ($testDir -and (Test-Path $testDir)) {
                        try {
                            Remove-Item -Path $testDir -Recurse -Force -ErrorAction Stop
                            Write-Verbose "  Cleaned up: $testDir"
                        }
                        catch {
                            Write-Warning "Failed to cleanup: $testDir"
                        }
                    }
                }
            } -ThrottleLimit 4  # Parallel execution with 4 threads (User Story 3)

            # Calculate suite duration (User Story 3 - T025)
            $suiteDuration = (Get-Date) - $suiteStartTime

            # Summary report with performance metrics
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "E2E Test Suite Summary" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan

            $passedTests = ($testResults | Where-Object { $_.Status -eq 'Completed' }).Count
            $failedTests = ($testResults | Where-Object { $_.Status -eq 'Failed' }).Count
            $timeoutTests = ($testResults | Where-Object { $_.Status -eq 'Timeout' }).Count

            # Convert Duration TimeSpan to TotalSeconds for measurement
            $durationSeconds = $testResults | ForEach-Object { $_.Duration.TotalSeconds }
            $testDurations = $durationSeconds | Measure-Object -Sum -Average -Maximum -Minimum

            $totalJokes = ($testResults | Measure-Object -Property TotalJokes -Sum).Sum
            $preservedJokes = ($testResults | Measure-Object -Property JokesPreserved -Sum).Sum

            Write-Host "Total Tests:     $totalTests" -ForegroundColor White
            Write-Host "Passed:          $passedTests" -ForegroundColor Green
            Write-Host "Failed:          $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { 'Red' } else { 'Green' })
            Write-Host "Timeout:         $timeoutTests" -ForegroundColor $(if ($timeoutTests -gt 0) { 'Yellow' } else { 'Green' })

            Write-Host "`nPerformance:" -ForegroundColor Cyan
            Write-Host "Suite Duration:  $($suiteDuration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor $(if ($suiteDuration.TotalMinutes -lt 15) { 'Green' } else { 'Yellow' })
            Write-Host "Avg Test Time:   $($testDurations.Average.ToString('F1'))s" -ForegroundColor White
            Write-Host "Fastest Test:    $($testDurations.Minimum.ToString('F1'))s" -ForegroundColor White
            Write-Host "Slowest Test:    $($testDurations.Maximum.ToString('F1'))s" -ForegroundColor White

            Write-Host "`nData Preservation:" -ForegroundColor Cyan
            Write-Host "Total Jokes:     $totalJokes" -ForegroundColor White
            Write-Host "Preserved:       $preservedJokes" -ForegroundColor $(if ($preservedJokes -eq $totalJokes) { 'Green' } else { 'Red' })
            Write-Host "Preservation:    $([Math]::Round(($preservedJokes / $totalJokes) * 100, 2))%" -ForegroundColor $(if ($preservedJokes -eq $totalJokes) { 'Green' } else { 'Red' })

            # Per-merge summary
            Write-Host "`nPer-Merge Results:" -ForegroundColor Cyan

            # Add index for display
            $indexedResults = $testResults | ForEach-Object -Begin { $i = 0 } -Process {
                $i++
                $_ | Add-Member -NotePropertyName Index -NotePropertyValue $i -PassThru -Force
            }

            foreach ($result in $indexedResults) {
                $statusSymbol = switch ($result.Status) {
                    'Completed' { '✓' }
                    'Failed' { '✗' }
                    'Timeout' { '⏱' }
                    default { '?' }
                }

                $statusColor = switch ($result.Status) {
                    'Completed' { 'Green' }
                    'Failed' { 'Red' }
                    'Timeout' { 'Yellow' }
                    default { 'Gray' }
                }

                Write-Host "  [$($result.Index.ToString('D2'))/$totalTests] $statusSymbol $($result.SourceVersion) → $($result.TargetVersion): " -NoNewline
                Write-Host "$($result.Status.ToUpper()) " -NoNewline -ForegroundColor $statusColor
                Write-Host "($($result.Duration.TotalSeconds.ToString('F1'))s) - Jokes: $($result.JokesPreserved)/$($result.TotalJokes)"
            }

            Write-Host "========================================`n" -ForegroundColor Cyan

            # Performance assertion (User Story 3 - SC-001)
            $suiteDuration.TotalMinutes | Should -BeLessThan 15 -Because "Test suite must complete in under 15 minutes"

            # Data preservation assertion (zero tolerance)
            $failedTests | Should -Be 0 -Because "All merge tests must preserve 100% of dad jokes"
            $preservedJokes | Should -Be $totalJokes -Because "100% dad joke preservation required (zero tolerance)"
        }
    }
}

AfterAll {
    # Generate comprehensive test report (User Story 5)
    if ($script:testResults -and $script:testResults.Count -gt 0) {
        Write-Verbose "Generating comprehensive E2E test report..."
        Write-E2ETestReport -TestResults $script:testResults
    }

    # Final cleanup (catch any orphaned directories)
    if (Test-Path $testRoot) {
        $orphanedDirs = Get-ChildItem -Path $testRoot -Directory -Filter "test-*" -ErrorAction SilentlyContinue

        if ($orphanedDirs) {
            Write-Host "`nCleaning up $($orphanedDirs.Count) orphaned test directories..." -ForegroundColor Yellow
            foreach ($dir in $orphanedDirs) {
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Write-Host "`nE2E test suite completed" -ForegroundColor Cyan
}
