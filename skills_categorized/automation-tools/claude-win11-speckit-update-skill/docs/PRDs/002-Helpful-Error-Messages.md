# PRD: Helpful Error Messages for Non-SpecKit Projects

## Executive Summary

Enhance the `/speckit-update` command to provide helpful, actionable error messages when invoked in projects that don't have SpecKit installed. Replace cryptic error messages with educational guidance that explains what SpecKit is, why it's required, and how to install it.

**Problem:** First-time users get confusing error messages that don't explain what SpecKit is or how to get started.

**Solution:** Context-aware error messages that detect the user's environment, provide educational content, and offer clear next steps.

**Impact:** Improves onboarding experience and reduces user confusion, especially for developers discovering SpecKit through the updater skill.

## Problem Statement

When users run `/speckit-update` in a project without SpecKit installed, they receive this error:

```
Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)

Prerequisites validation failed. Please fix the issues above and try again.
```

**User Pain Points:**
- **No context:** Error doesn't explain what SpecKit is
- **No guidance:** No instructions on how to install SpecKit
- **Dead end:** User is stuck without actionable next steps
- **Poor discovery:** Users finding the updater skill first get frustrated

**Real-World Scenario:**
1. Developer discovers "SpecKit Safe Update" skill in Claude Code
2. Installs the skill, excited to try it
3. Runs `/speckit-update` in their project
4. Gets cryptic error with no explanation
5. Gives up or spends time searching for SpecKit documentation

## Goals

### Primary Goals
1. **Educate users** about what SpecKit is when they encounter the error
2. **Provide actionable steps** to install SpecKit in their project
3. **Reduce friction** in the onboarding experience
4. **Improve discoverability** of SpecKit for users who find the updater first

### Secondary Goals
- Detect if SpecKit commands are already available (skill installed but project not initialized)
- Link to official documentation for learning more
- Maintain consistent tone with other error messages in the skill

### Non-Goals (v1)
- **Automatic SpecKit installation:** Don't auto-run `/speckit.constitution` without user consent
- **Interactive setup wizard:** Keep error message simple and text-based
- **Version detection:** Don't attempt to detect available SpecKit versions
- **Multi-agent detection:** Only focus on Claude Code context

## User Stories

### Story 1: First-Time User Discovery
**As a** developer new to SpecKit who found the updater skill first
**I want to** understand what SpecKit is when I get an error
**So that** I know whether it's relevant to my workflow and how to get started

**Acceptance Criteria:**
- Error message explains what SpecKit is in one sentence
- Error message indicates this is expected (not a bug or failure)
- Error message tone is helpful, not accusatory

### Story 2: Experienced Developer with Uninitialized Project
**As a** developer who uses SpecKit in other projects
**I want to** be reminded how to initialize SpecKit in this project
**So that** I can quickly set up and start using the updater

**Acceptance Criteria:**
- Error message provides exact command to run for initialization
- Command is context-aware (detects if `/speckit.constitution` is available)
- Error message is concise (can be scanned quickly)

### Story 3: Developer Evaluating SpecKit
**As a** developer evaluating whether to adopt SpecKit
**I want to** easily find documentation about what SpecKit does
**So that** I can make an informed decision before installing

**Acceptance Criteria:**
- Error message includes link to official SpecKit documentation
- Link is to stable documentation (not specific version)
- Error distinguishes between "SpecKit not installed" vs "project not initialized"

## Technical Design

### Detection Logic

The error occurs in [scripts/helpers/Invoke-PreUpdateValidation.ps1:44-48](../scripts/helpers/Invoke-PreUpdateValidation.ps1):

```powershell
# Current implementation
$specifyDir = Join-Path $ProjectRoot ".specify"
if (-not (Test-Path $specifyDir)) {
    $errors += "Not a SpecKit project (.specify/ directory not found)"
}
```

### Proposed Implementation

Replace with context-aware error message generation:

```powershell
# Enhanced implementation
$specifyDir = Join-Path $ProjectRoot ".specify"
if (-not (Test-Path $specifyDir)) {
    $errorMessage = Get-HelpfulSpecKitError -ProjectRoot $ProjectRoot
    $errors += $errorMessage
}

function Get-HelpfulSpecKitError {
    param([string]$ProjectRoot)

    # Base error message
    $message = @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

"@

    # Check if SpecKit commands are available
    $hasSpecKitCommands = Test-SpecKitCommandsAvailable

    if ($hasSpecKitCommands) {
        # SpecKit skill is installed, project just needs initialization
        $message += @"
To initialize SpecKit in this project, run:

    /speckit.constitution

Then you can use /speckit-update to keep templates up to date.
"@
    }
    else {
        # SpecKit not installed at all
        $message += @"
This updater requires SpecKit to be installed first.

Learn more: https://github.com/github/spec-kit
"@
    }

    return $message
}

function Test-SpecKitCommandsAvailable {
    # Check if .claude/commands/ contains SpecKit commands
    # This indicates the SpecKit skill is installed but project not initialized

    $claudeCommandsDir = Join-Path $env:USERPROFILE ".claude\commands"

    if (Test-Path $claudeCommandsDir) {
        $specKitCommands = @(
            "speckit.constitution.md",
            "speckit.specify.md",
            "speckit.plan.md"
        )

        foreach ($cmd in $specKitCommands) {
            $cmdPath = Join-Path $claudeCommandsDir $cmd
            if (Test-Path $cmdPath) {
                return $true
            }
        }
    }

    return $false
}
```

### Error Message Variants

#### Variant A: SpecKit Commands Available (Skill Installed)
```
Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)

    SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

    To initialize SpecKit in this project, run:

        /speckit.constitution

    Then you can use /speckit-update to keep templates up to date.

Prerequisites validation failed. Please fix the issues above and try again.
```

#### Variant B: SpecKit Not Installed
```
Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)

    SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

    This updater requires SpecKit to be installed first.

    Learn more: https://github.com/github/spec-kit

Prerequisites validation failed. Please fix the issues above and try again.
```

### Implementation Location

**Primary Change:**
- File: [scripts/helpers/Invoke-PreUpdateValidation.ps1](../scripts/helpers/Invoke-PreUpdateValidation.ps1)
- Lines: 44-48 (current error check)
- Function: Add `Get-HelpfulSpecKitError` helper function

**Supporting Changes:**
- Add `Test-SpecKitCommandsAvailable` function to detect SpecKit installation state
- Update unit tests to verify error message content
- Update integration tests to cover both variants

### Alternative Approach: Simple Static Message

If command detection proves complex, use a simplified static message:

```powershell
$specifyDir = Join-Path $ProjectRoot ".specify"
if (-not (Test-Path $specifyDir)) {
    $errors += @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework for building features.

If SpecKit is already installed:
  • Run: /speckit.constitution

If SpecKit is not installed:
  • Learn more: https://github.com/github/spec-kit
"@
}
```

**Tradeoff:** Less personalized but simpler to implement and maintain.

## Command Behavior Specification

### Before Fix
```powershell
PS> cd C:\projects\my-app
PS> /speckit-update

Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)

Prerequisites validation failed. Please fix the issues above and try again.
```

**User Experience:** Confusion, frustration, no clear next step.

### After Fix (Variant A: Commands Available)
```powershell
PS> cd C:\projects\my-app
PS> /speckit-update

Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)

    SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

    To initialize SpecKit in this project, run:

        /speckit.constitution

    Then you can use /speckit-update to keep templates up to date.

Prerequisites validation failed. Please fix the issues above and try again.
```

**User Experience:** Clear understanding, actionable next step, encouragement to continue.

### After Fix (Variant B: SpecKit Not Available)
```powershell
PS> cd C:\projects\my-app
PS> /speckit-update

Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)

    SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

    This updater requires SpecKit to be installed first.

    Learn more: https://github.com/github/spec-kit

Prerequisites validation failed. Please fix the issues above and try again.
```

**User Experience:** Understands the dependency, knows where to learn more.

## Implementation Plan

### Single Sprint Implementation
**Timeline:** 1-2 days (small change)
**Approach:** Enhance error message with educational content and context detection

**Tasks:**
1. ✅ Create PRD (this document)
2. Add `Get-HelpfulSpecKitError` function to `Invoke-PreUpdateValidation.ps1`
3. Implement `Test-SpecKitCommandsAvailable` for context detection
4. Update error message call site to use new function
5. Write unit tests for both error message variants
6. Write integration test for non-SpecKit project scenario
7. Update CHANGELOG.md under `[Unreleased]`
8. Manual testing in both scenarios
9. Update issue #13 with implementation details

**Definition of Done:**
- ✅ Error message explains what SpecKit is
- ✅ Error message provides actionable next steps
- ✅ Context detection works for both scenarios
- ✅ Unit tests pass for both variants
- ✅ Integration test validates end-to-end behavior
- ✅ Manual testing confirms improved UX
- ✅ CHANGELOG updated

### Testing Strategy

**Unit Tests** (`tests/unit/Invoke-PreUpdateValidation.Tests.ps1`):
```powershell
Describe "Get-HelpfulSpecKitError" {
    Context "When SpecKit commands are available" {
        It "Should suggest running /speckit.constitution" {
            Mock Test-SpecKitCommandsAvailable { return $true }

            $result = Get-HelpfulSpecKitError -ProjectRoot "C:\test"

            $result | Should -Match "/speckit.constitution"
            $result | Should -Match "SpecKit is a Claude Code workflow framework"
        }
    }

    Context "When SpecKit commands are not available" {
        It "Should provide documentation link" {
            Mock Test-SpecKitCommandsAvailable { return $false }

            $result = Get-HelpfulSpecKitError -ProjectRoot "C:\test"

            $result | Should -Match "https://github.com/github/spec-kit"
            $result | Should -Match "SpecKit is a Claude Code workflow framework"
        }
    }
}

Describe "Test-SpecKitCommandsAvailable" {
    It "Returns true when SpecKit commands exist" {
        Mock Test-Path { return $true }

        $result = Test-SpecKitCommandsAvailable

        $result | Should -Be $true
    }

    It "Returns false when SpecKit commands don't exist" {
        Mock Test-Path { return $false }

        $result = Test-SpecKitCommandsAvailable

        $result | Should -Be $false
    }
}
```

**Integration Tests** (`tests/integration/UpdateOrchestrator.Tests.ps1`):
```powershell
Describe "Non-SpecKit Project Error Handling" {
    It "Shows helpful error when .specify/ doesn't exist" {
        # Setup: Create temp directory without .specify/
        $testDir = New-TempDirectory
        Set-Location $testDir

        # Execute
        $result = & "$PSScriptRoot\..\..\scripts\update-orchestrator.ps1" -CheckOnly

        # Assert
        $result | Should -Match "SpecKit is a Claude Code workflow framework"
        $result | Should -Match "(speckit.constitution|github.com/github/spec-kit)"

        # Cleanup
        Remove-Item $testDir -Recurse -Force
    }
}
```

**Manual Testing:**
```powershell
# Test Case 1: SpecKit commands available
cd C:\test\non-speckit-project
/speckit-update
# Expected: Error with /speckit.constitution suggestion

# Test Case 2: SpecKit not installed (simulate by hiding commands)
# Temporarily rename .claude\commands
mv $env:USERPROFILE\.claude\commands $env:USERPROFILE\.claude\commands.backup
cd C:\test\non-speckit-project
/speckit-update
# Expected: Error with documentation link
# Restore: mv $env:USERPROFILE\.claude\commands.backup $env:USERPROFILE\.claude\commands

# Test Case 3: Normal SpecKit project (regression check)
cd C:\test\speckit-project
/speckit-update --check-only
# Expected: Normal behavior, no error
```

## Success Metrics

### Primary Metrics
- **User comprehension:** 90%+ of users understand what SpecKit is from error message
- **Reduced confusion:** 80%+ reduction in "what is SpecKit?" support questions
- **Conversion rate:** 50%+ of users who see error proceed to install SpecKit

### Secondary Metrics
- **Error clarity:** Error message scores 8+/10 in user testing
- **Documentation clicks:** Track clicks to SpecKit documentation link
- **Time to resolution:** Average time from error to successful initialization < 5 minutes

### Measurement
- User surveys in GitHub discussions
- GitHub issue activity (questions about "what is SpecKit?")
- Analytics on documentation link (if tracking available)

## Dependencies

### Technical Dependencies
- None (pure enhancement to existing code)
- PowerShell 7+ (already required)
- Access to `.claude\commands\` directory for detection

### External Dependencies
- SpecKit documentation remains at https://github.com/github/spec-kit
- SpecKit command names remain consistent (`/speckit.constitution`)

### Documentation Dependencies
- Update README.md to mention improved error messages
- Update SKILL.md if error message format changes significantly

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|---------|-----------|------------|
| Command detection fails in some environments | Medium | Low | Fall back to generic message with both options |
| SpecKit documentation URL changes | Low | Low | Use main repository URL (stable) |
| Error message too verbose | Low | Medium | Keep message under 10 lines, test readability |
| Users ignore error message | Medium | Medium | Use clear formatting, bullet points, whitespace |
| Detection logic has false positives | Medium | Low | Test with multiple scenarios, use conservative detection |

## Design Decisions

### Decision 1: Context Detection vs Static Message
**Options:**
- A) Detect if SpecKit commands are available and customize message
- B) Show generic message with both scenarios

**Decision:** A (Context Detection)
**Rationale:** Better UX with personalized guidance. Detection is simple (file existence checks) and low-risk.

### Decision 2: Explanation Detail Level
**Options:**
- A) One sentence: "SpecKit is a Claude Code workflow framework"
- B) Detailed paragraph explaining features and benefits
- C) Link only to documentation

**Decision:** A (One Sentence)
**Rationale:** Error messages should be scannable. Users can click documentation link for details.

### Decision 3: Command Recommendation
**Options:**
- A) Always recommend `/speckit.constitution`
- B) Detect availability and customize recommendation
- C) Don't recommend any specific command

**Decision:** B (Detect and Customize)
**Rationale:** Avoids confusion when command doesn't exist. Clear path forward in both scenarios.

### Decision 4: Documentation Link
**Options:**
- A) Link to GitHub repository
- B) Link to official docs site (if exists)
- C) No link

**Decision:** A (GitHub Repository)
**Rationale:** Most stable URL. GitHub repo is canonical source. No separate docs site currently exists.

### Decision 5: Error Message Tone
**Options:**
- A) Technical/formal: "System requirement not met"
- B) Helpful/educational: "SpecKit is a workflow framework..."
- C) Casual/friendly: "Hey! Looks like you need SpecKit first"

**Decision:** B (Helpful/Educational)
**Rationale:** Balances professionalism with approachability. Matches existing skill tone.

## Appendix: Error Message Evolution

### Version History

**v0.1.0 - v0.3.1 (Current):**
```
Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)
```

**v0.4.0 (Proposed):**
```
Prerequisites not met:
  X Not a SpecKit project (.specify/ directory not found)

    SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

    To initialize SpecKit in this project, run:

        /speckit.constitution

    Then you can use /speckit-update to keep templates up to date.
```

### Similar Error Messages in the Wild

**npm** (missing package.json):
```
npm ERR! code ENOENT
npm ERR! syscall open
npm ERR! path C:\project\package.json
npm ERR! errno -4058
npm ERR! enoent ENOENT: no such file or directory, open 'C:\project\package.json'
npm ERR! enoent This is related to npm not being able to find a file.
```
**Analysis:** Technical but unhelpful. Doesn't explain what npm is or how to create package.json.

**git** (not a git repository):
```
fatal: not a git repository (or any of the parent directories): .git
```
**Analysis:** Clear but assumes user knows Git. No guidance on how to initialize.

**SpecKit Updater Goal:**
Be more helpful than standard CLI tools while staying concise.

---

**Document Version:** 1.0.0 (Ready for Implementation)
**Last Updated:** 2025-10-22
**Status:** Ready for development
**Related Issue:** #13
**Owner:** TBD
**Stakeholders:** SpecKit updater users, first-time SpecKit users

**Change Log:**
- **v1.0.0 (2025-10-22):** Initial PRD based on issue #13 analysis
