#!/usr/bin/env bash
# new-target.sh — scaffold a new bug bounty target directory
# Usage: new-target.sh <program-name> [base-dir]
# Example: new-target.sh hackerone-acme ~/BugBounty

set -e

PROGRAM="${1:?Usage: new-target.sh <program-name> [base-dir]}"
BASE_DIR="${2:-$HOME/BugBounty}"
TARGET_DIR="$BASE_DIR/$PROGRAM"

if [[ -d "$TARGET_DIR" ]]; then
  echo "[-] Directory already exists: $TARGET_DIR"
  exit 1
fi

# Create directory structure
mkdir -p "$TARGET_DIR"/{.kiro/agents,recon,fuzzing,ports,loot}

# Local agent override — inherits global prompt/skills, adds target context
cat > "$TARGET_DIR/.kiro/agents/bugbounty.json" << EOF
{
  "name": "bugbounty",
  "description": "Bug bounty agent — $PROGRAM",
  "prompt": "file:///root/.kiro/prompts/bugbounty.txt",
  "tools": ["fs_read", "fs_write", "execute_bash", "grep", "glob", "code"],
  "resources": [
    "skill:///root/.kiro/skills/bug-bounty-mapper-skill/SKILL.md",
    "skill:///root/.kiro/skills/fuzzing-skill/SKILL.md",
    "skill:///root/.kiro/skills/recon-skill/SKILL.md",
    "skill:///root/.kiro/skills/portscan-skill/SKILL.md",
    "file://scope.txt"
  ],
  "hooks": {
    "agentSpawn": [
      {
        "command": "echo '[BB] Target: $PROGRAM' && echo '[BB] Started: '\$(date) && echo '[BB] Scope:' && { cat scope.txt 2>/dev/null || echo '(scope.txt not filled yet)'; }",
        "description": "Show target context on spawn"
      }
    ]
  },
  "keyboardShortcut": "ctrl+shift+b",
  "welcomeMessage": "Loaded target: $PROGRAM. Check scope.txt before testing."
}
EOF

# Scope file — fill this in before starting
cat > "$TARGET_DIR/scope.txt" << EOF
Program : $PROGRAM
Platform: (e.g. HackerOne / Bugcrowd / Intigriti)
URL     : 

IN SCOPE
--------


OUT OF SCOPE
------------


NOTES
-----

EOF

echo "[+] Target scaffolded: $TARGET_DIR"
echo ""
echo "    Next steps:"
echo "    1. Fill in $TARGET_DIR/scope.txt"
echo "    2. cd $TARGET_DIR"
echo "    3. kiro-cli chat"
