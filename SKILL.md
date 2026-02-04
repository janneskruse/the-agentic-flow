---
name: create-beads-orchestration
description: Bootstrap lean multi-agent orchestration with beads task tracking. Use for projects needing agent delegation without heavy MCP overhead.
user-invocable: true
---

# Create Beads Orchestration

Set up lightweight multi-agent orchestration with git-native task tracking for Claude Code.

## What This Skill Does

This skill bootstraps a complete multi-agent workflow where:

- **Orchestrator** (you) investigates issues, manages tasks, delegates implementation
- **Supervisors** (specialized agents) execute fixes in isolated worktrees
- **Beads CLI** tracks all work with git-native task management
- **Hooks** enforce workflow discipline automatically

Each task gets its own worktree at `.worktrees/bd-{BEAD_ID}/`, keeping main clean and enabling parallel work.

## Beads Kanban UI

The setup will auto-detect [Beads Kanban UI](https://github.com/AvivK5498/Beads-Kanban-UI) and configure accordingly. If not found, you'll be offered to install it.

---

## Step 0: Detect Setup State (ALWAYS RUN FIRST)

<detection-phase>
**Before doing anything else, detect if this is a fresh setup or a resume after restart.**

Check for bootstrap artifacts:
```bash
ls .claude/agents/scout.md 2>/dev/null && echo "BOOTSTRAP_COMPLETE" || echo "FRESH_SETUP"
```

**If `BOOTSTRAP_COMPLETE`:**
- Bootstrap already ran in a previous session
- Skip directly to **Step 4: Run Discovery**
- Do NOT ask for project info or run bootstrap again

**If `FRESH_SETUP`:**
- This is a new installation
- Proceed to **Step 1: Get Project Info**
</detection-phase>

---

## Workflow Overview

<mandatory-workflow>
| Step | Action | When to Run |
|------|--------|-------------|
| 0 | Detect setup state | **ALWAYS** (determines path) |
| 1 | Get project info from user | Fresh setup only |
| 2 | Run bootstrap | Fresh setup only |
| 3 | **STOP** - Instruct user to restart | Fresh setup only |
| 4 | Run discovery agent | After restart OR if bootstrap already complete |

**The setup is NOT complete until Step 4 (discovery) has run.**
</mandatory-workflow>

---

## Step 0.5: Pre-Discovery Dialogue (Fresh Setup Only)

**Before running discovery, gather context from the user to optimize scanning.**

Ask the user:

1. **"What problem are you trying to solve IN this project?"**
   - This helps scope which supervisors are needed
   - Informs discovery about relevant tech stack areas

2. **"Do you have a guidance document for the project structure (README, architecture doc, etc.)?"**
   - **If Yes** → Ask: "Should I verify it against the codebase, or trust it as-is?"
     - **Verify** → Discovery will run targeted checks against specific claims
     - **Trust** → Discovery will parse and extract structure, skip deep scanning
   - **If No** → Ask: "Should the discovery agent scan the repository to gather this information?"
     - **Yes** → Run smart discovery (README first, then targeted)
     - **No** → Create minimal setup, user will specify agents manually later

---

## Step 1: Get Project Info (Fresh Setup Only)

<critical-step1>
**YOU MUST GET PROJECT INFO AND DETECT/ASK ABOUT KANBAN UI BEFORE PROCEEDING TO STEP 2.**

1. **Project directory**: Where to install (default: current working directory)
2. **Project name**: For agent templates (will auto-infer from package.json/pyproject.toml if not provided)
3. **Kanban UI**: Auto-detect, or ask the user to install
</critical-step1>

### 1.1 Get Project Directory and Name

Ask the user or auto-detect from package.json/pyproject.toml.

### 1.2 Detect or Install Kanban UI

```bash
which bead-kanban 2>/dev/null && echo "KANBAN_FOUND" || echo "KANBAN_NOT_FOUND"
```

**If KANBAN_FOUND** → Use `--with-kanban-ui` flag. Tell the user:
> Detected Beads Kanban UI. Configuring worktree management via API.

**If KANBAN_NOT_FOUND** → Ask:

```
AskUserQuestion(
  questions=[
    {
      "question": "Beads Kanban UI not detected. It adds a visual kanban board with dependency graphs and API-driven worktree management. Install it?",
      "header": "Kanban UI",
      "options": [
        {"label": "Yes, install it (Recommended)", "description": "Runs: npm install -g beads-kanban-ui"},
        {"label": "Skip", "description": "Use git worktrees directly. You can install later."}
      ],
      "multiSelect": false
    }
  ]
)
```

- If "Yes" → Run `npm install -g beads-kanban-ui`, then use `--with-kanban-ui` flag
- If "Skip" → do NOT use `--with-kanban-ui` flag

---

## Step 2: Run Bootstrap

```bash
# With Kanban UI:
npx @apapacho/the-agentic-flow bootstrap \
  --project-name "{{PROJECT_NAME}}" \
  --project-dir "{{PROJECT_DIR}}" \
  --with-kanban-ui

# Without Kanban UI (git worktrees only):
npx @apapacho/the-agentic-flow bootstrap \
  --project-name "{{PROJECT_NAME}}" \
  --project-dir "{{PROJECT_DIR}}"
```

The bootstrap script will:
1. Install beads CLI (via brew, npm, or go)
2. Initialize `.beads/` directory
3. Copy agent templates to `.claude/agents/`
4. Copy hooks to `.claude/hooks/`
5. Configure `.claude/settings.json`
6. Create `CLAUDE.md` with orchestrator instructions
7. Update `.gitignore`

**Verify bootstrap completed successfully before proceeding.**

---

## Step 3: STOP - User Must Restart

<critical>
**YOU MUST STOP HERE AND INSTRUCT THE USER TO RESTART CLAUDE CODE.**

Tell the user:

> **Setup phase complete. You MUST restart Claude Code now.**
>
> The new hooks and MCP configuration will only load after restart.
>
> After restarting:
> 1. Open this same project directory
> 2. Tell me "Continue orchestration setup" or run `/create-beads-orchestration` again
> 3. I will run the discovery agent to complete setup
>
> **Do not skip this restart - the orchestration will not work without it.**

**DO NOT proceed to Step 4 in this session. The restart is mandatory.**
</critical>

---

## Step 4: Conditional Discovery (After Restart OR Detection)

<post-restart>
**Run this step if:**
- Step 0 detected `BOOTSTRAP_COMPLETE`, OR
- User returned after restart and said "continue setup" or ran `/create-beads-orchestration` again

### 4.1: Check User's Discovery Preference

<post-restart-check>
**If you (the agent) do not know the user's preference yet (e.g., after restart):**
1. Ask: "I'm ready to setup the project. Do you have a guidance document, or should I scan the repo?"
2. Wait for answer.
</post-restart-check>

**If user provided guidance document:**
1. Read the guidance document they specified
2. Extract tech stack from it
3. **SKIP discovery agent entirely**
4. Create minimal supervisors based on extracted tech stack
5. Tell user: "Created supervisors based on your guidance: [list]"

**If user said "trust" existing docs:**
1. Read README.md (first 100 lines)
2. Extract tech stack mentions
3. **SKIP discovery agent entirely**
4. Create minimal supervisors
5. Tell user: "Created supervisors based on README: [list]"

**If user said "scan the repo" (or "yes", "go ahead"):**
1. Run the discovery agent with the **required confirmation keyword**:
   ```python
   Task(
       subagent_type="discovery",
       prompt="User confirmed: scan the repo. Detect tech stack using token-efficient scanning. Budget: 5k tokens max."
   )
   ```

**If user said "no, I'll specify agents manually":**
1. **SKIP discovery entirely**
2. Create ONLY the core agents (scout, detective, architect, scribe, code-reviewer)
3. Tell user: "Minimal setup complete. Add custom supervisors to `.claude/agents/` as needed."

### 4.2: After Discovery/Setup Completes

Tell the user:

> **Orchestration setup complete!**
>
> Created supervisors: [list what was created]
>
> You can now use the orchestration workflow:
> - Create tasks with `bd create "Task name" -d "Description"`
> - The orchestrator will delegate to appropriate supervisors
> - All work requires code review before completion
</post-restart>

---

## What This Creates

- **Beads CLI** for git-native task tracking (one bead = one worktree = one task)
- **Core agents**: scout, detective, architect, scribe, code-reviewer (all run via Claude Task)
- **Discovery agent**: Auto-detects tech stack and creates specialized supervisors
- **Hooks**: Enforce orchestrator discipline, code review gates, concise responses
- **Worktree-per-task workflow**: Isolated development in `.worktrees/bd-{BEAD_ID}/`

**With `--with-kanban-ui`:**
- Worktrees created via API (localhost:3008) with git fallback
- Requires [Beads Kanban UI](https://github.com/AvivK5498/Beads-Kanban-UI) running

**Without `--with-kanban-ui`:**
- Worktrees created via raw git commands

## Epic Workflow (Cross-Domain Features)

For features requiring multiple supervisors (e.g., DB + API + Frontend), use the **epic workflow**:

### When to Use Epics

| Task Type | Workflow |
|-----------|----------|
| Single-domain (one supervisor) | Standalone bead |
| Cross-domain (multiple supervisors) | Epic with children |

### Epic Workflow Steps

1. **Create epic**: `bd create "Feature name" -d "Description" --type epic`
2. **Create design doc** (if needed): Dispatch architect to create `.designs/{EPIC_ID}.md`
3. **Link design**: `bd update {EPIC_ID} --design ".designs/{EPIC_ID}.md"`
4. **Create children with dependencies**:
   ```bash
   bd create "DB schema" -d "..." --parent {EPIC_ID}              # BD-001.1
   bd create "API endpoints" -d "..." --parent {EPIC_ID} --deps BD-001.1  # BD-001.2
   bd create "Frontend" -d "..." --parent {EPIC_ID} --deps BD-001.2       # BD-001.3
   ```
5. **Dispatch sequentially**: Use `bd ready` to find unblocked tasks (each child gets own worktree)
6. **User merges each PR**: Wait for child's PR to merge before dispatching next
7. **Close epic**: `bd close {EPIC_ID}` after all children merged

### Design Docs

Design docs ensure consistency across epic children:
- Schema definitions (exact column names, types)
- API contracts (endpoints, request/response shapes)
- Shared constants/enums
- Data flow between layers

**Key rule**: Orchestrator dispatches architect to create design docs. Orchestrator never writes design docs directly.

### Hooks Enforce Epic Workflow

- **enforce-sequential-dispatch.sh**: Blocks dispatch if task has unresolved blockers
- **enforce-bead-for-supervisor.sh**: Requires BEAD_ID for all supervisors
- **validate-completion.sh**: Verifies worktree, push, bead status before supervisor completes

## Requirements

- **beads CLI**: Installed automatically by bootstrap (via brew, npm, or go)

## More Information

See the full documentation: https://github.com/janneskruse/the-agentic-flow
