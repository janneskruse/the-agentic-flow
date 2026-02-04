#!/bin/bash
#
# PostToolUse: Enforce concise responses from subagents
#
# Subagents should return concise reports (max 10 lines, ~500 chars)
# This reduces context usage and keeps orchestrator focused.
#

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_name', ''))")
AGENT_TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('agent_transcript_path', ''))")

# Only check Task tool responses
[[ "$TOOL_NAME" != "Task" ]] && exit 0

# Get the tool response
RESPONSE=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_result', ''))")
[[ -z "$RESPONSE" ]] && exit 0

# Count lines and characters
LINE_COUNT=$(echo "$RESPONSE" | wc -l | tr -d ' ')
CHAR_COUNT=$(echo "$RESPONSE" | wc -c | tr -d ' ')

# Limits
MAX_LINES=10
MAX_CHARS=500

# Check limits (warn but don't block - agent already completed)
if [[ "$LINE_COUNT" -gt "$MAX_LINES" ]] || [[ "$CHAR_COUNT" -gt "$MAX_CHARS" ]]; then
  # Log warning (PostToolUse can't deny, only add context)
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "warning": "Subagent response exceeded limits (${LINE_COUNT} lines, ${CHAR_COUNT} chars). Target: ${MAX_LINES} lines, ${MAX_CHARS} chars. Consider asking agents for more concise reports."
  }
}
EOF
  exit 0
fi

exit 0
