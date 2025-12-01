#!/bin/bash
# write-policies.sh - Intelligent write policy enforcement
# Implements context-aware write restrictions for documentation files

# Write modes
declare -A WRITE_MODE=(
  [SUMMARY_ONLY]=1
  [STRUCTURED]=2
  [FULL_ACCESS]=3
)

# File-specific write rules
declare -A FILE_RULES_MODE
declare -A FILE_RULES_MAX_LINES
declare -A FILE_RULES_REQUIRE_CONCISE
declare -A FILE_RULES_BLOCK_ESSAYS

# Initialize rules
init_write_rules() {
  # CLAUDE.md rules
  FILE_RULES_MODE["CLAUDE.md"]=${WRITE_MODE[SUMMARY_ONLY]}
  FILE_RULES_MAX_LINES["CLAUDE.md"]=50
  FILE_RULES_REQUIRE_CONCISE["CLAUDE.md"]=true
  FILE_RULES_BLOCK_ESSAYS["CLAUDE.md"]=true

  # agents.md rules
  FILE_RULES_MODE["agents.md"]=${WRITE_MODE[SUMMARY_ONLY]}
  FILE_RULES_MAX_LINES["agents.md"]=30
  FILE_RULES_REQUIRE_CONCISE["agents.md"]=true
  FILE_RULES_BLOCK_ESSAYS["agents.md"]=true

  # *.plan.md rules
  FILE_RULES_MODE["*.plan.md"]=${WRITE_MODE[STRUCTURED]}
  FILE_RULES_MAX_LINES["*.plan.md"]=200
  FILE_RULES_REQUIRE_CONCISE["*.plan.md"]=false
  FILE_RULES_BLOCK_ESSAYS["*.plan.md"]=false

  # settings.json rules
  FILE_RULES_MODE["settings.json"]=${WRITE_MODE[FULL_ACCESS]}
  FILE_RULES_MAX_LINES["settings.json"]=9999
  FILE_RULES_REQUIRE_CONCISE["settings.json"]=false
  FILE_RULES_BLOCK_ESSAYS["settings.json"]=false
}

# Get matching rule for filename
get_file_rule() {
  local filename="$1"
  local basename=$(basename "$filename")

  # Exact match
  if [[ -n "${FILE_RULES_MODE[$basename]}" ]]; then
    echo "$basename"
    return 0
  fi

  # Pattern match
  for pattern in "${!FILE_RULES_MODE[@]}"; do
    if [[ "$pattern" == *"*"* ]]; then
      # Convert glob to regex
      local regex="${pattern//\*/.*}"
      if [[ "$basename" =~ ^${regex}$ ]]; then
        echo "$pattern"
        return 0
      fi
    fi
  done

  # No match - full access
  echo ""
  return 0
}

# Check if file should be restricted
check_write_policy() {
  local filepath="$1"
  local content="$2"
  local settings_file="${3:-}"

  # Load settings if provided
  local intelligent_writes=true
  if [[ -f "$settings_file" ]]; then
    intelligent_writes=$(grep -o '"intelligentWrites"[[:space:]]*:[[:space:]]*\(true\|false\)' "$settings_file" | grep -o 'true\|false' || echo "true")
  fi

  # Skip if intelligent writes disabled
  if [[ "$intelligent_writes" != "true" ]]; then
    return 0  # Allow write
  fi

  # Initialize rules
  init_write_rules

  # Get applicable rule
  local rule=$(get_file_rule "$filepath")
  if [[ -z "$rule" ]]; then
    return 0  # No rule - allow write
  fi

  # Get rule parameters
  local mode=${FILE_RULES_MODE[$rule]}
  local max_lines=${FILE_RULES_MAX_LINES[$rule]}
  local require_concise=${FILE_RULES_REQUIRE_CONCISE[$rule]:-false}
  local block_essays=${FILE_RULES_BLOCK_ESSAYS[$rule]:-false}

  # Count lines in content
  local line_count=$(echo "$content" | wc -l)

  # Check max lines
  if [[ $line_count -gt $max_lines ]]; then
    cat >&2 << EOF
[Claudisms] Write policy violation for $(basename "$filepath")

Rule: SUMMARY_ONLY (max $max_lines lines)
Actual: $line_count lines

Suggestion: Create a separate project-specific documentation file instead.
For CLAUDE.md updates, use this format:

## Update: $(date +%Y-%m-%d)
- Brief summary point 1
- Brief summary point 2

Keep updates concise (<50 lines total).
EOF
    return 1  # Block write
  fi

  # Check for essays (word count)
  if [[ "$block_essays" == "true" ]]; then
    local word_count=$(echo "$content" | wc -w)
    if [[ $word_count -gt 500 ]]; then
      cat >&2 << EOF
[Claudisms] Essay detected in $(basename "$filepath")

Word count: $word_count words
Limit: 500 words for summary files

Suggestion: Create a separate documentation file (e.g., PROJECT-NOTES.md)
and add a brief reference in CLAUDE.md:

## Project Documentation
See PROJECT-NOTES.md for detailed architecture notes.
EOF
      return 1  # Block write
    fi
  fi

  # Structured mode checks
  if [[ $mode -eq ${WRITE_MODE[STRUCTURED]} ]]; then
    # Check for section headers (##)
    if ! echo "$content" | grep -q "^##"; then
      cat >&2 << EOF
[Claudisms] Structured write policy for *.plan.md files

Requirement: Use section headers (## Section Name)
EOF
      return 1  # Block write
    fi
  fi

  return 0  # Allow write
}

# Validate and suggest format for CLAUDE.md
suggest_claude_md_format() {
  cat << 'EOF'
Recommended CLAUDE.md update format:

## Update: YYYY-MM-DD
- Concise summary point 1
- Concise summary point 2
- Key decision or change

Keep total file under 50 lines.
For extensive notes, create separate docs.
EOF
}

# Export functions for sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # Being sourced - export functions
  export -f init_write_rules
  export -f get_file_rule
  export -f check_write_policy
  export -f suggest_claude_md_format
fi

# CLI usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Direct execution
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <filepath> <content_file> [settings.json]"
    echo ""
    echo "Check if write should be allowed based on intelligent write policies."
    echo ""
    echo "Exit codes:"
    echo "  0 - Write allowed"
    echo "  1 - Write blocked (policy violation)"
    exit 2
  fi

  filepath="$1"
  content_file="$2"
  settings_file="${3:-}"

  if [[ ! -f "$content_file" ]]; then
    echo "Error: Content file not found: $content_file" >&2
    exit 2
  fi

  content=$(cat "$content_file")

  check_write_policy "$filepath" "$content" "$settings_file"
  exit $?
fi
