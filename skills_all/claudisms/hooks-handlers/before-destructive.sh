#!/bin/bash

# Claudisms PreToolUse Hook: before-destructive.sh
# Guards against destructive operations based on destructive_guard setting
# Modes: on (block all), off (allow all), exclude (allow refactoring, block git push/DB drops)

# Load settings
source "${CLAUDE_PLUGIN_ROOT}/lib/settings-loader.sh"

# Get destructive guard setting
GUARD_MODE=$(get_setting "destructive_guard")

# If destructive guard is off, allow all operations
if [[ "$GUARD_MODE" == "off" ]]; then
  exit 0
fi

# Get tmp location for logging
TMP_DIR=$(get_tmp_location)

# Log environment for debugging (if debug enabled)
if [[ "$(get_setting "debug_logging")" == "on" ]]; then
  env > "${TMP_DIR}/hook-destructive-$$.log"
fi

# Detect operation type from tool and parameters
TOOL_NAME="${CLAUDE_TOOL_NAME}"
OPERATION_TYPE="unknown"
SEVERITY="high"
OPERATION_DESC=""

# Function to detect destructive Bash commands
detect_destructive_bash() {
  local cmd="$1"

  # Dangerous rm operations
  if [[ "$cmd" =~ rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f|rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r ]]; then
    OPERATION_TYPE="file_deletion"
    SEVERITY="critical"
    OPERATION_DESC="recursive file deletion (rm -rf)"
    return 0
  fi

  # Git push to production branches
  if [[ "$cmd" =~ git[[:space:]]+push ]]; then
    if [[ "$cmd" =~ --force|main|master|production ]]; then
      OPERATION_TYPE="git_push"
      SEVERITY="critical"
      OPERATION_DESC="git push to protected branch or force push"
      return 0
    else
      OPERATION_TYPE="git_push"
      SEVERITY="medium"
      OPERATION_DESC="git push"
      return 0
    fi
  fi

  # Database drops (case-insensitive)
  local cmd_upper="${cmd^^}"
  if [[ "$cmd_upper" =~ DROP[[:space:]]+TABLE|DROP[[:space:]]+DATABASE ]]; then
    OPERATION_TYPE="database_drop"
    SEVERITY="critical"
    OPERATION_DESC="database table/schema deletion"
    return 0
  fi

  # Dangerous DELETE operations (without WHERE clause is more dangerous)
  if [[ "$cmd_upper" =~ DELETE[[:space:]]+FROM ]]; then
    if [[ ! "$cmd_upper" =~ WHERE ]]; then
      OPERATION_TYPE="database_delete"
      SEVERITY="critical"
      OPERATION_DESC="bulk database DELETE (no WHERE clause)"
      return 0
    else
      OPERATION_TYPE="database_delete"
      SEVERITY="medium"
      OPERATION_DESC="database DELETE operation"
      return 0
    fi
  fi

  # TRUNCATE operations
  if [[ "$cmd_upper" =~ TRUNCATE[[:space:]]+TABLE ]]; then
    OPERATION_TYPE="database_truncate"
    SEVERITY="critical"
    OPERATION_DESC="database TRUNCATE operation"
    return 0
  fi

  return 1
}

# Analyze the tool and its parameters
case "$TOOL_NAME" in
  "Bash")
    BASH_CMD="${CLAUDE_TOOL_PARAMETER_command}"
    if detect_destructive_bash "$BASH_CMD"; then
      # Operation detected
      :
    else
      # Not destructive
      exit 0
    fi
    ;;

  "Write"|"Edit")
    # File operations are generally allowed in exclude mode
    # Only block in "on" mode if deleting multiple files
    if [[ "$GUARD_MODE" == "exclude" ]]; then
      exit 0  # Allow file refactoring
    fi
    # In "on" mode, we don't block individual file writes/edits
    exit 0
    ;;

  *)
    # Unknown tool - don't block
    exit 0
    ;;
esac

# Apply guard mode rules
if [[ "$GUARD_MODE" == "on" ]]; then
  # Block ALL destructive operations
  SHOULD_BLOCK=true
elif [[ "$GUARD_MODE" == "exclude" ]]; then
  # Allow refactoring (file edits), block git push and DB operations
  case "$OPERATION_TYPE" in
    "git_push"|"database_drop"|"database_delete"|"database_truncate")
      SHOULD_BLOCK=true
      ;;
    "file_deletion")
      # Only block if it's a critical recursive deletion
      if [[ "$SEVERITY" == "critical" ]]; then
        SHOULD_BLOCK=true
      else
        SHOULD_BLOCK=false
      fi
      ;;
    *)
      SHOULD_BLOCK=false
      ;;
  esac
else
  # Unknown mode - default to blocking
  SHOULD_BLOCK=true
fi

# If we should block, output context explaining the guard
if [[ "$SHOULD_BLOCK" == "true" ]]; then
  # Build severity indicator
  SEVERITY_EMOJI=""
  case "$SEVERITY" in
    "critical") SEVERITY_EMOJI="🚨" ;;
    "high") SEVERITY_EMOJI="⚠️" ;;
    "medium") SEVERITY_EMOJI="⚡" ;;
  esac

  # Build mode explanation
  MODE_EXPLANATION=""
  if [[ "$GUARD_MODE" == "on" ]]; then
    MODE_EXPLANATION="destructive_guard is ON - all destructive operations require confirmation"
  elif [[ "$GUARD_MODE" == "exclude" ]]; then
    MODE_EXPLANATION="destructive_guard is EXCLUDE - git push and database operations require confirmation"
  fi

  # Output restrictive context
  cat << EOF
{
  "hookSpecificOutput": {
    "context": [
      "",
      "# ${SEVERITY_EMOJI} DESTRUCTIVE OPERATION DETECTED",
      "",
      "**Operation:** ${OPERATION_DESC}",
      "**Severity:** ${SEVERITY}",
      "**Guard Mode:** ${GUARD_MODE}",
      "",
      "${MODE_EXPLANATION}",
      "",
      "## What's Being Guarded:",
      "",
EOF

  # List what's being protected based on mode
  if [[ "$GUARD_MODE" == "on" ]]; then
    cat << EOF
      "- Recursive file deletions (rm -rf)",
      "- Git push operations (especially to main/master)",
      "- Database DROP operations (tables, schemas)",
      "- Database DELETE/TRUNCATE operations",
      "",
      "## To Proceed:",
      "",
      "1. **Disable guard temporarily:** Run \`/claudisms-settings set destructive_guard off\`",
      "2. **Use exclude mode (allow refactoring):** Run \`/claudisms-settings set destructive_guard exclude\`",
      "3. **Confirm you want to proceed** with this specific operation",
      "",
EOF
  elif [[ "$GUARD_MODE" == "exclude" ]]; then
    cat << EOF
      "- Git push operations (to prevent accidental production pushes)",
      "- Database DROP/DELETE/TRUNCATE operations",
      "- Critical file deletions (rm -rf on large directories)",
      "",
      "**Note:** File refactoring (edits, renames) is allowed in exclude mode.",
      "",
      "## To Proceed:",
      "",
      "1. **Disable guard temporarily:** Run \`/claudisms-settings set destructive_guard off\`",
      "2. **Confirm you want to proceed** with this specific operation",
      "",
EOF
  fi

  cat << EOF
      "## Blocked Command:",
      "",
      "\`\`\`bash",
      "${BASH_CMD}",
      "\`\`\`",
      ""
    ]
  }
}
EOF
else
  # Operation is allowed - silent exit
  exit 0
fi
