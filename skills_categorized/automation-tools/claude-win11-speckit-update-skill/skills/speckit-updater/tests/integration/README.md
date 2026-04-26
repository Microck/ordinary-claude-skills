# Integration Tests for SpecKit Safe Update Orchestrator

This directory contains comprehensive integration tests for the update orchestrator that validate end-to-end workflows.

## Overview

The integration tests cover all scenarios specified in Phase 5 of the implementation plan:

1. **Standard Update (No Conflicts)** - Fresh project with manifest, available update, no customizations
2. **Update with Customizations** - Project with customized files, no upstream changes
3. **Update with Conflicts** - Customized files with upstream changes requiring resolution
4. **First-Time Manifest Generation** - Old project without manifest
5. **Custom Commands Preservation** - Project with custom commands, official commands updated
6. **Rollback on Failure** - Simulated failure mid-update with automatic rollback
7. **Backup Retention** - Multiple updates creating backups, cleanup old backups
8. **Command Lifecycle** - New official commands added, old commands removed

Plus additional scenarios:
- Check-Only Mode
- Force Mode
- Rollback Command
- Error Handling

## Prerequisites

### Required

- **PowerShell 7.0+**
  ```powershell
  $PSVersionTable.PSVersion
  ```

- **Pester 5.x**
  ```powershell
  Install-Module -Name Pester -Force -SkipPublisherCheck
  ```

### Optional

- **VSCode** with PowerShell extension for debugging tests
- **Git** (for validation tests)

## Running the Tests

### Run All Integration Tests

From the repository root:

```powershell
# Run all integration tests
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -Output Detailed
```

### Run Specific Scenario

```powershell
# Run only scenario 1 (Standard Update)
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -FullName "*Scenario 1*" -Output Detailed

# Run only conflict resolution tests
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -FullName "*Scenario 3*" -Output Detailed
```

### Run with Code Coverage

```powershell
$config = New-PesterConfiguration
$config.Run.Path = ".\tests\integration\UpdateOrchestrator.Tests.ps1"
$config.Output.Verbosity = "Detailed"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = ".\scripts\**\*.ps1", ".\scripts\**\*.psm1"
$config.CodeCoverage.OutputFormat = "JaCoCo"
$config.CodeCoverage.OutputPath = ".\tests\coverage\integration-coverage.xml"

Invoke-Pester -Configuration $config
```

### Continuous Integration

The tests are designed to run in CI/CD environments:

```powershell
# CI-friendly output
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -CI
```

## Test Architecture

### Mocking Strategy

The integration tests use Pester mocking to isolate external dependencies:

1. **GitHub API Calls** - Mocked using predefined responses from `tests/fixtures/mock-github-responses/`
2. **VSCode Commands** - `Open-DiffView`, `Open-MergeEditor` are mocked to simulate user interactions
3. **User Input** - `Read-Host` and `Show-QuickPick` are mocked to provide automated responses

### Test Projects

Each test scenario creates temporary test projects based on fixtures:

- `sample-project-with-manifest` - Complete project with existing manifest
- `sample-project-with-customizations` - Project with user-modified files
- `sample-project-without-manifest` - Legacy project needing manifest creation

Test projects are created in `$env:TEMP` and cleaned up after each test.

### Helper Functions

The tests include several helper functions:

- `New-TestProject` - Creates isolated test project from fixture
- `Remove-TestProject` - Cleans up test project after tests
- `Mock-GitHubApi` - Configures GitHub API mocks with custom responses
- `Mock-VSCodeCommands` - Mocks VSCode integration functions
- `Mock-UserInput` - Provides automated responses to interactive prompts

## Test Scenarios Details

### Scenario 1: Standard Update (No Conflicts)

**Purpose:** Validates the happy path - clean update with no customizations.

**Setup:**
- Fresh project with manifest
- No user customizations
- Upstream has updates

**Validates:**
- Update completes successfully
- Manifest version updated
- Backup created
- Files updated with new content

### Scenario 2: Update with Customizations

**Purpose:** Validates that user customizations are preserved.

**Setup:**
- Project with customized files
- Upstream has NO changes to customized files
- Upstream has changes to other files

**Validates:**
- Customized files preserved
- Non-customized files updated
- Manifest marks customizations correctly

### Scenario 3: Update with Conflicts

**Purpose:** Validates conflict detection and resolution workflow.

**Setup:**
- User customized a file
- Upstream also modified the same file

**Validates:**
- Conflicts detected
- Merge editor invoked (Flow A)
- Resolution applied correctly
- Temp files cleaned up

### Scenario 4: First-Time Manifest Generation

**Purpose:** Validates manifest creation for legacy projects.

**Setup:**
- Project without manifest
- Existing SpecKit files

**Validates:**
- Manifest creation offered
- All existing files tracked
- All files marked as customized (safe default)

### Scenario 5: Custom Commands Preservation

**Purpose:** Validates that custom commands are never overwritten.

**Setup:**
- Project with custom command files
- Official commands updated upstream

**Validates:**
- Custom commands preserved
- Official commands updated
- Custom commands listed in summary
- Manifest tracks custom commands

### Scenario 6: Rollback on Failure

**Purpose:** Validates automatic rollback on update failure.

**Setup:**
- Simulate error mid-update
- Backup created before failure

**Validates:**
- Automatic rollback triggered
- Files restored to original state
- Backup preserved for manual recovery
- Clear error message displayed

### Scenario 7: Backup Retention

**Purpose:** Validates automatic cleanup of old backups.

**Setup:**
- 7 existing backups (exceeds limit of 5)
- New update creates 8th backup

**Validates:**
- Cleanup prompt displayed
- Only 5 most recent kept (plus new one)
- Oldest backups deleted first

### Scenario 8: Command Lifecycle

**Purpose:** Validates handling of added/removed commands.

**Setup:**
- New official command in upstream
- Old official command removed upstream
- Custom command exists

**Validates:**
- New official command added
- Obsolete official command removed
- Custom commands unaffected
- Manifest updated with new command list

## Debugging Tests

### Enable Verbose Output

```powershell
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -Output Detailed -Verbose
```

### Debug Specific Test

In VSCode with PowerShell extension:

1. Set breakpoint in test file
2. Press F5 or use "Debug Pester Tests" CodeLens
3. Step through test execution

### Inspect Test Projects

To keep test projects for manual inspection:

1. Comment out `Remove-TestProject` call in `AfterAll`
2. Run the test
3. Navigate to `$env:TEMP\test-project-*` to inspect

### View Mock Call History

```powershell
# After running tests, check mock invocations
Should -Invoke -ModuleName GitHubApiClient -CommandName Get-LatestSpecKitRelease -Exactly 1
```

## Common Issues

### Tests Fail with "Module not found"

**Solution:** Ensure modules are built and in the correct location:

```powershell
# Verify modules exist
Get-ChildItem .\scripts\modules\*.psm1
```

### Tests Fail with "Permission denied"

**Solution:** Close any open files/editors that might lock test files:

```powershell
# Close VSCode tabs with test projects
# Run tests again
```

### Tests Hang on User Input

**Solution:** Ensure user input mocks are properly configured:

```powershell
# Check Mock-UserInput is called in BeforeAll
# Verify Read-Host is mocked
```

### Cleanup Failures

**Solution:** Tests may fail to clean up if files are locked:

```powershell
# Manually clean up test projects
Get-ChildItem $env:TEMP -Filter "test-project-*" -Directory | Remove-Item -Recurse -Force
```

## Performance

Integration tests are slower than unit tests due to:

- File system operations
- Project creation/cleanup
- Full orchestrator execution

**Typical Execution Time:**
- Single scenario: 5-15 seconds
- All scenarios: 2-5 minutes

## Extending Tests

### Add New Scenario

1. Add new `Context` block in test file
2. Create `BeforeAll` with test setup
3. Create `AfterAll` with cleanup
4. Add `It` blocks for assertions
5. Document scenario in this README

### Add New Mock Response

1. Create JSON file in `tests/fixtures/mock-github-responses/`
2. Update `Mock-GitHubApi` function to load it
3. Use in test scenario

### Add New Fixture Project

1. Create directory in `tests/fixtures/`
2. Add realistic SpecKit structure
3. Reference in `New-TestProject` calls

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Pester
        shell: pwsh
        run: |
          Install-Module -Name Pester -Force -SkipPublisherCheck

      - name: Run Integration Tests
        shell: pwsh
        run: |
          Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -CI

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: testResults.xml
```

## Test Maintenance

### When to Update Tests

- Adding new orchestrator features
- Changing update workflow
- Modifying conflict resolution
- Updating manifest schema
- Adding new command types

### Test Quality Checklist

- [ ] All scenarios from plan covered
- [ ] Mocks isolate external dependencies
- [ ] Tests are deterministic (no flaky tests)
- [ ] Cleanup always runs (even on failure)
- [ ] Clear assertion messages
- [ ] Documented edge cases

## Related Documentation

- **Unit Tests:** `tests/unit/README.md` (if exists)
- **Implementation Plan:** `specs/001-safe-update/plan.md` (Phase 5)
- **Orchestrator Documentation:** `scripts/update-orchestrator.ps1` (inline help)

## Support

For issues with integration tests:

1. Check this README for common issues
2. Review test output for specific errors
3. Enable verbose/debug output
4. Inspect test projects manually
5. Open GitHub issue with test output

---

**Last Updated:** 2025-01-19
**Test Framework:** Pester 5.x
**Coverage Target:** >80% for orchestrator and helpers
