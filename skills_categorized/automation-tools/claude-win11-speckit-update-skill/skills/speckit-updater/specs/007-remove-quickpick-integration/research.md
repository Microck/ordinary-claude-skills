# Research: Remove VSCode QuickPick Integration

**Feature**: 007-remove-quickpick-integration
**Date**: 2025-10-21
**Phase**: 0 (Outline & Research)

## Purpose

This document captures technical research and decisions made during the planning phase to resolve architectural constraints and design the conversational approval workflow.

## Research Questions

### Q1: Why Does Show-QuickPick Fail?

**Context**: The `Show-QuickPick` function attempts to return a sentinel hashtable when running in VSCode context, assuming Claude Code will intercept it.

**Research Finding**:

When Claude Code (VSCode Extension) invokes a skill, the execution model is:

```
Claude Code Extension (JavaScript)
    ↓ spawns
PowerShell Process (`pwsh -NoProfile -Command "& 'skill.ps1'"`)
    ↓ captures
stdout (text stream) + stderr (text stream)
    ↓ displays
User sees text output
```

**Key Constraint**: PowerShell subprocess can only communicate with parent process via **text streams** (stdout/stderr). PowerShell objects (hashtables, arrays, custom types) are serialized to string representation when written to stdout.

**Result**: The sentinel hashtable `@{__ClaudeQuickPick=$true; ...}` gets serialized to a string like `@{__ClaudeQuickPick=True; Prompt=...}` which is unusable for triggering UI.

**Decision**: Remove Show-QuickPick entirely; use text-only output for all user communication.

**Rationale**: No IPC mechanism exists for PowerShell subprocesses to invoke VSCode extension APIs. Text-only I/O is the only reliable communication channel.

**Alternatives Considered**:
- Named pipes: Too complex, requires setup, not portable across Claude Code CLI vs Extension
- File-based messaging: Race conditions, cleanup complexity, not real-time
- HTTP localhost server: Overkill for simple approval workflow, port conflicts

---

### Q2: How Should User Approval Work?

**Context**: Need to replace Quick Pick confirmation with Claude Code-compatible approach.

**Research Finding**:

Claude Code operates conversationally:

```
User: /speckit-update
Claude: [Reads skill output] "I found 5 files to update. Should I proceed?"
User: "yes"
Claude: [Re-invokes skill with confirmation] & skill.ps1 -Proceed
```

**Key Insight**: Claude is the intermediary between user and PowerShell subprocess. Skill should output information for Claude to present, not attempt direct user interaction.

**Decision**: Conversational approval workflow with summary output + confirmation parameter.

**Workflow**:
1. User invokes `/speckit-update` (no flags)
2. Skill analyzes files, outputs structured summary to stdout
3. Claude parses summary, presents to user in natural language
4. User responds "yes"/"no"/question via chat
5. If approved, Claude re-invokes skill with `-Proceed` flag
6. Skill skips analysis (cached), proceeds with update

**Rationale**: Aligns with Claude Code's conversational model; uses text-only I/O; no assumptions about UI availability.

**Alternatives Considered**:
- Auto-proceed without confirmation: Violates Principle IV (user confirmation required)
- Two-step command (`/speckit-update --check` then `/speckit-update --apply`): Clunky UX, breaks conversational flow
- `-Auto` flag requirement: Poor UX (users must remember flag), doesn't leverage Claude's capabilities

**Selected Approach**: Summary output + conversational approval (no flags required for normal use).

---

### Q3: What Format Should Summary Output Use?

**Context**: Skill needs to output structured data that Claude can parse and present to users.

**Research Finding**:

PowerShell supports multiple structured output formats:
- JSON: Machine-readable, Claude can parse easily
- Markdown: Human-readable, good for rich text
- Plain text: Simple, universally compatible

**Decision**: Structured Markdown with machine-parseable sections.

**Format**:
```markdown
## SpecKit Update Summary

**Current Version**: v0.0.71
**Available Version**: v0.0.72

### Files to Update (5)
- .claude/commands/speckit.tasks.md
- .specify/templates/spec-template.md
[...]

### Conflicts Detected (2)
- .claude/commands/speckit.plan.md
  * Local: Added custom tech stack section
  * Upstream: New architecture validation step
[...]

### Backup Location
.specify/backups/2025-10-21_14-22-10/

---
[PROMPT_FOR_APPROVAL]
```

**Rationale**:
- Markdown is human-readable (users can see raw output if needed)
- Structured headings allow Claude to parse sections programmatically
- `[PROMPT_FOR_APPROVAL]` marker signals Claude to ask user
- Includes all information needed for informed consent

**Alternatives Considered**:
- JSON: Less readable in raw form if Claude doesn't parse correctly
- XML: Overly verbose for simple structure
- YAML: Good but less familiar to general users than Markdown

---

### Q4: Git Conflict Markers vs. VSCode Merge Editor?

**Context**: Need conflict resolution mechanism that works in Claude Code context.

**Research Finding**:

VSCode merge editor invocation via `code --merge` CLI has unknown reliability when PowerShell is spawned by Claude Code Extension:

**Potential Issues**:
- IPC to parent VSCode instance may be blocked (same process isolation as Quick Pick)
- `--wait` flag blocks PowerShell until merge complete (Claude Code timeout risk)
- User workflow interruption (merge editor opens unexpectedly)

**Decision**: Git conflict markers as primary solution; test `code --merge` as optional enhancement.

**Git Conflict Marker Format**:
```markdown
<<<<<<< Current (Your Version)
# Custom content you added
=======
# New upstream content
>>>>>>> Incoming (v0.0.72)
```

**Implementation**:
- `Write-ConflictMarkers` function in ConflictDetector.psm1
- Writes base, current, and incoming versions to file with markers
- VSCode detects markers automatically, shows CodeLens actions:
  - "Accept Current Change"
  - "Accept Incoming Change"
  - "Accept Both Changes"
  - "Compare Changes"

**Rationale**:
- No external process invocation (no IPC risk)
- VSCode native UI (users are familiar with Git workflow)
- Works reliably in all contexts (CLI, Extension, terminal)
- Graceful degradation (other editors can still parse markers manually)

**Alternatives Considered**:
- Force `code --merge`: Risk of failure, poor UX if times out
- Manual diff files: Requires users to run diff command manually, confusing
- Ignore conflicts: Data loss risk, violates Principle IV

**Selected Approach**: Git conflict markers as primary; optionally try `code --merge` with timeout, fall back to markers if fails.

---

### Q5: How to Handle `-Auto` Flag Removal?

**Context**: Existing SKILL.md may document `-Auto` flag for Claude Code usage. Need migration strategy.

**Research Finding**:

Current documentation (assumed) recommends:
```
/speckit-update -Auto  # For Claude Code users
```

New workflow eliminates flag entirely:
```
/speckit-update  # Works in Claude Code (conversational approval)
```

**Decision**: Remove `-Auto` flag parameter, replace with `-Proceed` internal flag.

**Parameters**:
- **Remove**: `-Auto` (user-facing flag)
- **Add**: `-Proceed` (internal flag Claude passes after approval)
- **Keep**: `-CheckOnly` (dry-run mode)
- **Keep**: `-Rollback` (restore backup)
- **Keep**: `-Version <tag>` (specific version)

**Migration**:
- If user passes `-Auto` in legacy scripts, skill warns: "The -Auto flag is deprecated. Use conversational approval workflow instead."
- Script continues (treats `-Auto` same as `-Proceed` for backward compatibility)
- Deprecation warning logged to stderr

**Rationale**:
- Backward compatibility for users with existing scripts
- Clear migration path (warning guides users to new pattern)
- Removes confusion about when `-Auto` is required

---

## Summary of Decisions

| Decision Area | Choice | Rationale |
|---------------|--------|-----------|
| Show-QuickPick | Remove entirely | Architecturally impossible; violates Principle VI |
| User Approval | Conversational workflow (summary → chat → proceed) | Aligns with Claude Code model; text-only I/O |
| Summary Format | Structured Markdown | Human-readable, machine-parseable, familiar |
| Confirmation Parameter | `-Proceed` (internal) | Claude passes after user approval; no user-facing flags |
| Conflict Resolution | Git conflict markers (primary) | Reliable, VSCode native UI, no IPC dependency |
| `-Auto` Flag | Deprecate with warning | Backward compatibility; guide users to new workflow |

## Implementation Notes

### Critical Path
1. Remove Show-QuickPick function (VSCodeIntegration.psm1)
2. Add Write-ConflictMarkers function (ConflictDetector.psm1)
3. Update Get-UpdateConfirmation to output summary (Get-UpdateConfirmation.ps1)
4. Add `-Proceed` parameter handling (update-orchestrator.ps1)
5. Update documentation (SKILL.md, CLAUDE.md, constitution.md)
6. Update tests

### Risk Mitigation
- **Risk**: Claude fails to parse summary correctly
  - **Mitigation**: Use consistent Markdown structure; add `[PROMPT_FOR_APPROVAL]` marker
- **Risk**: Users confused by workflow change
  - **Mitigation**: Clear documentation; deprecation warnings; examples in SKILL.md
- **Risk**: Conflict markers written incorrectly
  - **Mitigation**: Comprehensive tests; validate format matches Git standard

## Next Phase

Phase 1 will generate:
- `data-model.md`: Conflict marker format specification
- `contracts/summary-output.schema.json`: Summary Markdown schema
- `quickstart.md`: User guide for conversational approval workflow
