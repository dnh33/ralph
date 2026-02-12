---
name: loop
description: "Start a Ralph development loop — autonomous, self-correcting work cycle"
argument-hint: '"task description" --max-iterations N --completion-promise "TEXT"'
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Task
---

You are starting a Ralph development loop — an autonomous, multi-iteration work cycle that prevents you from stopping until the task is complete.

## Step 1: Initialize

Run the setup script. Pass the user's arguments EXACTLY as provided — do not rename, reorder, or infer flags:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ralph-setup.sh" $ARGUMENTS
```

If the script fails, show the error and stop. Do not proceed with a broken loop.

## Step 2: Execute the task

Begin working on the task immediately. You are in a persistent development loop.

**How this works:**
- A Stop hook is active. When you try to finish, it checks if you're actually done.
- If not done, it blocks you from stopping and sends you back to continue.
- Each iteration, you should check your previous work and improve on it.

**Rules:**
1. Work from current file state, not memory or assumptions
2. After each meaningful change, VERIFY it works (run tests, check output, lint, etc.)
3. Check `.claude/ralph/state.json` to see your current iteration and max
4. When the task is genuinely complete AND verified:
   - If a completion promise was set: write that EXACT promise text to `.claude/ralph/complete`
   - If no promise was set: write `DONE` to `.claude/ralph/complete`
5. Do NOT write the completion marker until you have verified the work is correct
6. If sent back by the hook, read the state file, review your work, and fix what's incomplete

**To cancel manually:** Tell the user to run `/ralph:cancel`
