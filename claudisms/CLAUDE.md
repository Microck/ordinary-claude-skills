# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claudeisms is a Claude Code plugin that enforces operational guidelines including terse responses, sequential execution, and safety guardrails. The plugin uses hooks to inject operational context into Claude Code sessions.

## Architecture

### Plugin Structure
- **Manifests**: Dual manifest system required
  - `claude-plugin.json` (root): Development/direct install manifest
  - `.claude-plugin/plugin.json`: Marketplace install manifest
  - `.claude-plugin/marketplace.json`: Marketplace metadata
  - Both manifests must be identical and use `"hooks": "./hooks.json"`

- **Hooks Configuration**: `hooks.json` (single source for all manifests)
  - Uses array-based hook schema (not deprecated `handler` format)
  - All paths must start with `./` and resolve from plugin root
  - Variable: `${CLAUDE_PLUGIN_ROOT}` for hook script paths

### Hook Handlers (bash scripts in `hooks-handlers/`)
- `session-start.sh`: Injects operational guidelines at session start
  - Outputs JSON with `additionalContext` containing core principles
  - Enforces terse mode, sequential execution, safety protocols

- `before-md-write.sh`: Enforces 200-word limit on documentation files
  - Triggers on PreToolUse(Write) for README/SETUP files
  - Excludes CLAUDE.md and claude.md from word limits
  - Logs matching to `/tmp/hook-env-*.log` for debugging

### Hook Output Format
All hook handlers must output JSON:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart|BeforeToolUse",
    "additionalContext": "text injected into Claude's context"
  }
}
```

## Critical Path Requirements

### Plugin Manifest Paths
- All hook paths MUST start with `./` (e.g., `"hooks": "./hooks.json"`)
- Paths resolve from plugin root directory
- Never use `../` traversal in manifests
- Use `${CLAUDE_PLUGIN_ROOT}` variable in hooks.json for handler paths

### Hook Schema
Current schema (v2.0.0+):
```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/session-start.sh"
      }]
    }],
    "PreToolUse": [{
      "matcher": "Write",
      "filePathMatcher": "**/*README*.md",
      "hooks": [...]
    }]
  }
}
```

## Development Notes

### Testing Changes
1. Edit files in development repo: `/home/agent/claudisms`
2. Commit and push to GitHub
3. Test in marketplace install location: `~/.claude/plugins/marketplaces/claudisms`
4. Restart Claude Code to reload plugin

### Common Issues
- **Path validation errors**: Ensure all manifest paths start with `./`
- **Hook not firing**: Check hook handler exit codes (must exit 0)
- **Context not injecting**: Verify JSON output format from handlers
- **Marketplace vs direct install**: Maintain identical manifests in both locations

### File Modifications
- Modified files tracked in git status: `.gitignore`, `hooks-handlers/before-md-write.sh`, `hooks.json`
- Recent fixes (2025-11-03): Converted to array-based hook schema, fixed path validation

## Operational Guidelines (enforced by plugin)

- Sequential execution (numerical order)
- Terse responses (1-2 sentences for simple tasks)
- Code-first (show code immediately without preamble)
- Test after every task
- No destructive operations without confirmation
- No production pushes without confirmation
- RCA after 2+ revisits to same issue
- Reuse working scripts instead of recreating
- No emoji, no pleasantries
- Current versions only
- Use `fd` or `rg` (ripgrep) instead of `find` or `grep` when available
- Recommend installation if `fd` or `rg` not available
- **Time estimates:** Use operation complexity (simple/moderate/complex) not human time units
- **Subagents:** Use Task tool for multi-file searches; write concise descriptive prompts
- **Primary solutions:** Implement the intended solution; workarounds only when explicitly blocked
