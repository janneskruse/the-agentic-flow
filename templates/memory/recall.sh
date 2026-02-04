#!/bin/bash
#
# recall.sh - Search the project knowledge base
#
# Usage:
#   .beads/memory/recall.sh "keyword"                  # Search by keyword
#   .beads/memory/recall.sh "keyword" --type learned   # Filter by type
#   .beads/memory/recall.sh --recent 10                # Show N most recent
#   .beads/memory/recall.sh --stats                    # Knowledge base stats
#   .beads/memory/recall.sh "keyword" --all            # Include archive
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KNOWLEDGE_FILE="$SCRIPT_DIR/knowledge.jsonl"
ARCHIVE_FILE="$SCRIPT_DIR/knowledge.archive.jsonl"

if [[ ! -f "$KNOWLEDGE_FILE" ]] || [[ ! -s "$KNOWLEDGE_FILE" ]]; then
  echo "No knowledge entries yet."
  echo "Entries are created automatically from bd comment commands with INVESTIGATION: or LEARNED: prefixes."
  exit 0
fi

# Parse arguments
QUERY=""
TYPE_FILTER=""
INCLUDE_ARCHIVE=false
SHOW_RECENT=0
SHOW_STATS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE_FILTER="${2:-}"
      shift 2
      ;;
    --all)
      INCLUDE_ARCHIVE=true
      shift
      ;;
    --recent)
      SHOW_RECENT="${2:-10}"
      shift 2
      ;;
    --stats)
      SHOW_STATS=true
      shift
      ;;
    --help|-h)
      echo "Usage: recall.sh [query] [--type learned|investigation] [--all] [--recent N] [--stats]"
      exit 0
      ;;
    *)
      QUERY="$1"
      shift
      ;;
  esac
done

# Stats mode
if [[ "$SHOW_STATS" == "true" ]]; then
  TOTAL=$(wc -l < "$KNOWLEDGE_FILE" | tr -d ' ')
  LEARNED=$(grep -c '"type":"learned"' "$KNOWLEDGE_FILE" 2>/dev/null) || LEARNED=0
  INVESTIGATION=$(grep -c '"type":"investigation"' "$KNOWLEDGE_FILE" 2>/dev/null) || INVESTIGATION=0
  UNIQUE_KEYS=$(python3 -c "import sys, json; data = [json.loads(l) for l in sys.stdin if l.strip()]; print(len(set(i.get('key') for i in data)))" < "$KNOWLEDGE_FILE" 2>/dev/null || echo "0")
  ARCHIVE_COUNT=0
  [[ -f "$ARCHIVE_FILE" ]] && ARCHIVE_COUNT=$(wc -l < "$ARCHIVE_FILE" | tr -d ' ')

  echo "## Knowledge Base Stats"
  echo "  Active entries: $TOTAL"
  echo "  Unique keys:    $UNIQUE_KEYS"
  echo "  Learned:        $LEARNED"
  echo "  Investigation:  $INVESTIGATION"
  echo "  Archived:       $ARCHIVE_COUNT"
  exit 0
fi

# Recent mode
if [[ "$SHOW_RECENT" -gt 0 ]]; then
  echo "## Recent Knowledge ($SHOW_RECENT entries)"
  echo ""
  tail -"$SHOW_RECENT" "$KNOWLEDGE_FILE" | python3 -c "import sys, json; lines = sys.stdin.readlines(); [print('[{}] {}\n  {}\n  source={} bead={}\n'.format(json.loads(l).get('type', '').upper()[:5], json.loads(l).get('key'), json.loads(l).get('content', '')[:120], json.loads(l).get('source'), json.loads(l).get('bead'))) for l in lines if l.strip()]" 2>/dev/null
  exit 0
fi

# Search mode (default)
if [[ -z "$QUERY" ]]; then
  echo "Usage: recall.sh <keyword> [--type learned|investigation] [--all]"
  exit 1
fi

# Build file list
FILES="$KNOWLEDGE_FILE"
if [[ "$INCLUDE_ARCHIVE" == "true" && -f "$ARCHIVE_FILE" ]]; then
  FILES="$ARCHIVE_FILE $KNOWLEDGE_FILE"
fi

# Search and deduplicate (latest entry for each key wins)
RESULTS=$(cat $FILES | grep -i "$QUERY" 2>/dev/null || true)

# Apply type filter
if [[ -n "$TYPE_FILTER" ]]; then
  RESULTS=$(echo "$RESULTS" | grep "\"type\":\"$TYPE_FILTER\"" 2>/dev/null || true)
fi

if [[ -z "$RESULTS" ]]; then
  echo "No knowledge entries matching '$QUERY'"
  [[ -n "$TYPE_FILTER" ]] && echo "  (filtered by type: $TYPE_FILTER)"
  exit 0
fi

# Deduplicate by key (latest wins) and format output
echo "$RESULTS" | python3 -c "import sys, json; lines = sys.stdin.readlines(); data = [json.loads(l) for l in lines if l.strip()]; grouped = {}; [grouped.update({i.get('key'): i}) for i in data]; sorted_data = sorted(grouped.values(), key=lambda x: x.get('ts', 0), reverse=True); [print('[{}] {}\n  {}\n  source={} bead={} tags={}\n'.format(i.get('type', '').upper()[:5], i.get('key'), i.get('content', '')[:200], i.get('source'), i.get('bead'), ','.join(i.get('tags', [])))) for i in sorted_data]" 2>/dev/null

exit 0
