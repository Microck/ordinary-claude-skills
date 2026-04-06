#!/bin/bash

# Claudisms Settings Manager
# Slash command for managing Claudisms plugin settings

# Locate plugin root (prefer installed marketplace location)
if [[ -d ~/.claude/plugins/marketplaces/claudisms ]]; then
  CLAUDE_PLUGIN_ROOT=~/.claude/plugins/marketplaces/claudisms
elif [[ -z "${CLAUDE_PLUGIN_ROOT}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CLAUDE_PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
fi

# Locate settings file
SETTINGS_FILE="${CLAUDE_PLUGIN_ROOT}/.claudisms-settings"
LIB_DIR="${CLAUDE_PLUGIN_ROOT}/lib"

# Source settings loader for validation functions
if [[ -f "${LIB_DIR}/settings-loader.sh" ]]; then
  source "${LIB_DIR}/settings-loader.sh"
else
  echo "Error: settings-loader.sh not found in ${LIB_DIR}"
  exit 1
fi

# Valid setting names
VALID_SETTINGS="terse_mode doc_limits destructive_guard sequential_only tmp_location debug_logging excluded_files"

# Show help
show_help() {
  cat << 'EOF'
Claudisms Settings Manager

Usage:
  /claudisms-settings                    Show current settings
  /claudisms-settings set <key> <value>  Set a setting
  /claudisms-settings exclude <pattern>  Add file exclusion pattern
  /claudisms-settings include <pattern>  Remove file exclusion pattern
  /claudisms-settings help               Show this help

Settings:
  terse_mode         on|off           Enable terse responses (1-2 sentences)
  doc_limits         on|off|exclude   Limit .md files to 200 words
  destructive_guard  on|off|exclude   Block destructive operations
  sequential_only    on|off           Enforce sequential execution
  tmp_location       pwd|system       Temp directory location
  debug_logging      on|off           Enable debug logging

File Exclusions:
  excluded_files     Comma-separated  Patterns to exclude from rules

Examples:
  /claudisms-settings set terse_mode off
  /claudisms-settings set doc_limits exclude
  /claudisms-settings exclude "**/*PLANNING*.md"
  /claudisms-settings include CLAUDE.md
  /claudisms-settings set tmp_location pwd

Patterns:
  CLAUDE.md          Exact filename match
  *.md               Wildcard match
  **/*PLANNING*.md   Recursive glob match
EOF
}

# Show current settings
show_settings() {
  echo "Current Claudisms Settings:"
  echo "============================"
  echo ""

  if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "Settings file: ${SETTINGS_FILE}"
    echo "Status: Not found (using defaults)"
    echo ""
    echo "Defaults:"
    echo "  terse_mode         = on"
    echo "  doc_limits         = on"
    echo "  destructive_guard  = on"
    echo "  sequential_only    = on"
    echo "  tmp_location       = pwd"
    echo "  debug_logging      = off"
    echo "  excluded_files     = CLAUDE.md,claude.md"
    echo ""
    echo "Use '/claudisms-settings set <key> <value>' to create settings file"
    return
  fi

  # Read and display settings with descriptions
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue

    # Trim whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # Display with formatting
    printf "  %-20s = %s\n" "$key" "$value"
  done < "$SETTINGS_FILE"

  echo ""
  echo "Settings file: ${SETTINGS_FILE}"
  echo "Use '/claudisms-settings help' for usage information"
}

# Set a setting value
set_setting() {
  local key="$1"
  local value="$2"

  # Validate key
  if [[ ! " $VALID_SETTINGS " =~ " $key " ]]; then
    echo "Error: Invalid setting name: $key"
    echo "Valid settings: $VALID_SETTINGS"
    return 1
  fi

  # Validate value (except for excluded_files which has custom validation)
  if [[ "$key" != "excluded_files" ]]; then
    if ! validate_setting_value "$key" "$value"; then
      echo "Error: Invalid value '$value' for setting '$key'"
      echo "Valid values: ${VALID_VALUES[$key]}"
      return 1
    fi
  fi

  # Create settings file if it doesn't exist
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "Creating new settings file: $SETTINGS_FILE"
    cat > "$SETTINGS_FILE" << 'EOSETTINGS'
# Claudisms Plugin Settings
# Format: key=value (no spaces around =)

# Rule Groups (on|off|exclude)
terse_mode=on
doc_limits=on
destructive_guard=on
sequential_only=on

# File Exclusions (comma-separated patterns)
excluded_files=CLAUDE.md,claude.md

# Temp Directory
tmp_location=pwd

# Debug Logging
debug_logging=off
EOSETTINGS
  fi

  # Atomic update: write to temp file, then move
  local temp_file="${SETTINGS_FILE}.tmp.$$"
  local found=0

  # Update or add setting
  while IFS= read -r line; do
    # Check if this is the line to update
    if [[ "$line" =~ ^[[:space:]]*${key}[[:space:]]*= ]]; then
      echo "${key}=${value}"
      found=1
    else
      echo "$line"
    fi
  done < "$SETTINGS_FILE" > "$temp_file"

  # If setting wasn't found, append it
  if [[ $found -eq 0 ]]; then
    echo "${key}=${value}" >> "$temp_file"
  fi

  # Atomic move
  mv "$temp_file" "$SETTINGS_FILE"

  echo "Setting updated: ${key}=${value}"
  echo "Reload settings with: /claudisms-reload"
}

# Add exclusion pattern
add_exclusion() {
  local pattern="$1"

  if [[ -z "$pattern" ]]; then
    echo "Error: Pattern cannot be empty"
    return 1
  fi

  # Get current exclusions
  local current_exclusions=$(grep "^excluded_files=" "$SETTINGS_FILE" 2>/dev/null | cut -d= -f2)

  # Check if pattern already exists
  if [[ ",$current_exclusions," =~ ,${pattern}, ]]; then
    echo "Pattern already excluded: $pattern"
    return 0
  fi

  # Add pattern
  local new_exclusions="${current_exclusions},${pattern}"
  new_exclusions="${new_exclusions#,}"  # Remove leading comma if exists

  set_setting "excluded_files" "$new_exclusions"
  echo "Added exclusion: $pattern"
}

# Remove exclusion pattern
remove_exclusion() {
  local pattern="$1"

  if [[ -z "$pattern" ]]; then
    echo "Error: Pattern cannot be empty"
    return 1
  fi

  # Get current exclusions
  local current_exclusions=$(grep "^excluded_files=" "$SETTINGS_FILE" 2>/dev/null | cut -d= -f2)

  # Check if pattern exists (using literal string matching)
  if [[ ",${current_exclusions}," != *",${pattern},"* ]]; then
    echo "Pattern not found in exclusions: $pattern"
    echo "Current exclusions: $current_exclusions"
    return 1
  fi

  # Remove pattern by rebuilding the list
  local new_exclusions=""
  IFS=',' read -ra PATTERNS <<< "$current_exclusions"
  for p in "${PATTERNS[@]}"; do
    if [[ "$p" != "$pattern" ]]; then
      if [[ -n "$new_exclusions" ]]; then
        new_exclusions="${new_exclusions},${p}"
      else
        new_exclusions="$p"
      fi
    fi
  done

  set_setting "excluded_files" "$new_exclusions"
  echo "Removed exclusion: $pattern"
}

# Main command dispatcher
main() {
  local command="${1:-show}"

  case "$command" in
    help|--help|-h)
      show_help
      ;;
    set)
      if [[ -z "$2" ]] || [[ -z "$3" ]]; then
        echo "Error: Usage: /claudisms-settings set <key> <value>"
        exit 1
      fi
      set_setting "$2" "$3"
      ;;
    exclude)
      if [[ -z "$2" ]]; then
        echo "Error: Usage: /claudisms-settings exclude <pattern>"
        exit 1
      fi
      add_exclusion "$2"
      ;;
    include)
      if [[ -z "$2" ]]; then
        echo "Error: Usage: /claudisms-settings include <pattern>"
        exit 1
      fi
      remove_exclusion "$2"
      ;;
    show|"")
      show_settings
      ;;
    *)
      echo "Error: Unknown command: $command"
      echo "Use '/claudisms-settings help' for usage information"
      exit 1
      ;;
  esac
}

# Execute main
main "$@"
