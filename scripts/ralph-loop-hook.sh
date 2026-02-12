#!/bin/bash
set -euo pipefail

# Ralph Loop — Stop Hook
# Intercepts agent stop events to maintain the development loop.
# Returns JSON: {"decision": "approve"} or {"decision": "block", "reason": "..."}

STATE_DIR=".claude/ralph"
STATE_FILE="$STATE_DIR/state.json"
COMPLETE_FILE="$STATE_DIR/complete"

# Read hook input from stdin (required by Claude Code hooks)
INPUT=$(cat)

# If no state file, no active loop — let the agent stop
if [[ ! -f "$STATE_FILE" ]]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Check if loop is active
ACTIVE=$(jq -r '.active // false' "$STATE_FILE")
if [[ "$ACTIVE" != "true" ]]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Load state
CURRENT_ITERATION=$(jq -r '.current_iteration' "$STATE_FILE")
MAX_ITERATIONS=$(jq -r '.max_iterations' "$STATE_FILE")
COMPLETION_PROMISE=$(jq -r '.completion_promise // ""' "$STATE_FILE")
ORIGINAL_PROMPT=$(jq -r '.original_prompt' "$STATE_FILE")

# --- Check completion conditions ---

# 1. Completion marker file exists
if [[ -f "$COMPLETE_FILE" ]]; then
  if [[ -n "$COMPLETION_PROMISE" ]]; then
    # Promise mode: verify the marker contains the promise text
    MARKER_CONTENT=$(cat "$COMPLETE_FILE" 2>/dev/null || echo "")
    if [[ "$MARKER_CONTENT" == *"$COMPLETION_PROMISE"* ]]; then
      rm -f "$STATE_FILE" "$COMPLETE_FILE"
      rmdir "$STATE_DIR" 2>/dev/null || true
      echo "{\"decision\": \"approve\", \"systemMessage\": \"Ralph loop complete after $CURRENT_ITERATION iterations. Promise fulfilled: $COMPLETION_PROMISE\"}"
      exit 0
    fi
    # Promise not matched — remove invalid marker and continue
    rm -f "$COMPLETE_FILE"
  else
    # No promise required — completion marker is sufficient
    rm -f "$STATE_FILE" "$COMPLETE_FILE"
    rmdir "$STATE_DIR" 2>/dev/null || true
    echo "{\"decision\": \"approve\", \"systemMessage\": \"Ralph loop complete after $CURRENT_ITERATION iterations.\"}"
    exit 0
  fi
fi

# 2. Max iterations reached
if [[ $CURRENT_ITERATION -ge $MAX_ITERATIONS ]]; then
  rm -f "$STATE_FILE" "$COMPLETE_FILE" 2>/dev/null
  rmdir "$STATE_DIR" 2>/dev/null || true
  echo "{\"decision\": \"approve\", \"systemMessage\": \"Ralph loop ended: reached max iterations ($MAX_ITERATIONS). Task may be incomplete.\"}"
  exit 0
fi

# --- Continue the loop ---

# Increment iteration
NEW_ITERATION=$((CURRENT_ITERATION + 1))
TMP_STATE=$(mktemp)
jq ".current_iteration = $NEW_ITERATION" "$STATE_FILE" > "$TMP_STATE" || {
  rm -f "$TMP_STATE"
  echo '{"decision": "approve", "systemMessage": "Ralph loop error: failed to update state."}'
  exit 0
}
mv "$TMP_STATE" "$STATE_FILE"

# Block the stop — force the agent to continue
# The reason becomes the instruction the agent receives
ESCAPED_PROMPT=$(echo "$ORIGINAL_PROMPT" | jq -Rs '.')

cat <<EOF
{
  "decision": "block",
  "reason": "RALPH LOOP — Iteration $NEW_ITERATION of $MAX_ITERATIONS. Continue working on the task. Check .claude/ralph/state.json for loop state. When genuinely done, write completion marker to .claude/ralph/complete. Original task: $ORIGINAL_PROMPT",
  "systemMessage": "Ralph loop: starting iteration $NEW_ITERATION of $MAX_ITERATIONS. Review your previous work in the files and continue. Do not stop until the task is complete or create .claude/ralph/complete to signal completion."
}
EOF

exit 0
