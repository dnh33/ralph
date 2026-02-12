#!/bin/bash
set -euo pipefail

# Ralph Loop — Cancel Script
# Stops an active loop and cleans up state

STATE_DIR=".claude/ralph"
STATE_FILE="$STATE_DIR/state.json"
COMPLETE_FILE="$STATE_DIR/complete"

if [[ -f "$STATE_FILE" ]]; then
  ITERATION=$(jq -r '.current_iteration // "?"' "$STATE_FILE" 2>/dev/null || echo "?")
  TASK=$(jq -r '.original_prompt // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
  rm -f "$STATE_FILE" "$COMPLETE_FILE"
  rmdir "$STATE_DIR" 2>/dev/null || true
  echo "Ralph loop cancelled."
  echo "  Was on iteration: $ITERATION"
  echo "  Task was: $TASK"
else
  echo "No active Ralph loop to cancel."
fi
