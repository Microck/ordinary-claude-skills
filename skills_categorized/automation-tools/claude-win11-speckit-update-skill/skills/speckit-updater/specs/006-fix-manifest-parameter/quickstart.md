# Quickstart: Parameter Standardization Implementation

**Feature**: 006-fix-manifest-parameter
**Date**: 2025-10-20
**Purpose**: Step-by-step guide for implementing comprehensive parameter standardization

## Overview

This guide walks through the implementation process for the all-at-once parameter standardization refactoring. Follow these steps in order to ensure a successful, safe refactoring.

## Prerequisites

Before starting implementation:

- [ ] Feature specification reviewed and approved ([spec.md](spec.md))
- [ ] Implementation plan reviewed ([plan.md](plan.md))
- [ ] Research findings reviewed ([research.md](research.md))
- [ ] Parameter naming standard documented ([contracts/parameter-naming-standard.md](contracts/parameter-naming-standard.md))
- [ ] Current branch: `006-fix-manifest-parameter`
- [ ] All existing tests passing on baseline
- [ ] Baseline code coverage measured

## Implementation Phases

### Phase 0: Baseline Establishment (Day 1)

**Goal**: Establish baseline metrics and create audit tooling

#### Step 1: Measure Baseline Coverage
```powershell
# Run current test suite
.\tests\test-runner.ps1 -Coverage

# Document baseline metrics:
# - Current coverage percentage
# - Number of passing tests
# - Number of failing tests (if any)
```

**Expected Output**:
```
Baseline Metrics (2025-10-20):
- Code Coverage: ~75% (needs increase to 90%+)
- Passing Tests: 132
- Failing Tests: 45 (known Pester 5.x scoping issues - modules work correctly)
```

#### Step 2: Create Parameter Audit Tool
```powershell
# Location: scripts/tools/audit-parameters.ps1
# Implementation: Use PowerShell AST to parse all .ps1 and .psm1 files
# Output: JSON and markdown reports

# Test the audit tool manually:
& .\scripts\tools\audit-parameters.ps1 -OutputFormat "both" -OutputPath ".\audit-baseline"
```

**Expected Output**:
```
Parameter Audit Report (Baseline)
==================================
Files Scanned: 15
Functions Found: 87
Parameters Declared: 234
Violations Found: ~12-15 (estimate)
Compliance Rate: ~93-95%

Top Violations:
- New-SpecKitManifest: $SpecKitVersion → $Version (5 locations)
- [Other violations from audit]
```

#### Step 3: Run Baseline Audit
```powershell
# Run audit tool to identify all violations
& .\scripts\tools\audit-parameters.ps1 -FailOnViolations

# Save baseline report for comparison
Copy-Item .\parameter-audit-report.json .\audit-baseline-before-refactoring.json
```

---

### Phase 1: Immediate Bug Fix (Day 2)

**Goal**: Fix the P1 blocking bug (New-SpecKitManifest parameter issue)

#### Step 4: Fix ManifestManager.psm1
```powershell
# File: scripts/modules/ManifestManager.psm1

# Changes required:
# 1. Line 126: Change parameter declaration
#    [string]$SpecKitVersion → [string]$Version
#
# 2. Line 135: Update verbose message
#    "Creating new manifest for SpecKit version $SpecKitVersion"
#    → "Creating new manifest for SpecKit version $Version"
#
# 3. Line 138: Update function call
#    Get-OfficialSpecKitCommands -SpecKitVersion $SpecKitVersion
#    → Get-OfficialSpecKitCommands -Version $Version
#
# 4. Comment-based help: Update .PARAMETER documentation
#    .PARAMETER SpecKitVersion → .PARAMETER Version
```

#### Step 5: Fix update-orchestrator.ps1
```powershell
# File: scripts/update-orchestrator.ps1

# Change required:
# Line 200: Add missing -Version parameter
#
# Before:
# $manifest = New-SpecKitManifest -ProjectRoot $projectRoot -AssumeAllCustomized
#
# After:
# $manifest = New-SpecKitManifest `
#     -ProjectRoot $projectRoot `
#     -Version $targetRelease.tag_name `
#     -AssumeAllCustomized
```

#### Step 6: Test P1 Fix
```powershell
# Run ManifestManager unit tests
Invoke-Pester -Path .\tests\unit\ManifestManager.Tests.ps1

# Run integration test for first-time manifest creation
# Manual test: Remove manifest and run update
Remove-Item .\.specify\manifest.json -ErrorAction SilentlyContinue
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose

# Expected: Manifest created successfully, update check completes
```

---

### Phase 2: Comprehensive Audit (Day 3)

**Goal**: Identify ALL parameter naming inconsistencies across codebase

#### Step 7: Run Full Parameter Audit
```powershell
# Run audit tool with detailed output
& .\scripts\tools\audit-parameters.ps1 -OutputFormat "both"

# Review violations by severity:
# 1. Critical: Missing required parameters
# 2. High: Non-standard canonical names
# 3. Medium: Inconsistent call sites
# 4. Low: Outdated documentation
```

#### Step 8: Categorize Violations
```powershell
# Create refactoring task list from audit report
# Group violations by:
# - Module (HashUtils, GitHubApiClient, ManifestManager, etc.)
# - Severity (critical first, then high, medium, low)
# - Type (signature, call site, documentation, messages)

# Example task list:
# Module: HashUtils
# - [ ] Refactor Get-NormalizedHash: -FilePath parameter (if needed)
#
# Module: GitHubApiClient
# - [ ] Refactor Download-SpecKitTemplates: -Version parameter (check if needed)
# - [ ] Refactor Get-OfficialSpecKitCommands: verify -Version parameter
#
# Module: BackupManager
# - [ ] Refactor Create-Backup: standardize path parameters
#
# [Continue for all modules]
```

---

### Phase 3: Systematic Refactoring (Days 4-6)

**Goal**: Refactor all modules to use standardized parameter names

**Refactoring Pattern (repeat for each module)**:

#### Module Refactoring Template

**For each module (e.g., HashUtils.psm1)**:

1. **Backup current version** (git already tracks, but verify clean state):
   ```powershell
   git status  # Verify no uncommitted changes
   ```

2. **Identify violations in module**:
   ```powershell
   # Review audit report section for this module
   # List all violations with line numbers
   ```

3. **Refactor function signatures**:
   ```powershell
   # For each function with violations:
   # - Update param block parameter names
   # - Update internal variable usage
   # - Update verbose/error messages using the variable
   # - Update comment-based help (.PARAMETER documentation)
   ```

4. **Update call sites**:
   ```powershell
   # Search for all calls to this function:
   Select-String -Path .\scripts\**\*.ps1,.\scripts\**\*.psm1 -Pattern "FunctionName"

   # Update each call site to use new parameter names
   ```

5. **Update tests**:
   ```powershell
   # Update unit tests for this module:
   # - Fix function calls in tests
   # - Add new tests if coverage gaps exist
   # - Run tests to verify no breakage

   Invoke-Pester -Path .\tests\unit\ModuleName.Tests.ps1
   ```

6. **Verify module completion**:
   ```powershell
   # Re-run audit for this module only
   & .\scripts\tools\audit-parameters.ps1 | Where-Object { $_.file_path -like "*ModuleName*" }

   # Expected: Zero violations for this module
   ```

#### Recommended Module Order

Refactor in dependency order (Tier 0 → Tier 1 → Tier 2):

**Day 4: Tier 0 Modules** (no dependencies)
1. HashUtils.psm1
2. GitHubApiClient.psm1
3. VSCodeIntegration.psm1

**Day 5: Tier 1 Modules** (depend on Tier 0)
4. ManifestManager.psm1 (already partially done in Phase 1)

**Day 6: Tier 2 Modules** (depend on Tier 1)
5. BackupManager.psm1
6. ConflictDetector.psm1

**Day 6: Scripts & Helpers**
7. update-orchestrator.ps1 (already partially done in Phase 1)
8. All helper scripts in scripts/helpers/

---

### Phase 4: Test Coverage Expansion (Day 7)

**Goal**: Achieve 90%+ code coverage

#### Step 9: Measure Current Coverage
```powershell
# Run test suite with coverage
.\tests\test-runner.ps1 -Coverage

# Analyze uncovered lines:
# - Review coverage report (coverage/coverage.xml or console output)
# - Identify functions/lines with no coverage
# - Prioritize: error paths, edge cases, new audit tool
```

#### Step 10: Add Missing Tests
```powershell
# For each uncovered area:
# 1. Identify test gap (what scenario isn't tested?)
# 2. Write test case
# 3. Run test to verify it passes
# 4. Re-run coverage to verify line now covered

# Example: Add tests for parameter validation
Describe "New-SpecKitManifest Parameter Validation" {
    It "Should throw when Version is null" {
        { New-SpecKitManifest -ProjectRoot "." -Version $null } | Should -Throw
    }

    It "Should throw when Version is empty string" {
        { New-SpecKitManifest -ProjectRoot "." -Version "" } | Should -Throw
    }
}
```

#### Step 11: Add Tests for Audit Tool
```powershell
# Create: tests/unit/ParameterAuditTool.Tests.ps1

# Test cases:
# - Detect non-standard parameter names
# - Detect missing required parameters
# - Detect mismatched call sites
# - Detect outdated documentation
# - Generate valid JSON output
# - Generate valid markdown output
# - Exit code 0 when compliant
# - Exit code 1 when violations found
```

#### Step 12: Verify 90%+ Coverage
```powershell
# Run final coverage check
.\tests\test-runner.ps1 -Coverage

# Expected output:
# Code Coverage: 90.5% or higher
# All tests passing
```

---

### Phase 5: Manual Testing (Day 8)

**Goal**: Validate all critical user workflows work correctly

#### Step 13: Manual Testing Checklist

**Test Case 1: First-Time Update (No Manifest)**
```powershell
# Setup: Remove existing manifest
Remove-Item .\.specify\manifest.json -ErrorAction SilentlyContinue

# Execute: Run update in check-only mode
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose

# Verify:
# - ✅ Manifest created successfully
# - ✅ Version detected from GitHub API
# - ✅ Update preview displayed
# - ✅ No errors about missing parameters
```

**Test Case 2: Existing Update (With Manifest)**
```powershell
# Setup: Ensure manifest exists (from Test Case 1)

# Execute: Run update in check-only mode
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose

# Verify:
# - ✅ Manifest loaded successfully
# - ✅ File states analyzed correctly
# - ✅ Update preview displayed
# - ✅ Customization detection works
```

**Test Case 3: AssumeAllCustomized Flag**
```powershell
# Setup: Remove manifest
Remove-Item .\.specify\manifest.json -ErrorAction SilentlyContinue

# Execute: Run update with AssumeAllCustomized
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose

# Verify:
# - ✅ Manifest created with all files marked customized
# - ✅ No files marked for update (all preserved)
```

**Test Case 4: Explicit Version Parameter**
```powershell
# Execute: Run update with specific version
& .\scripts\update-orchestrator.ps1 -Version v0.0.72 -CheckOnly -Verbose

# Verify:
# - ✅ Specified version used (not latest)
# - ✅ Update check completes successfully
```

**Test Case 5: Conflict Resolution Workflow**
```powershell
# Setup: Modify a tracked file to create conflict
# (Manually edit .claude/commands/speckit.specify.md)

# Execute: Run update (not check-only)
& .\scripts\update-orchestrator.ps1 -Verbose

# Verify:
# - ✅ Conflict detected
# - ✅ 3-way merge editor launched (if in VSCode)
# - ✅ User can resolve conflict
# - ✅ Update completes after resolution
```

**Test Case 6: Rollback Workflow**
```powershell
# Execute: Trigger rollback
& .\scripts\update-orchestrator.ps1 -Rollback -Verbose

# Verify:
# - ✅ Most recent backup identified
# - ✅ Files restored from backup
# - ✅ Manifest reverted
# - ✅ Exit code 6
```

**Test Case 7: Force Mode**
```powershell
# Execute: Run update with force flag
& .\scripts\update-orchestrator.ps1 -Force -Verbose

# Verify:
# - ✅ No confirmation prompts
# - ✅ Update proceeds automatically
# - ✅ Custom commands still preserved
```

**Test Case 8: Get-Help for Refactored Functions**
```powershell
# Verify help documentation updated
Get-Help New-SpecKitManifest -Full

# Verify:
# - ✅ .PARAMETER Version (not SpecKitVersion)
# - ✅ All other parameters documented correctly
# - ✅ Examples use correct parameter names
```

---

### Phase 6: Final Validation (Day 9)

**Goal**: Confirm 100% compliance and readiness for release

#### Step 14: Run Final Parameter Audit
```powershell
# Run audit tool with strict validation
& .\scripts\tools\audit-parameters.ps1 -FailOnViolations

# Expected output:
# Violations Found: 0
# Compliance Rate: 100%
# ✅ PASS
```

#### Step 15: Run Full Test Suite
```powershell
# Run all tests (unit + integration)
.\tests\test-runner.ps1

# Expected output:
# All tests passing
# No regressions from baseline
```

#### Step 16: Performance Baseline Check
```powershell
# Measure update command performance
Measure-Command {
    & .\scripts\update-orchestrator.ps1 -CheckOnly
}

# Compare to baseline (from Phase 0)
# Expected: No significant performance degradation
# Acceptable: ±10% variance
```

#### Step 17: Final Manual Smoke Test
```powershell
# Run one final end-to-end update
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose

# Verify all workflows still functional
```

---

### Phase 7: Documentation & Release (Day 10)

**Goal**: Update documentation and prepare for merge

#### Step 18: Update CHANGELOG.md
```markdown
## [Unreleased]

### Changed
- **BREAKING (internal)**: Standardized all parameter names across PowerShell modules and scripts
  - `New-SpecKitManifest` now uses `-Version` parameter (was `-SpecKitVersion`)
  - All functions updated to use canonical parameter names per naming standard
  - See `docs/parameter-naming-standard.md` for complete reference

### Added
- Automated parameter naming audit tool (`scripts/tools/audit-parameters.ps1`)
- Parameter naming standard document (`docs/parameter-naming-standard.md`)
- Comprehensive test coverage expansion (now 90%+ coverage)

### Fixed
- Issue #8: `New-SpecKitManifest` blocking first-time users with missing parameter error
```

#### Step 19: Update CONTRIBUTING.md
```markdown
## Parameter Naming Standards

All new functions MUST follow the parameter naming standard defined in
`docs/parameter-naming-standard.md`. Before submitting a PR, run the
automated audit tool to verify compliance:

\`\`\`powershell
& .\scripts\tools\audit-parameters.ps1 -FailOnViolations
\`\`\`

Expected output: `✅ PASS - All parameters comply with naming standard`
```

#### Step 20: Update Bug Report
```powershell
# Update docs/bugs/004-new-manifest-speckit-version-parameter.md
# Add "RESOLVED" status
# Add resolution date
# Add commit reference (to be filled after merge)
```

#### Step 21: Commit All Changes
```powershell
# Stage all changes
git add .

# Create comprehensive commit message
git commit -m "refactor: complete parameter standardization across codebase (issue #8)

This commit implements comprehensive parameter naming standardization across
all PowerShell modules, scripts, and helpers. The refactoring addresses issue
#8 (New-SpecKitManifest parameter bug) and establishes a systematic parameter
naming standard for long-term maintainability.

Changes:
- Fix New-SpecKitManifest to use -Version parameter (was -SpecKitVersion)
- Standardize all function parameters per naming standard
- Create automated parameter audit tool for CI/CD enforcement
- Expand test coverage from 75% to 90%+
- Document canonical parameter names in naming standard

Affected modules:
- ManifestManager.psm1 (primary fix + additional standardization)
- HashUtils.psm1
- GitHubApiClient.psm1
- VSCodeIntegration.psm1
- BackupManager.psm1
- ConflictDetector.psm1
- update-orchestrator.ps1
- All helper scripts in scripts/helpers/

Testing:
- All unit tests passing (132 tests)
- All integration tests passing
- Code coverage: 90.5%
- Manual testing completed (8 test cases)
- Parameter audit: 100% compliance

Breaking Changes:
- Internal parameter names changed (no user-facing API changes)
- Developers must update any custom scripts calling skill functions

Fixes: #8

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Rollback Plan

If critical issues discovered after merge:

```powershell
# Option 1: Revert commit
git revert <commit-hash>

# Option 2: Restore from backup (if changes deployed to prod)
& .\scripts\update-orchestrator.ps1 -Rollback

# Option 3: Cherry-pick only P1 fix (if comprehensive refactoring has issues)
git cherry-pick <p1-fix-commit-hash>
```

## Success Criteria Checklist

Before considering this feature complete, verify:

- [ ] All 5 code locations in ManifestManager.psm1 fixed (P1 bug)
- [ ] Parameter naming standard document created and approved
- [ ] All PowerShell modules audited and refactored
- [ ] All PowerShell scripts and helpers audited and refactored
- [ ] Automated parameter audit tool created and tested
- [ ] Code coverage reaches 90%+ across all modules
- [ ] All unit tests passing (no regressions)
- [ ] All integration tests passing
- [ ] All 8 manual test cases passing
- [ ] Parameter audit tool reports 100% compliance
- [ ] Performance baseline maintained (no regression)
- [ ] CHANGELOG.md updated
- [ ] CONTRIBUTING.md updated
- [ ] Bug report (004) marked resolved
- [ ] Documentation reviewed and accurate

## Next Steps

After this feature is complete:

1. Run `/speckit.tasks` to generate implementation task list
2. Execute tasks following this quickstart guide
3. Create pull request for review
4. Merge to main after approval
5. Update skill version in SKILL.md
6. Close issue #8

---

**Estimated Timeline**: 10 days (can be compressed with focused effort)
**Risk Level**: High (all-at-once refactoring)
**Mitigation**: Comprehensive testing (90% coverage + manual validation)
