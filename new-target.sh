#!/usr/bin/env bash
# new-target.sh — scaffold a new bug bounty target directory for Claude Code
# Usage: ./new-target.sh <target-name> [base-dir]
# Example: ./new-target.sh acme-corp ~/BugBounty

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"

TARGET="${1:?Usage: new-target.sh <target-name> [base-dir]}"
BASE_DIR="${2:-$HOME/BugBounty}"
TARGET_DIR="$BASE_DIR/$TARGET"

if [[ -d "$TARGET_DIR" ]]; then
  echo "[-] Directory already exists: $TARGET_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

# Prompt -> CLAUDE.md (project instructions loaded automatically by Claude Code)
cp "$REPO/prompts/bugbounty.txt" "$TARGET_DIR/CLAUDE.md"

# Skills -> .claude/skills/<name>/
mkdir -p "$TARGET_DIR/.claude/skills"
for skill_dir in "$REPO/skills"/*/; do
  name="$(basename "$skill_dir")"
  mkdir -p "$TARGET_DIR/.claude/skills/$name"
  rsync -a --delete --exclude='.git' "$skill_dir" "$TARGET_DIR/.claude/skills/$name"/
done

# MCP servers -> .mcp.json (project-scoped MCP config)
cp "$REPO/settings/mcp.json" "$TARGET_DIR/.mcp.json"

# Scope file — referenced by the bugbounty prompt; fill in before testing
cat > "$TARGET_DIR/scope.txt" << EOF
Program : $TARGET
Platform: (e.g. HackerOne / Bugcrowd / Intigriti)
URL     :

IN SCOPE
--------


OUT OF SCOPE
------------


NOTES
-----

EOF

# Hunt script — starts the braindump loop + interactive bugbounty agent
cp "$REPO/hunt" "$TARGET_DIR/hunt"
chmod +x "$TARGET_DIR/hunt"

echo "[+] Target scaffolded: $TARGET_DIR"
echo ""
echo "    Next steps:"
echo "    1. Fill in $TARGET_DIR/scope.txt"
echo "    2. cd $TARGET_DIR"
echo "    3. ./hunt"
