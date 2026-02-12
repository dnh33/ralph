# Ralph

Self-referential development loop + brutally honest code roaster for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Inspired by the [Gemini CLI Ralph extension](https://github.com/gemini-cli-extensions/ralph), rebuilt from scratch for Claude Code's hook architecture.

## What It Does

### Development Loop

Ralph prevents Claude from stopping until the task is actually done. It uses Claude Code's Stop hook to intercept completion attempts, check if the work is truly finished, and send the agent back for another iteration if not.

```
You: /ralph:loop "Refactor the auth module and add tests" --max-iterations 10
Claude: *works on refactoring*
Claude: *tries to stop*
Ralph:  "Nice try. Iteration 2 of 10. Keep going."
Claude: *continues working, verifies tests pass*
Claude: *writes completion marker*
Ralph:  "Loop complete after 3 iterations."
```

### Code Roaster

Ralph includes a code review agent with the personality of Gordon Ramsay crossed with a senior engineer who's seen too much. Ask for a "code roast" or "brutal review" and Ralph delivers honest, actionable feedback wrapped in sharp humor.

## Installation

```bash
claude plugin install ralph
```

Or install from source:

```bash
git clone https://github.com/dnh33/ralph.git
claude plugin install --path ./ralph
```

## Usage

### Loop Commands

| Command | Description |
|---------|-------------|
| `/ralph:loop "task" [options]` | Start an autonomous development loop |
| `/ralph:cancel` | Cancel an active loop and clean up |
| `/ralph:help` | Show usage guide |

### Loop Options

- `--max-iterations N` — Maximum iterations before forced stop (default: 5)
- `--completion-promise "TEXT"` — Loop continues until agent writes this exact text to the completion marker

### Examples

Basic loop:
```
/ralph:loop "Fix all failing tests in src/"
```

With iteration limit:
```
/ralph:loop "Build a REST API for users" --max-iterations 15
```

With completion promise:
```
/ralph:loop "Implement OAuth2 flow" --completion-promise "All OAuth2 tests passing"
```

### Code Roaster

Just ask for a roast in natural language:
- "Roast my code"
- "Give me a brutal review of this file"
- "Be honest, how bad is this?"

The `ralph-code-roaster` agent triggers automatically.

## How It Works

```
┌──────────────────────────────────────────────────┐
│  /ralph:loop "task" --max-iterations 10          │
│                                                  │
│  1. ralph-setup.sh creates .claude/ralph/        │
│     ├── state.json  (iteration, prompt, config)  │
│     └── complete    (written when done)           │
│                                                  │
│  2. Agent works on the task                      │
│                                                  │
│  3. Agent tries to stop                          │
│     └── Stop hook fires → ralph-loop-hook.sh     │
│         ├── Complete marker exists? → APPROVE     │
│         ├── Max iterations hit?     → APPROVE     │
│         └── Otherwise?              → BLOCK       │
│             (sends agent back with instructions)  │
│                                                  │
│  4. Loop continues until done or max reached     │
└──────────────────────────────────────────────────┘
```

### State Management

Ralph stores loop state in `.claude/ralph/` within your project:

- `state.json` — Tracks iteration count, max iterations, original prompt, completion promise, timestamps
- `complete` — Marker file the agent writes when genuinely done

State is cleaned up automatically when the loop completes or is cancelled.

## Files

```
ralph/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── agents/
│   └── code-roaster.md      # Ralph code roaster agent
├── commands/
│   ├── loop.md              # /ralph:loop command
│   ├── cancel.md            # /ralph:cancel command
│   └── help.md              # /ralph:help command
├── hooks/
│   └── hooks.json           # Stop hook configuration
└── scripts/
    ├── ralph-setup.sh       # Loop initialization
    ├── ralph-loop-hook.sh   # Core loop engine (Stop hook)
    └── ralph-cancel.sh      # Loop cleanup
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (for JSON processing in hook scripts)
- `bash`

## Safety

- Default max iterations is 5 — prevents runaway loops
- `/ralph:cancel` always works as an emergency stop
- Deleting `.claude/ralph/` manually also kills the loop
- Hook approves immediately if no active loop exists (no interference with normal usage)

## License

MIT
