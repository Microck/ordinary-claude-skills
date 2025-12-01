# Claudisms Library Functions

## settings-loader.sh

### validate_setting_value(key, value)
Validates a setting value against allowed values.

**Returns:**
- 0 if valid
- 1 if invalid

**Example:**
```bash
validate_setting_value "terse_mode" "on"  # returns 0 (valid)
validate_setting_value "terse_mode" "foo" # returns 1 (invalid)
```

### get_setting(key)
Gets a setting value by key.

**Returns:** Setting value or empty string

**Example:**
```bash
value=$(get_setting "terse_mode")  # returns "on" or "off"
```

### get_all_settings()
Exports all loaded settings in key=value format.

**Returns:** All settings, one per line

**Example:**
```bash
get_all_settings
# Output:
# terse_mode=on
# doc_limits=on
# excluded_files=CLAUDE.md,claude.md
```

### get_tmp_location()
Gets the tmp directory path based on settings.

**Returns:** Absolute path to tmp directory

**Example:**
```bash
tmp=$(get_tmp_location)  # returns /path/to/project/tmp or /tmp
```

### is_file_excluded(file_path)
Checks if a file path matches exclusion patterns from settings.

**Returns:**
- 0 if excluded
- 1 if not excluded

**Example:**
```bash
if is_file_excluded "/home/user/CLAUDE.md"; then
  echo "File is excluded"
fi
```

## file-matcher.sh

### match_pattern(file_path, pattern)
Matches a file path against a single pattern.

**Supports:**
- Exact matches: `CLAUDE.md`
- Wildcards: `*.md`, `test-?.sh`
- Glob patterns: `**/*PLANNING*.md`
- Case-insensitive for .md files

**Returns:**
- 0 if matches
- 1 if no match

**Example:**
```bash
match_pattern "/home/user/file.md" "*.md"  # returns 0 (matches)
```

### match_any_pattern(file_path, patterns)
Matches a file path against comma-separated patterns.

**Returns:**
- 0 if matches any pattern
- 1 if no match

**Example:**
```bash
match_any_pattern "/home/user/CLAUDE.md" "CLAUDE.md,README.md,*.txt"
# returns 0 (matches)
```

### validate_pattern(pattern)
Validates a pattern syntax.

**Returns:**
- 0 if valid
- 1 if invalid

**Example:**
```bash
validate_pattern "*.md"      # returns 0 (valid)
validate_pattern "/bad/path" # returns 1 (invalid - starts with /)
```

## Usage in Hook Handlers

```bash
#!/bin/bash

# Load settings library
source "${CLAUDE_PLUGIN_ROOT}/lib/settings-loader.sh"

# Optional: Load file-matcher library if needed
source "${CLAUDE_PLUGIN_ROOT}/lib/file-matcher.sh"

# Get tmp location for debug logs
TMP_DIR=$(get_tmp_location)

# Check if file is excluded
if is_file_excluded "$CLAUDE_TOOL_PARAMETER_file_path"; then
  exit 0  # Silent exit
fi

# Check setting value
if [[ "$(get_setting 'doc_limits')" == "off" ]]; then
  exit 0  # Silent exit
fi

# Continue with hook logic...
```
