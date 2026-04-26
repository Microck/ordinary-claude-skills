# List of Claudeisms

Line-by-line operational guidelines enforced by this plugin.

## Core Execution Principles

1. **Sequential execution only** - Use numerical task ordering (Task 1, 2, 3), never week-based planning or parallel phases
2. **Terse responses** - 1-2 sentences maximum for simple tasks; eliminate preamble and pleasantries
3. **Code-first** - Show code immediately without "I'll now..." or "Let me..." introductions
4. **Test after every task** - Run verification after each change before proceeding
5. **No destructive ops without confirmation** - Block `rm -rf`, `DROP TABLE`, `DELETE FROM`, `TRUNCATE`, database/folder deletion
6. **No production pushes without confirmation** - Require explicit approval for `git push` to main/production branches
7. **Current versions only** - Never specify outdated package versions or deprecated patterns
8. **Ask for clarification when irrational** - Question unclear requirements instead of guessing
9. **Never blame user** - Frame issues as "unexpected behavior" not "you did X wrong"
10. **RCA after 2+ revisits** - Perform root cause analysis if returning to same issue multiple times
11. **Reuse scripts, don't recreate** - Reference and run existing working scripts instead of rewriting
12. **Prefer fd/rg over find/grep** - Use modern tools (fd for files, ripgrep for content) when available
13. **Recommend fd/rg installation** - Suggest installing if not available instead of silently using legacy tools
14. **Implement primary solution** - Try harder to implement intended solution; workarounds only when explicitly blocked

## Response Format

15. **Single sentence for simple tasks** - "Fixed typo in config.yaml:12" not "I've successfully fixed the typo..."
16. **Code without preamble** - Show code block directly, skip "Here's the code:" or "I'll write..."
17. **path:line for references** - Use `src/app.ts:45` format when referencing code locations
18. **Error: problem + fix in <10 words** - "Syntax error line 23: missing semicolon" not paragraphs

## Elaboration Rules

19. **Elaborate only when user asks "why" or "how"** - Provide detail when explicitly requested
20. **Elaborate when user says "explain" or "details"** - Expand explanations on demand
21. **Elaborate for architecture decisions** - Discuss trade-offs when design choices need user input
22. **Elaborate for security/data loss warnings** - Always explain risks before destructive operations

## Subagent Usage Guidelines

23. **Use Task tool with subagent_type=Explore for codebase questions** - "How does X work?" requires exploration
24. **Use Task tool for multi-file searches (>3 files)** - Avoid manual grep/glob loops
25. **Use Task tool for ambiguous queries** - "Where is error handling?" needs systematic search
26. **Use Task tool for architecture understanding** - System design questions require thorough exploration
27. **Format subagent descriptions: Action + Scope + Expected Output** - Clear, structured prompts
28. **Include thoroughness level** - Specify "quick", "medium", or "very thorough"
29. **Specify output format** - "Return file paths and line numbers" not vague expectations
30. **Good example: "Search codebase for authentication flows..."** - Complete, specific description
31. **Bad example: "Find auth stuff"** - Vague, incomplete, missing scope

## Never Do

32. **Never repeat user's words** - Skip "You mentioned...", "As you said...", "You're right that..."
33. **Never confirm understanding** - Skip "I understand you want...", start doing the task
34. **Never blame user for issues** - Frame as system behavior not user error
35. **Never say "production ready" or "100% done"** - Use "tests passing" or "requirements met"
36. **Never run long queries on large tables** - Warn before SELECT without LIMIT on production data
37. **Never delete DB/folders without confirmation** - Always require explicit approval
38. **Never use find/grep if fd/rg available** - Prefer modern, faster alternatives

## Documentation Limits

39. **README/SETUP files: 200 words maximum** - Enforced by PreToolUse(Write) hook unless `doc_limits=off`
40. **CLAUDE.md exempt from limits** - Project guidance files excluded from word count
41. **Exclude pattern support** - Use `excluded_files` setting for custom exemptions

## Settings Management

42. **terse_mode=on** - Enforce 1-2 sentence responses and code-first output
43. **terse_mode=off** - Allow normal verbosity (disables session-start context injection)
44. **doc_limits=on** - Apply 200-word limit to all README/SETUP files
45. **doc_limits=off** - Disable documentation length enforcement
46. **doc_limits=exclude** - Apply limits except to files matching `excluded_files` patterns
47. **destructive_guard=on** - Block destructive bash/SQL commands, require user approval
48. **destructive_guard=off** - Disable destructive operation protection
49. **destructive_guard=exclude** - Use pattern matching for selective protection
50. **sequential_only=on** - Enforce numerical task ordering, no week-based planning
51. **sequential_only=off** - Allow flexible planning approaches
52. **tmp_location=pwd** - Create `${PWD}/tmp` for session-isolated logs
53. **tmp_location=system** - Use `/tmp` for shared logs across sessions
54. **debug_logging=on** - Enable hook execution logs to `${tmp_location}/hook-env-*.log`
55. **debug_logging=off** - Disable debug logging for cleaner tmp directory
56. **excluded_files patterns** - Comma-separated glob patterns bypass `doc_limits` hook

## Time Estimation

57. **Use operation complexity not human time** - Say "simple", "moderate", "complex" not "5 minutes", "1 hour"
58. **Avoid human time units** - No minutes/hours/days for estimating development tasks

## Hook Behavior

59. **SessionStart hook injects operational context** - Loads guidelines at session start
60. **PreToolUse(Write) hook enforces doc limits** - Checks README/SETUP files before write
61. **PreToolUse(Bash) hook blocks destructive commands** - Matches `rm -rf`, SQL DROP/DELETE/TRUNCATE, `git push`
62. **Hooks read settings from .claudisms-settings** - Key=value format, loaded via lib/settings-loader.sh
63. **Hooks respect excluded_files patterns** - Fine-grained control over when rules apply

## File Exclusion Patterns

64. **Exact match: CLAUDE.md** - Matches files ending with CLAUDE.md
65. **Wildcards: *.md** - Matches any .md file in current directory
66. **Recursive glob: \*\*/\*PLANNING\*.md** - Matches PLANNING.md files in any subdirectory

## Installation & Maintenance

67. **Prefer marketplace install over manual** - Use `/plugin` command, add `jeffersonwarrior/claudisms`
68. **Active hooks read from marketplace location** - `~/.claude/plugins/marketplaces/claudisms/`
69. **Slash commands auto-detect marketplace** - Prioritize installed location over dev repo
70. **Changes require `/claudisms-reload`** - Or restart Claude Code to reload settings
71. **Enable in settings.json** - `"enabledPlugins": {"claudeisms@claudisms": true}`
72. **Uninstaller cleans all configuration** - Use `claude-plugin-uninstall.sh` for complete removal

## Troubleshooting

73. **Settings not applying: check file location** - Verify `~/.claude/plugins/marketplaces/claudisms/.claudisms-settings`
74. **Settings not applying: run reload** - Execute `/claudisms-reload` after manual edits
75. **Settings not applying: enable debug** - Set `debug_logging=on` to diagnose hook execution
76. **Settings not applying: check logs** - Review `${PWD}/tmp/hook-env-*.log` for errors
77. **Marketplace naming: use jeffersonwarrior/claudisms** - Plugin name is `claudeisms`, marketplace is `claudisms`
78. **Manifest paths must start with ./** - All plugin.json paths resolve from plugin root
79. **Hooks must output valid JSON** - Use `hookSpecificOutput` with `additionalContext` field
80. **Hooks must exit 0** - Non-zero exit codes prevent context injection

## Architecture Requirements

81. **Dual manifest system required** - `claude-plugin.json` (root) and `.claude-plugin/plugin.json` (marketplace)
82. **Both manifests must be identical** - Use same hooks reference and commands array
83. **Hooks reference: ./hooks.json** - Single source for all hook configurations
84. **Array-based hook schema** - Use `hooks: [{type, command}]` not deprecated `handler` format
85. **Variable: ${CLAUDE_PLUGIN_ROOT}** - Use for hook script paths in hooks.json
86. **Commands array: .md file paths** - Use `["./commands/foo.md"]` not object schema
87. **Hook output: JSON with additionalContext** - Required format for context injection
88. **Settings loader: lib/settings-loader.sh** - Shared library for get_setting(), get_tmp_location()
89. **File matcher: lib/file-matcher.sh** - Pattern matching for excluded_files support
90. **Write policies: lib/write-policies.sh** - Documentation limit enforcement logic
