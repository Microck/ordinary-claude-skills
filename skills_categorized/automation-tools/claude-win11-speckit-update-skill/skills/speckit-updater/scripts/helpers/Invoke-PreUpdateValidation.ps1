#Requires -Version 7.0

<#
.SYNOPSIS
    Validates prerequisites before running SpecKit update.

.DESCRIPTION
    Performs critical and non-critical checks:
    - Critical: Git installed, .specify/ exists, write permissions, clean Git state
    - Warnings: VSCode installed, internet connectivity, disk space

    Critical checks must pass. Warnings allow user to continue with confirmation.

.PARAMETER ProjectRoot
    Path to the project root directory.

.OUTPUTS
    Throws exception if critical checks fail or user cancels.
    Returns successfully if all checks pass or user confirms to continue despite warnings.
#>

<#
.SYNOPSIS
    Checks if SpecKit commands are installed in Claude Code.

.DESCRIPTION
    Detects whether SpecKit slash commands exist in the user's .claude/commands/
    directory by checking for at least one official SpecKit command file.

.OUTPUTS
    [bool] True if any SpecKit command is found, False otherwise.

.EXAMPLE
    Test-SpecKitCommandsAvailable
    # Returns: $true or $false
#>
function Test-SpecKitCommandsAvailable {
    [CmdletBinding()]
    param()

    try {
        $claudeCommandsDir = Join-Path $env:USERPROFILE ".claude\commands"

        if (-not (Test-Path $claudeCommandsDir)) {
            Write-Verbose "Claude commands directory not found: $claudeCommandsDir"
            return $false
        }

        # Check for any of the core SpecKit commands
        $coreCommands = @(
            "speckit.constitution.md",
            "speckit.specify.md",
            "speckit.plan.md"
        )

        foreach ($cmd in $coreCommands) {
            $cmdPath = Join-Path $claudeCommandsDir $cmd
            if (Test-Path $cmdPath) {
                Write-Verbose "SpecKit command found: $cmdPath"
                return $true
            }
        }

        Write-Verbose "No SpecKit commands found in: $claudeCommandsDir"
        return $false
    }
    catch {
        Write-Verbose "Error checking for SpecKit commands: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Generates a helpful error message for non-SpecKit projects.

.DESCRIPTION
    Creates context-aware error messages based on whether SpecKit commands are
    detected in the user's environment. Provides actionable next steps:
    - If commands available: Suggest running /speckit.constitution
    - If not available: Provide link to SpecKit documentation
    - If detection fails: Show both options as fallback

.OUTPUTS
    [string] Formatted error message with educational content and next steps.

.EXAMPLE
    Get-HelpfulSpecKitError
    # Returns multi-line error message string
#>
function Get-HelpfulSpecKitError {
    [CmdletBinding()]
    param()

    try {
        $hasSpecKitCommands = Test-SpecKitCommandsAvailable

        if ($hasSpecKitCommands) {
            # Variant A: Commands available - suggest initialization
            $message = @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

To initialize SpecKit in this project, run:

    /speckit.constitution

Then you can use /speckit-update to keep templates up to date.
"@
        }
        else {
            # Variant B: Commands not available - provide documentation link
            $message = @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

This updater requires SpecKit to be installed first.

Learn more: https://github.com/github/spec-kit
"@
        }

        return $message
    }
    catch {
        # Fallback: Show both options if detection fails
        Write-Verbose "Failed to detect SpecKit commands, using fallback message: $($_.Exception.Message)"

        $message = @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

If SpecKit is already installed:
  • Run: /speckit.constitution

If SpecKit is not installed:
  • Learn more: https://github.com/github/spec-kit
"@

        return $message
    }
}

function Invoke-PreUpdateValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD,

        [Parameter(Mandatory=$false)]
        [switch]$Proceed
    )

    $errors = @()
    $warnings = @()

    Write-Host "Validating prerequisites..." -ForegroundColor Cyan

    # ========================================
    # CRITICAL CHECKS (must pass)
    # ========================================

    # 1. Check if Git is installed
    $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitInstalled) {
        $errors += "Git not found in PATH. Install: winget install Git.Git"
    }

    # 2. Check if .specify/ directory exists
    $specifyDir = Join-Path $ProjectRoot ".specify"
    $specifyExists = Test-Path $specifyDir

    if (-not $specifyExists) {
        # Check if user has already approved with -Proceed flag
        if ($Proceed) {
            # User approved - proceed with installation
            Write-Verbose "User approved SpecKit installation, proceeding..."
            Write-Host ""
            Write-Host "📦 Installing SpecKit..." -ForegroundColor Cyan
            Write-Host ""
            # Continue to validation - orchestrator will handle installation
            return
        }

        # Don't add to errors - offer to install SpecKit instead
        Write-Host ""
        Write-Host "SpecKit is not installed in this project." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This skill can install the latest SpecKit templates and create a manifest to track future updates." -ForegroundColor Cyan
        Write-Host ""

        # Detect non-interactive mode (Claude Code)
        try {
            $isInteractive = -not [Console]::IsInputRedirected
        }
        catch {
            $isInteractive = $true
        }

        if ($isInteractive) {
            # Interactive mode: prompt user
            $response = Read-Host "Would you like to install SpecKit now? (Y/n)"
            if ($response -eq 'n' -or $response -eq 'N') {
                Write-Host ""
                Write-Host "SpecKit installation cancelled." -ForegroundColor Yellow
                Write-Host ""
                $helpfulError = Get-HelpfulSpecKitError
                Write-Host $helpfulError -ForegroundColor Cyan
                Write-Host ""
                throw "User declined SpecKit installation"
            }
            # If yes, continue - orchestrator will handle first-time setup
            Write-Host ""
            Write-Host "Proceeding with SpecKit installation..." -ForegroundColor Green
            Write-Host ""
        }
        else {
            # Non-interactive mode (Claude Code): Show message and exit for approval
            Write-Verbose "Awaiting user approval for SpecKit installation"
            Write-Host "[PROMPT_FOR_INSTALL]" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "SpecKit is not currently installed in this project." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "The updater can install the latest SpecKit templates for you." -ForegroundColor Gray
            Write-Host "This will:" -ForegroundColor Gray
            Write-Host "  • Create .specify/ directory structure" -ForegroundColor Gray
            Write-Host "  • Download latest SpecKit templates from GitHub" -ForegroundColor Gray
            Write-Host "  • Create manifest to track future updates" -ForegroundColor Gray
            Write-Host ""
            Write-Host "To proceed with installation, run:" -ForegroundColor Cyan
            Write-Host "  /speckit-update -Proceed" -ForegroundColor White
            Write-Host ""
            # Exit gracefully with code 0 (not throw) for conversational workflow
            exit 0
        }
    }

    # 3. Check write permissions
    if (Test-Path $specifyDir -PathType Container) {
        $testFile = Join-Path $specifyDir ".write-test-$(Get-Random)"
        try {
            "test" | Out-File $testFile -ErrorAction Stop
            Remove-Item $testFile -ErrorAction SilentlyContinue
        }
        catch {
            $errors += "No write permission to .specify/ directory: $($_.Exception.Message)"
        }
    }

    # 4. Check Git working directory state (only if Git is installed)
    if ($gitInstalled) {
        try {
            Push-Location $ProjectRoot
            $gitStatus = git status --porcelain 2>&1

            # Check if we're in a Git repository
            if ($LASTEXITCODE -ne 0) {
                $warnings += "Not a Git repository. Changes will not be tracked in version control."
            }
            else {
                # Check for unstaged changes in .specify/ or .claude/ directories
                $relevantChanges = $gitStatus | Where-Object {
                    $_ -match '^\s*[MADRCU\?].*\.(specify|claude)/'
                }

                if ($relevantChanges) {
                    $errors += "Git working directory has unstaged changes in .specify/ or .claude/. Please commit or stash changes first."
                }
            }
        }
        catch {
            $warnings += "Could not check Git status: $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }
    }

    # ========================================
    # NON-CRITICAL CHECKS (warnings only)
    # ========================================

    # 5. Check if VSCode is installed (for diff/merge)
    $codeInstalled = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codeInstalled) {
        $warnings += "VSCode not found in PATH. Diff and merge views may not work. Install: winget install Microsoft.VisualStudioCode"
    }

    # 6. Check internet connectivity
    try {
        $null = Invoke-RestMethod -Uri "https://api.github.com" -Method Head -TimeoutSec 5 -ErrorAction Stop
    }
    catch {
        $warnings += "Cannot reach GitHub API. Check internet connection. Update will fail without network access."
    }

    # 7. Check disk space
    try {
        $drive = (Get-Item $ProjectRoot).PSDrive
        if ($drive) {
            $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
            if ($freeSpaceGB -lt 1) {
                $warnings += "Low disk space: ${freeSpaceGB}GB free. Backups may fail."
            }
        }
    }
    catch {
        # Silently ignore disk space check failures
    }

    # ========================================
    # DISPLAY RESULTS
    # ========================================

    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "Prerequisites not met:" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "  X $err" -ForegroundColor Red
        }
        Write-Host ""
        throw "Prerequisites validation failed. Please fix the issues above and try again."
    }

    if ($warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Non-critical issues detected:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  ! $warning" -ForegroundColor Yellow
        }
        Write-Host ""

        # Use console prompt for confirmation
        $response = Read-Host "Continue anyway? (Y/n)"
        if ($response -eq 'n' -or $response -eq 'N') {
            throw "Update cancelled by user due to warnings."
        }
    }

    Write-Host "Prerequisites validated successfully" -ForegroundColor Green
    Write-Host ""
}
