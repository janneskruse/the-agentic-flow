#!/bin/bash
#
# SubagentStop: Enforce completion format and verbosity limits
#

INPUT=$(cat)
AGENT_TRANSCRIPT=$(echo "$INPUT" | jq -r '.agent_transcript_path // empty')

[[ -z "$AGENT_TRANSCRIPT" || ! -f "$AGENT_TRANSCRIPT" ]] && echo '{"decision":"approve"}' && exit 0

# Extract last response
LAST_RESPONSE=$(tail -50 "$AGENT_TRANSCRIPT" | grep -o '"text":"[^"]*"' | tail -1 | sed 's/"text":"//;s/"$//')

# Check for supervisor agents
AGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // empty')

if [[ "$AGENT_TYPE" =~ supervisor ]]; then
  # Worker supervisor is exempt from bead requirements
  IS_WORKER="false"
  if [[ "$AGENT_TYPE" == *"worker"* ]]; then
    IS_WORKER="true"
  fi

  if [[ "$IS_WORKER" == "false" ]]; then
    # Check if this is an epic child task (BEAD_ID contains dot like BD-001.1)
    BEAD_ID_FROM_RESPONSE=$(echo "$LAST_RESPONSE" | grep -oE "BEAD [A-Za-z0-9._-]+" | head -1 | awk '{print $2}')
    IS_EPIC_CHILD="false"
    if [[ "$BEAD_ID_FROM_RESPONSE" == *"."* ]]; then
      IS_EPIC_CHILD="true"
    fi

    # Supervisors must include completion report
    HAS_BEAD_COMPLETE=$(echo "$LAST_RESPONSE" | grep -cE "BEAD.*COMPLETE" 2>/dev/null || true)
    HAS_BRANCH=$(echo "$LAST_RESPONSE" | grep -cE "Branch:.*bd-" 2>/dev/null || true)
    [[ -z "$HAS_BEAD_COMPLETE" ]] && HAS_BEAD_COMPLETE=0
    [[ -z "$HAS_BRANCH" ]] && HAS_BRANCH=0

    # Check completion format (required for all)
    if [[ "$HAS_BEAD_COMPLETE" -lt 1 ]] || [[ "$HAS_BRANCH" -lt 1 ]]; then
      if [[ "$IS_EPIC_CHILD" == "true" ]]; then
        cat << 'EOF'
{"decision":"block","reason":"Epic child task completion format required:\n\nBEAD {BEAD_ID} COMPLETE\nBranch: {EPIC_BRANCH}\nFiles: [list]\nSummary: [1 sentence]\n\nRun: bd update {BEAD_ID} --status done"}
EOF
      else
        cat << 'EOF'
{"decision":"block","reason":"Supervisor must use completion report format:\n\nBEAD {BEAD_ID} COMPLETE\nBranch: bd-{BEAD_ID}\nFiles: [list]\nTests: pass\nSummary: [1 sentence]\n\nRun bd update {BEAD_ID} --status inreview first."}
EOF
      fi
      exit 0
    fi

    # Check for at least 1 comment
    HAS_COMMENT=$(grep -c '"bd comment\|"command":"bd comment' "$AGENT_TRANSCRIPT" 2>/dev/null) || HAS_COMMENT=0
    [[ -z "$HAS_COMMENT" ]] && HAS_COMMENT=0

    if [[ "$HAS_COMMENT" -lt 1 ]]; then
      cat << 'EOF'
{"decision":"block","reason":"Supervisor must leave at least 1 comment on the bead.\n\nRun: bd comment {BEAD_ID} \"Completed: [brief summary of work done]\""}
EOF
      exit 0
    fi
  fi

  # Enforce concise responses for ALL supervisors (including worker)
  DECODED_RESPONSE=$(printf '%b' "$LAST_RESPONSE")
  LINE_COUNT=$(echo "$DECODED_RESPONSE" | wc -l | tr -d ' ')
  CHAR_COUNT=${#DECODED_RESPONSE}

  if [[ "$LINE_COUNT" -gt 15 ]] || [[ "$CHAR_COUNT" -gt 800 ]]; then
    cat << EOF
{"decision":"block","reason":"Response too verbose (${LINE_COUNT} lines, ${CHAR_COUNT} chars). Max: 15 lines, 800 chars.\n\nUse concise format:\nBEAD {ID} COMPLETE\nBranch: bd-{ID}\nFiles: [names only]\nTests: pass\nSummary: [1 sentence]"}
EOF
    exit 0
  fi
fi

echo '{"decision":"approve"}'
