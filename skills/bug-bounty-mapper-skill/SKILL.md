---
name: bug-bounty-mapper
description: >
  Use the `bbm` CLI to interact with BB-Manager at mapper.fhdsec.info.
  Use when the user wants to manage bug bounty data: targets, subdomains, notes,
  checklists, scans, fuzzing, ports, alerts, dorking, JS recon, and more.
---

# Bug Bounty Mapper — bbm CLI Skill

## Setup

```bash
export BBM_BASE_URL="https://mapper.fhdsec.info/api"
# CF auth is built-in — no token needed
```

Locate `bbm` before using it:
```bash
# Option 1: if installed globally
which bbm

# Option 2: find it in the repo
find / -name "bbm" -type f -executable 2>/dev/null | head -1

# Option 3: run directly from repo
BBM=$(find / -name "bbm" -type f -executable 2>/dev/null | head -1)
$BBM targets list
```

Once found, optionally alias it:
```bash
alias bbm="$(which bbm 2>/dev/null || find / -name bbm -type f -executable 2>/dev/null | head -1)"
```

All output is JSON. Pipe to `jq` for filtering.

---

## Quick Reference

```
bbm <resource> <action> [args] [--flags]
```

### Targets
```bash
bbm targets list
bbm targets get <id>
bbm targets create --name "BitGo" --program-url "https://..." --status active
bbm targets update <id> --name "..." --status paused
bbm targets delete <id>
bbm targets stats <id>
bbm targets alerts <id>
bbm targets ip-addresses <id>
bbm targets historical-urls <id>
bbm targets scan-now <id>
bbm targets scan-history <id>
bbm targets snapshots-summary <id>
```

### Subdomains
```bash
bbm subdomains list <target_id> [--search X] [--notable] [--alive] [--page N] [--page-size N]
bbm subdomains get <id>
bbm subdomains notable <target_id>
bbm subdomains stats <target_id>
bbm subdomains export <target_id>
bbm subdomains add <target_id> --domain sub.example.com
bbm subdomains bulk-add <target_id> sub1.com sub2.com sub3.com
bbm subdomains bulk-notable <target_id> sub1.com sub2.com        # mark notable by domain
bbm subdomains bulk-unnotable <target_id> --ids 10 20 30         # unmark notable by ID (reliable)
bbm subdomains toggle-notable <id>
bbm subdomains notable-ports <id> --ports 80 443 8080
bbm subdomains update <id> [--notable] [--tags tag1 tag2]
bbm subdomains delete <id>
bbm subdomains history <id>
```

### Excluded Subdomains
```bash
bbm excluded list <target_id>
bbm excluded add <target_id> "*.noise.com"
bbm excluded delete <id>
```

### Notes
```bash
bbm notes get-target <target_id>
bbm notes get-target-main <target_id>
bbm notes update-target <target_id> "## Findings\n\ncontent here"
bbm notes update-target <target_id> "appended content" --append   # append instead of replace
bbm notes get-subdomain <subdomain_id>
bbm notes update-subdomain <subdomain_id> "XSS found at /search"
bbm notes update-subdomain <subdomain_id> "more info" --append
bbm notes delete <note_id>
```

### Scope
```bash
bbm scope list <target_id>
bbm scope add <target_id> "*.bitgo.com" --type include [--wildcard] [--notes "..."]
bbm scope update <id> --type exclude
bbm scope delete <id>
```

### Scans
```bash
bbm scans list
bbm scans get <id>
bbm scans create <target_id> [--agent-id N] [--scan-types subdomains ports fuzzing]
bbm scans cancel <id>
bbm scans retry <id>
bbm scans logs <id>
bbm scans agent-logs <id>
```

### Scan Dashboard
```bash
bbm scan-dashboard active
bbm scan-dashboard queued
bbm scan-dashboard history
bbm scan-dashboard metrics
```

### Scan Agents
```bash
bbm agents list
bbm agents get <id>
bbm agents status <id>
```

### Alerts
```bash
bbm alerts list [--target-id N] [--alert-type X] [--state unread|read|acknowledged] [--notable]
bbm alerts get <id>
bbm alerts stats
bbm alerts set-state <id> acknowledged
bbm alerts toggle-notable <id>
bbm alerts set-note <id> "note text"
bbm alerts delete <id>
bbm alerts delete-all
bbm alerts delete-target --target-id <id>
bbm alerts bulk-delete --ids 1 2 3
```

### Checklists
```bash
bbm checklists list [--target-id N]
bbm checklists get <id>
bbm checklists create --name "OWASP Top 10" [--description "..."] [--category "web"]
bbm checklists update <id> --name "..."
bbm checklists delete <id>
bbm checklists export <id>
bbm checklists items <id>
bbm checklists add-item <id> --title "Test XSS" [--description "..."] [--category "injection"]
bbm checklists attach-target <id> --target-id <tid>
bbm checklists detach-target <id> --target-id <tid>
bbm checklists attach-subdomain <id> --subdomain-id <sid>
bbm checklists detach-subdomain <id> --subdomain-id <sid>
```

### Progress
```bash
bbm progress dashboard <target_id>
bbm progress combined
bbm progress target <target_id>
bbm progress subdomain <subdomain_id>
bbm progress toggle-target <item_id> <target_id>
bbm progress toggle-subdomain <item_id> <subdomain_id>
bbm progress findings-target <item_id> <target_id> "markdown findings"
bbm progress findings-subdomain <item_id> <subdomain_id> "markdown findings"
```

### JS Recon
```bash
bbm jsrecon stats <target_id>
bbm jsrecon scan <target_id>
bbm jsrecon scans <target_id>
bbm jsrecon files <target_id>
bbm jsrecon findings <target_id>
bbm jsrecon endpoints <target_id>
bbm jsrecon urls <target_id>
bbm jsrecon delete <target_id>
```

### Fuzzing
```bash
bbm fuzzing results --subdomain-id <id>
bbm fuzzing all-results --target-id <id>
bbm fuzzing stats-target --target-id <id>
bbm fuzzing stats-subdomain --subdomain-id <id>
bbm fuzzing notable-subdomains --target-id <id>
bbm fuzzing subdomains-stats --target-id <id>
bbm fuzzing delete --id <result_id>
bbm fuzzing delete-subdomain --subdomain-id <id>
```

### Open Ports
```bash
bbm ports results --subdomain-id <id>
bbm ports stats-target --target-id <id>
bbm ports stats-subdomain --subdomain-id <id>
bbm ports all-subdomains --target-id <id>
bbm ports subdomains-stats --target-id <id>
bbm ports filter-values --target-id <id>
bbm ports delete --id <port_id>
bbm ports delete-subdomain --subdomain-id <id>
```

### Dorking
```bash
bbm dorking providers <target_id> [--mode scope|wildcard|cidr]
bbm dorking dorks <target_id> --provider google [--mode scope]
bbm dorking open <target_id> --dork-id <id> [--mode scope] [--context "*.bitgo.com"]
bbm dorking bulk-open <target_id> --provider google [--mode scope]
bbm dorking bulk-mark-checked <target_id>
bbm dorking reset <target_id>
```

### Vhost Scans
```bash
bbm vhost list
bbm vhost get <id>
bbm vhost create --target-id <id>
bbm vhost findings <id>
bbm vhost complete <id>
bbm vhost delete <id>
```

### Snapshots
```bash
bbm snapshots summary <target_id>
bbm snapshots create <target_id>
bbm snapshots history <target_id> --type subdomains
bbm snapshots compare <target_id> --type subdomains
```

### Quick Links
```bash
bbm quick-links list
bbm quick-links categories
bbm quick-links get <id>
bbm quick-links create --title "Shodan" --url "https://shodan.io" --category "recon"
bbm quick-links update <id> --title "..."
bbm quick-links delete <id>
```

### Activity Log
```bash
bbm activity [--entity-type subdomain|target|note|...]
```

### Settings
```bash
bbm settings alerts-get [--target-id N]
bbm settings telegram-get
bbm settings telegram-test
bbm settings slack-get
bbm settings slack-test
bbm settings dorks-list
```

---

## Common Workflows

### Recon on target X
```bash
ID=$(bbm targets list | jq '.[] | select(.name=="BitGo") | .id')
bbm subdomains notable $ID
bbm fuzzing all-results --target-id $ID | jq '.items[:10]'
bbm ports stats-target --target-id $ID
bbm jsrecon findings $ID
bbm alerts list --target-id $ID --state unread
```

### Add subdomains + mark notable
```bash
bbm subdomains bulk-add 2 sub1.bitgo.com sub2.bitgo.com
bbm subdomains bulk-notable 2 sub1.bitgo.com sub2.bitgo.com
```

### Clean up noise (unmark notable by IDs)
```bash
bbm subdomains bulk-unnotable 2 --ids 10 20 30 40
```

### Write/append notes
```bash
bbm notes update-target 2 "## Summary\n\nInitial recon complete."
bbm notes update-subdomain 42 "## XSS\n\nFound reflected XSS at /search?q="
bbm notes update-target 2 "\n## New Finding\n\nAdded later." --append
```

### Trigger scan
```bash
AGENT=$(bbm agents list | jq '.[0].id')
bbm scans create 2 --agent-id $AGENT --scan-types subdomains ports fuzzing
bbm scan-dashboard active
```
