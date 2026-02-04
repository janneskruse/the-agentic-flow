#!/bin/bash
#
# PreToolUse:Task - Soft reminder to set bead status before dispatch
#

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('prompt', ''))")

# Only remind if dispatching a bead task (prompt contains BEAD_ID)
if [[ "$PROMPT" == *"BEAD_ID:"* ]]; then
  echo "IMPORTANT: Before dispatching, ensure bead is in_progress: bd update {BEAD_ID} --status in_progress"
fi

exit 0
