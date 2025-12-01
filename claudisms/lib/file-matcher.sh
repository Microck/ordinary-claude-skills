#!/bin/bash

# File pattern matching library for Claudisms plugin
# Supports glob patterns: *, **, ?, exact matches

# Match a file path against a pattern
# Usage: match_pattern "/path/to/file.md" "*.md"
# Returns: 0 (true) if matches, 1 (false) if no match
match_pattern() {
  local file_path="$1"
  local pattern="$2"

  # Get the basename for simple patterns
  local basename="${file_path##*/}"

  # Case-insensitive for .md files (convert both to lowercase)
  local is_md_pattern=false
  if [[ "$pattern" == *.md ]] || [[ "$pattern" == *.MD ]]; then
    is_md_pattern=true
    pattern="${pattern,,}"  # Convert pattern to lowercase
    file_path="${file_path,,}"  # Convert path to lowercase
    basename="${basename,,}"  # Convert basename to lowercase
  fi

  # Exact match (no wildcards)
  if [[ "$pattern" != *"*"* && "$pattern" != *"?"* ]]; then
    # Check if path ends with pattern (exact filename match)
    if [[ "$file_path" == *"/$pattern" || "$basename" == "$pattern" ]]; then
      return 0
    fi
    return 1
  fi

  # Handle ** pattern (match anywhere in path)
  if [[ "$pattern" == *"**"* ]]; then
    # Convert glob pattern to regex
    # ** -> .*
    # * -> [^/]*
    # ? -> [^/]
    # . -> \.
    local regex_pattern="$pattern"
    regex_pattern="${regex_pattern//./\\.}"  # Escape dots
    regex_pattern="${regex_pattern//\*\*/.*}"  # ** -> .*
    regex_pattern="${regex_pattern//\*/[^/]*}"  # * -> [^/]*
    regex_pattern="${regex_pattern//\?/[^/]}"  # ? -> single char

    if [[ "$file_path" =~ $regex_pattern ]]; then
      return 0
    fi
    return 1
  fi

  # Handle * and ? patterns (single directory level)
  # Use bash's built-in pattern matching
  if [[ "$pattern" == *"/"* ]]; then
    # Pattern includes path separator, match against full path
    # Convert pattern for bash glob matching
    local glob_pattern="$pattern"
    # Escape special regex chars, keep * and ?
    if [[ "$file_path" == $glob_pattern ]]; then
      return 0
    fi
  else
    # Pattern is just filename, match against basename
    # Use bash pattern matching
    case "$basename" in
      $pattern)
        return 0
        ;;
    esac
  fi

  return 1
}

# Match a file path against multiple patterns
# Usage: match_any_pattern "/path/to/file.md" "*.md,*.txt,README"
# Returns: 0 (true) if matches any pattern, 1 (false) if no match
match_any_pattern() {
  local file_path="$1"
  local patterns="$2"

  # Split patterns by comma
  IFS=',' read -ra PATTERN_ARRAY <<< "$patterns"

  for pattern in "${PATTERN_ARRAY[@]}"; do
    # Trim whitespace
    pattern=$(echo "$pattern" | xargs)

    if match_pattern "$file_path" "$pattern"; then
      return 0
    fi
  done

  return 1
}

# Test if a pattern is valid
# Usage: validate_pattern "*.md"
# Returns: 0 (true) if valid, 1 (false) if invalid
validate_pattern() {
  local pattern="$1"

  # Empty pattern is invalid
  [[ -z "$pattern" ]] && return 1

  # Pattern should not start with /
  [[ "$pattern" =~ ^/ ]] && return 1

  # Pattern is valid
  return 0
}
