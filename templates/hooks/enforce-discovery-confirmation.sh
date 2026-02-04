#!/bin/bash
#
# PreToolUse:Task - Block discovery agent without user confirmation
#
# Ensures discovery only runs if user explicitly confirmed via SKILL.md dialogue
#

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_name', ''))")

[[ "$TOOL_NAME" != "Task" ]] && exit 0

SUBAGENT_TYPE=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('subagent_type', ''))")
PROMPT=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('prompt', ''))")

# Only enforce for discovery agent
[[ "$SUBAGENT_TYPE" != "discovery" ]] && exit 0

# Check if prompt contains user confirmation keywords
# These keywords should be in the prompt if user answered the SKILL.md questions
if [[ "$PROMPT" == *"user confirmed"* ]] || \
   [[ "$PROMPT" == *"scan the repo"* ]] || \
   [[ "$PROMPT" == *"Budget: 5k tokens max"* ]]; then
  # User confirmed, allow discovery
  exit 0
fi

# Block discovery without confirmation
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<discovery-requires-confirmation>\nDiscovery agent requires user confirmation before running.\n\n<action>\nYou MUST ask the user these questions first (from SKILL.md Step 0.5):\n\n1. \"What problem are you trying to solve IN this project?\"\n\n2. \"Do you have a guidance document for the project structure?\"\n   - If YES: Read it, extract tech stack, SKIP discovery\n   - If NO: Ask \"Should the discovery agent scan the repository?\"\n     - If YES: Include \"scan the repo\" in the dispatch prompt\n     - If NO: Create minimal setup, SKIP discovery\n\nOnly dispatch discovery if user explicitly said \"scan the repo\".\nInclude \"Budget: 5k tokens max\" in the prompt to confirm user approval.\n</action>\n</discovery-requires-confirmation>"}}
EOF
exit 0
