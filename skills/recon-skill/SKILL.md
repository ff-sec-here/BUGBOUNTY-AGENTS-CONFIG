---
name: recon
description: >
  Subdomain enumeration and recon methodology. Use when the user wants to discover
  subdomains, live hosts, technologies, or expand the attack surface. Covers
  subfinder, amass, httpx, and bulk importing results into BB-Mapper.
---

# Recon Skill

## Subdomain Enumeration

### subfinder (fast, passive)
```bash
subfinder -d target.com -all -recursive \
  -o subfinder.txt
```

### amass (thorough, active+passive)
```bash
amass enum -d target.com -passive -o amass.txt
# Active (slower, more results):
amass enum -d target.com -o amass-active.txt
```

### Combine and deduplicate
```bash
cat subfinder.txt amass.txt | sort -u > all-subs.txt
```

## Live Host Detection (httpx)

```bash
httpx -l all-subs.txt \
  -title -tech-detect -status-code -ip \
  -json -o httpx.json
```

Key flags:
| Flag | Output |
|------|--------|
| `-title` | Page title |
| `-tech-detect` | Technology fingerprint |
| `-status-code` | HTTP status |
| `-ip` | Resolved IP |
| `-follow-redirects` | Follow redirects |
| `-json` | JSON output for BB-Mapper |

## Import into BB-Mapper

### Bulk add raw subdomains
```
POST /targets/{targetId}/subdomains/bulk
Body: { "domains": ["sub1.example.com", "sub2.example.com"] }
```

### Bulk import httpx results (enriched)
```
POST /targets/{targetId}/subdomains/bulk-httpx
Body: <httpx JSON output>
```
This stores status codes, titles, and tech stack alongside each subdomain.

## Interesting Findings to Flag
- Non-standard ports in httpx output (8080, 8443, 9000, etc.)
- Dev/staging subdomains: `dev.`, `staging.`, `test.`, `beta.`, `uat.`
- Admin subdomains: `admin.`, `manage.`, `portal.`, `internal.`
- Old/legacy: `old.`, `legacy.`, `v1.`, `v2.`
- API subdomains: `api.`, `api2.`, `rest.`, `graphql.`

## After Import
1. Review subdomains in BB-Mapper
2. Mark interesting ones as notable: `PUT /subdomains/{id}/toggle-notable`
3. Trigger JS recon: `POST /targets/{targetId}/js-recon/scan`
4. Check alerts for newly discovered subdomains

## Workflow
1. Run subfinder + amass → combine → deduplicate
2. Run httpx on combined list
3. Bulk import raw domains into BB-Mapper
4. Bulk import httpx JSON for enrichment
5. Mark notable subdomains
6. Proceed to fuzzing and port scanning on notable hosts
