#!/usr/bin/env bash
# Render a Mermaid file to PNG locally (offline). Usage:
#   render_diagram.sh <input.mmd> <output.png>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <input.mmd> <output.png>" >&2
  exit 2
fi

in="$1"
out="$2"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cfg="$here/puppeteer-config.json"

[ -f "$in" ] || { echo "input not found: $in" >&2; exit 1; }

if command -v mmdc >/dev/null 2>&1; then
  mmdc -p "$cfg" -i "$in" -o "$out" -b white -s 2
else
  # Fallback without a global install; first run downloads the package.
  npx --yes -p @mermaid-js/mermaid-cli mmdc -p "$cfg" -i "$in" -o "$out" -b white -s 2
fi

echo "wrote $out"
