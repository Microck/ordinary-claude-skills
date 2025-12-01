# Bug Report: Installation Flow Doesn't Respect -Proceed Flag

**Issue:** #22
**Status:** OPEN
**Reporter:** Bobby Johnson (@NotMyself)
**Created:** 2025-10-23T15:26:19Z
**Severity:** High (Blocks core installation workflow)

## Summary

When installing SpecKit via conversational workflow, the `-Proceed` flag is ignored, causing the installation prompt to appear twice instead of proceeding with installation. The validation helper (`Invoke-PreUpdateValidation.ps1`) doesn't accept or check the `-Proceed` parameter, so it always treats installation as unapproved, even when the user has already approved via conversational workflow.

## Environment

- **OS:** Windows 11
- **PowerShell Version:** 7.0+
- **Claude Code Version:** Latest
- **SpecKit Updater Version:** v1.0
- **Affected Component:** `scripts/helpers/Invoke-PreUpdateValidation.ps1` (lines 206-221)
- **Related Files:** `scripts/update-orchestrator.ps1` (line 189)

## Problem Description

### Steps to Reproduce

1. Navigate to a project without SpecKit installed (no `.specify/` directory)
2. Run `/speckit-updater`
3. Observe the `[PROMPT_FOR_INSTALL]` marker and installation offer
4. Approve via conversational workflow in Claude Code
5. Run `/speckit-updater -Proceed`
6. **Bug:** Same prompt appears again instead of proceeding

### Expected Behavior

On second invocation with `-Proceed` flag, the updater should:
- Skip the installation prompt
- Proceed with creating `.specify/` directory structure
- Download latest SpecKit templates from GitHub
- Create manifest to track future updates
- Complete installation successfully

### Actual Behavior

The updater shows the same `[PROMPT_FOR_INSTALL]` message and exits with error:
```
Error: Awaiting user approval for SpecKit installation
```

Even though `-Proceed` was passed, the validation helper doesn't recognize or respect it.

## Root Cause Analysis

### Primary Issue

**File:** `scripts/helpers/Invoke-PreUpdateValidation.ps1`
**Location:** Lines 206-221

The function signature doesn't include a `-Proceed` parameter:

```powershell
function Invoke-PreUpdateValidation {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )
    # ... validation logic
}
```

The installation detection logic (lines 206-221) always treats SpecKit installation as unapproved:

```powershell
# Check if SpecKit is installed
if (-not (Test-Path $specifyPath)) {
    Write-Host "`n[PROMPT_FOR_INSTALL]" -ForegroundColor Cyan
    Write-Host "SpecKit is not currently installed in this project." -ForegroundColor Yellow
    Write-Host "This command can initialize SpecKit by downloading the latest templates." -ForegroundColor Gray

    throw "Awaiting user approval for SpecKit installation"
}
```

**Problem:** There's no conditional check for `-Proceed` flag, so the function always throws an error when SpecKit is not installed, regardless of whether the user has already approved.

### Orchestrator Call Site

**File:** `scripts/update-orchestrator.ps1`
**Location:** Line 189

The orchestrator calls the validation helper without passing `-Proceed`:

```powershell
Invoke-PreUpdateValidation -ProjectRoot $projectRoot
```

Even if the helper had a `-Proceed` parameter, it wouldn't receive the value because the orchestrator doesn't pass it.

## Impact

### User Experience Issues

1. **Broken Installation Flow:** Users cannot install SpecKit via `/speckit-updater` command
2. **Confusing Double Prompts:** Same prompt appears twice, making users think the first approval didn't work
3. **Lost Productivity:** Users must find workaround (manually initialize with `/speckit.constitution` first)
4. **Inconsistent Behavior:** Update flow respects `-Proceed` correctly, but installation flow doesn't
5. **Trust Erosion:** Tool doesn't honor user's approval, creating frustration

### Severity Justification

**High** - This completely blocks the primary installation workflow. Users cannot use the skill's intended installation feature at all. The workaround requires knowledge of SpecKit internals that most users won't have.

### Impact Scope

- **New Users:** Cannot install SpecKit via skill (100% blocked)
- **Existing Users:** Unaffected (only impacts fresh installations)
- **Documentation:** Installation instructions in README are unusable

## Comparison with Update Flow

The **update flow** (lines 381-409 in update-orchestrator.ps1) already handles `-Proceed` correctly:

```powershell
# Step 7: Get user confirmation
if (-not $Proceed) {
    Write-Host "`n[PROMPT_FOR_PROCEED]" -ForegroundColor Cyan
    Write-Host "Run the command again with -Proceed flag to apply changes." -ForegroundColor Gray
    exit 0  # Graceful exit, waiting for approval
}
else {
    Write-Verbose "Proceeding with update (user approved)"
}
```

**Installation should follow the same pattern:**
- **First invocation:** Show summary → Output `[PROMPT_FOR_INSTALL]` marker → Exit gracefully
- **Second invocation with -Proceed:** Skip confirmation → Execute installation

## Proposed Solution

### Fix Overview

1. Add `-Proceed` parameter to `Invoke-PreUpdateValidation` function signature
2. Update installation detection logic to check `-Proceed` flag
3. Pass `-Proceed` from orchestrator to validation helper
4. Ensure graceful exit (code 0) when awaiting approval

### Code Changes

#### Change 1: Update Helper Function Signature

**File:** `scripts/helpers/Invoke-PreUpdateValidation.ps1`
**Location:** Function parameter block (around line 20)

```powershell
function Invoke-PreUpdateValidation {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter()]
        [switch]$Proceed
    )

    # ... rest of function
}
```

#### Change 2: Update Installation Detection Logic

**File:** `scripts/helpers/Invoke-PreUpdateValidation.ps1`
**Location:** Lines 206-221

**Current Code:**
```powershell
# Check if SpecKit is installed
if (-not (Test-Path $specifyPath)) {
    Write-Host "`n[PROMPT_FOR_INSTALL]" -ForegroundColor Cyan
    Write-Host "SpecKit is not currently installed in this project." -ForegroundColor Yellow
    Write-Host "This command can initialize SpecKit by downloading the latest templates." -ForegroundColor Gray

    throw "Awaiting user approval for SpecKit installation"
}
```

**Proposed Code:**
```powershell
# Check if SpecKit is installed
if (-not (Test-Path $specifyPath)) {
    if (-not $Proceed) {
        # First invocation - show installation offer
        Write-Host "`n[PROMPT_FOR_INSTALL]" -ForegroundColor Cyan
        Write-Host "SpecKit is not currently installed in this project." -ForegroundColor Yellow
        Write-Host "This command can initialize SpecKit by downloading the latest templates from GitHub." -ForegroundColor Gray
        Write-Host "`nTo proceed with installation, run:" -ForegroundColor Cyan
        Write-Host "  /speckit-update -Proceed" -ForegroundColor White

        Write-Verbose "Awaiting user approval for SpecKit installation"
        exit 0  # Graceful exit - waiting for approval
    }
    else {
        # Second invocation with -Proceed - user approved
        Write-Verbose "User approved SpecKit installation, proceeding..."
        Write-Host "`n📦 Installing SpecKit..." -ForegroundColor Cyan
        # Continue validation (don't exit or throw)
    }
}
```

#### Change 3: Pass -Proceed from Orchestrator

**File:** `scripts/update-orchestrator.ps1`
**Location:** Line 189

**Current Code:**
```powershell
Invoke-PreUpdateValidation -ProjectRoot $projectRoot
```

**Proposed Code:**
```powershell
Invoke-PreUpdateValidation -ProjectRoot $projectRoot -Proceed:$Proceed
```

### Benefits

- ✅ Fixes broken installation workflow
- ✅ Consistent with update flow pattern (lines 381-409)
- ✅ Graceful exit (code 0) instead of throwing error
- ✅ Clear instruction to user on what command to run
- ✅ Verbose logging for debugging
- ✅ Minimal code changes (< 20 lines modified)

### Drawbacks

- None identified - this is a straightforward bug fix with no negative side effects

## Testing Plan

### Manual Testing

```powershell
# Test 1: Fresh installation (no .specify/)
cd C:\test-project-without-speckit
/speckit-updater
# Expected: [PROMPT_FOR_INSTALL] marker, instruction to run with -Proceed, exit 0

# Test 2: Approve installation
/speckit-updater -Proceed
# Expected: Installation proceeds, downloads templates, creates manifest, exit 0

# Test 3: Existing SpecKit installation
cd C:\test-project-with-speckit
/speckit-updater
# Expected: No installation prompt, normal update flow
```

### Integration Tests

**Add to:** `tests/integration/UpdateOrchestrator.Tests.ps1`

```powershell
Describe "SpecKit Installation Flow" {
    Context "When SpecKit not installed" {
        BeforeEach {
            # Create test project without .specify/ directory
            $testRoot = Join-Path $TestDrive "fresh-project"
            New-Item -ItemType Directory -Path $testRoot -Force
            Set-Location $testRoot
        }

        It "Should show installation prompt without -Proceed flag" {
            # Run without -Proceed
            $result = & $orchestratorPath -CheckOnly -ErrorAction SilentlyContinue

            # Verify: [PROMPT_FOR_INSTALL] marker shown
            $result | Should -Match '\[PROMPT_FOR_INSTALL\]'

            # Verify: Exit code 0 (graceful)
            $LASTEXITCODE | Should -Be 0
        }

        It "Should proceed with installation when -Proceed flag passed" {
            # Run with -Proceed
            $result = & $orchestratorPath -Proceed

            # Verify: .specify/ directory created
            Test-Path (Join-Path $testRoot '.specify') | Should -Be $true

            # Verify: Manifest created
            Test-Path (Join-Path $testRoot '.specify/manifest.json') | Should -Be $true

            # Verify: Templates downloaded
            Test-Path (Join-Path $testRoot '.claude/commands/speckit.specify.md') | Should -Be $true

            # Verify: Success exit code
            $LASTEXITCODE | Should -Be 0
        }

        It "Should not throw error when awaiting approval" {
            # Run without -Proceed
            { & $orchestratorPath -CheckOnly } | Should -Not -Throw
        }
    }

    Context "When SpecKit already installed" {
        BeforeEach {
            # Create test project with .specify/ directory
            $testRoot = Join-Path $TestDrive "existing-project"
            New-Item -ItemType Directory -Path "$testRoot\.specify" -Force
        }

        It "Should not show installation prompt" {
            # Run without -Proceed
            $result = & $orchestratorPath -CheckOnly

            # Verify: No [PROMPT_FOR_INSTALL] marker
            $result | Should -Not -Match '\[PROMPT_FOR_INSTALL\]'
        }
    }
}
```

### Unit Tests

**Add to:** `tests/unit/Invoke-PreUpdateValidation.Tests.ps1`

```powershell
Describe "Invoke-PreUpdateValidation" {
    Context "Installation Detection" {
        BeforeEach {
            $testRoot = Join-Path $TestDrive "test-project"
            New-Item -ItemType Directory -Path $testRoot -Force
        }

        It "Should accept -Proceed parameter" {
            # Test that parameter binding works
            Mock Test-Path { $false }

            { Invoke-PreUpdateValidation -ProjectRoot $testRoot -Proceed } | Should -Not -Throw
        }

        It "Should exit gracefully when installation not approved" {
            # No .specify/ directory
            Mock Test-Path { $false } -ParameterFilter { $Path -like '*\.specify' }

            # Run without -Proceed
            # Should exit with code 0, not throw
            $result = Invoke-PreUpdateValidation -ProjectRoot $testRoot -ErrorAction SilentlyContinue
            $LASTEXITCODE | Should -Be 0
        }

        It "Should continue when installation approved" {
            # No .specify/ directory
            Mock Test-Path { $false } -ParameterFilter { $Path -like '*\.specify' }

            # Run with -Proceed - should not exit, should continue validation
            { Invoke-PreUpdateValidation -ProjectRoot $testRoot -Proceed } | Should -Not -Throw
        }
    }
}
```

## Documentation Updates

### CLAUDE.md

**Section:** "Key Workflows" → Add "Installation Flow"

```markdown
### Installation Flow (Fresh SpecKit Setup)

When SpecKit is not installed (no `.specify/` directory), the skill uses a conversational approval workflow:

1. **First invocation:** `/speckit-update`
   - Detects no `.specify/` directory
   - Shows `[PROMPT_FOR_INSTALL]` marker
   - Describes what installation will do
   - Exits gracefully (code 0) awaiting approval

2. **Second invocation:** `/speckit-update -Proceed`
   - Skips installation prompt
   - Creates `.specify/` directory structure
   - Downloads latest SpecKit templates from GitHub
   - Creates manifest to track future updates
   - Completes installation successfully

This pattern mirrors the update flow's `-Proceed` handling (lines 381-409).
```

### SKILL.md

**Section:** "Usage Examples" → Update installation example

```markdown
## Installing SpecKit for the First Time

If your project doesn't have SpecKit installed yet, this skill can initialize it:

```bash
# Step 1: Check what will be installed
/speckit-update

# Step 2: Proceed with installation
/speckit-update -Proceed
```

The skill will:
- Download the latest SpecKit templates from GitHub
- Create `.specify/` directory structure
- Initialize manifest for tracking future updates
```

### CHANGELOG.md

**Version:** Next release (e.g., v1.1.0)

```markdown
### Fixed
- Installation flow now respects `-Proceed` flag for conversational approval workflow (Issue #22)
- Validation helper gracefully exits (code 0) when awaiting installation approval instead of throwing error
- Installation prompt no longer appears twice when user approves via conversational workflow
```

## Related Code

- **Primary:** [scripts/helpers/Invoke-PreUpdateValidation.ps1:206-221](../../scripts/helpers/Invoke-PreUpdateValidation.ps1) (Installation detection)
- **Orchestrator:** [scripts/update-orchestrator.ps1:189](../../scripts/update-orchestrator.ps1) (Validation call site)
- **Reference:** [scripts/update-orchestrator.ps1:381-409](../../scripts/update-orchestrator.ps1) (Correct -Proceed pattern)

## Related Issues

- **Issue #13** - First-time install scenarios (related workflow)
- **Conversational Workflow Pattern** - Documented in CLAUDE.md "Architectural Limitations" section

## Timeline

- **2025-10-23:** Issue #22 created by Bobby Johnson
- **2025-10-23:** Documented as bug #008
- **Status:** Ready for implementation

## Priority

**High** - This completely blocks the primary installation workflow. Should be fixed immediately before any other features or bugs.

## Success Criteria

- ✅ Installation prompt shown on first invocation without `-Proceed`
- ✅ Installation proceeds on second invocation with `-Proceed`
- ✅ Graceful exit (code 0) when awaiting approval (not throwing error)
- ✅ Clear instruction shown to user on what command to run
- ✅ Consistent with update flow's `-Proceed` handling
- ✅ All integration tests pass
- ✅ Documentation updated
- ✅ Users can successfully install SpecKit via skill

## Notes

### Design Considerations

1. **Exit vs. Throw:** Must use `exit 0` instead of `throw` when awaiting approval to maintain graceful conversational workflow
2. **Consistent Pattern:** Follow exact same pattern as update flow (lines 381-409) for maintainability
3. **Verbose Logging:** Add clear verbose messages for debugging approval flow
4. **User Guidance:** Show exact command user should run (`/speckit-update -Proceed`)

### Why This Bug Existed

The installation flow was likely implemented before the conversational workflow pattern was established for updates. The validation helper was designed to be strict (throw error if SpecKit not installed) without considering the two-phase approval workflow.

### Future Enhancements

- [ ] Consider adding `-Force` flag to skip all prompts (for automated/CI scenarios)
- [ ] Add progress indicators during template download
- [ ] Show preview of what templates will be installed
- [ ] Add `-DryRun` flag to show what installation would do without executing
