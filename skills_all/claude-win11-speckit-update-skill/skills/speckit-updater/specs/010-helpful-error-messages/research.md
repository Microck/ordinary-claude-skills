# Research: Helpful Error Messages for Non-SpecKit Projects

**Feature**: 010-helpful-error-messages
**Date**: 2025-10-22
**Status**: Complete

## Research Questions & Decisions

### Question 1: How should we detect SpecKit command availability?

**Research Findings**:

Examined the current codebase and SpecKit documentation to understand command file structure:

1. **Command File Location**: SpecKit commands are installed in `$env:USERPROFILE\.claude\commands\` on Windows
2. **Official Command Files**: 8 official SpecKit commands with `.md` extension:
   - `speckit.constitution.md`
   - `speckit.specify.md`
   - `speckit.clarify.md`
   - `speckit.plan.md`
   - `speckit.tasks.md`
   - `speckit.implement.md`
   - `speckit.analyze.md`
   - `speckit.checklist.md`

3. **Detection Strategy Options**:
   - **Option A**: Check for all 8 commands (strict)
   - **Option B**: Check for any 1 of the 8 commands (permissive)
   - **Option C**: Check for specific subset (e.g., constitution + specify + plan as minimum viable set)

**Decision**: **Option B - Check for any 1 official SpecKit command**

**Rationale**:
- If ANY official SpecKit command exists, it indicates SpecKit skill is installed
- Partial installations should still get the "initialize project" message (more helpful than generic "install SpecKit")
- False negatives are acceptable (if someone has custom commands only, they get the "install SpecKit" message)
- False positives are unlikely (custom commands would not use `speckit.*` naming pattern)

**Implementation**:
```powershell
function Test-SpecKitCommandsAvailable {
    $claudeCommandsDir = Join-Path $env:USERPROFILE ".claude\commands"

    if (-not (Test-Path $claudeCommandsDir)) {
        return $false
    }

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

    return $false
}
```

**Alternatives Considered**:
- Checking for SpecKit skill directory (`$env:USERPROFILE\.claude\skills\speckit\`) - rejected because skill installation patterns vary
- Parsing command file contents to verify authenticity - rejected as overkill for this use case
- Checking Git remote URL for SpecKit repository - rejected as too invasive

---

### Question 2: What fallback behavior should we use if command detection fails?

**Research Findings**:

Analyzed error handling patterns in existing codebase (`Invoke-PreUpdateValidation.ps1`, `scripts/modules/GitHubApiClient.psm1`) and PowerShell best practices:

1. **Existing Pattern**: Errors are accumulated in an array and displayed together
2. **Error Stream Usage**: Critical errors use `throw` after displaying formatted output via `Write-Host`
3. **Graceful Degradation**: Non-critical checks issue warnings and allow continuation

**Failure Scenarios**:
- `$env:USERPROFILE` is not set (extremely rare, but possible in some contexts)
- `.claude\commands\` directory permissions deny read access
- Filesystem errors during path checking

**Decision**: **Use try-catch with fallback to generic helpful message**

**Rationale**:
- If detection fails, we should still show a helpful message (better than cryptic original)
- Fail-safe approach: Show both options (initialize OR install) if we can't determine state
- Aligns with existing error handling patterns in codebase
- Prevents feature from causing new error paths

**Implementation**:
```powershell
function Get-HelpfulSpecKitError {
    try {
        $hasSpecKitCommands = Test-SpecKitCommandsAvailable

        if ($hasSpecKitCommands) {
            # Variant A: Commands available
            return @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

To initialize SpecKit in this project, run:

    /speckit.constitution

Then you can use /speckit-update to keep templates up to date.
"@
        }
        else {
            # Variant B: Commands not available
            return @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

This updater requires SpecKit to be installed first.

Learn more: https://github.com/github/spec-kit
"@
        }
    }
    catch {
        # Fallback: Show both options if detection fails
        return @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

If SpecKit is already installed:
  • Run: /speckit.constitution

If SpecKit is not installed:
  • Learn more: https://github.com/github/spec-kit
"@
    }
}
```

**Alternatives Considered**:
- Throwing exception on detection failure - rejected as too harsh for informational feature
- Logging detection errors to file - rejected as adds complexity for minimal benefit
- Silently falling back to original error - rejected as defeats purpose of feature

---

### Question 3: What exact error message wording maximizes clarity?

**Research Findings**:

Analyzed error message UX best practices and reviewed the PRD's proposed messages:

**UX Principles from Research**:
1. **Lead with what happened**: Start with the factual error state
2. **Explain why it matters**: Brief context about what SpecKit is
3. **Provide actionable next steps**: Exact commands or links
4. **Use scannable formatting**: Whitespace, indentation, bullet points
5. **Keep under 10 lines**: Maintainable at-a-glance comprehension

**Comparative Analysis**:

| Aspect | Original Message | PRD Proposal | Research Recommendation |
|--------|-----------------|--------------|------------------------|
| Length | 1 line | 8-10 lines | 8-10 lines ✓ |
| Tone | Technical/terse | Helpful/educational | Helpful/educational ✓ |
| Context | None | 1 sentence | 1 sentence ✓ |
| Next steps | None | Specific command/link | Specific command/link ✓ |
| Formatting | Plain text | Indented, whitespace | Indented, whitespace ✓ |

**Decision**: **Use PRD-proposed wording with minor refinements**

**Rationale**:
- PRD messages were vetted against user stories and acceptance criteria
- One-sentence SpecKit explanation strikes right balance (not too brief, not too verbose)
- Command formatting (indented, on separate line) improves scannability
- Links provide escape hatch for users wanting more information

**Final Messages**:

**Variant A (Commands Available)**:
```
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

To initialize SpecKit in this project, run:

    /speckit.constitution

Then you can use /speckit-update to keep templates up to date.
```

**Variant B (Commands Not Available)**:
```
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

This updater requires SpecKit to be installed first.

Learn more: https://github.com/github/spec-kit
```

**Fallback (Detection Failed)**:
```
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

If SpecKit is already installed:
  • Run: /speckit.constitution

If SpecKit is not installed:
  • Learn more: https://github.com/github/spec-kit
```

**Alternatives Considered**:
- Adding emoji indicators (ℹ️, ⚠️) - rejected to maintain consistency with existing error messages
- Multi-paragraph SpecKit explanation - rejected as too verbose
- Including version numbers - rejected as adds maintenance burden
- Adding "Why am I seeing this?" FAQ section - rejected as over-complicates

---

### Question 4: How do we ensure cross-platform compatibility?

**Research Findings**:

Investigated PowerShell environment variable behavior and path handling across platforms:

**Current Project Scope**: Windows-only (PowerShell 7+ on Windows via Claude Code extension)
- Skill metadata in `SKILL.md` doesn't specify cross-platform support
- Test infrastructure uses Windows-specific paths
- Distribution instructions use Windows conventions (`$env:USERPROFILE`)

**PowerShell Path Handling**:
1. `$env:USERPROFILE` - Windows-specific (maps to user home)
2. `$env:HOME` - Cross-platform (works on Windows, macOS, Linux)
3. `Join-Path` - Cross-platform (handles forward/backslash automatically)
4. `Test-Path` - Cross-platform

**Decision**: **Use Windows-specific implementation for now, document cross-platform path for future**

**Rationale**:
- Current skill is explicitly Windows-only
- Using `$env:USERPROFILE` aligns with existing codebase conventions
- Over-engineering cross-platform support adds complexity for no current benefit
- Easy migration path if cross-platform support is added later (change `USERPROFILE` to `HOME`)

**Implementation** (Windows-specific):
```powershell
$claudeCommandsDir = Join-Path $env:USERPROFILE ".claude\commands"
```

**Future Migration Path** (if cross-platform support added):
```powershell
$userHome = if ($IsWindows) { $env:USERPROFILE } else { $env:HOME }
$claudeCommandsDir = Join-Path $userHome ".claude/commands"
```

**Alternatives Considered**:
- Implementing cross-platform support immediately - rejected as YAGNI (You Aren't Gonna Need It)
- Using `~/.claude/commands` string literal - rejected as less explicit than environment variable
- Detecting platform and choosing variable dynamically - rejected as unnecessary for current scope

---

## Key Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Detection Method** | Check for any 1 of 3 core SpecKit commands | Balances permissiveness with accuracy |
| **Fallback Strategy** | Try-catch with generic helpful message | Fail-safe, never worse than original error |
| **Message Wording** | Use PRD-proposed messages with minor tweaks | Vetted against user acceptance criteria |
| **Platform Support** | Windows-specific (`$env:USERPROFILE`) | Aligns with current skill scope |
| **Error Formatting** | Multi-line here-strings with indentation | Matches existing error message patterns |
| **Function Names** | `Get-HelpfulSpecKitError`, `Test-SpecKitCommandsAvailable` | Follows PowerShell verb-noun conventions |
| **Integration Point** | Modify line 47 in `Invoke-PreUpdateValidation.ps1` | Minimal invasiveness, clear separation of concerns |

---

## Open Questions Resolved

All research questions have been resolved. No blocking uncertainties remain.

**Phase 0 Status**: ✅ COMPLETE

**Ready for Phase 1**: Design artifacts (quickstart.md) can now be generated with full context.
