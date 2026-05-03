---
name: burp-project-parser
description: >
  Search and extract data from Burp Suite .burp project files. Use when the user wants to
  analyze a local .burp file: search proxy history, site map, audit items, or regex-search
  response headers/bodies. Trigger phrases: "search the burp project", "find in burp file",
  "what vulnerabilities in the burp", "get audit items from burp", "search burp file".
---

# Burp Suite Project File Parser Skill

Parse `.burp` project files from the command line and extract data as JSON.

## Prerequisites

- Burp Suite Professional installed (Community edition does not support `.burp` project files)
- The extension jar installed at: `~/.kiro/skills/burp-project-parser/burpsuite-project-file-parser-all.jar`
- The extension must be loaded in Burp Suite with **Output set to system console**
- `jq` (optional, for filtering/formatting)

## Base Command

```bash
java -jar -Djava.awt.headless=true $BURP_JAR \
  --project-file=/path/to/project.burp \
  --user-config-file=$BURP_USER_CONFIG \
  [operation]
```

Set these env vars or substitute directly:
```bash
# Linux default paths
BURP_JAR="$HOME/BurpSuitePro/burpsuite_pro.jar"
BURP_USER_CONFIG="$HOME/.BurpSuite/UserConfigPro.json"   # optional but speeds up loading
PARSER_JAR="$HOME/.kiro/skills/burp-project-parser/burpsuite-project-file-parser-all.jar"
```

The extension jar is loaded via Burp's `--unpacked-burp-extension` flag or pre-configured in the user config. If using a dedicated user config with only this extension, add `--user-config-file` pointing to it.

Alternatively, run Burp headless with the extension already installed:
```bash
java -jar -Djava.awt.headless=true "$BURP_JAR" \
  --project-file="$BURP_FILE" \
  [operation flags]
```

## Operations

### Audit Items (scanner findings)
```bash
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp auditItems
# Filter high severity only:
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp auditItems | jq 'select(.severity == "High")'
```

### Proxy History
```bash
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp proxyHistory
# Sub-components (faster for large files):
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp proxyHistory.request.headers
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp proxyHistory.response.body
```

### Site Map
```bash
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp siteMap
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp siteMap.request.headers
```

### Search Response Headers (regex)
```bash
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp \
  "responseHeader='.*(nginx|Apache|Servlet).*'"
```

### Search Response Body (regex)
```bash
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp \
  "responseBody='.*<form.*'"
# Trim output to 80 chars around match:
... | grep -o -P -- "url\":.{0,100}|.{0,80}<form.{0,80}"
```

### Combine flags
```bash
java -jar -Djava.awt.headless=true "$BURP_JAR" --project-file=project.burp auditItems siteMap
```

## Performance Tips

- Use sub-components (`proxyHistory.request.headers`) to skip large response bodies
- Limit memory: add `-Xmx2G` before `-jar`
- Use a dedicated user config with only this extension loaded (`--user-config-file`) to speed up Burp startup

## Common Use Cases

**Find all high/critical findings:**
```bash
... auditItems | jq 'select(.severity == "High" or .severity == "Critical")'
```

**Find CORS headers:**
```bash
... "responseHeader='.*[Aa]ccess-[Cc]ontrol.*'"
```

**Find API keys / secrets in responses:**
```bash
... "responseBody='.*(?:api_key|secret|token|password).*'"
```

**List all unique URLs captured:**
```bash
... proxyHistory.request.headers | jq -r '.url' | sort -u
```

**Find forms (potential injection points):**
```bash
... "responseBody='.*<form.*'" | grep -o -P -- "url\":.{0,100}|.{0,80}<form.{0,80}"
```

## Output Format

All output is newline-delimited JSON (one object per line). Pipe to `jq` for pretty-printing or `grep` for filtering.
