# Beads Orchestration

Multi-agent orchestration for Claude Code. An orchestrator investigates issues and delegates implementation to specialized supervisors.

## Quick Start

```bash
# In any Claude Code session
/create-beads-orchestration
```

The skill walks you through setup, then creates tech-specific supervisors based on your codebase.

## How It Works

```
┌─────────────────────────────────────────┐
│            ORCHESTRATOR                 │
│  Investigates with Grep/Read/Glob       │
│  Delegates implementation via Task()    │
└──────────────────┬──────────────────────┘
                   │
       ┌───────────┼───────────┐
       ▼           ▼           ▼
  ┌─────────┐ ┌─────────┐ ┌─────────┐
  │ react-  │ │ python- │ │ worker- │
  │supervisor│ │supervisor│ │supervisor│
  └────┬────┘ └────┬────┘ └────┬────┘
       │           │           │
   bd-BD-001   bd-BD-002   bd-BD-003
   (branch)    (branch)    (branch)
```

**Orchestrator:** Investigates the issue, identifies root cause, delegates with specific fix instructions.

**Supervisors:** Execute the fix confidently on isolated branches. Created by discovery agent based on your tech stack.

## Task Tracking

Uses [beads](https://github.com/steveyegge/beads) for git-native task management:

```bash
bd create "Add auth" -d "JWT-based authentication"  # Create task
bd update BD-001 --status in_progress               # Mark started
bd comment BD-001 "Completed login endpoint"        # Log progress
bd update BD-001 --status inreview                  # Mark done
bd close BD-001                                     # Close task
```

## Delegation Format

```python
Task(
  subagent_type="react-supervisor",
  prompt="""BEAD_ID: BD-001

Problem: Login button doesn't redirect after success
Root cause: src/components/Login.tsx:45 - missing router.push()
Fix: Add router.push('/dashboard') after successful auth"""
)
```

## Epics (Cross-Domain Features)

For features spanning multiple supervisors:

```bash
bd create "User profiles" -d "..." --type epic           # Create epic
bd create "DB schema" -d "..." --parent BD-001           # Child .1
bd create "API endpoints" -d "..." --parent BD-001 --deps BD-001.1  # Child .2
bd create "Frontend" -d "..." --parent BD-001 --deps BD-001.2       # Child .3
```

Children work on a shared epic branch. Orchestrator dispatches sequentially based on dependencies.

## What Gets Installed

```
.claude/
├── agents/           # Supervisors (discovery creates tech-specific ones)
├── hooks/            # Workflow enforcement
├── skills/           # subagents-discipline
└── settings.json
CLAUDE.md             # Orchestrator instructions
.beads/               # Task database
```

## Hooks

| Hook | Purpose |
|------|---------|
| `block-orchestrator-tools.sh` | Orchestrator can't Edit/Write |
| `enforce-bead-for-supervisor.sh` | Supervisors need BEAD_ID |
| `validate-epic-close.sh` | Can't close epic with open children |
| `enforce-branch-before-edit.sh` | Must be on feature branch to edit |
| `validate-completion.sh` | Completion format requirements |

## Requirements

- Claude Code with hooks support
- beads CLI: `brew install steveyegge/beads/bd` or `npm install -g @beads/bd`

## License

MIT
