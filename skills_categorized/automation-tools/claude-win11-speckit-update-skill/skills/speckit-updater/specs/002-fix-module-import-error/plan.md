# Implementation Plan: Fix Module Import Error

**Branch**: `002-fix-module-import-error` | **Date**: 2025-10-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-fix-module-import-error/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Fix critical bug preventing `/speckit-update` skill execution due to module import errors. The script fails with "Export-ModuleMember cmdlet can only be called from inside a module" error, which is non-fatal (modules actually load correctly) but the try-catch block treats it as fatal and exits.

**Technical Approach**: Implement module import validation that distinguishes between fatal errors (missing functions) and non-fatal errors (Export-ModuleMember warnings, unapproved verbs). Modify update-orchestrator.ps1 to verify module functions are available post-import rather than failing on PowerShell's internal module loading quirks.

## Technical Context

**Language/Version**: PowerShell 7.x (pwsh.exe)
**Primary Dependencies**: Pester 5.x (testing), PowerShell Core modules
**Storage**: N/A (bug fix to existing script error handling)
**Testing**: Pester 5.x unit tests for validation logic, integration tests for orchestrator
**Target Platform**: Windows 11 with PowerShell 7.x (Claude Code environment)
**Project Type**: Single project (PowerShell skill with modular architecture)
**Performance Goals**: Module import phase completes in under 2 seconds
**Constraints**: Must not require module restructuring (keep existing `.psm1` files without manifests)
**Scale/Scope**: Affects single entry point script (update-orchestrator.ps1) and potentially 6 module files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Modular Architecture ✅ PASS

**Requirement**: Business logic in modules, helpers for orchestration only

**Compliance**: This bug fix modifies update-orchestrator.ps1 (orchestrator) only. The validation logic will be added to the orchestrator's module import section, not moved to a separate module, because:
- Module import is orchestration responsibility (loading dependencies)
- Validation is a one-time setup check, not reusable business logic
- No new modules created; existing module architecture preserved

**Verdict**: ✅ PASS - Fix maintains existing modular architecture

### Principle II: Fail-Fast with Rollback ✅ PASS

**Requirement**: Transactional updates with automatic rollback on errors

**Compliance**: This fix occurs during the import phase BEFORE any file operations. No rollback logic changes required because:
- Import validation runs before backup creation
- No user files modified during this phase
- Early exit with clear error message is appropriate
- Rollback only applies to file modification phases (steps 8-13)

**Verdict**: ✅ PASS - Import validation appropriately placed before transactional phases

### Principle III: Customization Detection via Normalized Hashing ✅ PASS

**Requirement**: Use normalized hashing for file comparison

**Compliance**: This bug fix does not affect file hashing or customization detection. The HashUtils module and its normalized hashing remain unchanged.

**Verdict**: ✅ PASS - No impact on hashing logic

### Principle IV: User Confirmation Required ✅ PASS

**Requirement**: Explicit user confirmation before applying changes

**Compliance**: This bug fix occurs during prerequisite validation, before user confirmation phase. No changes to confirmation workflow.

**Verdict**: ✅ PASS - No impact on user confirmation flow

### Principle V: Testing Discipline ✅ PASS

**Requirement**: Pester unit tests for modules, integration tests for orchestrator

**Compliance**: This fix requires:
- Unit tests for module validation logic (test required function detection)
- Integration tests for orchestrator error handling (test fatal vs non-fatal errors)
- Edge case tests (missing modules, partial loads, PowerShell version)

**Verdict**: ✅ PASS - Tests will be added as required

### PowerShell Standards ✅ PASS

**Code Style Requirements**:
- Function names: Import validation will use internal helper pattern (no new exported functions)
- Error handling: Will use try-catch with appropriate error streams
- Comment-based help: Not required for internal validation code
- Verbose logging: Will add `Write-Verbose` for diagnostic information

**Verdict**: ✅ PASS - Follows PowerShell standards

### Overall Constitution Compliance

**Status**: ✅ ALL GATES PASSED

No constitution violations. This is a bug fix that improves error handling without changing architecture, transaction model, or user-facing workflows.

## Project Structure

### Documentation (this feature)

```text
specs/002-fix-module-import-error/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output: PowerShell error handling patterns
├── quickstart.md        # Phase 1 output: Testing and validation guide
└── checklists/
    └── requirements.md  # Quality checklist (already created)
```

**Note**: No data-model.md or contracts/ needed - this is a bug fix, not a feature with entities or APIs.

### Source Code (repository root)

```text
scripts/
├── update-orchestrator.ps1  # PRIMARY TARGET: Module import error handling
├── modules/                 # UNCHANGED: Existing 6 modules remain as-is
│   ├── HashUtils.psm1
│   ├── VSCodeIntegration.psm1
│   ├── GitHubApiClient.psm1
│   ├── ManifestManager.psm1
│   ├── BackupManager.psm1
│   └── ConflictDetector.psm1
└── helpers/                 # UNCHANGED: Helper functions remain as-is

tests/
├── unit/
│   └── UpdateOrchestrator.Tests.ps1  # NEW: Tests for import validation
└── integration/
    └── UpdateOrchestrator.Tests.ps1  # MODIFIED: Add import error scenarios
```

**Structure Decision**: This is a bug fix targeting the orchestrator script only. The existing single-project structure with modular PowerShell architecture remains unchanged. No new modules or helpers are created; the fix is localized to the module import section of update-orchestrator.ps1 (lines 90-124).

## Complexity Tracking

*No constitution violations - this section is empty.*

## Phase 0: Research (Complete)

**Status**: ✅ Complete

**Outputs**:
- [research.md](research.md) - PowerShell error handling patterns and module import validation strategies

**Key Findings**:
- Export-ModuleMember error is non-terminating; modules load successfully despite error
- Post-import function validation is more reliable than try-catch error detection
- Required functions identified: 6 critical functions (one per module)
- Error suppression approach: Use `-ErrorAction SilentlyContinue` during import, validate afterward

## Phase 1: Design & Contracts (Complete)

**Status**: ✅ Complete

**Outputs**:
- [quickstart.md](quickstart.md) - Testing and validation guide for developers
- Agent context updated in [CLAUDE.md](../../CLAUDE.md)

**No Data Model or Contracts Required**: This is a bug fix to error handling logic, not a feature with entities or APIs.

**Design Decisions**:
- Localize fix to update-orchestrator.ps1 lines 90-124 only
- Add required functions array with 6 critical functions
- Preserve existing module structure (no `.psd1` manifests)
- Suppress warnings during import, validate afterward

### Post-Phase 1 Constitution Re-Check

**Status**: ✅ ALL GATES STILL PASS

No changes to original assessment. Design confirms:

- **Modular Architecture**: No new modules created, existing architecture preserved
- **Fail-Fast with Rollback**: Import validation occurs before transactional phases
- **Normalized Hashing**: No impact on hashing logic
- **User Confirmation**: No impact on confirmation workflow
- **Testing Discipline**: Unit and integration tests will be added (required by constitution)
- **PowerShell Standards**: Implementation follows PascalCase, try-catch, verbose logging standards

**Complexity**: Zero additional complexity. This is a targeted bug fix with clear scope.

