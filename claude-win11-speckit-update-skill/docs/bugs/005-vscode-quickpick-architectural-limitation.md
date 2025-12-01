# Bug Report: VSCode Quick Pick Integration Does Not Work - Architectural Limitation

**Issue:** #10
**Status:** OPEN
**Reporter:** Bobby Johnson (@NotMyself)
**Created:** 2025-10-21T00:56:14Z
**Severity:** Medium (workaround available via `-Auto` flag)

## Summary

The `Show-QuickPick` function in `VSCodeIntegration.psm1` attempts to display VSCode Quick Pick UI by returning a sentinel hashtable when running in VSCode context. This approach fundamentally cannot work because Claude Code executes PowerShell skills via `pwsh -Command` and only captures text output streams (stdout/stderr). There is no mechanism for PowerShell scripts to invoke VSCode UI elements or pass structured data back to the extension.

## Environment

- **OS:** Windows 11
- **PowerShell Version:** 7.x (pwsh.exe)
- **Skill Version:** v0.1.5
- **Execution Context:** Invoked via `/speckit-update` skill in Claude Code
- **Affected Component:** `scripts/modules/VSCodeIntegration.psm1` (lines 55-143)

## Root Cause

### The Flawed Assumption

The `Show-QuickPick` function returns a sentinel hashtable when detecting VSCode context:

```powershell
if ($context -eq 'vscode-extension' -or $context -eq 'vscode-terminal') {
    # In VSCode context: return sentinel hashtable for Claude orchestration
    # Claude Code extension will intercept this and show native Quick Pick
    return @{
        __ClaudeQuickPick = $true
        Prompt = $Prompt
        Options = $Options
        MultiSelect = $MultiSelect.IsPresent
    }
}
```

**This assumes Claude Code will:**
1. Parse PowerShell object output (it doesn't - only text streams)
2. Intercept special hashtables (no such interception exists)
3. Show native VSCode Quick Pick (no integration for this exists)

### The Reality

When Claude Code invokes a skill:

1. **Execution:** `pwsh -NoProfile -Command "& '{skill_path}/scripts/update-wrapper.ps1' [parameters]"`
2. **Output Capture:** Captures stdout/stderr as **text only**
3. **Display:** Renders captured text to user
4. **No UI Integration:** PowerShell scripts cannot trigger VSCode UI elements

**Result:** The sentinel hashtable gets serialized to text output like `@{__ClaudeQuickPick=True; Prompt=...}`, which is unusable for triggering UI.

## Impact

### User-Facing Issues

When `Show-QuickPick` is called in VSCode context:
- Returns hashtable object instead of user selection
- Interactive confirmation prompts fail
- Users see: `"The update was cancelled because the interactive confirmation prompt cannot be displayed"`
- Forces users to run skill manually or with `-Auto` flag

### Affected Functions

- **`Show-QuickPick`** (VSCodeIntegration.psm1, lines 55-143) - Core broken functionality
- **`Get-UpdateConfirmation.ps1`** (scripts/helpers/, lines 113-126) - Calls `Show-QuickPick`
- Any future code that attempts interactive prompts in Claude Code context

## Current Workaround

**Version v0.1.5** added the `-Auto` flag to bypass interactive prompts:

```powershell
/speckit-update -Auto
```

- Automatically proceeds without user confirmation
- **Recommended approach** for Claude Code invocation
- Documented in SKILL.md

### Limitations of Workaround

- Removes user control over which changes to apply
- No opportunity to review changes before proceeding
- Not ideal for cautious users who want to preview updates

## Attempted Solution (Why It Failed)

The original implementation attempted to bridge PowerShell and VSCode using a sentinel pattern:

1. Detect VSCode context via environment variables
2. Return special hashtable instead of prompting
3. Assume Claude Code extension would parse and handle it

**Why this cannot work:**
- PowerShell → Claude Code communication is **one-way text streams only**
- No extension API exists for PowerShell scripts to invoke VSCode UI
- Structured data (objects, hashtables) gets serialized to strings
- No parsing mechanism exists in Claude Code to detect sentinel patterns

## Potential Solutions

### Option 1: Remove Quick Pick Functionality (Recommended)

**Approach:** Accept architectural limitation and simplify codebase.

**Changes Required:**
- ✅ Delete `Show-QuickPick` function from VSCodeIntegration.psm1 (lines 55-143)
- ✅ Remove all calls to `Show-QuickPick` in Get-UpdateConfirmation.ps1 (lines 113-126)
- ✅ Document that `-Auto` flag is required for Claude Code invocation
- ✅ Keep `Read-Host` fallback for terminal use (when not using `-Auto`)
- ✅ Add warning if running without `-Auto` in non-terminal context

**Rationale:**
- Eliminates non-functional code
- Reduces maintenance burden
- Makes architectural limitations explicit
- Simplifies codebase

**Risk:** Low - function doesn't work anyway

### Option 2: Output Text-Based Instructions for Claude

**Approach:** Output structured text that Claude Code could potentially parse.

**Example:**
```powershell
Write-Host "CLAUDE_PROMPT: Do you want to proceed? (yes/no)"
Write-Host "CLAUDE_OPTIONS: yes,no"
```

**Requires:**
- Claude Code extension support (doesn't exist yet)
- Standardized prompt format specification
- Changes to how Claude Code processes skill output
- Claude AI model parsing text prompts and responding

**Rationale:** Future-proofing if Claude Code adds prompt interception

**Risk:** High - requires external changes, uncertain timeline

### Option 3: Wait for MCP Server Integration

**Approach:** Wait for Model Context Protocol (MCP) server support in Claude Code skills.

**Requires:**
- Claude Code adding MCP server support for skills
- Skills exposing prompt capabilities via MCP protocol
- Significant architectural changes to skill structure

**Rationale:** Proper client-server communication for UI interactions

**Risk:** Very high - requires major architectural changes, uncertain if/when available

### Option 4: Document as Limitation (Minimal Approach)

**Approach:** Keep code as-is, document that it doesn't work.

**Changes:**
- Update SKILL.md to clearly state interactive prompts don't work
- Require `-Auto` flag for all Claude Code usage
- Add code comments explaining limitation
- No code changes to VSCodeIntegration.psm1

**Rationale:** Minimal effort, preserves code for potential future use

**Risk:** Medium - confusing code that doesn't work, maintenance burden

## Recommendation

**Implement Option 1 + Option 4 (hybrid approach):**

1. **Remove broken functionality:**
   - Delete `Show-QuickPick` function entirely
   - Remove calls to `Show-QuickPick` from helper scripts
   - Clean up related test code

2. **Enhance documentation:**
   - Update SKILL.md to document `-Auto` as required for Claude Code
   - Add architectural limitations section to CLAUDE.md
   - Document that interactive prompts only work in direct terminal invocation

3. **Improve user experience:**
   - Add runtime warning if not using `-Auto` in VSCode context
   - Provide clear error message explaining to use `-Auto` flag
   - Keep `Read-Host` for direct terminal invocation

4. **Update constitution:**
   - Add principle prohibiting VSCode UI integration attempts
   - Document that skills can only use text-based I/O

## Files Requiring Changes

### Code Modifications

- **scripts/modules/VSCodeIntegration.psm1**
  - Lines 55-143: Delete `Show-QuickPick` function
  - Update `Export-ModuleMember` to remove function (line 144)
  - Keep `Get-VSCodeContext` (lines 8-53) - still useful for detection

- **scripts/helpers/Get-UpdateConfirmation.ps1**
  - Lines 113-126: Remove `Show-QuickPick` call
  - Replace with direct `Read-Host` or return early if `-Auto` is set
  - Add warning if in VSCode without `-Auto`

- **scripts/update-orchestrator.ps1**
  - Add validation: if VSCode context detected and `-Auto` not set, show error
  - Suggest using `-Auto` flag in error message

### Documentation Updates

- **SKILL.md**
  - Document `-Auto` flag as required for Claude Code invocation
  - Add examples showing usage with `-Auto`
  - Explain interactive prompts only work in terminal

- **CLAUDE.md**
  - Add "Architectural Limitations" section
  - Document VSCode UI integration impossibility
  - Explain PowerShell → Claude Code communication constraints

- **.specify/memory/constitution.md**
  - Add principle: "Skills MUST NOT attempt to invoke VSCode UI elements"
  - Add principle: "Skills communicate via text streams only (stdout/stderr)"

### Testing Updates

- **tests/unit/VSCodeIntegration.Tests.ps1**
  - Remove tests for `Show-QuickPick` function
  - Keep tests for `Get-VSCodeContext` (still needed)

- **tests/integration/UpdateOrchestrator.Tests.ps1**
  - Add test: verify error shown if VSCode context without `-Auto`
  - Add test: verify `-Auto` bypasses prompts successfully

## Testing Plan

### Before Changes

1. Verify `Show-QuickPick` is indeed broken:
   ```powershell
   Import-Module .\scripts\modules\VSCodeIntegration.psm1 -Force
   $result = Show-QuickPick -Prompt "Test" -Options @("A", "B")
   $result.GetType().Name  # Should be "Hashtable" not "String"
   ```

2. Confirm broken behavior in skill:
   ```powershell
   /speckit-update  # Should fail with confirmation prompt error
   ```

### After Changes

1. Verify function removed:
   ```powershell
   Import-Module .\scripts\modules\VSCodeIntegration.psm1 -Force
   Get-Command Show-QuickPick -ErrorAction SilentlyContinue  # Should return nothing
   ```

2. Verify `-Auto` works:
   ```powershell
   /speckit-update -Auto  # Should complete without prompts
   ```

3. Verify error shown without `-Auto` in VSCode:
   ```powershell
   /speckit-update  # Should show clear error about using -Auto flag
   ```

4. Verify terminal mode still works:
   ```powershell
   pwsh -Command "& '.\scripts\update-orchestrator.ps1' -CheckOnly"  # Should use Read-Host
   ```

### Success Criteria

- ✅ No broken code attempting VSCode UI integration
- ✅ Clear documentation of architectural limitations
- ✅ Helpful error messages guide users to `-Auto` flag
- ✅ Terminal invocation still supports interactive prompts
- ✅ All tests pass after cleanup

## Related Issues

- **Issue #1** - Export-ModuleMember fatal error (resolved)
- **Issue #4** - Module functions not available (resolved)
- **Issue #6** - Missing SpecKitVersion parameter (resolved)
- **Issue #8** - New-SpecKitManifest parameter issue (resolved)

## Related Documentation

- [VSCode Integration Module](../../scripts/modules/VSCodeIntegration.psm1)
- [Get Update Confirmation Helper](../../scripts/helpers/Get-UpdateConfirmation.ps1)
- [Update Orchestrator](../../scripts/update-orchestrator.ps1)
- [Skill Definition](../../SKILL.md)
- [Project Instructions](../../CLAUDE.md)
- [Constitution](./../.specify/memory/constitution.md)

## Timeline

- **2025-10-21:** Issue discovered and reported
- **v0.1.5:** `-Auto` flag added as workaround
- **Status:** Awaiting decision on permanent solution

## Priority

**Medium:** Workaround is available (`-Auto` flag), but codebase contains broken functionality that should be removed or fixed properly to avoid confusion and maintenance burden.

## Notes

This is a **fundamental architectural limitation** of how Claude Code executes skills, not a bug in the skill implementation. PowerShell scripts cannot invoke VSCode UI elements because:

1. Skills run in separate `pwsh` processes spawned by Claude Code
2. Communication is limited to text streams (stdout/stderr)
3. No API exists for PowerShell to call VSCode extension functions
4. Object serialization converts hashtables to strings

**The correct long-term solution requires changes to Claude Code architecture** (e.g., MCP server support), not skill code changes. In the meantime, removing broken code and documenting limitations is the pragmatic approach.
