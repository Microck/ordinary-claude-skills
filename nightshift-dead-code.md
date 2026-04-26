# Nightshift Dead Code Analysis

## Summary

ordinary-claude-skills is a content repository (Claude skill markdown files). Traditional dead code (unused functions, unreachable paths) does not apply. Analysis focuses on structural dead code: unreferenced files, empty metadata, redundant directories, and stale content.

## Findings

### P1 — Massive Redundant Duplication: `skills_all/` → `skills_categorized/`

**Impact:** 400 of 415 skill directories (96.4%) in `skills_all/` are duplicated in `skills_categorized/`. This adds ~2099 redundant files (~4MB) that serve no purpose.

- `skills_all/`: 415 directories, 2099 files (flat structure)
- `skills_categorized/`: 1444 directories, 3032 files (organized by category)
- Only 15 skills exist in `skills_all/` but NOT in `skills_categorized/`

The 15 non-duplicated skills:
1. aws-skills (compound skill with sub-skills)
2. brand-guidelines
3. claude-scientific-skills (compound skill)
4. claude-win11-speckit-update-skill
5. claudisms
6. ffuf-claude-skill
7. internal-comms
8. ios-simulator-skill
9. notebooklm-skill
10. playwright-skill
11. superpowers-lab
12. template-skill
13. theme-factory
14. webapp-testing
15. xlsx

**Recommendation:** Migrate the 15 non-duplicated skills into `skills_categorized/`, then remove `skills_all/`. Update any references in docs/SUMMARY.md and README.md.

### P2 — 15 Skills Missing metadata.json

The following skills in `skills_all/` lack `metadata.json` files, making them invisible to any automated tooling that scans metadata:

- aws-skills, brand-guidelines, claude-scientific-skills, claude-win11-speckit-update-skill
- claudisms, ffuf-claude-skill, internal-comms, ios-simulator-skill
- notebooklm-skill, playwright-skill, superpowers-lab, template-skill
- theme-factory, webapp-testing, xlsx

**Note:** These are the same 15 skills not duplicated to `skills_categorized/`. The lack of metadata likely prevented their migration.

**Recommendation:** Create metadata.json for each, then migrate to `skills_categorized/`.

### P3 — `.gitignore` Excludes `*.py`

The `.gitignore` contains `*.py` which would exclude any Python scripts from being tracked. While this is intentional for a markdown-only repo, it could cause confusion if someone adds automation scripts.

### P3 — `docs/pages/` Contains Rendered Content

The `docs/pages/*.md` files appear to be rendered/compiled versions of skill content for the static site (docsify). These are derived from `skills_all/` (or `skills_categorized/`) and would need regeneration if source changes. Not dead code per se, but worth documenting the build dependency.

## Proposed Cleanup

1. **Create metadata.json** for the 15 missing skills
2. **Migrate** those 15 skills into appropriate `skills_categorized/` subdirectories
3. **Remove** `skills_all/` directory entirely
4. **Update** README.md to reference `skills_categorized/` as the canonical source
5. **Verify** docs build still works after removal

## Metrics

| Metric | Value |
|--------|-------|
| Total files | 5,203 |
| Duplicate files (skills_all) | 2,099 (~40%) |
| Potential space savings | ~4MB |
| Skills with missing metadata | 15/415 (3.6%) |
