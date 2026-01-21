# Streamlined Orchestration Workflow

Applied to `beads-kanban-ui` as case study. Changes reduce overhead while keeping task tracking intact.

## Philosophy Change

**Before:** Orchestrator describes problem → Supervisor investigates + fixes
**After:** Orchestrator investigates → Supervisor executes fix confidently

## Changes Summary

### 1. Hooks

#### Deleted
- `warn-orchestrator-code-read.sh` - Orchestrator should read code to investigate

#### Modified: `block-orchestrator-tools.sh`
Changed from allowlist to denylist:
```bash
# DENYLIST: Block implementation tools for orchestrator
BLOCKED="Edit|Write|NotebookEdit"

# Git: only block add|commit (allow push, rebase, reset)
```
- All MCP tools allowed
- Grep, Read, Glob allowed
- All bash commands allowed (except git add/commit)

#### Modified: `validate-completion.sh`
Removed code review enforcement. Kept:
- Completion format requirement
- Verbosity limit (15 lines, 800 chars)
- Comment requirement

#### Modified: `settings.json`
Removed reference to deleted `warn-orchestrator-code-read.sh`

---

### 2. Skill: `subagents-discipline`

Simplified from 159 lines to 68 lines. Removed:
- DEMO block requirement
- Completion checklist
- Verbose examples

Kept core principles:
- Rule 1: Look before you code (check actual data)
- Rule 2: Test both levels (component + feature)
- Rule 3: Use your tools
- Epic children: read design doc

---

### 3. Supervisors (all 4)

#### Phase 0: Simplified
From 7-step mandatory checklist to 4 steps:
```
1. Branch checkout
2. Mark in progress: bd update {BEAD_ID} --status in_progress
3. If epic child: Read design doc
4. Invoke: Skill(skill: "subagents-discipline")
```

#### Phase 0.5: Changed from Skepticism to Confidence
**Before:**
> If the orchestrator included fix suggestions... The orchestrator cannot Grep - their analysis may be incomplete. Verify independently.

**After:**
> The orchestrator has investigated and provided a fix strategy.
> **Default behavior:** Execute the fix confidently.
> **Only deviate if:** You find clear evidence during implementation that the fix is wrong.

#### Removed
- verification_logs references
- VERIFICATION comment requirements
- Code review dispatch requirement
- "skipping code review" from banned lists

#### Kept
- Branch discipline (not working on main)
- Bead workflow (bd update, bd comment)
- Completion report format
- Domain expertise sections
- RAMS + WIG reviews (nextjs-supervisor)
- react-best-practices skill (nextjs-supervisor)

---

### 4. CLAUDE.md

#### Changed Orchestrator Rules
**Before:**
```
YOU ARE AN ORCHESTRATOR. You delegate, never implement.
- NEVER use Grep/Edit/Write/WebFetch
YOU ARE STRICTLY FORBIDDEN FROM PROPOSING FIXES TO SUPERVISORS.
```

**After:**
```
YOU ARE AN ORCHESTRATOR. You investigate, then delegate implementation.
- Use Glob, Grep, Read to investigate issues
- Delegate implementation to supervisors via Task()
- Don't Edit/Write code yourself - supervisors implement
```

#### New Investigation-First Workflow
```
1. Investigate - Use Grep, Read, Glob to understand the issue
2. Identify root cause - Find the specific file, function, line
3. Formulate fix - Determine the correct solution
4. Delegate with confidence - Tell the supervisor exactly what to fix
```

#### Delegation Format
```
Task(
  subagent_type="{tech}-supervisor",
  prompt="BEAD_ID: {id}

Problem: [what's broken]
Root cause: [file:line - what you found]
Fix: [specific change to make]"
)
```

#### Removed
- "Problem Description, Not Solution Prescription" section
- Code Review sections
- FORBIDDEN lists

#### Kept
- Beads commands reference
- Epic vs Standalone guidance
- Epic workflow with design docs
- Supervisor list

---

## Files Modified

```
beads-kanban-ui/
├── .claude/
│   ├── hooks/
│   │   ├── block-orchestrator-tools.sh  # Modified (denylist)
│   │   ├── validate-completion.sh       # Modified (no code review)
│   │   ├── warn-orchestrator-code-read.sh  # DELETED
│   │   └── settings.json                # Modified (removed hook ref)
│   ├── skills/
│   │   └── subagents-discipline/
│   │       └── SKILL.md                 # Simplified
│   └── agents/
│       ├── nextjs-supervisor.md         # Updated phases
│       ├── rust-supervisor.md           # Updated phases
│       ├── worker-supervisor.md         # Updated phases
│       └── merge-supervisor.md          # Updated phases
└── CLAUDE.md                            # Investigation-first workflow
```

---

## Result

- Faster iteration (orchestrator investigates fully before delegating)
- Less ceremony (no DEMO blocks, no code review enforcement)
- User tests manually, prompts for fix if needed
- Beads tracking remains intact for task management
