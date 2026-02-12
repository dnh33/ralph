---
name: help
description: "Show Ralph usage guide"
---

Display this help information directly — do NOT use any subagent or external tool:

## Ralph — Development Loop + Code Roaster

### Loop Commands

- `/ralph:loop "task description" [options]` — Start an autonomous development loop
- `/ralph:cancel` — Cancel an active loop and clean up
- `/ralph:help` — Show this help

### Loop Options

- `--max-iterations N` — Stop after N iterations (default: 5)
- `--completion-promise "TEXT"` — Loop continues until agent writes TEXT to `.claude/ralph/complete`

### How the Loop Works

1. You run `/ralph:loop "Build feature X" --max-iterations 10`
2. The agent works on the task
3. When it tries to stop, a Stop hook checks if it's actually done
4. If not done → sent back to continue (iteration increments)
5. Loop ends when: completion marker written, max iterations reached, or manually cancelled

### Code Roaster

Ralph also includes a code roasting agent. Ask for a "code roast" or "brutal review" and the ralph-code-roaster agent will be triggered automatically.

### Safety

- Max iterations prevents infinite loops (default: 5)
- `/ralph:cancel` always works as emergency stop
- State stored in `.claude/ralph/` — delete this directory to force-stop
