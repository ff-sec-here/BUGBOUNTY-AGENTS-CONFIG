---
name: js-recon
description: >
  JavaScript reconnaissance workflow. Use when the user wants to find secrets, endpoints,
  API keys, or internal paths in JavaScript files. Covers pulling context from BB-Mapper,
  triggering BB-Mapper JS scan, manual local analysis with tools, and pushing findings back.
---

# JS Recon Workflow

## Step 1 — Pull Context from BB-Mapper

Before doing anything, get the current state of the target:

```
# Get notable subdomains (these are your JS hunting targets)
GET /targets/{targetId}/subdomains?is_notable=true

# Check if a JS scan has already run
GET /targets/{targetId}/js-recon/scans

# Pull existing JS findings to avoid duplicating work
GET /targets/{targetId}/js-recon/findings
GET /targets/{targetId}/js-recon/endpoints
GET /targets/{targetId}/js-recon/urls
```

Review what's already known before running anything new.

## Step 2 — Trigger BB-Mapper JS Scan

BB-Mapper crawls all subdomains and extracts JS files, endpoints, and secrets automatically:

```
POST /targets/{targetId}/js-recon/scan
```

Then pull results:
```
GET /targets/{targetId}/js-recon/stats
GET /targets/{targetId}/js-recon/findings    ← secrets, keys, tokens
GET /targets/{targetId}/js-recon/endpoints   ← discovered API endpoints
GET /targets/{targetId}/js-recon/files       ← all JS files found
```

## Step 3 — Triage JS Files Before Deep Analysis

Don't read every file. Do a quick pass first and mark which files are worth reading:

**Interesting file signals:**
- Large files (10k+ lines) — more code = more attack surface
- Files with non-generic names: `app.js`, `main.js` are boring; `payments.js`, `admin.js`, `api.js`, `auth.js` are not
- Files loaded only on specific pages (login, checkout, admin panel)
- Chunks with suspicious names in webpack builds
- Source maps (`.js.map`) — expose original unminified source

```bash
# Check for source maps
curl -s https://target.com/app.js | grep sourceMappingURL
# If found, fetch original source:
curl -s https://target.com/app.js.map | python3 -m json.tool | grep -i "sources"
```

Mark interesting files, start reading those first.

## Step 4 — Local Deep Analysis

### Collect JS file URLs
```bash
# Extract JS files from a live target
curl -s https://target.com | grep -oP 'src="[^"]+\.js[^"]*"' | sed 's/src="//;s/"//'

# Historical JS via gau/waybackurls
gau target.com | grep "\.js$" | sort -u > js-urls.txt
waybackurls target.com | grep "\.js$" | sort -u >> js-urls.txt
sort -u js-urls.txt -o js-urls.txt
```

### Download JS files
```bash
mkdir -p js-files
while read url; do
    filename=$(echo "$url" | md5sum | cut -d' ' -f1).js
    curl -s "$url" -o "js-files/$filename"
    echo "$url -> $filename"
done < js-urls.txt
```

### Pattern-based grep (adapt to the target — don't just Ctrl+F blindly)
```bash
# Endpoints and paths
grep -rhoP '["\x60](/[a-zA-Z0-9_/.-]+)["\x60]' js-files/ | sort -u > endpoints.txt

# API calls
grep -rhoiP '(POST|GET|PUT|DELETE|PATCH|method\s*:\s*["\x60][A-Z]+)' js-files/ | sort -u

# Parameters being used
grep -rhoiP 'params\s*[=:{]' js-files/ | sort -u

# Content-Type hints (often reveals endpoints)
grep -rhoiP 'content-type["\s:]+["\x60][^"x60]+' js-files/ -i | sort -u

# Secrets and tokens
grep -rhoiP '(api[_-]?key|secret|token|password|auth|bearer)\s*[=:]\s*["\x60][^"x60]{8,}' js-files/ > secrets.txt

# Internal URLs and domains
grep -rhoP '(https?://[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}[^\s"x60]*)' js-files/ | sort -u > domains.txt

# Hard-to-guess paths (goldmine — like /rmt_stage)
grep -rhoP '["\x60](/[a-zA-Z0-9_-]{6,})["\x60]' js-files/ | sort -u
```

### Automated secret scanning
```bash
trufflehog filesystem ./js-files/ --json > trufflehog.json
gitleaks detect --source ./js-files/ --report-format json --report-path gitleaks.json
```

### Endpoint extraction
```bash
for f in js-files/*.js; do python3 linkfinder.py -i "$f" -o cli; done | sort -u >> endpoints.txt
```

## Step 5 — Deep Reading: What to Analyse

When reading JS files manually, focus on **how data flows**, not just what strings appear.

### Sync/Async flows and param parsing
- How are parameters parsed and where are they used?
- Are user-supplied values passed directly into fetch/XHR without sanitisation?
- Are there `eval()`, `innerHTML`, `document.write()` sinks?
- Are params reflected into URLs, headers, or request bodies?

### How API requests are constructed
```javascript
// Look for patterns like these — understand what params are sent and where
fetch('/api/v2/users/' + userId, { method: 'GET', headers: { Authorization: 'Bearer ' + token } })
axios.post('/api/transfer', { from: accountId, to: targetId, amount: amount })
```
- What IDs are used? Are they sequential, UUIDs, emails?
- Can you substitute another user's ID? → IDOR
- Are there parameters that look like they control access level or role?

### postMessage usage
```javascript
// Look for message listeners — check if origin is validated
window.addEventListener('message', function(event) {
  // Is event.origin checked? If not → postMessage injection
  // Is event.data used in a sink? → XSS via postMessage
})
```
- Missing or weak `event.origin` check → postMessage injection
- `event.origin === window.origin` with null origin → null origin bypass possible
- Data from `event.data` going into `innerHTML`, `eval`, `location` → XSS/redirect

### Client-side routing (SPAs)
- Find where routes are defined (React Router, Vue Router, Angular routes)
- Look for `:param` style path parameters — understand every param you can supply
- Check callback/OAuth routes — can you inject attacker-controlled data into a callback?

### URL parsing edge cases
```javascript
// Look for URL parsing — check for differentials
new URL(userInput)
a.href = userInput; a.hostname  // old technique, behaves differently from new URL()
```
- `\/` → gets converted to `//` in some parsers → open redirect
- `javascript://hostname.com/` → Chrome parses hostname, can bypass checks
- Whitespace/newlines stripped by fetch but not by browser → parsing differential

### CSPT (Client-Side Path Traversal)
- Look for user input injected directly into URL paths in fetch/XHR
- `../` in path parameters can redirect requests to unintended endpoints
- Check if path params are URL-encoded or passed raw

### Cookie and storage handling
- Where are tokens stored? `localStorage`, `sessionStorage`, cookies?
- Are there `credentialless` iframes? (useful for attacks requiring no cookie)
- `document.cookie` reads/writes — what's being set and read?

### Feature flags and hidden functionality
```javascript
// Disabled features, hidden routes, internal flags
if (user.role === 'admin') { ... }
if (featureFlags.enableBetaPayments) { ... }
// These reveal what exists even if not exposed in UI
```

## Step 6 — Triage Findings

| Finding Type | Note-Taking Level | Action |
|-------------|------------------|--------|
| Active API key / secret | **Finding** | Validate immediately, full POC |
| IDOR-pattern endpoint (email/ID as param) | **Primitive** | Test with another account |
| postMessage without origin check | **Primitive** | Build PoC |
| Hard-to-guess internal path | **Lead** | Fuzz it, check directly |
| New subdomain/domain | **Note** | Add to BB-Mapper subdomains |
| Interesting API path | **Lead** | Fuzz with ffuf |
| Commented-out code | **Note** | May reveal logic or old endpoints |
| Client-side route with params | **Lead** | Enumerate all params |
| URL parsing differential | **Primitive** | Test for redirect/bypass |

## Step 7 — Push Back to BB-Mapper

```
# Notes on the subdomain
PUT /subdomains/{subdomainId}/note
Body: { "content": "## JS Analysis\n\n### Endpoints Found\n...\n\n### Suspicious Params\n...\n\n### Leads\n..." }

# Cross-subdomain findings
PUT /targets/{targetId}/notes/main

# New subdomains discovered in JS
POST /targets/{targetId}/subdomains/bulk
Body: { "domains": ["internal.target.com"] }

# Mark subdomain notable if high-value JS found
PUT /subdomains/{id}/toggle-notable

# Track leads as checklist items
PUT /progress/{itemId}/subdomain/{subdomainId}/findings
Body: { "findings": "endpoint /api/v2/users/{email} found in app.js — leaks user data, needs auth test" }
```

## Workflow Summary

```
BB-Mapper context (notable subs, existing findings)
    ↓
Trigger BB-Mapper JS scan (broad automated coverage)
    ↓
Triage JS files — mark interesting ones, skip boring ones
    ↓
Deep read: flows, params, postMessage, routing, URL parsing
    ↓
Grep for patterns (adapt to target, don't just Ctrl+F blindly)
    ↓
Classify: Note / Lead / Primitive / Finding
    ↓
Push everything back to BB-Mapper
    ↓
Follow up: fuzz discovered paths, test IDORs, build PoCs
```
