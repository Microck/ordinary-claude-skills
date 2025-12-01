# Tasks: Plugin-Based Distribution

**Input**: Design documents from [specs/015-plugin-distribution/](.)
**Prerequisites**: [plan.md](plan.md) (tech stack, structure), [spec.md](spec.md) (user stories), [research.md](research.md) (decisions), [data-model.md](data-model.md) (manifest entities), [contracts/](contracts/) (JSON schemas)

**Tests**: Integration tests included for backward compatibility validation per Constitution requirement (Principle V: Testing Discipline)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Local development environment and validation tools

- [ ] T001 Validate current branch is `015-plugin-distribution` and is up to date with main
- [ ] T002 [P] Create local directory for marketplace repository simulation at `C:\temp\claude-plugins` (used consistently in subsequent tasks)
- [ ] T003 [P] Run existing test suite to establish baseline: `./tests/test-runner.ps1` (record actual test count and verify all pass; currently 132 unit tests expected)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No blocking prerequisites for this feature - repository restructuring is self-contained

**⚠️ CRITICAL**: This phase intentionally left minimal. Repository restructuring does not require foundational infrastructure. User story work can begin immediately after Phase 1 validation.

- [ ] T004 Backup current repository state before restructuring: Create Git tag `pre-plugin-restructuring` for safety

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - First-Time Installation (Priority: P1) 🎯 MVP

**Goal**: Enable installation via `/plugin install speckit-updater` command from NotMyself marketplace. This is the core value proposition - transforming from manual Git clone to professional plugin-based distribution.

**Independent Test**: Start with clean environment (no existing installation), run `/plugin marketplace add NotMyself/claude-plugins`, then `/plugin install speckit-updater`, verify skill appears in `/help` and `/speckit-update --check-only` works in a SpecKit project within 30 seconds.

### Step 1: Create Marketplace Repository (US1)

- [ ] T005 [US1] Create new GitHub repository `NotMyself/claude-plugins` via GitHub web interface or CLI
- [ ] T006 [US1] Clone marketplace repository locally: `git clone https://github.com/NotMyself/claude-plugins C:\temp\claude-plugins`
- [ ] T007 [P] [US1] Create `.claude-plugin/` directory in marketplace repository at `C:\temp\claude-plugins\.claude-plugin`
- [ ] T008 [P] [US1] Create `.gitignore` file in marketplace repository at `C:\temp\claude-plugins\.gitignore` with standard GitHub/editor exclusions
- [ ] T009 [US1] Create `marketplace.json` manifest in `C:\temp\claude-plugins\.claude-plugin\marketplace.json` using data-model.md structure and contracts/marketplace-manifest.schema.json validation
- [ ] T010 [US1] Validate marketplace.json against schema: Use JSON validator or PowerShell `Test-Json -SchemaFile contracts/marketplace-manifest.schema.json -Path C:\temp\claude-plugins\.claude-plugin\marketplace.json`
- [ ] T011 [US1] Create `README.md` for marketplace in `C:\temp\claude-plugins\README.md` with installation instructions, plugin list, and support links
- [ ] T012 [US1] Create `LICENSE` file in `C:\temp\claude-plugins\LICENSE` (MIT license)
- [ ] T013 [US1] Commit marketplace repository: `git add . && git commit -m "feat: initialize NotMyself plugin marketplace"`
- [ ] T014 [US1] Push marketplace repository to GitHub: `git push origin main`
- [ ] T015 [US1] Verify marketplace.json is accessible via raw.githubusercontent.com URL in browser

### Step 2: Create Plugin Manifest (US1)

- [ ] T016 [P] [US1] Create `.claude-plugin/` directory at repository root: `mkdir .claude-plugin`
- [ ] T017 [US1] Create `plugin.json` manifest in `.claude-plugin/plugin.json` using data-model.md structure and contracts/plugin-manifest.schema.json validation (version: `0.8.0`)
- [ ] T018 [US1] Validate plugin.json against schema: `Test-Json -SchemaFile specs/015-plugin-distribution/contracts/plugin-manifest.schema.json -Path .claude-plugin/plugin.json`
- [ ] T019 [US1] Commit plugin manifest: `git add .claude-plugin && git commit -m "feat: add plugin manifest for v0.8.0"`

### Step 3: Repository Restructuring (US1)

- [ ] T020 [US1] Create `skills/` directory at repository root: `mkdir skills`
- [ ] T021 [US1] Create `skills/speckit-updater/` subdirectory: `mkdir skills/speckit-updater`
- [ ] T022 [P] [US1] Move `SKILL.md` to `skills/speckit-updater/SKILL.md` using `git mv`
- [ ] T023 [P] [US1] Move `scripts/` directory to `skills/speckit-updater/scripts/` using `git mv scripts skills/speckit-updater/`
- [ ] T024 [P] [US1] Move `tests/` directory to `skills/speckit-updater/tests/` using `git mv tests skills/speckit-updater/`
- [ ] T025 [P] [US1] Move `templates/` directory to `skills/speckit-updater/templates/` using `git mv templates skills/speckit-updater/`
- [ ] T026 [P] [US1] Move `specs/` directory to `skills/speckit-updater/specs/` using `git mv specs skills/speckit-updater/`
- [ ] T027 [P] [US1] Move `data/` directory to `skills/speckit-updater/data/` using `git mv data skills/speckit-updater/`

### Step 4: Path Updates After Restructuring (US1)

- [ ] T028 [US1] Update test runner paths in `skills/speckit-updater/tests/test-runner.ps1` to reference modules from new location (see research.md Q7 for path changes)
- [ ] T029 [US1] Validate module import paths remain correct in `skills/speckit-updater/scripts/update-orchestrator.ps1` (relative paths should be preserved)
- [ ] T030 [US1] Update GitHub Actions workflow paths in `.github/workflows/*.yml` to reference `./skills/speckit-updater/scripts/update-orchestrator.ps1`
- [ ] T031 [US1] Update data file references in `skills/speckit-updater/scripts/modules/FingerprintDetector.psm1` to correct parent directory traversals
- [ ] T032 [US1] Commit restructuring atomically: `git add . && git commit -m "refactor: restructure as plugin for v0.8.0"`

### Step 5: Integration Testing (US1)

- [ ] T033 [US1] Create integration test file: `skills/speckit-updater/tests/integration/PluginCompatibility.Tests.ps1`
- [ ] T034 [P] [US1] Write test scenario 1 in PluginCompatibility.Tests.ps1: Manual installation from restructured repository (simulate `git clone`, verify skill loads)
- [ ] T035 [P] [US1] Write test scenario 2 in PluginCompatibility.Tests.ps1: Plugin installation flow (mock Claude Code plugin system behavior)
- [ ] T036 [P] [US1] Write test scenario 3 in PluginCompatibility.Tests.ps1: Migration from manual to plugin (remove manual, simulate plugin install, verify behavior identical)
- [ ] T037 [P] [US1] Write test scenario 4 in PluginCompatibility.Tests.ps1: Path resolution validation (verify all relative paths work from new locations)
- [ ] T037.1 [P] [US1] Write test scenario 5 in PluginCompatibility.Tests.ps1: Side-by-side installation detection (simulate both manual and plugin installations existing, verify Claude Code loading behavior and no conflicts)
- [ ] T038 [US1] Run PluginCompatibility.Tests.ps1: `Invoke-Pester skills/speckit-updater/tests/integration/PluginCompatibility.Tests.ps1` (must pass all 5 scenarios)
- [ ] T039 [US1] Run full test suite from new location: `./skills/speckit-updater/tests/test-runner.ps1` (must pass all 132 existing unit tests without modification) — validates restructuring didn't break functionality
- [ ] T040 [US1] Commit integration tests: `git add skills/speckit-updater/tests/integration/PluginCompatibility.Tests.ps1 && git commit -m "test: add plugin compatibility integration tests"`

### Step 6: Local Plugin Testing (US1)

- [ ] T041 [US1] Test adding local marketplace in Claude Code: `/plugin marketplace add "file:///C:/temp/claude-plugins"` (verify marketplace loads)
- [ ] T042 [US1] Test plugin installation from local repository: `/plugin install speckit-updater` (verify skill installs and appears in `/help`)
- [ ] T043 [US1] Test skill functionality after plugin install: Navigate to SpecKit project, run `/speckit-update --check-only` (verify command executes successfully)
- [ ] T044 [US1] Measure installation time: Record time from `/plugin install` to skill availability (must be <30 seconds excluding network)
- [ ] T045 [US1] Test manual installation from restructured repository: `git clone` to clean directory, verify skill loads from `skills/speckit-updater/SKILL.md`
- [ ] T046 [US1] Verify all 15 workflow steps execute correctly after restructuring: Run full update cycle in test SpecKit project

**Checkpoint**: User Story 1 is complete. Plugin installation works via marketplace, backward compatibility maintained, tests pass. This is the MVP.

---

## Phase 4: User Story 2 - Team Standardization (Priority: P2)

**Goal**: Provide simple, shareable installation instructions that teams can use to standardize on the skill without detailed setup documentation. Reduce onboarding time from 5-10 minutes to under 1 minute.

**Independent Test**: Share two commands (`/plugin marketplace add` and `/plugin install`) with a team member who has no prior knowledge of the skill. Success means they can install and use the skill without asking clarification questions.

### Documentation Updates for Team Use (US2)

- [ ] T047 [P] [US2] Update README.md "Installation" section in `README.md`: Add plugin installation as primary method (prominently featured), keep manual installation as alternative, add verification steps
- [ ] T048 [P] [US2] Update CLAUDE.md "Distribution Model" section in `CLAUDE.md`: Document plugin-based distribution, marketplace repository, update installation flow references
- [ ] T049 [P] [US2] Update SKILL.md header in `skills/speckit-updater/SKILL.md`: Add installation note referencing NotMyself marketplace at top of file
- [ ] T050 [P] [US2] Update CONTRIBUTING.md "Development Setup" section in `CONTRIBUTING.md`: Document plugin structure, update paths for new directory layout, add testing instructions for both installation modes
- [ ] T051 [US2] Review all documentation for accuracy: Verify all commands, file paths, and URLs are correct and work as documented
- [ ] T052 [US2] Commit documentation updates: `git add README.md CLAUDE.md SKILL.md CONTRIBUTING.md && git commit -m "docs: update for plugin-based distribution (v0.8.0)"`

**Checkpoint**: User Story 2 is complete. Teams can easily share two-command installation instructions. Documentation is clear and accurate.

---

## Phase 5: User Story 3 - Existing User Migration (Priority: P3)

**Goal**: Provide optional migration path for existing users with manual installations to benefit from plugin features (version management, easier updates) without losing functionality or requiring forced migration.

**Independent Test**: Start with working manual installation, follow migration guide (remove manual, install plugin), verify identical behavior. Success means skill works the same way after migration with no configuration changes.

### Migration Documentation (US3)

- [ ] T053 [US3] Create migration guide: `docs/migration-guide-plugin.md` with step-by-step instructions (remove manual installation, install via plugin, verify migration)
- [ ] T054 [P] [US3] Add migration benefits section to migration guide explaining version management and easier updates
- [ ] T055 [P] [US3] Add troubleshooting section to migration guide covering common migration issues and solutions
- [ ] T056 [P] [US3] Add "no forced migration" disclaimer to migration guide emphasizing optional nature and continued support for manual installations
- [ ] T057 [US3] Link migration guide from README.md "Installation" section and CHANGELOG.md v0.8.0 entry
- [ ] T058 [US3] Test migration procedure: Follow guide exactly on test machine with manual installation, verify all steps work and behavior is identical
- [ ] T059 [US3] Commit migration guide: `git add docs/migration-guide-plugin.md && git commit -m "docs: add plugin migration guide"`

**Checkpoint**: User Story 3 is complete. Existing users have clear optional migration path with comprehensive guide.

---

## Phase 6: User Story 4 - Future Skills Discovery (Priority: P3)

**Goal**: Set foundation for distributing multiple SpecKit-related skills through the same marketplace. Enable users to discover and install additional skills as they become available.

**Independent Test**: Run `/plugin` after marketplace is added, verify all plugins (currently just speckit-updater) are listed with names, versions, and descriptions. Success means the marketplace structure supports adding more plugins in the future without changes.

### Marketplace Scalability (US4)

- [ ] T060 [P] [US4] Add "Future Plugins" section to marketplace README at `C:\temp\claude-plugins\README.md` explaining planned skills (speckit-validator, speckit-templates, etc.)
- [ ] T061 [P] [US4] Add plugin categorization tags to marketplace.json: Ensure `tags` field is used consistently for future discoverability
- [ ] T062 [P] [US4] Document marketplace maintenance workflow in `C:\temp\claude-plugins\README.md`: How to add new plugins, update versions, test marketplace changes
- [ ] T063 [US4] Validate marketplace supports multiple plugin entries: Add dummy second plugin entry to marketplace.json, validate schema still passes, remove dummy entry
- [ ] T064 [US4] Commit marketplace scalability updates: `cd C:\temp\claude-plugins && git add . && git commit -m "docs: add future plugin guidance and maintenance workflow"`
- [ ] T065 [US4] Push marketplace updates: `cd C:\temp\claude-plugins && git push origin main`

**Checkpoint**: User Story 4 is complete. Marketplace is ready for future plugins, documentation explains how to add them.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Release preparation, final validation, and cross-story improvements

### CHANGELOG and Release Notes

- [ ] T066 [P] Update CHANGELOG.md in `CHANGELOG.md`: Add v0.8.0 release notes with plugin distribution feature, breaking changes section (none), migration guide link, technical details
- [ ] T067 [P] Create GitHub Release notes template in local file: Detailed release notes with installation instructions, benefits, backward compatibility notes, migration guide link (see research.md Phase 4 for format)
- [ ] T068 [P] Add badges to README.md: Version badge (`v0.8.0`), Plugin badge (`claude-code-plugin`), License badge

### Version Alignment

- [ ] T069 Verify version consistency across all files: `.claude-plugin/plugin.json` (`0.8.0`), marketplace.json (`0.8.0`), CHANGELOG.md (`## [0.8.0]`), GitHub Release tag (`v0.8.0`)
- [ ] T070 Commit version updates: `git add CHANGELOG.md README.md && git commit -m "chore: prepare v0.8.0 release"`

### Pre-Release Validation

- [ ] T071 Run complete test suite one final time: `./skills/speckit-updater/tests/test-runner.ps1 -Coverage` (must pass 100%) — final pre-release validation with coverage report
- [ ] T072 [P] Validate plugin.json manifest one final time: `Test-Json -SchemaFile specs/015-plugin-distribution/contracts/plugin-manifest.schema.json -Path .claude-plugin/plugin.json`
- [ ] T073 [P] Validate marketplace.json manifest one final time: `Test-Json -SchemaFile specs/015-plugin-distribution/contracts/marketplace-manifest.schema.json -Path C:\temp\claude-plugins\.claude-plugin\marketplace.json`
- [ ] T074 Test complete plugin installation flow end-to-end: Clean environment → add marketplace → install plugin → use skill (record timing, must be <30 seconds)
- [ ] T075 Test manual installation flow end-to-end: Clean environment → git clone → verify skill loads and works identically
- [ ] T076 [P] Read through all documentation one final time: Verify accuracy, fix typos, ensure all links work

### Release Execution

- [ ] T077 Create Git tag for v0.8.0: `git tag v0.8.0 && git push origin v0.8.0`
- [ ] T078 Create GitHub Release for v0.8.0: Use release notes template, attach tag `v0.8.0`, mark as latest release
- [ ] T079 Update marketplace.json to reference v0.8.0: Edit `C:\temp\claude-plugins\.claude-plugin\marketplace.json` to update `plugins[0].version` to `"0.8.0"`
- [ ] T080 Commit marketplace version update: `cd C:\temp\claude-plugins && git add .claude-plugin/marketplace.json && git commit -m "chore: update speckit-updater to v0.8.0"`
- [ ] T081 Push marketplace version update: `cd C:\temp\claude-plugins && git push origin main`

### Public Testing

- [ ] T082 Test plugin installation from public GitHub marketplace: Clean environment, `/plugin marketplace add NotMyself/claude-plugins`, `/plugin install speckit-updater` (verify works from live GitHub)
- [ ] T083 Verify marketplace.json is accessible publicly: Test URL `https://raw.githubusercontent.com/NotMyself/claude-plugins/main/.claude-plugin/marketplace.json` in browser
- [ ] T084 Test plugin metadata display: Run `/plugin` and `/plugin info speckit-updater`, verify all metadata (name, version, description, author) displays correctly
- [ ] T085 Test manual installation from public GitHub: Clean environment, `git clone https://github.com/NotMyself/claude-win11-speckit-safe-update-skill speckit-updater`, verify skill works

### Issue and Communication

- [ ] T086 Close GitHub issue #14: Link to v0.8.0 release, thank contributors, mark as resolved
- [ ] T087 [P] Create GitHub Discussions post announcing v0.8.0: Explain plugin distribution, provide installation instructions, invite feedback
- [ ] T088 [P] Update any external documentation (wiki, team wikis, blog posts) with new installation method
- [ ] T089 [P] Create GitHub issue to update constitution Distribution section: Propose amendment to add plugin installation method alongside Git clone method (follows constitution amendment process per v1.3.1 governance)

**Checkpoint**: All user stories complete, release published, public testing validated. Feature is done.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - Minimal phase, repository restructuring is self-contained
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion - Core MVP functionality
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion - Builds on US1 by adding team-friendly documentation
- **User Story 3 (Phase 5)**: Depends on User Story 1 completion - Optional migration guide builds on US1
- **User Story 4 (Phase 6)**: Depends on User Story 1 completion - Marketplace scalability builds on US1
- **Polish (Phase 7)**: Depends on all desired user stories being complete - Release preparation

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - Core functionality enabling plugin installation
- **User Story 2 (P2)**: Can start after User Story 1 - Documentation updates reference plugin installation from US1
- **User Story 3 (P3)**: Can start after User Story 1 - Migration guide assumes plugin installation works
- **User Story 4 (P3)**: Can start after User Story 1 - Marketplace scalability assumes marketplace exists from US1

**Key Insight**: US2, US3, and US4 are NOT independently testable without US1. They all depend on the core plugin installation infrastructure from US1. However, once US1 is complete, US2/US3/US4 can proceed in parallel.

### Within Each User Story

**User Story 1 (P1) - First-Time Installation:**
1. Marketplace repository (T005-T015) → Plugin manifest (T016-T019) → Restructuring (T020-T032) → Testing (T033-T040) → Validation (T041-T046)
2. Marketplace must exist before plugin can reference it
3. Plugin manifest must exist before restructuring (validates new structure)
4. Restructuring must complete before testing paths
5. All tests must pass before considering US1 complete

**User Story 2 (P2) - Team Standardization:**
- All documentation tasks (T047-T051) can run in parallel (different files)
- Review task (T051) depends on all doc updates completing
- Commit (T052) is final step

**User Story 3 (P3) - Existing User Migration:**
- Migration guide sections (T054-T056) can run in parallel
- Migration guide creation (T053) must happen first
- Testing migration (T058) depends on guide being complete

**User Story 4 (P3) - Future Skills Discovery:**
- All marketplace scalability tasks (T060-T063) can run in parallel
- Commit and push (T064-T065) are final steps

### Parallel Opportunities

**Phase 1 (Setup):**
- T002 and T003 can run in parallel

**Phase 3 (User Story 1):**
- Within marketplace creation: T007 and T008 can run in parallel
- Within restructuring: T022-T027 (6 git mv operations) can run in parallel (all move different directories)
- Within integration tests: T034-T037 (4 test scenarios) can be written in parallel
- T022-T027 (move operations) can all run together

**Phase 4 (User Story 2):**
- T047-T050 (4 documentation files) can all be updated in parallel

**Phase 5 (User Story 3):**
- T054-T056 (migration guide sections) can be written in parallel

**Phase 6 (User Story 4):**
- T060-T063 (marketplace scalability) can all be done in parallel

**Phase 7 (Polish):**
- T066-T068 (CHANGELOG, release notes, badges) can be done in parallel
- T072-T073 (both validations) can run in parallel
- T087-T088 (communication tasks) can run in parallel

---

## Parallel Example: User Story 1 (Repository Restructuring)

```powershell
# Launch all directory moves together (T022-T027):
# These are safe to run in parallel because they move different source directories

# Terminal 1:
git mv SKILL.md skills/speckit-updater/SKILL.md

# Terminal 2:
git mv scripts skills/speckit-updater/

# Terminal 3:
git mv tests skills/speckit-updater/

# Terminal 4:
git mv templates skills/speckit-updater/

# Terminal 5:
git mv specs skills/speckit-updater/

# Terminal 6:
git mv data skills/speckit-updater/

# All 6 moves can execute simultaneously without conflicts
```

---

## Parallel Example: User Story 2 (Documentation Updates)

```powershell
# Launch all documentation updates together (T047-T050):
# These are safe to run in parallel because they edit different files

# Agent 1:
Task: "Update README.md Installation section in README.md"

# Agent 2:
Task: "Update CLAUDE.md Distribution Model section in CLAUDE.md"

# Agent 3:
Task: "Update SKILL.md header in skills/speckit-updater/SKILL.md"

# Agent 4:
Task: "Update CONTRIBUTING.md Development Setup section in CONTRIBUTING.md"

# All 4 documentation updates can happen simultaneously
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (~15 minutes)
2. Complete Phase 2: Foundational (~5 minutes, minimal)
3. Complete Phase 3: User Story 1 (~8-10 hours)
   - Marketplace repository creation (~2 hours)
   - Plugin manifest creation (~1 hour)
   - Repository restructuring (~3 hours)
   - Integration testing (~2-3 hours)
   - Local plugin testing (~1 hour)
4. **STOP and VALIDATE**: Test plugin installation end-to-end, verify backward compatibility
5. **MVP COMPLETE**: Plugin-based installation is functional

**Estimated Time for MVP**: ~10-12 hours for one developer

### Incremental Delivery

1. Complete Setup + Foundational → Baseline established (~20 minutes)
2. Add User Story 1 → Test independently → **MVP READY** (~10 hours)
3. Add User Story 2 → Test independently → **Team-Ready** (~3 hours)
4. Add User Story 3 → Test independently → **Migration-Ready** (~2 hours)
5. Add User Story 4 → Test independently → **Future-Proof** (~2 hours)
6. Polish and Release → **Public Release** (~3 hours)

**Total Estimated Time**: ~20 hours (consistent with PRD estimate of 21 hours)

### Parallel Team Strategy

With multiple developers (after User Story 1 is complete):

1. **Day 1**: All developers complete Phase 1 + Phase 2 + Phase 3 (User Story 1) together (~10 hours)
2. **Day 2**: Once US1 is done, split work:
   - Developer A: User Story 2 (Documentation) - ~3 hours
   - Developer B: User Story 3 (Migration Guide) - ~2 hours
   - Developer C: User Story 4 (Marketplace Scalability) - ~2 hours
3. **Day 3**: All developers collaborate on Phase 7 (Polish & Release) - ~3 hours
4. **Result**: Complete in 3 days with 3 developers vs 3 days with 1 developer

**Key Constraint**: User Story 1 MUST complete before other stories can begin (they all depend on plugin installation working).

---

## Notes

- [P] tasks = different files, no dependencies, safe to parallelize
- [Story] label (US1, US2, US3, US4) maps task to specific user story for traceability
- User Story 1 is the critical path - all other stories depend on it
- User Stories 2, 3, 4 can proceed in parallel after US1 completes
- Each user story should be independently completable and testable (with US1 as prerequisite)
- Commit frequently, especially after restructuring operations (easy rollback)
- Stop at any checkpoint to validate story independently
- Use `git mv` for all file moves to preserve Git history
- Validate JSON manifests against schemas before committing
- Test both plugin and manual installation methods throughout
- Avoid: vague tasks, same file conflicts, changes without test validation

---

## Success Validation

After completing all tasks, verify success criteria from spec.md:

- **SC-001**: Plugin installation completes in <30 seconds (validate with T074)
- **SC-002**: 95%+ installation success rate (validate with public testing T082-T085)
- **SC-003**: 100% backward compatibility (validate with T039, T045, T085)
- **SC-004**: Marketplace browsable via `/plugin` (validate with T042, T084)
- **SC-005**: 90%+ users install without extra docs (validate with team feedback)
- **SC-006**: Installation reduced to 2 commands (validate with T042, T082)
- **SC-007**: 80%+ reduction in onboarding time (validate with team feedback)
- **SC-008**: All existing tests pass (validate with T039, T071)
- **SC-009**: 50%+ new users choose plugin method (measure post-release)

**Note on External Measurements**: Success criteria SC-002 (95%+ success rate), SC-005 (90%+ users install without docs), SC-007 (80%+ onboarding time reduction), and SC-009 (50%+ plugin adoption) require post-release measurement and cannot be validated during implementation. These will be measured through:
- GitHub issue reports (installation failures)
- User feedback surveys (documentation clarity, onboarding time)
- GitHub Insights metrics (clone count vs plugin installations, if trackable)

**Post-Release Tracking**: Create GitHub issue after v0.8.0 release to track these metrics over the first month.

**If any success criteria fail during validation, address before considering feature complete.**
