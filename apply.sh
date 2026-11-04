#!/bin/bash
# Apply skills/agents/prompts from this repo to one or more coding agent tools.
# Supported targets: kiro-cli, claude-code, opencode (default: all three).
#
# Usage:
#   ./apply.sh                 # apply to every supported target
#   ./apply.sh kiro-cli
#   ./apply.sh claude-code opencode
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO/skills"
AGENTS_DIR="$REPO/agents"
PROMPTS_DIR="$REPO/prompts"

ALL_TARGETS=(kiro-cli claude-code opencode)

if [ "$#" -eq 0 ]; then
  TARGETS=("${ALL_TARGETS[@]}")
else
  TARGETS=("$@")
  for t in "${TARGETS[@]}"; do
    case "$t" in
      kiro-cli|claude-code|opencode) ;;
      *)
        echo "Unknown target: $t (expected: kiro-cli, claude-code, opencode)" >&2
        exit 1
        ;;
    esac
  done
fi

copy_skill_dir() {
  # copy_skill_dir <src_skill_dir> <dest_skill_dir>
  local src="$1" dest="$2"
  mkdir -p "$dest"
  # Mirror the whole skill folder (SKILL.md plus references/, scripts/, etc.),
  # not just top-level files.
  rsync -a --delete --exclude='.git' "$src"/ "$dest"/
}

# ---------------------------------------------------------------------------
# kiro-cli: ~/.kiro/{skills,agents,prompts}
# ---------------------------------------------------------------------------
apply_kiro_cli() {
  local KIRO="$HOME/.kiro"
  echo "== kiro-cli =="

  for skill_dir in "$SKILLS_DIR"/*/; do
    name=$(basename "$skill_dir")
    copy_skill_dir "$skill_dir" "$KIRO/skills/$name"
    echo "  skill: $name"
  done

  if [ -d "$AGENTS_DIR" ]; then
    mkdir -p "$KIRO/agents"
    for f in "$AGENTS_DIR"/*.json; do
      [ -e "$f" ] || continue
      name=$(basename "$f")
      sed "s|file:///[^\"]*/.kiro/|file://$KIRO/|g;
           s|skill:///[^\"]*/.kiro/|skill://$KIRO/|g" "$f" > "$KIRO/agents/$name"
      echo "  agent: $name"
    done
  fi

  if [ -d "$PROMPTS_DIR" ]; then
    mkdir -p "$KIRO/prompts"
    cp "$PROMPTS_DIR"/* "$KIRO/prompts/"
    echo "  prompts synced"
  fi
}

# ---------------------------------------------------------------------------
# claude-code: ~/.claude/skills/<name>/SKILL.md, ~/.claude/agents/<name>.md
# ---------------------------------------------------------------------------
apply_claude_code() {
  local CLAUDE="$HOME/.claude"
  echo "== claude-code =="

  for skill_dir in "$SKILLS_DIR"/*/; do
    name=$(basename "$skill_dir")
    copy_skill_dir "$skill_dir" "$CLAUDE/skills/$name"
    echo "  skill: $name"
  done

  if [ -d "$AGENTS_DIR" ]; then
    mkdir -p "$CLAUDE/agents"
    for f in "$AGENTS_DIR"/*.json; do
      [ -e "$f" ] || continue
      base=$(basename "$f" .json)
      out="$CLAUDE/agents/$base.md"
      convert_agent_to_markdown "$f" "$out" "claude-code"
      echo "  agent: $base.md"
    done
  fi
}

# ---------------------------------------------------------------------------
# opencode: ~/.config/opencode/skills/<name>/SKILL.md, .../agents/<name>.md
# ---------------------------------------------------------------------------
apply_opencode() {
  local OC="$HOME/.config/opencode"
  echo "== opencode =="

  for skill_dir in "$SKILLS_DIR"/*/; do
    name=$(basename "$skill_dir")
    copy_skill_dir "$skill_dir" "$OC/skills/$name"
    echo "  skill: $name"
  done

  if [ -d "$AGENTS_DIR" ]; then
    mkdir -p "$OC/agents"
    for f in "$AGENTS_DIR"/*.json; do
      [ -e "$f" ] || continue
      base=$(basename "$f" .json)
      out="$OC/agents/$base.md"
      convert_agent_to_markdown "$f" "$out" "opencode"
      echo "  agent: $base.md"
    done
  fi
}

# Kiro agent JSON -> subagent markdown (claude-code / opencode).
# Both tools use YAML frontmatter + a markdown body as the system prompt.
# Kiro-specific fields with no equivalent (hooks, keyboardShortcut,
# toolsSettings) are dropped; a note is left in the body so nothing is
# silently lost.
convert_agent_to_markdown() {
  local src="$1" out="$2" flavor="$3"
  REPO="$REPO" PROMPTS_DIR="$PROMPTS_DIR" SKILLS_DIR="$SKILLS_DIR" FLAVOR="$flavor" \
    python3 -I - "$src" "$out" <<'PYEOF'
import json, os, re, sys

src, out = sys.argv[1], sys.argv[2]
flavor = os.environ["FLAVOR"]
repo = os.environ["REPO"]
prompts_dir = os.environ["PROMPTS_DIR"]
skills_dir = os.environ["SKILLS_DIR"]

with open(src) as fh:
    cfg = json.load(fh)

name = cfg.get("name", os.path.splitext(os.path.basename(src))[0])
description = (cfg.get("description") or "").strip()

def resolve_prompt(ref):
    if not ref:
        return ""
    ref = re.sub(r"^file://", "", ref)
    # kiro refs often point at /root/.kiro/prompts/<file> or ./relative paths
    candidates = []
    base = os.path.basename(ref)
    candidates.append(os.path.join(prompts_dir, base))
    candidates.append(os.path.join(os.path.dirname(src), ref))
    candidates.append(ref)
    for c in candidates:
        if os.path.isfile(c):
            with open(c) as fh:
                return fh.read().strip()
    return f"<!-- could not resolve prompt reference: {ref} -->"

prompt_body = resolve_prompt(cfg.get("prompt"))

skill_names = []
for res in cfg.get("resources", []):
    m = re.search(r"/skills/([^/]+)/SKILL\.md$", res)
    if m:
        skill_names.append(m.group(1))

tools = cfg.get("tools") or cfg.get("allowedTools") or []

lines = ["---", f"name: {name}"]
if description:
    esc = description.replace('"', '\\"')
    lines.append(f'description: "{esc}"')
if flavor == "claude-code":
    if tools:
        lines.append(f"tools: {', '.join(tools)}")
elif flavor == "opencode":
    lines.append("mode: subagent")
    if tools:
        lines.append("permission:")
        for t in tools:
            lines.append(f"  {t}: allow")
lines.append("---")
lines.append("")
if prompt_body:
    lines.append(prompt_body)
    lines.append("")

if skill_names:
    lines.append("## Related skills")
    lines.append("")
    lines.append("Consult these skills (installed alongside this agent) when their trigger conditions apply:")
    lines.append("")
    for s in skill_names:
        lines.append(f"- {s}")
    lines.append("")

dropped = [k for k in ("hooks", "keyboardShortcut", "toolsSettings", "welcomeMessage") if cfg.get(k)]
if dropped:
    lines.append(f"<!-- Not ported from the kiro-cli agent config (no {flavor} equivalent): {', '.join(dropped)} -->")
    lines.append("")

with open(out, "w") as fh:
    fh.write("\n".join(lines).rstrip() + "\n")
PYEOF
}

for t in "${TARGETS[@]}"; do
  case "$t" in
    kiro-cli) apply_kiro_cli ;;
    claude-code) apply_claude_code ;;
    opencode) apply_opencode ;;
  esac
done
