#!/bin/bash
#
# PostToolUse:Bash (async) - Capture knowledge from bd comment commands
#
# Detects: bd comment {BEAD_ID} "LEARNED: ..."
# Extracts knowledge entries into .beads/memory/knowledge.jsonl
#

INPUT=$(cat)
TOOL_NAPROMPT=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('prompt', ''))")
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_name', ''))")

# Only process Bash tool
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

# Extract the command that was executed
COMMAND=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))")
[[ -z "$COMMAND" ]] && exit 0

# Only process bd comment commands containing knowledge markers
echo "$COMMAND" | grep -qE 'bd\s+comment\s+' || exit 0
echo "$COMMAND" | grep -qE 'LEARNED:' || exit 0

# Extract BEAD_ID (argument after "bd comment")
BEAD_ID=$(echo "$COMMAND" | sed -E 's/.*bd[[:space:]]+comment[[:space:]]+([A-Za-z0-9._-]+)[[:space:]]+.*/\1/')
[[ -z "$BEAD_ID" || "$BEAD_ID" == "$COMMAND" ]] && exit 0

# Extract the comment body (content inside quotes after bead ID)
COMMENT_BODY=$(echo "$COMMAND" | sed -E 's/.*bd[[:space:]]+comment[[:space:]]+[A-Za-z0-9._-]+[[:space:]]+["'\'']//' | sed -E 's/["'\''][[:space:]]*$//' | head -c 4096)
[[ -z "$COMMENT_BODY" ]] && exit 0

# Determine type and extract content (voluntary LEARNED only)
TYPE=""
CONTENT=""
if echo "$COMMENT_BODY" | grep -q "LEARNED:"; then
  TYPE="learned"
  CONTENT=$(echo "$COMMENT_BODY" | sed 's/.*LEARNED:[[:space:]]*//' | head -c 2048)
fi

[[ -z "$TYPE" || -z "$CONTENT" ]] && exit 0

# Generate key from content (type + slugified first 60 chars)
SLUG=$(echo "$CONTENT" | head -c 60 | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
KEY="${TYPE}-${SLUG}"

# Detect source agent from CWD or transcript context
SOURCE="orchestrator"
CWD=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('cwd', ''))")
if echo "$CWD" | grep -q '\.worktrees/'; then
  # Inside a worktree = supervisor is running
  SOURCE="supervisor"
fi

# Build tags array - start with type tag
TAGS_ARRAY=("$TYPE")

# Scan content for known tech keywords and add matching tags
for tag in swift swiftui appkit menubar api security test database \
           networking ui layout performance crash bug fix workaround \
           gotcha pattern convention architecture auth middleware \
           async concurrency model protocol adapter scanner engine; do
  if echo "$CONTENT" | grep -qi "$tag"; then
    TAGS_ARRAY+=("$tag")
  fi
done

# Convert tags array to JSON
TAGS_JSON=$(python3 -c "import sys, json; print(json.dumps(sys.argv[1:]))" "${TAGS_ARRAY[@]}")

# Get timestamp
TS=$(date +%s)

# Build JSON entry with proper escaping
ENTRY=$(python3 -c "import sys, json; print(json.dumps({'key': sys.argv[1], 'type': sys.argv[2], 'content': sys.argv[3], 'source': sys.argv[4], 'tags': json.loads(sys.argv[5]), 'ts': int(sys.argv[6]), 'bead': sys.argv[7]}))" "$KEY" "$TYPE" "$CONTENT" "$SOURCE" "$TAGS_JSON" "$TS" "$BEAD_ID")

# Validate JSON
[[ -z "$ENTRY" ]] && exit 0
echo "$ENTRY" | python3 -c "import sys, json; json.load(sys.stdin)" >/dev/null 2>&1 || exit 0

# Resolve memory directory
MEMORY_DIR="${CLAUDE_PROJECT_DIR:-.}/.beads/memory"
mkdir -p "$MEMORY_DIR"
KNOWLEDGE_FILE="$MEMORY_DIR/knowledge.jsonl"

# Append entry
echo "$ENTRY" >> "$KNOWLEDGE_FILE"

# Rotation: archive oldest 500 when file exceeds 1000 lines
LINE_COUNT=$(wc -l < "$KNOWLEDGE_FILE" 2>/dev/null | tr -d ' ')
if [[ "$LINE_COUNT" -gt 1000 ]]; then
  ARCHIVE_FILE="$MEMORY_DIR/knowledge.archive.jsonl"
  head -500 "$KNOWLEDGE_FILE" >> "$ARCHIVE_FILE"
  tail -n +501 "$KNOWLEDGE_FILE" > "$KNOWLEDGE_FILE.tmp"
  mv "$KNOWLEDGE_FILE.tmp" "$KNOWLEDGE_FILE"
fi

exit 0
