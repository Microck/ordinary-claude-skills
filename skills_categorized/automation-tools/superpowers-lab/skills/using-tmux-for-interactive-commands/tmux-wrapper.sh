#!/bin/bash
# Simple wrapper around tmux for Claude Code to interact with interactive programs

set -euo pipefail

ACTION="${1:-}"
SESSION_NAME="${2:-}"

case "$ACTION" in
  start)
    COMMAND="${3:-bash}"
    shift 3 || true
    ARGS="$*"

    # Create new detached session
    if [ -n "$ARGS" ]; then
      tmux new-session -d -s "$SESSION_NAME" "$COMMAND" "$@"
    else
      tmux new-session -d -s "$SESSION_NAME" "$COMMAND"
    fi

    # Wait for initial output
    sleep 0.3

    # Capture and display initial state
    echo "Session: $SESSION_NAME"
    echo "---"
    tmux capture-pane -t "$SESSION_NAME" -p
    ;;

  send)
    shift 2
    if [ $# -eq 0 ]; then
      echo "Error: No input provided" >&2
      exit 1
    fi

    # Send all arguments as separate keys (allows "Enter", "Escape", etc.)
    tmux send-keys -t "$SESSION_NAME" "$@"

    # Wait a moment for output
    sleep 0.2

    # Capture and display updated state
    echo "Session: $SESSION_NAME"
    echo "---"
    tmux capture-pane -t "$SESSION_NAME" -p
    ;;

  capture)
    echo "Session: $SESSION_NAME"
    echo "---"
    tmux capture-pane -t "$SESSION_NAME" -p
    ;;

  stop)
    tmux kill-session -t "$SESSION_NAME"
    echo "Session $SESSION_NAME terminated"
    ;;

  list)
    tmux list-sessions
    ;;

  *)
    cat <<EOF
Usage: $0 <action> <session-name> [args...]

Actions:
  start <session-name> <command> [args...]  - Start a new interactive session
  send <session-name> <input>               - Send input to session (use Enter for newline)
  capture <session-name>                    - Capture current pane output
  stop <session-name>                       - Terminate session
  list                                      - List all sessions

Examples:
  $0 start python_session python3 -i
  $0 send python_session 'print("hello")' Enter
  $0 capture python_session
  $0 stop python_session
EOF
    exit 1
    ;;
esac
