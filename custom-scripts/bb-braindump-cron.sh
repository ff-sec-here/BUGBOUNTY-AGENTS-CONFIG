#!/usr/bin/env bash
# bb-braindump-cron.sh
# Called every 5 minutes by cron while a bugbounty session is active.
# Finds the most recent active bugbounty session and delegates to bb-braindump agent.

set -euo pipefail

LOG="/tmp/bb-braindump.log"
TS_FILE="/tmp/bb-braindump-last.ts"
DB="$HOME/.local/share/kiro-cli/data.sqlite3"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

# Find the most recently updated bugbounty session (cwd contains bugbounty work dirs)
# We identify bugbounty sessions by checking if the conversation has bugbounty agent activity
SESSION_ID=$(sqlite3 "$DB" "
  SELECT conversation_id FROM conversations_v2
  WHERE updated_at > (strftime('%s','now') - 3600) * 1000
  ORDER BY updated_at DESC
  LIMIT 1;
" 2>/dev/null || true)

if [[ -z "$SESSION_ID" ]]; then
  log "No active session in the last hour. Exiting."
  exit 0
fi

# Check if this session has bugbounty-related content (bbm or recon tools)
HAS_BB=$(sqlite3 "$DB" "
  SELECT 1 FROM conversations_v2
  WHERE conversation_id='$SESSION_ID'
  AND (value LIKE '%bbm%' OR value LIKE '%subfinder%' OR value LIKE '%ffuf%' OR value LIKE '%bugbounty%')
  LIMIT 1;
" 2>/dev/null || true)

if [[ -z "$HAS_BB" ]]; then
  log "Session $SESSION_ID has no bugbounty activity. Exiting."
  exit 0
fi

# Get last dump timestamp (default: 5 minutes ago)
if [[ -f "$TS_FILE" ]]; then
  LAST_TS=$(cat "$TS_FILE")
else
  LAST_TS=$(( ($(date +%s) - 300) * 1000 ))
fi

# Try to extract target ID from session (look for bbm targets get/stats calls)
BB_TARGET_ID=$(sqlite3 "$DB" "
  SELECT value FROM conversations_v2
  WHERE conversation_id='$SESSION_ID'
  LIMIT 1;
" 2>/dev/null | python3 -c "
import sys, json, re
try:
    d = json.load(sys.stdin)
    history = d.get('history', [])
    for entry in history:
        assistant = str(entry.get('assistant', ''))
        # look for bbm targets get <id> or target_id patterns
        m = re.search(r'bbm targets (?:get|stats|notes) (\d+)', assistant)
        if m:
            print(m.group(1))
            break
        m = re.search(r'target[_\s]id[=:\s]+(\d+)', assistant, re.I)
        if m:
            print(m.group(1))
            break
except:
    pass
" 2>/dev/null || true)

log "Session: $SESSION_ID | Target: ${BB_TARGET_ID:-unknown} | Last dump: $LAST_TS"

# Invoke bb-braindump agent via kiro-cli
export BB_SESSION_ID="$SESSION_ID"
export BB_TARGET_ID="${BB_TARGET_ID:-}"
export BB_LAST_DUMP_TS="$LAST_TS"

kiro-cli chat \
  --agent bb-braindump \
  --no-interactive \
  --trust-all-tools \
  "Run brain dump for session $BB_SESSION_ID, target ${BB_TARGET_ID:-unknown}, since timestamp $LAST_TS." \
  >> "$LOG" 2>&1 && log "Brain dump complete." || log "Brain dump failed."

# Update timestamp
date +%s%3N > "$TS_FILE"
