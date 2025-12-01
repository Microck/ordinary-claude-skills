# Quickstart Guide: Testing Installation Flow -Proceed Fix

**Feature**: Fix Installation Flow to Respect -Proceed Flag
**Branch**: `011-fix-install-proceed-flag`
**Audience**: Developers testing the bug fix

## Overview

This guide walks through manual testing of the installation flow `-Proceed` flag fix. Use this to verify the fix works correctly before running automated tests.

## Prerequisites

- PowerShell 7.0+
- Git installed and in PATH
- Internet connection (for GitHub API calls)
- Two test project directories:
  - One WITHOUT `.specify/` folder (fresh project)
  - One WITH `.specify/` folder (existing SpecKit project)

## Setup Test Environment

### 1. Create Test Projects

```powershell
# Create fresh project directory (no SpecKit)
$freshProject = "C:\temp\test-fresh-install"
New-Item -ItemType Directory -Path $freshProject -Force
Remove-Item "$freshProject\.specify" -Recurse -Force -ErrorAction SilentlyContinue

# Create existing SpecKit project directory
$existingProject = "C:\temp\test-existing-speckit"
New-Item -ItemType Directory -Path $existingProject -Force
New-Item -ItemType Directory -Path "$existingProject\.specify" -Force
```

### 2. Clone Skill (if not already)

```powershell
cd $env:USERPROFILE\.claude\skills
git clone https://github.com/NotMyself/claude-win11-speckit-update-skill speckit-updater
cd speckit-updater

# Switch to bug fix branch
git checkout 011-fix-install-proceed-flag
```

## Test Scenarios

### Scenario 1: Fresh Installation - First Invocation (No -Proceed)

**Expected**: Show installation prompt, exit gracefully with code 0

```powershell
# Navigate to fresh project
cd C:\temp\test-fresh-install

# Run updater without -Proceed flag
& "$env:USERPROFILE\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -Verbose

# VERIFY:
# ✅ Output contains: [PROMPT_FOR_INSTALL] in cyan
# ✅ Output contains: "SpecKit is not currently installed in this project." in yellow
# ✅ Output contains: "To proceed with installation, run:" in cyan
# ✅ Output contains: "/speckit-update -Proceed" in white
# ✅ Verbose output contains: "Awaiting user approval for SpecKit installation"
# ✅ Exit code is 0 (check with $LASTEXITCODE)
# ✅ NO error thrown
# ✅ .specify/ directory NOT created yet

Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })
```

### Scenario 2: Fresh Installation - Second Invocation (With -Proceed)

**Expected**: Skip prompt, proceed with installation

```powershell
# Still in fresh project directory
cd C:\temp\test-fresh-install

# Run updater WITH -Proceed flag
& "$env:USERPROFILE\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -Proceed -Verbose

# VERIFY:
# ✅ Output contains: "📦 Installing SpecKit..." in cyan
# ✅ Verbose output contains: "User approved SpecKit installation, proceeding..."
# ✅ NO [PROMPT_FOR_INSTALL] shown (prompt skipped)
# ✅ .specify/ directory created
# ✅ .specify/manifest.json created
# ✅ .claude/commands/ directory created with templates
# ✅ Exit code is 0
# ✅ Installation completes successfully

Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })

# Check artifacts created
Test-Path "$PWD\.specify" | Should -Be $true
Test-Path "$PWD\.specify\manifest.json" | Should -Be $true
Test-Path "$PWD\.claude\commands" | Should -Be $true
```

### Scenario 3: Fresh Installation - Direct Proceed (Skip First Step)

**Expected**: Proceed immediately with installation (explicit approval)

```powershell
# Create another fresh project
$directProceed = "C:\temp\test-direct-proceed"
New-Item -ItemType Directory -Path $directProceed -Force
Remove-Item "$directProceed\.specify" -Recurse -Force -ErrorAction SilentlyContinue
cd $directProceed

# Run updater WITH -Proceed flag on first invocation
& "$env:USERPROFILE\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -Proceed -Verbose

# VERIFY:
# ✅ Installation proceeds immediately (no prompt shown)
# ✅ .specify/ directory created
# ✅ Exit code is 0

Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })
```

### Scenario 4: Existing SpecKit Project - No Installation Prompt

**Expected**: No installation prompt, normal update check

```powershell
# Navigate to existing SpecKit project
cd C:\temp\test-existing-speckit

# Run updater (with or without -Proceed)
& "$env:USERPROFILE\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly -Verbose

# VERIFY:
# ✅ NO [PROMPT_FOR_INSTALL] shown
# ✅ Normal update check flow
# ✅ NO installation messages
# ✅ Exit code is 0

Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })
```

### Scenario 5: Multiple Installations - Idempotence Check

**Expected**: Running install multiple times on already-installed project behaves as update check

```powershell
# Navigate to project that was just installed in Scenario 2
cd C:\temp\test-fresh-install

# Run updater again with -Proceed
& "$env:USERPROFILE\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -Proceed -Verbose

# VERIFY:
# ✅ NO installation prompt (already installed)
# ✅ Behaves as normal update check
# ✅ NO duplicate installations
# ✅ Exit code is 0

Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })
```

## Verification Checklist

After running all scenarios, verify:

- [ ] Scenario 1: Installation prompt shown, exit code 0, no error thrown
- [ ] Scenario 2: Installation proceeds, files created, exit code 0
- [ ] Scenario 3: Direct proceed works, installation completes
- [ ] Scenario 4: No installation prompt for existing projects
- [ ] Scenario 5: Idempotent behavior (no duplicate installs)
- [ ] Verbose logging shows correct approval state transitions
- [ ] No double prompts observed in any scenario
- [ ] Exit behavior is graceful (`exit 0`) not error (`throw`)

## Common Issues

### Issue: "Command not recognized" error for Get-NormalizedHash

**Cause**: Module import order issue (nested imports)

**Solution**: Verify orchestrator imports all modules in correct order (Tier 0 → Tier 1 → Tier 2). Check for `Import-Module` statements inside `.psm1` files (should not exist per constitution).

### Issue: ".specify/ directory already exists" error

**Cause**: Test directory not cleaned properly

**Solution**: Run cleanup script:
```powershell
Remove-Item "C:\temp\test-*" -Recurse -Force -ErrorAction SilentlyContinue
```

### Issue: GitHub API rate limit exceeded

**Cause**: Too many test runs in one hour (60 request limit for unauthenticated)

**Solution**: Wait until rate limit resets (shown in error message) or use `-CheckOnly` flag to skip actual downloads during testing.

## Next Steps

After manual testing passes:

1. Run automated unit tests:
   ```powershell
   cd $env:USERPROFILE\.claude\skills\speckit-updater
   .\tests\test-runner.ps1 -Unit
   ```

2. Run automated integration tests:
   ```powershell
   .\tests\test-runner.ps1 -Integration
   ```

3. Run full test suite with coverage:
   ```powershell
   .\tests\test-runner.ps1 -Coverage
   ```

4. Review test results and fix any failures

5. Update CHANGELOG.md with fix description

6. Create pull request

## Cleanup

```powershell
# Remove test directories
Remove-Item "C:\temp\test-fresh-install" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\temp\test-existing-speckit" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\temp\test-direct-proceed" -Recurse -Force -ErrorAction SilentlyContinue
```

## References

- **Bug Report**: [docs/bugs/008-install-proceed-flag-ignored.md](../../docs/bugs/008-install-proceed-flag-ignored.md)
- **Spec**: [spec.md](spec.md)
- **Plan**: [plan.md](plan.md)
- **Update Orchestrator**: [scripts/update-orchestrator.ps1](../../scripts/update-orchestrator.ps1)
- **Validation Helper**: [scripts/helpers/Invoke-PreUpdateValidation.ps1](../../scripts/helpers/Invoke-PreUpdateValidation.ps1)
