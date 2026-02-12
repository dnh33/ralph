#!/bin/bash
set -euo pipefail

# Ralph Loop — Setup Script
# Initializes loop state for the Stop hook to manage

die() {
  echo "Error: $1" >&2
  exit 1
}

STATE_DIR=".claude/ralph"
STATE_FILE="$STATE_DIR/state.json"

mkdir -p "$STATE_DIR" || die "Could not create state directory: $STATE_DIR"

# Defaults
MAX_ITERATIONS=5
COMPLETION_PROMISE=""
PROMPT_ARGS=()

# Handle single-string argument from LLM tool invocation
if [[ $# -eq 1 ]]; then
  if [[ "$1" =~ " --" ]]; then
    eval set -- "$1"
  fi
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-iterations)
      [[ "${2:-}" =~ ^[0-9]+$ ]] || die "Invalid iteration limit: '${2:-}'"
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      [[ -n "${2:-}" ]] || die "Missing promise text."
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    *)
      PROMPT_ARGS+=("$1")
      shift
      ;;
  esac
done
PROMPT="${PROMPT_ARGS[*]:-}"

[[ -n "$PROMPT" ]] || die "No task specified. Usage: /ralph:loop \"task description\" [--max-iterations N] [--completion-promise \"TEXT\"]"

# Write state file
jq -n \
  --arg max "$MAX_ITERATIONS" \
  --arg promise "$COMPLETION_PROMISE" \
  --arg prompt "$PROMPT" \
  --arg started "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  '{
    active: true,
    current_iteration: 1,
    max_iterations: ($max | tonumber),
    completion_promise: $promise,
    original_prompt: $prompt,
    started_at: $started
  }' > "$STATE_FILE" || die "Failed to write state file"

echo ""
echo "Ralph loop initialized."
echo "  Task: $PROMPT"
echo "  Max iterations: $MAX_ITERATIONS"
if [[ -n "$COMPLETION_PROMISE" ]]; then
  echo "  Completion promise: $COMPLETION_PROMISE"
  echo ""
  echo "  To complete: write '$COMPLETION_PROMISE' to .claude/ralph/complete"
fi
echo ""
echo "Starting iteration 1 of $MAX_ITERATIONS..."
