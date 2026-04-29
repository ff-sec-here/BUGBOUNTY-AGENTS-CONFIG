---
name: bug-bounty-mapper
description: >
  Full API skill for BB-Manager at mapper.fhdsec.info. Use when the user wants to interact
  with their bug bounty data: list/create targets, manage subdomains, write notes, create
  checklists, trigger scans, view fuzzing/port results, manage alerts, dorking, JS recon,
  and more. Covers every API endpoint the platform exposes.
---

# Bug Bounty Mapper — API Skill

## Connection

**Base URL**: `https://mapper.fhdsec.info/api`

**Required headers on every request**:
```
Authorization: Bearer <API_TOKEN>
Content-Type: application/json
CF-Access-Client-Id: 105659c6de04429537d0a1e70798cd61.access
CF-Access-Client-Secret: cedcdf23ae8968138a179a6cd7fc96ed218529026e7a39a4b91e32fbf5405ae2
```

The `API_TOKEN` is the user's personal token from Settings → API Access in the UI.
Ask the user for it if not provided. Store it in the conversation context for the session.

---

## Targets

| Action | Method | Path |
|--------|--------|------|
| List all | GET | `/targets` |
| Get one | GET | `/targets/{id}` |
| Create | POST | `/targets` |
| Update | PUT | `/targets/{id}` |
| Delete | DELETE | `/targets/{id}` |
| Export | GET | `/targets/{id}/export` |
| Stats | GET | `/targets/{id}/stats` |
| Alerts for target | GET | `/targets/{target_id}/alerts` |
| Snapshots | GET | `/targets/{target_id}/snapshots` |

**Create/Update body**:
```json
{ "name": "...", "program_url": "...", "description": "...", "status": "active|paused|completed", "tags": ["..."] }
```

When the user says "target X" and you don't have the ID, call `GET /targets` first and match by name.

---

## Scope

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/targets/{targetId}/scope` |
| Create | POST | `/targets/{targetId}/scope` |
| Update | PUT | `/scope/{id}` |
| Delete | DELETE | `/scope/{id}` |

**Body**: `{ "type": "include|exclude", "pattern": "*.example.com", "is_wildcard": true, "notes": "..." }`

---

## Subdomains

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/targets/{targetId}/subdomains` |
| Get one | GET | `/subdomains/{id}` |
| Create | POST | `/targets/{targetId}/subdomains` |
| Bulk add | POST | `/targets/{targetId}/subdomains/bulk` |
| Bulk import httpx | POST | `/targets/{targetId}/subdomains/bulk-httpx` |
| Update | PUT | `/subdomains/{id}` |
| Delete | DELETE | `/subdomains/{id}` |
| Notable list | GET | `/targets/{targetId}/subdomains/notable` |
| Toggle notable | PUT | `/subdomains/{id}/toggle-notable` |
| Update notable ports | PUT | `/subdomains/{id}/notable-ports` |
| Bulk mark notable | POST | `/targets/{targetId}/subdomains/bulk-notable` |
| Stats | GET | `/targets/{targetId}/subdomains/stats` |
| Export | GET | `/targets/{targetId}/subdomains/export` |
| Filter values | GET | `/targets/{targetId}/subdomains/filter-values` |
| History | GET | `/subdomains/{id}/history` |

**Bulk add body**: `{ "domains": ["sub1.example.com", "sub2.example.com"] }`
**Bulk notable body**: `{ "domains": ["sub1.example.com"] }`
**Notable ports body**: `{ "notable_ports": [80, 443, 8080] }`

List supports query params: `search`, `status`, `is_notable`, `limit`, `offset`.

---

## Excluded Subdomains

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/targets/{id}/excluded-subdomains` |
| Add | POST | `/targets/{id}/excluded-subdomains` |
| Delete | DELETE | `/excluded-subdomains/{id}` |

---

## Notes

| Action | Method | Path |
|--------|--------|------|
| Get all target notes | GET | `/targets/{targetId}/notes` |
| Get/create main note | GET | `/targets/{targetId}/notes/main` |
| Update main note | PUT | `/targets/{targetId}/notes/main` |
| Get subdomain note | GET | `/subdomains/{subdomainId}/note` |
| Update subdomain note | PUT | `/subdomains/{subdomainId}/note` |
| Delete note | DELETE | `/notes/{noteId}` |

**Update body**: `{ "content": "markdown text here" }` — replaces existing content

**Append to existing notes**: `{ "content": "new text to add", "append": true }` — appends with double newline separator instead of replacing

Notes support full Markdown. When the user asks to "write notes" or "document findings", use these endpoints.

---

## Checklists

### Templates

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/checklists` |
| Get | GET | `/checklists/{id}` |
| Create | POST | `/checklists` |
| Update | PUT | `/checklists/{id}` |
| Delete | DELETE | `/checklists/{id}` |
| Export | GET | `/checklists/{id}/export` |
| Import | POST | `/checklists/import` |
| AI convert | POST | `/checklists/ai-convert` |
| AI generate items | POST | `/checklists/ai-generate-items` |

**Create body**: `{ "name": "...", "description": "...", "category": "..." }`

### Items

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/checklists/{checklistId}/items` |
| Create | POST | `/checklists/{checklistId}/items` |
| Update | PUT | `/checklist-items/{id}` |
| Delete | DELETE | `/checklist-items/{id}` |
| Reorder | PUT | `/checklist-items/reorder` |

**Item body**: `{ "title": "...", "description": "...", "category": "...", "order": 0 }`

### Attaching Checklists

| Level | Attach | Detach | List |
|-------|--------|--------|------|
| Target | POST `/targets/{targetId}/checklists/{checklistId}` | DELETE same | GET `/targets/{targetId}/checklists` |
| Subdomain | POST `/subdomains/{subdomainId}/checklists/{checklistId}` | DELETE same | GET `/subdomains/{subdomainId}/checklists` |
| Scope | POST `/scope/{scopeId}/checklists/{checklistId}` | DELETE same | GET `/scope/{scopeId}/checklists` |

### Progress Tracking

| Action | Method | Path |
|--------|--------|------|
| Target progress | GET | `/targets/{targetId}/progress` |
| Toggle target item | PUT | `/progress/{itemId}/target/{targetId}/toggle` |
| Target item findings | PUT | `/progress/{itemId}/target/{targetId}/findings` |
| Subdomain progress | GET | `/subdomains/{subdomainId}/progress` |
| Toggle subdomain item | PUT | `/progress/{itemId}/subdomain/{subdomainId}/toggle` |
| Subdomain item findings | PUT | `/progress/{itemId}/subdomain/{subdomainId}/findings` |
| Scope progress | GET | `/scope/{scopeId}/progress` |
| Toggle scope item | PUT | `/progress/{itemId}/scope/{scopeId}/toggle` |
| Scope item findings | PUT | `/progress/{itemId}/scope/{scopeId}/findings` |
| Dashboard | GET | `/progress/dashboard` |
| Scope dashboard | GET | `/progress/scope-dashboard` |
| Target dashboard | GET | `/progress/target-dashboard` |
| Combined dashboard | GET | `/progress/combined-dashboard` |

**Findings body**: `{ "findings": "markdown notes about this item" }`

### Custom Items

| Level | List | Create | Update | Delete | Toggle | Findings |
|-------|------|--------|--------|--------|--------|----------|
| Subdomain | GET `/checklists/{checklistId}/subdomain/{subdomainId}/custom-items` | POST same | PUT `/custom-items/{itemId}` | DELETE `/custom-items/{itemId}` | PUT `/custom-items/{itemId}/toggle` | PUT `/custom-items/{itemId}/findings` |
| Scope | GET `/checklists/{checklistId}/scope/{scopeId}/custom-items` | POST same | — | — | — | — |
| Target | GET `/checklists/{checklistId}/target/{targetId}/custom-items` | POST same | — | — | — | — |

---

## Fuzzing

| Action | Method | Path |
|--------|--------|------|
| Import ffuf | POST | `/targets/{targetId}/fuzzing/import-ffuf` |
| Get results | GET | `/subdomains/{subdomainId}/fuzzing` |
| Stats (subdomain) | GET | `/subdomains/{subdomainId}/fuzzing/stats` |
| Stats (target) | GET | `/targets/{targetId}/fuzzing/stats` |
| All results (target) | GET | `/targets/{targetId}/fuzzing/all-results` |
| All subdomains with fuzzing | GET | `/targets/{targetId}/all-subdomains-with-fuzzing` |
| Notable subdomains with fuzzing | GET | `/targets/{targetId}/notable-subdomains-with-fuzzing` |
| Subdomains with stats | GET | `/targets/{targetId}/subdomains-with-fuzzing-stats` |
| Delete result | DELETE | `/fuzzing/{resultId}` |
| Delete all for subdomain | DELETE | `/subdomains/{subdomainId}/fuzzing` |

---

## Open Ports

| Action | Method | Path |
|--------|--------|------|
| Import | POST | `/targets/{targetId}/openports/import` |
| Get results | GET | `/subdomains/{subdomainId}/openports` |
| Stats (subdomain) | GET | `/subdomains/{subdomainId}/openports/stats` |
| Stats (target) | GET | `/targets/{targetId}/openports/stats` |
| All subdomains with ports | GET | `/targets/{targetId}/all-subdomains-with-openports` |
| Subdomains with stats | GET | `/targets/{targetId}/subdomains-with-openports-stats` |
| Filter values | GET | `/targets/{targetId}/openports/filter-values` |
| Delete port | DELETE | `/openports/{portId}` |
| Delete all for subdomain | DELETE | `/subdomains/{subdomainId}/openports` |

---

## IP Addresses

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/targets/{targetId}/ip-addresses` |

---

## Historical URLs

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/targets/{targetId}/historical-urls` |
| Delete all | DELETE | `/targets/{targetId}/historical-urls` |

---

## JS Reconnaissance

| Action | Method | Path |
|--------|--------|------|
| Start scan | POST | `/targets/{targetId}/js-recon/scan` |
| List scans | GET | `/targets/{targetId}/js-recon/scans` |
| Get URLs | GET | `/targets/{targetId}/js-recon/urls` |
| Get findings | GET | `/targets/{targetId}/js-recon/findings` |
| Get files | GET | `/targets/{targetId}/js-recon/files` |
| Get endpoints | GET | `/targets/{targetId}/js-recon/endpoints` |
| Stats | GET | `/targets/{targetId}/js-recon/stats` |
| Delete data | DELETE | `/targets/{targetId}/js-recon` |

---

## Vhost Scans

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/vhost-scans` |
| Get | GET | `/vhost-scans/{id}` |
| Create | POST | `/vhost-scans` |
| Delete | DELETE | `/vhost-scans/{id}` |
| Get findings | GET | `/vhost-scans/{id}/findings` |
| Update finding | PATCH | `/vhost-scans/{scanId}/findings/{findingId}` |
| Upload results | POST | `/vhost-scans/{id}/upload-results` |
| Complete scan | POST | `/vhost-scans/{id}/complete` |

---

## Dorking

| Action | Method | Path |
|--------|--------|------|
| Providers summary | GET | `/targets/{targetId}/dorking/providers?mode=...` |
| Provider dorks | GET | `/targets/{targetId}/dorking/providers/{provider}/dorks?mode=...` |
| Open dork | POST | `/targets/{targetId}/dorking/open?dork_id=...&mode=...&context_value=...` |
| Bulk open | POST | `/targets/{targetId}/dorking/bulk-open?provider=...&mode=...&context_value=...` |
| Update tracking | PUT | `/targets/{targetId}/dorking/tracking/{trackingId}/status?status=...` |
| Bulk mark checked | POST | `/targets/{targetId}/dorking/bulk-mark-checked` |
| Reset tracking | DELETE | `/targets/{targetId}/dorking/reset` |

Dork modes: `target`, `subdomain`, `scope`.

---

## Alerts

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/alerts` |
| Get | GET | `/alerts/{id}` |
| Mark read | PUT | `/alerts/{id}/state?lifecycle_state=read` |
| Acknowledge | PUT | `/alerts/{id}/state?lifecycle_state=acknowledged` |
| Toggle notable | PUT | `/alerts/{id}/toggle-notable` |
| Update notes | PUT | `/alerts/{id}/note?notes=...` |
| Delete | DELETE | `/alerts/{id}` |
| Delete all | DELETE | `/alerts/all` |
| Delete all for target | DELETE | `/alerts/target/{targetId}/all` |
| Bulk delete | DELETE | `/alerts/bulk?alert_ids=1,2,3` |
| Stats | GET | `/alerts/stats` |
| Status transitions | GET | `/alerts/status-transitions` |
| Port numbers | GET | `/alerts/port-numbers` |

List filters: `target_id`, `alert_type`, `lifecycle_state`, `is_notable`, `date_from`, `date_to`, `status_from`, `status_to`, `port_number`, `limit`, `offset`.

---

## Scan Agents

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/scan-agents` |
| Get | GET | `/scan-agents/{id}` |
| Status | GET | `/scan-agents/{id}/status` |

---

## Scan Jobs

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/scan-jobs` |
| Get | GET | `/scan-jobs/{id}` |
| Create | POST | `/scan-jobs` |
| Cancel | POST | `/scan-jobs/{id}/cancel` |
| Retry | POST | `/scan-jobs/{id}/retry` |
| Logs | GET | `/scan-jobs/{id}/logs` |
| Agent logs | GET | `/scan-jobs/{id}/logs/agent` |

---

## Scan Schedules

| Action | Method | Path |
|--------|--------|------|
| Get schedule | GET | `/targets/{id}/scan-schedule` |
| Create/update schedule | PUT | `/targets/{id}/scan-schedule` |
| Delete schedule | DELETE | `/targets/{id}/scan-schedule` |
| Trigger scan now | POST | `/targets/{id}/scan-now` |

---

## Scan Dashboard

| Action | Method | Path |
|--------|--------|------|
| Active scans | GET | `/scan-dashboard/active` |
| Queued scans | GET | `/scan-dashboard/queued` |
| Scan history | GET | `/scan-dashboard/history` |
| Metrics | GET | `/scan-dashboard/metrics` |
| Fuzz results for job | GET | `/scan-dashboard/scan-jobs/{scanJobId}/fuzz-results` |
| Target scan history | GET | `/targets/{targetId}/scan-history` |
| Target scan analytics | GET | `/targets/{targetId}/scan-analytics` |
| Target scan comparison | GET | `/targets/{targetId}/scan-comparison` |

---

## Snapshots

| Action | Method | Path |
|--------|--------|------|
| Snapshot types | GET | `/targets/{targetId}/snapshots/types` |
| History by type | GET | `/targets/{targetId}/snapshots/{snapshotType}/history` |
| Compare snapshots | GET | `/targets/{targetId}/snapshots/{snapshotType}/compare` |
| Create snapshot | POST | `/targets/{targetId}/snapshots/create` |
| Summary | GET | `/targets/{targetId}/snapshots/summary` |

---

## Settings

### Alert Settings
- GET `/settings/alerts` — params: `alert_type`, `target_id`
- PUT `/settings/alerts` — params: `alert_type`, `target_id`, `is_enabled`, `send_to_telegram`, `send_to_slack`
- PUT `/settings/alerts/bulk` — body: array of settings objects

### Telegram
- GET `/settings/telegram`
- PUT `/settings/telegram` — body: `{ "bot_token": "...", "chat_id": "..." }`
- POST `/settings/telegram/test`
- DELETE `/settings/telegram`

### Slack
- GET `/settings/slack`
- PUT `/settings/slack` — body: `{ "webhook_url": "..." }`
- POST `/settings/slack/test`
- DELETE `/settings/slack`

### Dork Settings
- GET `/settings/dorks` — optional `search_engine` param
- POST `/settings/dorks`
- GET `/settings/dorks/{id}`
- PUT `/settings/dorks/{id}`
- DELETE `/settings/dorks/{id}`

---

## Quick Links

| Action | Method | Path |
|--------|--------|------|
| List | GET | `/quick-links` |
| By category | GET | `/quick-links/categories` |
| Get | GET | `/quick-links/{id}` |
| Create | POST | `/quick-links` |
| Update | PUT | `/quick-links/{id}` |
| Delete | DELETE | `/quick-links/{id}` |

**Body**: `{ "title": "...", "url": "...", "category": "...", "description": "..." }`

---

## Activity Log

- GET `/activity` — optional `entity_type` query param

---

## Workflow Patterns

### "Do hunting on target X"
1. `GET /targets` → find target ID by name
2. `GET /targets/{id}/subdomains` → review known subdomains
3. `GET /targets/{id}/subdomains/notable` → focus on notable ones
4. `GET /targets/{id}/fuzzing/all-results` → check fuzzing findings
5. `GET /targets/{id}/openports/stats` → check open ports
6. `GET /targets/{id}/js-recon/findings` → check JS findings
7. `GET /alerts?target_id={id}` → check recent alerts

### "Create notes for target X"
1. Resolve target ID via `GET /targets`
2. `GET /targets/{id}/notes/main` → check existing notes
3. `PUT /targets/{id}/notes/main` with `{ "content": "..." }` → write/append notes

### "Create a checklist for target X"
1. `POST /checklists` → create template
2. `POST /checklists/{id}/items` → add each item
3. `POST /targets/{targetId}/checklists/{checklistId}` → attach to target

### "Add subdomains to target X"
1. Resolve target ID
2. `POST /targets/{id}/subdomains/bulk` with `{ "domains": [...] }`

### "Mark subdomain as notable"
1. `GET /targets/{targetId}/subdomains?search=subdomain.name` → resolve subdomain ID
2. `PUT /subdomains/{id}/toggle-notable`

### "Show me all findings for target X"
1. Resolve target ID
2. Fetch in parallel:
   - `GET /targets/{id}/fuzzing/all-results`
   - `GET /targets/{id}/openports/stats`
   - `GET /targets/{id}/js-recon/findings`
   - `GET /alerts?target_id={id}&lifecycle_state=unread`
3. Summarise results grouped by type

### "Trigger a scan on target X"
1. Resolve target ID
2. `GET /scan-agents` → pick an available agent
3. `POST /scan-jobs` with `{ "target_id": ..., "agent_id": ..., "scan_types": ["subdomains","ports","fuzzing"] }`
4. `GET /scan-jobs/{id}/logs` to monitor progress

### "Show scan status"
1. `GET /scan-dashboard/active` → running scans
2. `GET /scan-dashboard/queued` → queued scans
3. `GET /scan-dashboard/metrics` → overall stats
