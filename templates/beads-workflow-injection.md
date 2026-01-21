<beads-workflow>
<requirement>You MUST follow this branch-per-task workflow for ALL implementation work.</requirement>

<on-task-start>
1. Branch: `git checkout -b bd-{BEAD_ID}` (or checkout existing for epic children)
2. Mark in progress: `bd update {BEAD_ID} --status in_progress`
3. If epic child: Read design doc via `bd show {EPIC_ID} --json | jq -r '.[0].design'`
4. Invoke: `Skill(skill: "subagents-discipline")`
</on-task-start>

<execute-with-confidence>
The orchestrator has investigated and provided a fix strategy.

**Default behavior:** Execute the fix confidently.

**Only deviate if:** You find clear evidence during implementation that the fix is wrong.

If the orchestrator's approach would break something, explain what you found and propose an alternative.
</execute-with-confidence>

<during-implementation>
1. Commit frequently with descriptive messages
2. Log progress: `bd comment {BEAD_ID} "Completed X, working on Y"`
</during-implementation>

<on-completion>
1. Final commit
2. Add comment: `bd comment {BEAD_ID} "Completed: [summary]"`
3. Mark ready: `bd update {BEAD_ID} --status inreview` (standalone) or `--status done` (epic child)
4. Return completion summary to orchestrator
</on-completion>

<banned>
- Working directly on main branch
- Implementing without BEAD_ID
- Merging your own branch
</banned>
</beads-workflow>
