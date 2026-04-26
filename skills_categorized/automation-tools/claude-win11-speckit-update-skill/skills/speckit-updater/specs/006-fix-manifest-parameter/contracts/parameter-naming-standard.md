# Parameter Naming Standard

**Version**: 1.0.0
**Effective Date**: 2025-10-20
**Status**: Active
**Applies To**: All PowerShell modules, scripts, and helpers in the SpecKit Safe Update Skill

## Purpose

This document defines the canonical parameter naming conventions for the SpecKit Safe Update Skill codebase. All functions MUST follow this standard to ensure consistency, readability, and maintainability.

## Guiding Principles

1. **Consistency**: Same concept = same parameter name everywhere
2. **Clarity**: Parameter name clearly indicates purpose
3. **PowerShell Convention**: Follow established PowerShell ecosystem patterns
4. **No Abbreviations**: Use full words unless extremely common (e.g., `Id`, `Url`)
5. **PascalCase**: All parameters use PascalCase (e.g., `-FilePath`, not `-file_path`)

## General Naming Rules

### Case Style
**Rule**: All parameters MUST use **PascalCase**.

**Examples**:
- ✅ `-FilePath`
- ✅ `-ProjectRoot`
- ✅ `-AssumeAllCustomized`
- ❌ `-filePath` (camelCase)
- ❌ `-file_path` (snake_case)
- ❌ `-FILEPATH` (UPPERCASE)

### Singular vs Plural
**Rule**: Prefer singular nouns UNLESS the parameter accepts a collection and plurality is semantically important.

**Examples**:
- ✅ `-Path` (single path)
- ✅ `-Paths` (array of paths - plurality important)
- ✅ `-File` (single file)
- ❌ `-Files` (if parameter only accepts one file)

### Abbreviations
**Rule**: Avoid abbreviations EXCEPT for extremely common terms.

**Allowed Abbreviations**:
- `Id` (identifier)
- `Url` (uniform resource locator)
- `Json` (JavaScript Object Notation)
- `Xml` (Extensible Markup Language)
- `Html` (HyperText Markup Language)
- `Uri` (Uniform Resource Identifier)

**Examples**:
- ✅ `-ManifestPath` (not `-MnfstPath`)
- ✅ `-BackupDirectory` (not `-BkpDir`)
- ✅ `-UserId` (`Id` is allowed abbreviation)
- ❌ `-Usr` (should be `-User`)
- ❌ `-Cfg` (should be `-Configuration`)

### Approved Verbs
**Rule**: Function names MUST use PowerShell approved verbs. Parameter names should align with function verbs when applicable.

**Common Approved Verbs**:
- `Get-` - retrieve data
- `Set-` - establish data
- `New-` - create something
- `Remove-` - delete something
- `Invoke-` - perform an action
- `Test-` - verify a condition
- `Update-` - refresh or modify
- `Add-` - append to collection
- `Clear-` - remove all items

**Reference**: [PowerShell Approved Verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)

## Canonical Parameter Names

### Core Parameters (SpecKit Domain)

#### -Version
**Type**: `string`
**Description**: SpecKit semantic version (e.g., "v0.0.72")
**Usage**: Specify which SpecKit release version to use
**Deprecated Names**: `SpecKitVersion`, `ReleaseVersion`, `Tag`
**Examples**:
```powershell
Get-SpecKitRelease -Version "v0.0.72"
New-SpecKitManifest -Version $targetRelease.tag_name
Download-SpecKitTemplates -Version "v0.0.72"
```

#### -ProjectRoot
**Type**: `string`
**Description**: Root directory of the SpecKit project (where `.specify/` folder exists)
**Usage**: Specify the project's root directory
**Deprecated Names**: `RootPath`, `Root`, `ProjectPath`
**Examples**:
```powershell
New-SpecKitManifest -ProjectRoot "C:\Users\bobby\my-project"
Get-Manifest -ProjectRoot $projectRoot
```

#### -ManifestPath
**Type**: `string`
**Description**: Full path to `.specify/manifest.json` file
**Usage**: Explicitly specify manifest file location
**Deprecated Names**: `Manifest`, `ManifestFile`
**Examples**:
```powershell
Get-Manifest -ManifestPath "C:\Users\bobby\my-project\.specify\manifest.json"
Save-Manifest -ManifestPath $manifestPath -Manifest $manifestObject
```

#### -BackupPath
**Type**: `string`
**Description**: Path to backup directory (typically `.specify/backups/YYYY-MM-DD_HH-MM-SS/`)
**Usage**: Specify backup location for restore operations
**Deprecated Names**: `Backup`, `BackupDir`, `BackupDirectory`
**Examples**:
```powershell
Restore-Backup -BackupPath ".specify/backups/2025-01-20_15-30-00"
```

### File System Parameters

#### -Path
**Type**: `string`
**Description**: Generic file or directory path
**Usage**: General-purpose path parameter when no ambiguity exists
**Deprecated Names**: None
**Examples**:
```powershell
Get-NormalizedHash -Path "README.md"
Test-Path -Path $filePath
```

#### -FilePath
**Type**: `string`
**Description**: Specific file path (use when ambiguity between file/directory exists)
**Usage**: Explicitly indicate a file path
**Deprecated Names**: `File`, `FileName`
**Examples**:
```powershell
Get-Content -FilePath "manifest.json"
Get-NormalizedHash -FilePath $templateFile
```

#### -DirectoryPath
**Type**: `string`
**Description**: Directory path (use when ambiguity between file/directory exists)
**Usage**: Explicitly indicate a directory path
**Deprecated Names**: `Directory`, `Dir`, `Folder`
**Examples**:
```powershell
Get-ChildItem -DirectoryPath ".specify/backups"
```

### Operational Parameters (Skill-Specific)

#### -CheckOnly
**Type**: `switch`
**Description**: Run in dry-run mode without making changes (show preview only)
**Usage**: Enable check/preview mode in update orchestrator
**Deprecated Names**: `DryRun`, `Preview`, `WhatIf` (reserved for PowerShell common parameter)
**Examples**:
```powershell
& update-orchestrator.ps1 -CheckOnly
```

#### -AssumeAllCustomized
**Type**: `switch`
**Description**: Treat all files as customized when creating new manifest (prevent overwrites)
**Usage**: Safe default for first-time manifest creation
**Deprecated Names**: `AllCustomized`, `AssumeCustomized`
**Examples**:
```powershell
New-SpecKitManifest -ProjectRoot $root -Version $version -AssumeAllCustomized
```

#### -Rollback
**Type**: `switch`
**Description**: Trigger rollback to most recent backup
**Usage**: Restore project to previous state
**Deprecated Names**: `Restore`, `Undo`
**Examples**:
```powershell
& update-orchestrator.ps1 -Rollback
```

#### -Force
**Type**: `switch`
**Description**: Bypass confirmations and overwrite warnings
**Usage**: Automated/scripted execution without prompts
**Deprecated Names**: `SkipConfirmation`, `Yes`
**Examples**:
```powershell
& update-orchestrator.ps1 -Force
```

### PowerShell Common Parameters

**Rule**: Do NOT redefine PowerShell common parameters. These are automatically available when using `[CmdletBinding()]`.

**Built-in Common Parameters**:
- `-Verbose` - Enable verbose output
- `-Debug` - Enable debug output
- `-ErrorAction` - Control error handling behavior
- `-WarningAction` - Control warning display
- `-InformationAction` - Control information message display
- `-ErrorVariable` - Store errors in variable
- `-WarningVariable` - Store warnings in variable
- `-OutVariable` - Store output in variable
- `-OutBuffer` - Set output buffer size
- `-WhatIf` - Show what would happen without executing
- `-Confirm` - Prompt for confirmation before executing

**Reference**: [PowerShell Common Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters)

## Module-Specific Parameters

### HashUtils Module

- `-Path` (string) - File path to hash
- `-Content` (string) - Direct content to hash (alternative to `-Path`)

### GitHubApiClient Module

- `-Version` (string) - SpecKit version to fetch
- `-ProjectRoot` (string) - Where to extract templates
- `-OutputPath` (string) - Where to save downloaded files

### ManifestManager Module

- `-ProjectRoot` (string) - Project root directory
- `-ManifestPath` (string) - Explicit manifest file path
- `-Version` (string) - SpecKit version for manifest
- `-AssumeAllCustomized` (switch) - Mark all files as customized
- `-Manifest` (PSCustomObject) - Manifest object to save

### BackupManager Module

- `-ProjectRoot` (string) - Project root directory
- `-BackupPath` (string) - Backup directory path
- `-FromVersion` (string) - Version being updated from
- `-ToVersion` (string) - Version being updated to

### ConflictDetector Module

- `-ProjectRoot` (string) - Project root directory
- `-Manifest` (PSCustomObject) - Current manifest object
- `-UpstreamFiles` (hashtable) - Upstream template file states

### VSCodeIntegration Module

- `-BasePath` (string) - Path to base/original file (3-way merge)
- `-CurrentPath` (string) - Path to current/local file (3-way merge)
- `-IncomingPath` (string) - Path to incoming/upstream file (3-way merge)
- `-MergedPath` (string) - Path where merged result should be saved

## Deprecation Process

When a parameter name is deprecated:

1. **Document in this standard**: Add deprecated name to `Deprecated Names` list
2. **Update code**: Refactor all usages to canonical name
3. **Update tests**: Verify all tests use canonical name
4. **Update documentation**: Update comment-based help
5. **Run audit**: Verify zero occurrences of deprecated name remain

**Do NOT**:
- Add parameter aliases for backward compatibility (internal API only)
- Support both old and new names (creates confusion)

## Validation

All code MUST pass the automated parameter audit tool before being merged. The audit tool verifies:

1. All function parameters use canonical names from this standard
2. All function call sites use correct parameter names
3. All comment-based help (`.PARAMETER`) uses canonical names
4. All verbose/error messages reference correct variable names
5. No deprecated parameter names exist in codebase

**Audit Tool Command**:
```powershell
& scripts/tools/audit-parameters.ps1 -FailOnViolations
```

**Expected Output**:
```
Parameter Audit Report
======================
Files Scanned: 15
Functions Analyzed: 87
Parameters Checked: 234
Violations Found: 0
Compliance Rate: 100%

✅ PASS - All parameters comply with naming standard
```

## Amendment Process

To propose changes to this standard:

1. **Create GitHub issue** with rationale for change
2. **Discuss with maintainers** to reach consensus
3. **Update this document** with new version number
4. **Update audit tool** to enforce new rules (if applicable)
5. **Update codebase** to comply with amended standard
6. **Update CHANGELOG.md** with amendment details

**Versioning**:
- **MAJOR** (X.0.0): Backward-incompatible changes (renames, deletions)
- **MINOR** (x.Y.0): New canonical names added
- **PATCH** (x.y.Z): Clarifications, typos, documentation improvements

## Compliance Checklist

Before merging code, verify:

- [ ] All new/modified function parameters use canonical names from this standard
- [ ] All new/modified function calls use correct parameter names
- [ ] Comment-based help (`.PARAMETER`) updated for all refactored parameters
- [ ] Verbose/error messages use correct variable names
- [ ] Automated parameter audit tool passes (`audit-parameters.ps1`)
- [ ] All unit tests updated for parameter changes
- [ ] All integration tests pass

## References

- [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [PowerShell Approved Verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- [PowerShell Common Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters)
- [Constitution - PowerShell Standards](../../.specify/memory/constitution.md#powershell-standards)

---

**Document History**:
- **v1.0.0** (2025-10-20): Initial version - established canonical names for all core parameters
