# Claudisms Slash Commands - Quick Start Guide

## Quick Reference

```bash
/claudisms-settings                    # Show all settings
/claudisms-settings help               # Show detailed help
/claudisms-settings set <key> <value>  # Change a setting
/claudisms-settings exclude <pattern>  # Add file exclusion
/claudisms-settings include <pattern>  # Remove file exclusion
/claudisms-reload                      # Apply changes
```

## Common Workflows

### 1. View Current Settings

```bash
/claudisms-settings
```

Output:
```
Current Claudisms Settings:
============================

terse_mode           = on
doc_limits           = on
destructive_guard    = on
sequential_only      = on
excluded_files       = CLAUDE.md,claude.md
tmp_location         = pwd
debug_logging        = off
```

### 2. Allow Verbose Responses

```bash
# Disable terse mode
/claudisms-settings set terse_mode off
/claudisms-reload

# Now Claude can provide detailed explanations

# Re-enable when done
/claudisms-settings set terse_mode on
/claudisms-reload
```

### 3. Write Long Documentation

```bash
# Option A: Disable doc limits entirely
/claudisms-settings set doc_limits off
/claudisms-reload

# Write your long README.md or documentation

# Re-enable limits
/claudisms-settings set doc_limits on
/claudisms-reload

# Option B: Exclude specific files
/claudisms-settings exclude "README.md"
/claudisms-settings exclude "ARCHITECTURE.md"
/claudisms-settings set doc_limits exclude
/claudisms-reload
```

### 4. Exclude Planning Files

```bash
# Add glob pattern for all planning files
/claudisms-settings exclude "**/*PLANNING*.md"
/claudisms-settings exclude "**/*TODO*.md"
/claudisms-settings set doc_limits exclude
/claudisms-reload

# Now PLANNING.md and TODO.md files can be any length
```

### 5. Isolate Multiple Sessions

```bash
# Set temp location to pwd (working directory)
/claudisms-settings set tmp_location pwd
/claudisms-reload

# Each Claude Code session now uses its own tmp directory
# No more log file collisions between projects
```

### 6. Enable Debug Logging

```bash
/claudisms-settings set debug_logging on
/claudisms-reload

# Hooks will now write detailed debug logs
# Check ${PWD}/tmp/hook-env-*.log for details
```

## Settings Details

### terse_mode (on|off)

Controls response verbosity.

- **on** (default): 1-2 sentences max, code-first approach
- **off**: Normal verbosity, detailed explanations allowed

### doc_limits (on|off|exclude)

Controls 200-word limit on .md files.

- **on** (default): Enforce 200-word limit on all .md files
- **off**: No word limits on any files
- **exclude**: Only limit files NOT in excluded_files list

### destructive_guard (on|off|exclude)

Controls blocking of destructive operations.

- **on** (default): Block DB drops, folder deletion, production pushes
- **off**: Allow all operations (use with caution!)
- **exclude**: Allow refactoring, but still block git push to main

### sequential_only (on|off)

Controls enforcement of sequential execution.

- **on** (default): Tasks must be numbered sequentially (1, 2, 3...)
- **off**: Allow week-based or parallel planning

### tmp_location (pwd|system)

Controls where temporary files are written.

- **pwd** (default): Creates ${PWD}/tmp for session isolation
- **system**: Uses /tmp (may collide with other sessions)

### debug_logging (on|off)

Controls debug logging verbosity.

- **off** (default): Normal operation
- **on**: Write detailed debug logs to tmp directory

### excluded_files (comma-separated patterns)

List of file patterns to exclude from certain rules.

Default: `CLAUDE.md,claude.md`

Patterns support:
- Exact filename: `README.md`
- Wildcards: `*.md`, `TEST_*.txt`
- Recursive glob: `**/*PLANNING*.md`, `**/docs/*.md`

## Pattern Examples

### Exact Match
```bash
/claudisms-settings exclude "CLAUDE.md"
```
Matches: Any file ending with `CLAUDE.md`

### Wildcard
```bash
/claudisms-settings exclude "TEST_*.md"
```
Matches: `TEST_results.md`, `TEST_output.md`, etc.

### Recursive Glob
```bash
/claudisms-settings exclude "**/*PLANNING*.md"
```
Matches: `PLANNING.md`, `docs/PLANNING.md`, `project/deep/dir/MY_PLANNING_DOC.md`

### Multiple Patterns
```bash
/claudisms-settings exclude "README.md"
/claudisms-settings exclude "CHANGELOG.md"
/claudisms-settings exclude "**/*PLANNING*.md"
/claudisms-reload
```

## Troubleshooting

### Settings Not Taking Effect

Always reload after making changes:
```bash
/claudisms-reload
```

### Exclusion Not Working

Check the pattern syntax:
```bash
/claudisms-settings
# Look at excluded_files value
```

Remove incorrect pattern and re-add:
```bash
/claudisms-settings include "wrong-pattern"
/claudisms-settings exclude "correct-pattern"
/claudisms-reload
```

### Invalid Setting Error

```bash
Error: Invalid setting name: typo_mode
Valid settings: terse_mode doc_limits destructive_guard sequential_only tmp_location debug_logging excluded_files
```

Fix: Use correct setting name from the list.

### Invalid Value Error

```bash
Error: Invalid value 'maybe' for setting 'terse_mode'
Valid values: on off
```

Fix: Use a valid value from the list.

## Tips

1. **Always reload** after changing settings
2. **Use quotes** for patterns with special characters
3. **Test settings** on non-critical files first
4. **Keep defaults** unless you need different behavior
5. **Document changes** if working in a team

## Getting Help

```bash
# Built-in help
/claudisms-settings help

# View current configuration
/claudisms-settings

# Check settings file directly
cat ~/.claude/plugins/claudisms/.claudisms-settings
```

## Advanced Usage

### Batch Changes

```bash
/claudisms-settings set terse_mode off
/claudisms-settings set doc_limits off
/claudisms-settings set debug_logging on
/claudisms-reload
```

### Temporary Override

```bash
# Save current settings
/claudisms-settings > /tmp/claudisms-backup.txt

# Make temporary changes
/claudisms-settings set terse_mode off
/claudisms-reload

# Do your work...

# Restore settings manually from backup
/claudisms-settings set terse_mode on
/claudisms-reload
```

### Project-Specific Patterns

```bash
# For a documentation-heavy project
/claudisms-settings exclude "**/*.md"
/claudisms-settings set doc_limits exclude
/claudisms-reload

# For a test-heavy project
/claudisms-settings exclude "**/test_*.py"
/claudisms-settings exclude "**/TEST_*.md"
/claudisms-reload
```

## Summary

Claudisms slash commands provide powerful runtime configuration without session restarts. Use them to:

- Adjust verbosity for specific tasks
- Exclude files from word limits
- Enable debug logging
- Isolate multiple sessions
- Customize plugin behavior per project

Remember: **Always reload after changes!**
