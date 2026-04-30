#!/bin/bash
# Sync skills, agents, prompts from bugbounty-agents-config to ~/.kiro
# Uses $HOME so it works for any user on any machine
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
KIRO="$HOME/.kiro"

# Sync skills
for skill_dir in "$REPO/skills"/*/; do
  name=$(basename "$skill_dir")
  mkdir -p "$KIRO/skills/$name"
  cp "$skill_dir"* "$KIRO/skills/$name/"
  echo "synced skill: $name"
done

# Sync agents (rewrite hardcoded /root or /home/... paths to $HOME)
if [ -d "$REPO/agents" ]; then
  mkdir -p "$KIRO/agents"
  for f in "$REPO/agents"/*.json; do
    name=$(basename "$f")
    sed "s|file:///[^\"]*/.kiro/|file://$KIRO/|g;
         s|skill:///[^\"]*/.kiro/|skill://$KIRO/|g" "$f" > "$KIRO/agents/$name"
    echo "synced agent: $name"
  done
fi

# Sync prompts
if [ -d "$REPO/prompts" ]; then
  mkdir -p "$KIRO/prompts"
  cp "$REPO/prompts"/* "$KIRO/prompts/"
  echo "synced prompts"
fi
