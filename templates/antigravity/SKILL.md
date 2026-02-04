---
name: beads-orchestration
description: Git-native task tracking and orchestration using 'beads'. Enables collaboration with other agents sharing the same repo.
---

# Beads Orchestration for Antigravity

This skill enables you to participate in the "Beads" orchestration system, a git-native task tracking protocol. You will use `bd` (Beads CLI) to read tasks, update status, and coordinate with other agents (like Claude) working on the same repository.

## Core Concept
- **Bead**: A unit of work, represented by a JSON file in `.beads/` and typically associated with a git worktree.
- **Shared State**: The `.beads` directory is the source of truth.
- **Role**: You act as an "Orchestrator" or a "Supervisor" depending on the task.

## Prerequisite: Beads CLI
You must have the `bd` CLI installed tasks.
Usage: `bd <command>` via `run_command`.

## Workflow

### 1. Discovery
When starting work, check for existing beads to understand the project state.

```powershell
bd list
```

### 2. Task Management
**Map Beads to your internal Task System (`task_boundary`):**
- When you pick up a bead (e.g., `BD-001`), set your `task_boundary` name to that bead's title.
- Update the bead status to let others know you are working on it.

```powershell
bd update BD-001 --status "in_progress"
```

### 3. Creating Tasks (Orchestration)
If you need to break down a large user request or delegate to another agent (e.g., if you are running in a mode where you hand off work), create new beads.

```powershell
bd create "Title of the subtask" -d "Detailed description of what needs to be done"
```

### 4. Completing Work
When you finish a task:
1. Ensure all your changes are committed (or pushed if working on a branch).
2. Update the bead status.

```powershell
bd update BD-001 --status "done"
```

## Rules of Engagement
1.  **Read First**: Always run `bd show {BEAD_ID}` and `bd comments {BEAD_ID}` before starting a task to get full context.
2.  **Log Decisions**: If you make a significant architectural decision, log it as a comment on the bead.
    ```powershell
    bd comment BD-001 "DECISION: Chose library X over Y because..."
    ```
3.  **Respect Locks**: If a bead is `in_progress` by another agent, do not touch it unless coordinating.

## Common `bd` Commands Reference
- `bd list`: Show open tasks.
- `bd create "Title" -d "Desc"`: Create a new task.
- `bd show {ID}`: Show details of a task.
- `bd update {ID} --status "done"`: Complete a task.
- `bd comments {ID}`: specific comments.
