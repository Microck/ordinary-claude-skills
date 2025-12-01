#!/bin/bash

# Claudisms Settings Reload
# Reloads settings without restarting Claude Code session

# Locate plugin root (prefer installed marketplace location)
if [[ -d ~/.claude/plugins/marketplaces/claudisms ]]; then
  CLAUDE_PLUGIN_ROOT=~/.claude/plugins/marketplaces/claudisms
elif [[ -z "${CLAUDE_PLUGIN_ROOT}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CLAUDE_PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
fi

# Locate settings file and library
SETTINGS_FILE="${CLAUDE_PLUGIN_ROOT}/.claudisms-settings"
LIB_DIR="${CLAUDE_PLUGIN_ROOT}/lib"

echo "Reloading Claudisms settings..."
echo ""

# Check if settings file exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "Warning: Settings file not found: $SETTINGS_FILE"
  echo "Using default settings."
  echo ""
fi

# Re-source settings loader
if [[ -f "${LIB_DIR}/settings-loader.sh" ]]; then
  # Clear existing CLAUDISMS_* environment variables
  unset $(env | grep '^CLAUDISMS_' | cut -d= -f1)

  # Reload settings
  source "${LIB_DIR}/settings-loader.sh"

  echo "Settings reloaded successfully!"
  echo ""

  # Show loaded settings
  echo "Current Settings:"
  echo "================="
  env | grep '^CLAUDISMS_' | sed 's/CLAUDISMS_//' | sort
  echo ""
  echo "Settings are now active in this session."
else
  echo "Error: settings-loader.sh not found in ${LIB_DIR}"
  exit 1
fi
