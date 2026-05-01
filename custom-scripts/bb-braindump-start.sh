#!/usr/bin/env bash
# bb-braindump-start.sh — start the braindump loop in the background
# Called by bugbounty agent agentSpawn hook.
# Logs to /tmp/bb-braindump.log

LOGFILE="/tmp/bb-braindump.log"
PIDFILE="/tmp/bb-braindump.pid"
TSFILE="/tmp/bb-braindump-last.ts"
INTERVAL=300  # 5 minutes

# Check if already running
if [[ -f "$PIDFILE" ]]; then
  PID=$(cat "$PIDFILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[braindump] ✅ Already running (PID $PID) — log: $LOGFILE"
    exit 0
  else
    echo "[braindump] ⚠️  Stale PID found, restarting..."
    rm -f "$PIDFILE"
  fi
fi

# Init timestamp if missing
if [[ ! -f "$TSFILE" ]]; then
  date +%s%3N > "$TSFILE"
fi

# Start loop in background
(
  echo "[braindump] 🚀 Started at $(date)" >> "$LOGFILE"
  while true; do
    TS=$(cat "$TSFILE" 2>/dev/null || echo 0)
    echo "[braindump] $(date '+%Y-%m-%d %H:%M:%S') — running dump (last: $TS)" >> "$LOGFILE"

    # Run braindump agent headlessly
    BB_LAST_DUMP_TS="$TS" \
    kiro-cli chat \
      --agent bb-braindump \
      --no-interactive \
      --message "Run brain dump. BB_SESSION_ID=${BB_SESSION_ID:-} BB_TARGET_ID=${BB_TARGET_ID:-} BB_LAST_DUMP_TS=$TS" \
      >> "$LOGFILE" 2>&1

    EXIT=$?
    if [[ $EXIT -ne 0 ]]; then
      echo "[braindump] ⚠️  Exit code $EXIT at $(date)" >> "$LOGFILE"
    fi

    date +%s%3N > "$TSFILE"
    sleep "$INTERVAL"
  done
) &

BGPID=$!
echo $BGPID > "$PIDFILE"
echo "[braindump] ✅ Started (PID $BGPID) — log: $LOGFILE"
echo "[braindump] 📋 Tail logs: tail -f $LOGFILE"
