# PRD: Smart Merge with Frictionless Onboarding

**Status**: Draft
**Created**: 2025-10-23
**GitHub Issue**: [#25](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/25)
**Target Release**: v0.5.0

---

## Executive Summary

Transform the first-time user experience from "manually resolve 15 conflicts" to "detected your version, zero conflicts" by implementing intelligent 3-way merge with automatic version detection. This eliminates the primary friction point for new users adopting the SpecKit Safe Update Skill.

---

## Problem Statement

### Current User Experience (First-Time Update)

When a user with an existing SpecKit installation runs `/speckit-update` for the first time:

1. **No manifest exists** → Version unknown
2. **System defaults to v0.0.0** (sentinel for "unknown version")
3. **All files assumed customized** (safe default to prevent data loss)
4. **Traditional conflict resolution** triggers for 10-15 files
5. **User manually resolves** each conflict using git markers or diff files

**Result:** Poor onboarding experience, high friction, discourages adoption.

### Pain Points

- **Time-consuming**: 15-30 minutes to manually resolve conflicts
- **Error-prone**: Users may accidentally choose wrong version
- **Intimidating**: Wall of conflicts scares new users
- **Unnecessary**: Most files are unchanged - conflicts are false positives
- **Constitution updates**: Always require manual merge (high-value file)

---

## Goals

### Primary Goal
Reduce first-time update friction from 15 manual conflicts to **0-2 conflicts** for 80%+ of users.

### Secondary Goals
1. **Automatic version detection**: Identify installed SpecKit version with 95%+ accuracy
2. **Intelligent merge**: Auto-merge 90%+ of files without user intervention
3. **Constitution auto-update**: Merge constitution changes automatically in 90%+ of cases
4. **Offline-first**: Work without internet connection (detection + merge)
5. **Automated maintenance**: Zero manual work to support new SpecKit releases

---

## Proposed Solution

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ 1. VERSION DETECTION (New)                                  │
│    Load fingerprint database → Match user files → Detect    │
│    v0.0.76 with 95% confidence                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. MANIFEST CREATION (Enhanced)                             │
│    Create manifest with REAL version (not v0.0.0)           │
│    Mark only truly-different files as customized            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. SMART 3-WAY MERGE (New)                                  │
│    Download original (v0.0.76) + incoming (v0.0.79)         │
│    Parse markdown → Match sections → Auto-merge             │
│    Generate granular conflict markers (section-level)       │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Design

### Component 1: Fingerprint Database

**File**: `data/speckit-fingerprints.json` (~120 KB)

**Structure**:
```json
{
  "schema_version": "1.0",
  "total_versions": 77,
  "latest_version": "v0.0.79",
  "versions": {
    "v0.0.79": {
      "release_date": "2025-10-23",
      "fingerprints": {
        ".claude/commands/speckit.specify.md": "sha256:a1b2c3...",
        ".claude/commands/speckit.plan.md": "sha256:e5f6g7...",
        ".specify/memory/constitution.md": "sha256:i9j0k1..."
      }
    }
  }
}
```

**Key Files Tracked** (12 per version):
- 8 official commands: `speckit.{specify,plan,tasks,implement,analyze,clarify,checklist,constitution}.md`
- 1 constitution: `.specify/memory/constitution.md`
- 3 templates: `.specify/templates/{spec,plan,tasks}-template.md`

**Generation**:
- Script: `scripts/generate-fingerprints.ps1`
- Process: Download all 77 SpecKit releases, compute normalized hashes
- One-time execution (~2 minutes with GitHub PAT)
- Result committed to repo

**Maintenance**:
- GitHub Action: `.github/workflows/update-fingerprints.yml`
- Checks for new releases every 6 hours
- Auto-generates fingerprints, creates PR
- Maintainer reviews and merges

---

### Component 2: FingerprintDetector Module

**File**: `scripts/modules/FingerprintDetector.psm1` (~150 LOC)

**Functions**:

```powershell
function Get-FingerprintDatabase {
    # Load data/speckit-fingerprints.json (local, instant)
}

function Find-SpecKitVersionByFingerprint {
    param([string]$ProjectRoot)

    # Strategy 1: Signature check (3 core files)
    #   - speckit.specify.md, speckit.plan.md, constitution.md
    #   - 100% match = High confidence, return immediately

    # Strategy 2: Full fingerprint (all 12 files)
    #   - 95-100% match = High confidence
    #   - 70-94% match = Medium confidence (conversational)
    #   - <70% match = Low confidence (offer options)

    return @{
        Version = "v0.0.76"
        Confidence = "High"
        CustomizedFiles = @("speckit.plan.md", "constitution.md")
    }
}
```

**Detection Algorithm**:

1. **Load database** from `data/speckit-fingerprints.json`
2. **Quick signature check** (3 files):
   - Compute normalized hashes for 3 core files
   - Check exact match against all 77 versions
   - 100% match → Return immediately (covers 95%+ of cases)
3. **Full fingerprint check** (12 files):
   - Compute hashes for all 12 tracked files
   - Find best match across 77 versions
   - Calculate confidence score (percentage match)
4. **Return result**:
   - High (95-100%): Auto-use, show customized files
   - Medium (70-94%): Conversational (suggest version)
   - Low (<70%): Conversational (offer options)

**Performance**:
- Signature check: <50ms (3 file hashes)
- Full check: <100ms (12 file hashes)
- No network calls, 100% offline

---

### Component 3: MarkdownMerger Module

**File**: `scripts/modules/MarkdownMerger.psm1` (~600 LOC)

**Core Function**:

```powershell
function Invoke-ThreeWayMarkdownMerge {
    param(
        [string]$Original,   # From v0.0.76 (detected version)
        [string]$Current,    # User's local file (may have customizations)
        [string]$Incoming,   # From v0.0.79 (target version)
        [string]$OriginalVersion,
        [string]$IncomingVersion
    )

    # 1. Parse all 3 versions into markdown AST
    $originalDoc = (ConvertFrom-Markdown $Original).Tokens
    $currentDoc = (ConvertFrom-Markdown $Current).Tokens
    $incomingDoc = (ConvertFrom-Markdown $Incoming).Tokens

    # 2. Extract sections (by headers)
    $originalSections = Get-MarkdownSections $originalDoc
    $currentSections = Get-MarkdownSections $currentDoc
    $incomingSections = Get-MarkdownSections $incomingDoc

    # 3. For each incoming section:
    $mergedContent = ""
    foreach ($incomingSection in $incomingSections) {
        # Match to original and current
        $matchOriginal = Find-SectionMatch $incomingSection $originalSections
        $matchCurrent = Find-SectionMatch $incomingSection $currentSections

        if ($matchOriginal -and $matchCurrent) {
            # Section exists in all 3 versions
            $customizations = Get-SectionCustomizations $matchOriginal $matchCurrent

            if ($customizations.Count -eq 0) {
                # No customizations → Use incoming as-is
                $mergedContent += $incomingSection.Content
            }
            elseif (Test-AutoMergeable $customizations $incomingSection) {
                # Customizations can be auto-merged
                $mergedContent += Merge-Customizations $incomingSection $customizations
            }
            else {
                # Conflict → Write granular git markers
                $mergedContent += Write-SectionConflictMarker `
                    -Header $incomingSection.Header `
                    -Current $matchCurrent.Body `
                    -Incoming $incomingSection.Body `
                    -CurrentVersion $OriginalVersion `
                    -IncomingVersion $IncomingVersion
            }
        }
        elseif (!$matchOriginal -and !$matchCurrent) {
            # Brand new section from upstream
            $mergedContent += $incomingSection.Content
        }
        else {
            # Section moved/renamed/deleted → Conflict
            $mergedContent += Write-SectionConflictMarker ...
        }
    }

    return $mergedContent
}
```

**Section Matching**:
- Use `ConvertFrom-Markdown` (built-in PowerShell 7+ cmdlet)
- Extract headers with line numbers
- Fuzzy match by header text (Levenshtein distance, 80% threshold)
- Handle renames: "Design Phase" → "Design & Architecture Phase"

**Customization Detection**:
- For matched sections: `Diff(Original, Current) = Customizations`
- Identify: additions, modifications, deletions
- Classify: auto-mergeable vs. conflict

**Auto-Merge Criteria**:
- User added lines, upstream added different lines → Combine
- User modified paragraph A, upstream modified paragraph B → Both
- User added section, upstream added different section → Both

**Conflict Criteria**:
- Same paragraph modified differently
- Section deleted upstream but user customized it
- Header renamed differently in both versions

**Conflict Marker Format**:
```markdown
## Section Header (from incoming structure)

<<<<<<< Current (Your Version - v0.0.76)
Your customized content here.
Custom additions you made.
=======
New upstream content here.
Official template updates.
>>>>>>> Incoming (v0.0.79)
```

**Key Features**:
- **Granular**: Only conflicted sections get markers (not entire file)
- **Resolvable**: Each section independently fixable with VSCode CodeLens
- **Structured**: Uses incoming header (preserves upstream organization)

---

### Component 4: GitHub Action Automation

**File**: `.github/workflows/update-fingerprints.yml`

**Triggers**:
- Schedule: Every 6 hours (`cron: '0 */6 * * *'`)
- Manual: `workflow_dispatch`

**Workflow**:
```yaml
jobs:
  update-fingerprints:
    runs-on: ubuntu-latest
    steps:
      - Checkout repo

      - Check latest SpecKit release via API

      - Check current database version

      - If new version detected:
          - Run update-fingerprints.ps1
          - Compute hashes for 12 files
          - Update JSON file
          - Create PR for review

      - Else:
          - Log "No new version" and exit
```

**Script**: `scripts/update-fingerprints.ps1` (~100 LOC)
- Download SpecKit archive for new version
- Extract 12 tracked files
- Compute normalized hashes
- Update `data/speckit-fingerprints.json`
- No Gist API calls (just file edit)

**Benefits**:
- Zero manual maintenance
- Version-controlled updates (PRs)
- Reviewed before merge
- Automated within 6 hours of SpecKit release

---

### Component 5: GitHubApiClient Enhancement

**File**: `scripts/modules/GitHubApiClient.psm1` (+150 LOC)

**New Functions**:

```powershell
function Get-SpecKitArchive {
    param(
        [string]$Version,  # e.g., "v0.0.76"
        [string]$CachePath = ".specify/.cache/archives"
    )

    # Check cache first
    $cachedArchive = Join-Path $CachePath "$Version.zip"
    if (Test-Path $cachedArchive) {
        return $cachedArchive
    }

    # Download from GitHub
    $url = "https://github.com/github/spec-kit/releases/download/$Version/spec-kit-template-claude-ps-$Version.zip"

    # Save to cache
    Invoke-WebRequest -Uri $url -OutFile $cachedArchive

    return $cachedArchive
}

function Get-FileFromArchive {
    param(
        [string]$ArchivePath,
        [string]$FilePath  # e.g., ".claude/commands/speckit.plan.md"
    )

    # Extract single file without full extraction
    $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "extract-$([guid]::NewGuid())")

    Expand-Archive -Path $ArchivePath -DestinationPath $tempDir

    $extractedFile = Join-Path $tempDir $FilePath
    $content = Get-Content $extractedFile -Raw

    Remove-Item $tempDir -Recurse -Force

    return $content
}
```

**Benefits**:
- Download archives once (original + incoming)
- Cache for reuse across multiple files
- Efficient extraction (only needed files)
- Clean up temp files automatically

---

### Component 6: Orchestrator Integration

**File**: `scripts/update-orchestrator.ps1` (+200 LOC changes)

**Enhanced Step 3: Manifest Loading**

```powershell
# Current behavior:
if (-not $manifest) {
    $manifest = New-SpecKitManifest -Version "v0.0.0" -AssumeAllCustomized
}

# New behavior:
if (-not $manifest) {
    # Attempt version detection
    $detection = Find-SpecKitVersionByFingerprint -ProjectRoot $projectRoot

    if ($detection.Confidence -eq "High") {
        # Auto-use detected version
        Write-Host "✅ Detected: $($detection.Version) ($($detection.Confidence) confidence)"
        Write-Host "   $($detection.CustomizedFiles.Count) files appear customized"

        $manifest = New-SpecKitManifest -Version $detection.Version `
                                        -MarkCustomized $detection.CustomizedFiles
    }
    elseif ($detection.Confidence -eq "Medium") {
        # Conversational workflow
        Write-Host "[VERSION_DETECTION_MEDIUM]"
        Write-Host "Probable version: $($detection.Version)"
        Write-Host "Confidence: $($detection.Confidence)"
        Write-Host "[END_VERSION_DETECTION]"

        exit 0  # Claude presents to user, awaits confirmation
    }
    else {
        # Low confidence or failed detection
        Write-Host "⚠️ Unable to detect version reliably"
        Write-Host "   Using safe default (v0.0.0)"

        $manifest = New-SpecKitManifest -Version "v0.0.0" -AssumeAllCustomized
    }
}
```

**Enhanced Step 11: Conflict Resolution**

```powershell
# Current behavior:
foreach ($conflict in $conflicts) {
    Write-ConflictMarkers -FilePath $conflict.path ...
}

# New behavior:
foreach ($conflict in $conflicts) {
    # Check if smart merge available
    if ($manifest.speckit_version -ne "v0.0.0") {
        # Download archives
        $originalArchive = Get-SpecKitArchive -Version $manifest.speckit_version
        $incomingArchive = Get-SpecKitArchive -Version $targetVersion

        # Extract specific files
        $original = Get-FileFromArchive -Archive $originalArchive -Path $conflict.path
        $current = Get-Content $conflict.path -Raw
        $incoming = Get-FileFromArchive -Archive $incomingArchive -Path $conflict.path

        # Smart 3-way merge
        if ($conflict.path -match '\.md$') {
            # Markdown file: Use semantic merge
            $merged = Invoke-ThreeWayMarkdownMerge `
                -Original $original `
                -Current $current `
                -Incoming $incoming `
                -OriginalVersion $manifest.speckit_version `
                -IncomingVersion $targetVersion
        }
        else {
            # Non-markdown: Use traditional merge
            $merged = Write-ConflictMarkers ...
        }

        # Write merged result
        Set-Content -Path $conflict.path -Value $merged
    }
    else {
        # v0.0.0 sentinel → Traditional merge
        Write-ConflictMarkers -FilePath $conflict.path ...
    }
}
```

---

## User Experience Scenarios

### Scenario 1: First-Time User on Recent Version (95% of cases)

**Setup**:
- User on SpecKit v0.0.76
- Has customized 3 files: `speckit.plan.md`, `speckit.tasks.md`, `constitution.md`
- Running `/speckit-update` for first time

**Experience**:
```
🔍 Detecting SpecKit version...
✅ Detected: v0.0.76 (98% match)
   3 files appear customized

Creating manifest for v0.0.76...

📊 Smart merge preview:
   • 9 files will update (no conflicts)
   • 3 files will auto-merge with your customizations
   • 0 conflicts require manual resolution

Proceed? [Y/n]: y

⏳ Downloading v0.0.76 (original)...
⏳ Downloading v0.0.79 (target)...
🔄 Merging 12 files...

✅ Update complete!
   • 9 files updated
   • 3 files auto-merged (constitution.md, speckit.plan.md, speckit.tasks.md)
   • 0 conflicts

Your customizations have been preserved and merged with the latest version.
```

**Result**: Zero manual work, 30 seconds total time.

---

### Scenario 2: First-Time User with Many Customizations

**Setup**:
- User on SpecKit v0.0.75
- Has heavily customized 8 files
- One section conflict in `constitution.md`

**Experience**:
```
🔍 Detecting SpecKit version...
✅ Detected: v0.0.75 (95% match)
   8 files appear customized

📊 Smart merge preview:
   • 4 files will update (no conflicts)
   • 7 files will auto-merge
   • 1 file has conflicts requiring review:
     - constitution.md (1 section)

Proceed? [Y/n]: y

⏳ Merging files...
✅ 11 files processed

⚠️ 1 file needs your review:
   .specify/memory/constitution.md

   Section "Testing Discipline" has conflicting changes.

   Open in editor? [Y/n]: y
```

**VSCode opens with:**
```markdown
## Testing Discipline

<<<<<<< Current (Your Version - v0.0.75)
All modules MUST have comprehensive Pester tests.
Custom rule: Integration tests run nightly.
=======
All modules MUST have corresponding Pester unit tests.
Integration tests MUST cover end-to-end workflows.
>>>>>>> Incoming (v0.0.79)
```

**User clicks**: "Accept Both Changes"

**Result**: 1 minute manual work (vs 15 minutes resolving 15 conflicts).

---

### Scenario 3: Older Version with Lower Confidence

**Setup**:
- User on SpecKit v0.0.60 (older version)
- 72% file match (medium confidence)

**Experience**:
```
🔍 Detecting SpecKit version...
⚠️ Probable version: v0.0.60 (72% match)
   6 files differ from official v0.0.60

I detected your SpecKit installation but need confirmation:

Analysis suggests you're on v0.0.60 with 6 customized files:
- .claude/commands/speckit.plan.md
- .claude/commands/speckit.specify.md
- (4 others)

Options:
1. Use v0.0.60 (enables smart merge)
2. Treat all files as customized (safest, traditional merge)
3. You know your version - tell me

[Awaiting user response via chat]
```

**User responds**: "Use v0.0.60"

**Claude re-invokes**: `/speckit-update -Proceed -DetectedVersion v0.0.60`

**Continues** with smart merge workflow.

---

### Scenario 4: Very Old/Undetectable Version

**Setup**:
- User on SpecKit v0.0.20 (very old, not in database)
- 40% file match (low confidence)

**Experience**:
```
🔍 Detecting SpecKit version...
⚠️ Unable to detect version reliably (best match: v0.0.48 at 40%)

Your SpecKit installation is too old or heavily customized for automatic detection.

Options:
1. Use safest approach (assume all files customized)
2. Tell me your version if you know it
3. Run `/speckit-update --version-check` to find out

[Awaiting user response]
```

**User responds**: "Use safest approach"

**System**: Creates manifest with v0.0.0, proceeds with traditional merge

**Result**: Falls back to current behavior (no regression).

---

## Success Metrics

### Primary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **First-time conflict count** | 0-2 conflicts for 80%+ of users | Track via telemetry/feedback |
| **Version detection accuracy** | 95%+ for recent versions (v0.0.60+) | Unit tests + user reports |
| **Auto-merge rate** | 90%+ of files merge without conflicts | Track conflicts vs total files |
| **Constitution auto-merge** | 90%+ of cases | Specific tracking for this file |
| **Detection speed** | <100ms (offline) | Performance tests |

### Secondary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **User satisfaction** | 8/10+ rating for onboarding | User surveys |
| **Time to first update** | <2 minutes (vs 15-30 minutes) | User feedback |
| **Support requests** | 50% reduction in onboarding issues | GitHub issues tagged "onboarding" |
| **Adoption rate** | 25% increase in first-week usage | Download vs active user ratio |

### Telemetry (If Implemented)

```powershell
# Optional anonymous metrics
@{
    event = "first_update_complete"
    detection_confidence = "High"
    detected_version = "v0.0.76"
    files_auto_merged = 12
    files_conflicted = 1
    time_to_complete = "45s"
}
```

---

## Implementation Plan

### Phase 1: Infrastructure (Week 1)

**Tasks**:
1. Generate fingerprint database (77 versions)
   - Script: `scripts/generate-fingerprints.ps1`
   - Requires: GitHub PAT, ~2 minutes runtime
   - Output: `data/speckit-fingerprints.json` (120 KB)

2. Create GitHub Action workflow
   - File: `.github/workflows/update-fingerprints.yml`
   - Test: Manual trigger, verify PR creation

3. Create update script
   - File: `scripts/update-fingerprints.ps1`
   - Test: Add fake version, verify JSON updated

**Deliverables**:
- Fingerprint database committed to repo
- GitHub Action functional
- Maintenance automation tested

**Estimate**: 4 hours

---

### Phase 2: Version Detection (Week 1)

**Tasks**:
1. Create FingerprintDetector module
   - File: `scripts/modules/FingerprintDetector.psm1`
   - Functions: `Get-FingerprintDatabase`, `Find-SpecKitVersionByFingerprint`

2. Implement signature check (3 files)
   - Fast path for 95%+ of cases

3. Implement full fingerprint check (12 files)
   - Fallback for edge cases

4. Implement confidence scoring
   - High/Medium/Low thresholds

5. Write unit tests
   - File: `tests/unit/FingerprintDetector.Tests.ps1`
   - Test all confidence levels

**Deliverables**:
- Detection module with 95%+ accuracy
- 20+ unit tests
- Performance benchmarks

**Estimate**: 6 hours

---

### Phase 3: Smart Merge Engine (Week 2)

**Tasks**:
1. Create MarkdownMerger module
   - File: `scripts/modules/MarkdownMerger.psm1`
   - Functions: `Invoke-ThreeWayMarkdownMerge`, `Get-MarkdownSections`, etc.

2. Implement section parsing
   - Use `ConvertFrom-Markdown` AST

3. Implement fuzzy matching
   - Levenshtein distance for header matching
   - 80% similarity threshold

4. Implement customization detection
   - Line-based diff within sections

5. Implement auto-merge logic
   - Combine compatible changes

6. Implement conflict marker generation
   - Granular, section-level markers

7. Write unit tests
   - File: `tests/unit/MarkdownMerger.Tests.ps1`
   - Test all merge scenarios

**Deliverables**:
- Merge engine with 90%+ auto-merge rate
- 30+ unit tests
- Edge case handling

**Estimate**: 12 hours

---

### Phase 4: GitHub API Enhancement (Week 2)

**Tasks**:
1. Add archive download function
   - Function: `Get-SpecKitArchive`
   - Caching logic

2. Add file extraction helper
   - Function: `Get-FileFromArchive`
   - Single-file extraction

3. Write unit tests
   - Mock GitHub API responses

**Deliverables**:
- Enhanced GitHubApiClient module
- Archive caching
- 10+ unit tests

**Estimate**: 3 hours

---

### Phase 5: Orchestrator Integration (Week 3)

**Tasks**:
1. Update manifest loading logic
   - Call version detection
   - Handle confidence levels
   - Conversational workflow markers

2. Update conflict resolution
   - Call smart merge for markdown files
   - Download archives
   - Write merged results

3. Update module imports
   - Add FingerprintDetector, MarkdownMerger to tier 0

4. Write integration tests
   - File: `tests/integration/SmartMerge.Tests.ps1`
   - End-to-end scenarios

**Deliverables**:
- Fully integrated orchestrator
- 15+ integration tests
- Manual test scenarios validated

**Estimate**: 8 hours

---

### Phase 6: Testing & Validation (Week 3)

**Tasks**:
1. Run existing test suite
   - Ensure no regressions

2. Manual testing scenarios
   - First-time user on v0.0.76
   - Heavily customized project
   - Old version (v0.0.60)
   - Undetectable version

3. Performance testing
   - Detection speed (<100ms)
   - Merge speed with large files

4. Edge case validation
   - Malformed markdown
   - Binary files with .md extension
   - Missing sections

**Deliverables**:
- All tests passing
- Manual test checklist completed
- Performance benchmarks met

**Estimate**: 6 hours

---

### Phase 7: Documentation (Week 4)

**Tasks**:
1. User documentation
   - File: `docs/smart-merge-guide.md`
   - How smart merge works
   - Interpreting conflict markers
   - Troubleshooting

2. Onboarding guide
   - File: `docs/onboarding-first-update.md`
   - What to expect on first update
   - Version detection explained

3. Architecture documentation
   - File: `docs/architecture/fingerprint-database.md`
   - File: `docs/architecture/merge-algorithm.md`

4. Update CLAUDE.md
   - Add smart merge section
   - Update workflow diagrams

5. Update README.md
   - Highlight frictionless onboarding
   - Link to new docs

6. Update CHANGELOG.md
   - Document new feature

**Deliverables**:
- Comprehensive documentation
- Updated project docs

**Estimate**: 5 hours

---

### Phase 8: Release Preparation (Week 4)

**Tasks**:
1. Update version to v0.5.0
   - File: `version.txt` or similar

2. Create release notes
   - Highlight key benefits
   - Migration guide (none needed)

3. Create demo video/GIF
   - Show before/after experience

4. Prepare announcement
   - GitHub discussion post
   - Social media if applicable

**Deliverables**:
- Release-ready package
- Marketing materials

**Estimate**: 2 hours

---

## Total Implementation Estimate

| Phase | Hours | Dependencies |
|-------|-------|--------------|
| 1. Infrastructure | 4 | None |
| 2. Version Detection | 6 | Phase 1 |
| 3. Smart Merge | 12 | Phase 2 |
| 4. GitHub API | 3 | None (parallel) |
| 5. Integration | 8 | Phases 2, 3, 4 |
| 6. Testing | 6 | Phase 5 |
| 7. Documentation | 5 | Phase 6 |
| 8. Release Prep | 2 | Phase 7 |
| **Total** | **46 hours** | ~2 weeks for 1 developer |

**Critical Path**: Phases 1 → 2 → 3 → 5 → 6 → 7 → 8

**Parallel Work**: Phase 4 can be done alongside Phase 3

---

## Risks & Mitigation

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **ConvertFrom-Markdown parsing fails** | High | Low | Graceful fallback to line-based merge |
| **Fuzzy matching mis-identifies sections** | Medium | Medium | Tune threshold (80% → 85%), extensive testing |
| **Auto-merge introduces errors** | High | Low | Conservative merge criteria, extensive tests |
| **Fingerprint database becomes stale** | Medium | Low | GitHub Action automation, alerts on failures |
| **Detection false positives** | Medium | Medium | Medium confidence → conversational confirmation |

### Operational Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **GitHub Action fails** | Low | Medium | Alerts, manual fallback, documented process |
| **SpecKit changes file structure** | High | Low | Update tracked files list, regenerate database |
| **Fingerprint collisions** | Low | Very Low | SHA-256 has negligible collision probability |
| **User confusion with new workflow** | Medium | Medium | Clear documentation, conversational fallbacks |

### Mitigation Strategies

1. **Extensive Testing**: 40+ unit tests, 15+ integration tests
2. **Fallback Mechanisms**: Traditional merge if detection fails
3. **Conversational Workflows**: Medium/low confidence → user confirmation
4. **Monitoring**: GitHub Action alerts if fingerprint update fails
5. **Documentation**: Comprehensive guides for users and maintainers

---

## Open Questions

### Technical Decisions

1. **Fuzzy matching threshold**: Use 80% or 85% similarity for section matching?
   - **Recommendation**: Start with 80%, tune based on false positive rate

2. **Embedded fallback**: If we later move to remote hosting, how many versions to embed?
   - **Recommendation**: N/A (using repo-based, but keep 5-version design ready)

3. **Auto-merge criteria**: How conservative should auto-merge logic be?
   - **Recommendation**: Conservative initially (reject ambiguous cases), relax based on data

4. **Cache retention**: How long to cache downloaded archives?
   - **Recommendation**: Cache for session duration, clean up after update

### Process Questions

5. **Release strategy**: Beta release first, or direct to stable?
   - **Recommendation**: Beta (v0.5.0-beta) for 1 week, gather feedback, then stable

6. **Telemetry**: Should we collect anonymous usage metrics?
   - **Recommendation**: Optional, opt-in, document clearly

7. **Backward compatibility**: Support rollback to old detection method?
   - **Recommendation**: Not needed (new system is strict superset)

---

## Success Criteria for Launch

### Must-Have (Blockers)

- ✅ Fingerprint database generated for all 77 versions
- ✅ Version detection achieves 95%+ accuracy on test set
- ✅ Smart merge auto-resolves 90%+ of files on test set
- ✅ GitHub Action successfully updates database
- ✅ All unit tests passing (40+)
- ✅ All integration tests passing (15+)
- ✅ Constitution auto-merges in 90%+ of test cases
- ✅ Documentation complete (user + developer guides)
- ✅ Manual testing completed for all scenarios
- ✅ No regressions in existing functionality

### Nice-to-Have (Post-Launch)

- Performance benchmarks published
- Demo video showing before/after experience
- User survey for feedback collection
- Telemetry framework (opt-in)
- Automated regression testing in CI

---

## Post-Launch Plan

### Week 1-2: Monitoring

- Monitor GitHub issues for onboarding-related problems
- Track GitHub Action execution (fingerprint updates)
- Collect user feedback via surveys/discussions

### Week 3-4: Iteration

- Analyze feedback, identify issues
- Tune fuzzy matching threshold if needed
- Fix bugs reported by early adopters
- Release v0.5.1 with improvements

### Month 2-3: Optimization

- Performance profiling and optimization
- Enhanced auto-merge heuristics based on real-world data
- Expand fingerprint database if older versions needed
- Consider telemetry implementation

---

## Appendix

### Alternative Approaches Considered

#### 1. Git-Based Version Detection
**Approach**: Use `git log` to find when SpecKit files were added/modified

**Rejected Because**:
- Requires clean git history (many users don't commit incrementally)
- Doesn't work if user committed after customization
- Unreliable for mixed version states

#### 2. Manifest Marker in SpecKit Templates
**Approach**: SpecKit embeds version in template files (e.g., `<!-- SpecKit v0.0.76 -->`)

**Rejected Because**:
- Requires changes to SpecKit itself (out of our control)
- Doesn't solve existing installations (no marker)
- Breaks if user edits files

#### 3. Two-Way Merge (Current vs Incoming Only)
**Approach**: Skip version detection, just merge current vs incoming

**Rejected Because**:
- Can't distinguish customization from original
- Every difference triggers conflict
- No better than current behavior

#### 4. User-Specified Version
**Approach**: Prompt user "What version are you on?"

**Rejected Because**:
- Most users don't know their version
- Violates "frictionless" goal
- Error-prone (user guesses wrong)

### References

- [GitHub Issue #25](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/25)
- [SpecKit Repository](https://github.com/github/spec-kit)
- [ConvertFrom-Markdown Documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertfrom-markdown)
- [Levenshtein Distance Algorithm](https://en.wikipedia.org/wiki/Levenshtein_distance)

---

**End of PRD**
