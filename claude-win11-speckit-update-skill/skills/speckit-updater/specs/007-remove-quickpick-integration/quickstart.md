# Quickstart: Conversational Update Workflow

**Feature**: 007-remove-quickpick-integration
**Date**: 2025-10-21
**Audience**: End users of SpecKit Safe Update Skill

## Overview

This guide explains the new conversational approval workflow for SpecKit updates, which replaces the previous `-Auto` flag requirement with a natural, chat-based confirmation process.

## What Changed?

### Before (v0.1.5 and earlier)

```
User: /speckit-update
Skill: ❌ Error: Interactive prompts not supported in Claude Code.
       Please use: /speckit-update -Auto

User: /speckit-update -Auto
Skill: ✅ Updating... (no preview, immediate execution)
```

**Problem**: Required memorizing a flag, no opportunity to review changes before proceeding.

### After (v0.2.0 and later)

```
User: /speckit-update
Skill: [Displays summary of proposed changes]

Claude: "I found 5 files to update and 1 conflict. Should I proceed?"

User: "yes"
Claude: [Re-invokes skill with approval, updates proceed]
```

**Benefit**: Natural conversation, preview before action, no flags required.

---

## Basic Workflow

### Step 1: Invoke Update

Simply type the command without any flags:

```
/speckit-update
```

### Step 2: Review Summary

The skill analyzes your project and outputs a summary like:

```markdown
## SpecKit Update Summary

**Current Version**: v0.0.71
**Available Version**: v0.0.72

### Files to Update (3)
- .claude/commands/speckit.tasks.md
- .specify/templates/spec-template.md
- .specify/scripts/powershell/create-new-feature.ps1

### Conflicts Detected (1)
- .claude/commands/speckit.plan.md
  * Local: Added custom tech stack review section
  * Upstream: New architecture validation step added

### Backup Location
.specify/backups/2025-10-21_14-22-10/

### Custom Commands (1)
- .claude/commands/custom-deploy.md (preserved)
```

### Step 3: Respond to Claude

Claude interprets the summary and asks for your approval. You can respond with:

**Approve**:
- "yes"
- "proceed"
- "go ahead"
- "update"

**Decline**:
- "no"
- "cancel"
- "not now"

**Ask Questions**:
- "What changes are in the new plan template?"
- "Will this affect my custom command?"
- "Can you explain the conflict?"

### Step 4: Skill Proceeds

If you approved, Claude re-invokes the skill with confirmation, and the update runs:

```
Updating 3 files...
Writing conflict markers for 1 file...
Backup saved to .specify/backups/2025-10-21_14-22-10/

✅ Update complete!
```

---

## Handling Conflicts

When the summary shows conflicts, the skill writes Git-style conflict markers to affected files. VSCode automatically detects these and shows resolution UI.

### Example Conflict Scenario

**Summary shows**:
```
### Conflicts Detected (1)
- .claude/commands/speckit.plan.md
  * Local: Added custom tech stack review section
  * Upstream: New architecture validation step added
```

**After update, file contains**:
```markdown
## Technical Context
[standard content]

<<<<<<< Current (Your Version)
## Custom Tech Stack Review
- Database choice: PostgreSQL vs MongoDB
- Frontend framework: React vs Vue
||||||| Base (v0.0.71)
[this section did not exist]
=======
## Architecture Validation
- Review against SOLID principles
- Identify coupling points
>>>>>>> Incoming (v0.0.72)

## Constitution Check
[continues...]
```

### Resolving in VSCode

1. Open the file (`.claude/commands/speckit.plan.md`)
2. VSCode shows CodeLens actions above the conflict:
   - **Accept Current Change** - Keep your version
   - **Accept Incoming Change** - Use new upstream version
   - **Accept Both Changes** - Merge both sections
   - **Compare Changes** - View side-by-side diff

3. Click your choice, VSCode removes markers and applies decision
4. Save the file

---

## Advanced Usage

### Check-Only Mode (No Changes)

Preview what would change without applying updates:

```
/speckit-update --check-only
```

**Output**: Same summary as normal, but no approval prompt. No files are modified.

**Use case**: Planning updates, understanding scope, checking for conflicts before committing.

### Specific Version

Update to a specific SpecKit release:

```
/speckit-update --version v0.0.72
```

**Output**: Summary shows update from current → specified version.

**Use case**: Pinning to tested version, reverting to earlier release.

### Rollback

Restore from previous backup if update caused issues:

```
/speckit-update --rollback
```

**Workflow**:
1. Skill lists available backups with timestamps
2. Claude asks which backup to restore
3. Confirm restoration
4. Files restored to backed-up state

**Use case**: Undo problematic update, recover from merge errors.

---

## Troubleshooting

### "No manifest found"

**Cause**: First time running skill in this project.

**Solution**: Skill creates `.specify/manifest.json` automatically. All files are marked as "customized" (safe default) to prevent data loss. Future updates will track customizations accurately.

### Conflict resolution UI doesn't appear

**Cause**: VSCode may not recognize conflict markers if file is not text-based or markers are malformed.

**Solution**:
1. Verify file has `.md`, `.txt`, `.json`, etc. extension (not binary)
2. Check that markers start at column 1 (no indentation):
   ```
   <<<<<<<  ✅ Correct
     <<<<<<<  ❌ Incorrect (indented)
   ```
3. Reload VSCode window if markers were just written

### "The -Auto flag is deprecated"

**Cause**: You used `/speckit-update -Auto` (old workflow).

**Solution**: Remove `-Auto` flag and use conversational workflow. The skill still works with `-Auto` for backward compatibility but warns you to migrate.

### Approval doesn't trigger update

**Cause**: Claude may not have understood your approval response.

**Solution**: Use clear affirmative language:
- ✅ "yes", "proceed", "go ahead"
- ❌ "maybe", "I think so", "probably"

If stuck, Claude can re-run `/speckit-update` to show the summary again.

---

## FAQ

**Q: Do I need to specify `-Auto` for Claude Code?**
A: No! This is the old workflow. Simply use `/speckit-update` with no flags.

**Q: Can I still use the skill from a terminal (not Claude Code)?**
A: Yes, but this is primarily a Claude Code skill. Terminal usage is for development/testing.

**Q: What happens to my custom commands during updates?**
A: Custom commands (files in `.claude/commands/` not in the official SpecKit list) are **never overwritten**, even with conflicts. They're always preserved.

**Q: How do I know if a file is conflicted before the update?**
A: Run `/speckit-update --check-only` to see a detailed report without making changes.

**Q: Can I review the backup before rollback?**
A: Yes! Backups are in `.specify/backups/{timestamp}/`. You can manually inspect files there before deciding to rollback.

**Q: Does the conversational workflow work in both Claude Code CLI and VSCode Extension?**
A: Yes! The workflow is identical in both contexts. Claude handles the presentation and approval regardless of which interface you're using.

---

## Examples

### Clean Update (No Conflicts)

```
User: /speckit-update

Skill: [Summary showing 5 files to update, 0 conflicts]

Claude: "I'll update 5 files from v0.0.71 to v0.0.72. A backup will be created. Proceed?"

User: "yes"

Skill: [Updating...]
       ✅ 5 files updated
       Backup: .specify/backups/2025-10-21_14-22-10/
```

### Update with Conflicts

```
User: /speckit-update

Skill: [Summary showing 3 files to update, 2 conflicts]

Claude: "I found 3 files to update and 2 conflicts that need your review.
         The conflicts are in speckit.plan.md and tasks-template.md.
         Should I proceed?"

User: "What are the conflicts about?"

Claude: "In speckit.plan.md, you added a custom tech stack review section,
         but upstream added an architecture validation section.
         In tasks-template.md, you modified the task checklist format,
         but upstream added dependency tracking."

User: "Okay, proceed and I'll merge them manually"

Skill: [Updating...]
       ✅ 3 files updated
       ⚠️  2 conflicts written to files (Git markers)
       📝 Open .claude/commands/speckit.plan.md to resolve

User: [Opens file in VSCode, resolves using CodeLens UI]
```

### Check-Only Preview

```
User: /speckit-update --check-only

Skill: [Summary showing proposed changes]

Claude: "This is a preview only - no files will be changed.
         5 files would be updated, 1 conflict detected."

User: "looks good, run the actual update"

User: /speckit-update

Skill: [Same summary, now with approval prompt]
```

---

## Next Steps

- **Implement Feature**: See [tasks.md](tasks.md) (generated by `/speckit.tasks`) for implementation plan
- **Technical Details**: See [plan.md](plan.md) for architecture and design decisions
- **Conflict Format**: See [data-model.md](data-model.md) for Git marker specifications
