#!/bin/bash

# Settings loader for Claudisms plugin
# Loads settings from .claudisms-settings file in plugin root

# Locate settings file
SETTINGS_FILE="${CLAUDE_PLUGIN_ROOT}/.claudisms-settings"

# Valid setting values for each type
declare -A VALID_VALUES
VALID_VALUES[terse_mode]="on off"
VALID_VALUES[doc_limits]="on off exclude"
VALID_VALUES[destructive_guard]="on off exclude"
VALID_VALUES[sequential_only]="on off"
VALID_VALUES[tmp_location]="pwd system"
VALID_VALUES[debug_logging]="on off"

# Validate setting value
# Usage: validate_setting_value "terse_mode" "on"
# Returns: 0 if valid, 1 if invalid
validate_setting_value() {
  local key="$1"
  local value="$2"

  # If key is excluded_files, always valid (comma-separated patterns)
  [[ "$key" == "excluded_files" ]] && return 0

  # Check if key has defined valid values
  if [[ -z "${VALID_VALUES[$key]}" ]]; then
    return 1  # Unknown setting
  fi

  # Check if value is in valid list
  if [[ " ${VALID_VALUES[$key]} " =~ " ${value} " ]]; then
    return 0
  else
    return 1
  fi
}

# Default settings (used when settings file is missing or incomplete)
declare -A DEFAULT_SETTINGS
DEFAULT_SETTINGS[terse_mode]="on"
DEFAULT_SETTINGS[doc_limits]="off"
DEFAULT_SETTINGS[destructive_guard]="on"
DEFAULT_SETTINGS[sequential_only]="on"
DEFAULT_SETTINGS[tmp_location]="pwd"
DEFAULT_SETTINGS[debug_logging]="off"
DEFAULT_SETTINGS[excluded_files]="CLAUDE.md,claude.md"

# Load all settings into environment if file exists
if [[ -f "$SETTINGS_FILE" ]]; then
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue

    # Trim whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # Validate setting value
    if ! validate_setting_value "$key" "$value"; then
      # Skip invalid settings silently or log if debug enabled
      if [[ "$value" == "on" ]] && [[ -n "${VALID_VALUES[$key]}" ]]; then
        # Debug mode might not be set yet, skip warning
        :
      fi
      continue
    fi

    # Export setting (don't overwrite existing environment variables)
    var_name="CLAUDISMS_${key}"
    export "${var_name}=${!var_name:-${value}}"
  done < "$SETTINGS_FILE"
else
  # Settings file missing - use defaults (don't overwrite existing environment variables)
  for key in "${!DEFAULT_SETTINGS[@]}"; do
    var_name="CLAUDISMS_${key}"
    export "${var_name}=${!var_name:-${DEFAULT_SETTINGS[$key]}}"
  done
fi

# Get setting value by key
# Usage: get_setting "terse_mode"
# Returns: setting value or empty string
get_setting() {
  local key="$1"
  local var_name="CLAUDISMS_${key}"
  echo "${!var_name}"
}

# Get all settings as key=value pairs
# Usage: get_all_settings
# Returns: all loaded settings in key=value format
get_all_settings() {
  env | grep '^CLAUDISMS_' | sed 's/CLAUDISMS_//'
}

# Get tmp location based on settings
# Returns: tmp directory path (creates if needed)
get_tmp_location() {
  local setting=$(get_setting "tmp_location")

  if [[ "$setting" == "system" ]]; then
    echo "/tmp"
  else
    # Default: pwd/tmp
    local pwd_tmp="${PWD}/tmp"
    mkdir -p "$pwd_tmp" 2>/dev/null
    echo "$pwd_tmp"
  fi
}

# Check if file path matches exclusion patterns
# Usage: is_file_excluded "/path/to/file.md"
# Returns: 0 (true) if excluded, 1 (false) if not excluded
is_file_excluded() {
  local file_path="$1"
  local excluded_files=$(get_setting "excluded_files")

  # If no exclusions defined, nothing is excluded
  [[ -z "$excluded_files" ]] && return 1

  # Split by comma and check each pattern
  IFS=',' read -ra PATTERNS <<< "$excluded_files"
  for pattern in "${PATTERNS[@]}"; do
    # Trim whitespace
    pattern=$(echo "$pattern" | xargs)

    # Simple pattern matching - convert glob to regex-like matching
    # **/* becomes .*
    # * becomes [^/]*
    # Exact match for simple filenames

    if [[ "$pattern" == *"**"* ]]; then
      # Handle **/* patterns - match anywhere in path
      local regex_pattern="${pattern//\*\*/.*}"
      regex_pattern="${regex_pattern//\*/[^/]*}"
      if [[ "$file_path" =~ $regex_pattern ]]; then
        return 0
      fi
    elif [[ "$pattern" == *"*"* ]]; then
      # Handle * patterns - use bash pattern matching
      if [[ "$file_path" == *${pattern}* ]]; then
        return 0
      fi
    else
      # Exact filename match (check if path ends with pattern)
      if [[ "$file_path" == *"$pattern" ]]; then
        return 0
      fi
    fi
  done

  return 1
}
