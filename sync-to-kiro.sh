#!/bin/bash
# Syncs bugbounty-agents-config → ~/.kiro (excludes settings and sqlite db)
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.kiro"

rsync -av --exclude='.git' \
          --exclude='sync-to-kiro.sh' \
          --exclude='settings/' \
          --exclude='*.sqlite3' \
          --exclude='.cli_bash_history' \
          "$SRC/" "$DEST/"

echo "✅ Synced to $DEST"
