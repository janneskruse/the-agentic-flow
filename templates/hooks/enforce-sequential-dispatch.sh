#!/bin/bash
#
# PreToolUse:Task - Enforce sequential dispatch and design doc existence
#
# For epic child tasks:
# 1. Blocks dispatch if task has unresolved blockers
# 2. Blocks dispatch if epic has design path but file doesn't exist
#

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_name', ''))")

[[ "$TOOL_NAME" != "Task" ]] && exit 0

SUBAGENT_TYPE=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('subagent_type', ''))")
PROMPT=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('prompt', ''))")

# Only check for supervisors (not architect, scout, etc.)
[[ ! "$SUBAGENT_TYPE" =~ supervisor ]] && exit 0

# Worker-supervisor is exempt
[[ "$SUBAGENT_TYPE" == *"worker"* ]] && exit 0

# Extract BEAD_ID
BEAD_ID=$(echo "$PROMPT" | grep -oE "BEAD_ID: [A-Za-z0-9._-]+" | head -1 | sed 's/BEAD_ID: //')
[[ -z "$BEAD_ID" ]] && exit 0

# Block dispatch to closed/done beads - create a new bead instead
BEAD_STATUS=$(bd show "$BEAD_ID" --json 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(data[0].get('status', '') if data else '')")
if [[ "$BEAD_STATUS" == "closed" || "$BEAD_STATUS" == "done" ]]; then
  cat << EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<closed-bead>\nBead ${BEAD_ID} is already ${BEAD_STATUS}. Do not reopen closed beads.\n\nCreate a new bead for follow-up work and relate it:\n\n  bd create \"Fix: [description]\" -d \"Follow-up to ${BEAD_ID}: [details]\"\n  # Returns: {NEW_ID}\n  bd dep relate {NEW_ID} ${BEAD_ID}\n\nThen dispatch with the NEW bead ID.\n</closed-bead>"}}
EOF
  exit 0
fi

# Check if this is an epic child (contains dot)
if [[ "$BEAD_ID" == *"."* ]]; then
  # Extract EPIC_ID (everything before last dot)
  EPIC_ID=$(echo "$BEAD_ID" | sed 's/\.[0-9]*$//')

  # Check for unresolved blockers (exclude parent epic - it's not a real blocker)
  BLOCKERS=$(bd dep list "$BEAD_ID" --json 2>/dev/null | python3 -c "import sys, json; epic = sys.argv[1]; data = json.load(sys.stdin); print(', '.join([i.get('id') for i in data if i.get('id') != epic and i.get('status') not in ['done', 'closed']]))" "$EPIC_ID" 2>/dev/null)

  if [[ -n "$BLOCKERS" ]]; then
    cat << EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<blocked-task>\nCannot dispatch ${BEAD_ID} - unresolved blockers: ${BLOCKERS}\n\nComplete blocking tasks first, then dispatch this one.\n\nUse: bd ready --json to see tasks with no blockers.\n</blocked-task>"}}
EOF
    exit 0
  fi

  # Check design doc exists (if epic has design field)
  DESIGN_PATH=$(bd show "$EPIC_ID" --json 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(data[0].get('design', '') if data else '')" 2>/dev/null)

  if [[ -n "$DESIGN_PATH" ]] && [[ ! -f "$DESIGN_PATH" ]]; then
    cat << EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<design-doc-missing>\nEpic ${EPIC_ID} has design path '${DESIGN_PATH}' but file doesn't exist.\n\n<stop-and-think>\nBefore dispatching architect, verify you fully understand the epic:\n\n1. Are the requirements clear and unambiguous?\n2. Do you know the expected inputs/outputs?\n3. Are there edge cases or constraints to consider?\n4. Do you understand how this integrates with existing code?\n\nIf ANY ambiguity exists -> Use AskUserQuestion to clarify FIRST.\nDo NOT dispatch architect with vague requirements.\n</stop-and-think>\n\n<next-steps>\nIf requirements are CLEAR:\n  Task(\n    subagent_type=\"architect\",\n    prompt=\"Create design doc for EPIC_ID: ${EPIC_ID}\n           Output: ${DESIGN_PATH}\n           \n           [Provide clear, specific requirements]\"\n  )\n\nIf requirements are UNCLEAR:\n  AskUserQuestion(\n    questions=[{\n      \"question\": \"[Your specific clarifying question]\",\n      \"header\": \"Clarify\",\n      \"options\": [...],\n      \"multiSelect\": false\n    }]\n  )\n</next-steps>\n</design-doc-missing>"}}
EOF
    exit 0
  fi
fi

exit 0
