#!/usr/bin/env bash
# bb-spawn-context.sh
# agentSpawn hook for bugbounty agent.
# Reads scope.txt from cwd, resolves target in BB-Mapper, and injects existing notes as context.

set -euo pipefail

BBM=$(which bbm 2>/dev/null || find / -name bbm -type f -executable 2>/dev/null | head -1 || true)
if [[ -z "$BBM" ]]; then
  echo "[bb-context] bbm not found, skipping context injection." >&2
  exit 0
fi

CWD=$(echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null || pwd)

# Try to get target name from scope.txt
TARGET_NAME=""
if [[ -f "$CWD/scope.txt" ]]; then
  TARGET_NAME=$(head -1 "$CWD/scope.txt" | tr -d '[:space:]')
fi

if [[ -z "$TARGET_NAME" ]]; then
  echo "[bb-context] No scope.txt found in $CWD. Skipping context injection."
  exit 0
fi

# Resolve target ID
TARGET_ID=$($BBM targets list 2>/dev/null | python3 -c "
import sys, json
targets = json.load(sys.stdin)
name = '$TARGET_NAME'.lower()
for t in targets:
    if t.get('name','').lower() == name or name in t.get('name','').lower():
        print(t['id'])
        break
" 2>/dev/null || true)

if [[ -z "$TARGET_ID" ]]; then
  echo "[bb-context] Target '$TARGET_NAME' not found in BB-Mapper."
  exit 0
fi

# Pull existing notes and recent activity
MAIN_NOTES=$($BBM notes get-target-main "$TARGET_ID" 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('content', '') or d.get('notes', '') or '')
" 2>/dev/null | head -100 || true)

RECENT_ACTIVITY=$($BBM activity --entity-type note 2>/dev/null | python3 -c "
import sys, json
items = json.load(sys.stdin)
for item in (items if isinstance(items, list) else items.get('items', []))[:10]:
    print(f\"- [{item.get('created_at','')}] {item.get('action','')} on {item.get('entity_type','')} {item.get('entity_id','')}\")
" 2>/dev/null || true)

# Output injected into agent context via stdout
cat <<EOF
## BB-Mapper Context for $TARGET_NAME (ID: $TARGET_ID)

### Existing Target Notes (last 100 lines):
${MAIN_NOTES:-"(no notes yet)"}

### Recent Activity:
${RECENT_ACTIVITY:-"(no recent activity)"}

---
Target ID for this session: $TARGET_ID
Use this ID for all bbm commands. Do not repeat work already documented above.
EOF

exit 0
