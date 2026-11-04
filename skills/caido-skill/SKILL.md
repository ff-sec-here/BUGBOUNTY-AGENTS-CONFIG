---
name: caido
description: >
  Caido proxy integration via MCP. Use when sending HTTP requests, replaying requests,
  reading proxy/intercept history, running fuzzing (Automate) sessions, managing scopes
  or findings, or interacting with Caido's Replay/Intercept/Automate features. All HTTP
  requests during bug bounty testing should go through Caido via this skill.
---

# Caido MCP Skill

## Overview
Caido is connected via MCP (`@caido`), backed by the `caido-mcp-server` community bridge
(stdio transport, connects out to Caido's own API via `CAIDO_URL`). All HTTP requests during
bug bounty testing should be sent through Caido — this keeps a full proxy history, allows
manual replay, and makes captured traffic queryable with HTTPQL.

Caido runs on the bug bounty server, reachable over the tailnet. `caido-mcp-server` runs
locally (stdio) and dials out to Caido over Tailscale — there's no tunnel or Access layer
in front of it; the tailnet is the only gate.

## Available Tools

### Proxy History / Requests

**List requests with an HTTPQL filter**
```
@caido/caido_list_requests
  httpql: 'req.host.eq:"target.com" AND resp.code.gte:400'
  limit: 20
  after: "<pagination cursor>"   # optional
```

**Get full request/response detail**
```
@caido/caido_get_request
  ids: ["<request id>"]
  include: ["requestHeaders", "requestBody", "responseHeaders", "responseBody"]
  bodyLimit: 2000
```

### Replay (manual retesting)

**Send a raw request through Replay**
```
@caido/caido_send_request
  raw: |
    GET /api/v1/users HTTP/1.1
    Host: target.com
    Authorization: Bearer <token>

  host: "target.com"
  port: 443
  tls: true
  sessionId: "<optional replay session id>"
```

**List / inspect replay sessions**
```
@caido/caido_list_replay_sessions
@caido/caido_get_replay_entry  id: "<entry id>"  bodyLimit: 2000
```

### Automate (fuzzing)
```
@caido/caido_list_automate_sessions
@caido/caido_get_automate_session   id: "<session id>"
@caido/caido_get_automate_entry     id: "<session id>"  limit: 50  after: "<cursor>"
@caido/caido_automate_task_control  action: "start"   session_id: "<session id>"
@caido/caido_automate_task_control  action: "pause"   task_id: "<task id>"
@caido/caido_automate_task_control  action: "resume"  task_id: "<task id>"
@caido/caido_automate_task_control  action: "cancel"  task_id: "<task id>"
```

### Findings
```
@caido/caido_list_findings
@caido/caido_create_finding   requestId: "<id>"  title: "IDOR on /api/users/{id}"  description: "..."
@caido/caido_delete_findings  ids: ["<id>", ...]
@caido/caido_export_findings  ids: ["<id>", ...]
```

### Scopes / Projects
```
@caido/caido_list_scopes
@caido/caido_create_scope  name: "bitgo"  allowlist: ["*.bitgo.com"]  denylist: ["static.bitgo.com"]
@caido/caido_list_projects
@caido/caido_select_project  id: "<project id>"
```

### Intercept Control
```
@caido/caido_intercept_status
@caido/caido_intercept_control       action: "pause"    # or "resume"
@caido/caido_list_intercept_entries  filter: 'req.path.cont:"admin"'  limit: 20
@caido/caido_forward_intercept        id: "<entry id>"  raw: "<optional base64 modified request>"
@caido/caido_drop_intercept           id: "<entry id>"
```

### Workflows
```
@caido/caido_list_workflows
@caido/caido_run_workflow     id: "<workflow id>"  type: "active"  request_id: "<id>"
@caido/caido_run_workflow     id: "<workflow id>"  type: "convert" input: "<raw text>"
@caido/caido_toggle_workflow  id: "<workflow id>"  enabled: true
```

### Tamper (Match & Replace)
```
@caido/caido_list_tamper_rules
@caido/caido_create_tamper_rule  collection_id: "<id>"  name: "strip CSP"  condition: 'resp.raw.cont:"Content-Security-Policy"'  sources: ["INTERCEPT", "REPLAY"]
@caido/caido_toggle_tamper_rule  id: "<id>"  enabled: false
@caido/caido_delete_tamper_rule  id: "<id>"
```

### Environments / Instance
```
@caido/caido_list_environments
@caido/caido_select_environment  id: "<id>"   # empty string deselects
@caido/caido_list_filters
@caido/caido_get_instance
```

## HTTPQL Cheat Sheet
Syntax: `namespace.field.operator:"value"`, combined with `AND` / `OR` (AND binds tighter).

- Namespaces: `req`, `resp`, `preset`, `row`, `source`
- Text fields (`host`, `method`, `path`, `query`, `ext`, `raw`): `eq`, `ne`, `cont` (contains, case-insensitive), `nlike`, `regex`, `nregex`
- Numeric fields (`resp.code`, `row.id`): `eq`, `ne`, `gt`, `gte`, `lt`, `lte`

Examples:
```
req.host.eq:"target.com" AND req.method.eq:"POST" AND resp.code.eq:200
req.host.cont:"api" AND resp.code.gte:400
req.raw.cont:"application/json"
req.path.cont:"admin" OR req.path.cont:"internal"
```

## Workflow Patterns

### Testing an endpoint
1. Make sure intercept is resumed (not paused) for automated testing: `caido_intercept_control action: "resume"`
2. Send the request via `caido_send_request`
3. Analyse the response directly
4. If interesting → note the request id and pull full detail with `caido_get_request`, or `caido_create_finding`

### IDOR testing
1. Send request as user A, note the response
2. Swap the ID/token to user B's value, resend via `caido_send_request`
3. Compare responses — different content = IDOR
4. Log a finding with `caido_create_finding`

### Fuzzing via Automate
1. Build/select the Automate session in the Caido UI (session creation isn't exposed over MCP yet)
2. Kick off with `caido_automate_task_control action: "start" session_id: "<id>"`
3. Poll `caido_get_automate_entry` for results
4. Pause/resume/cancel as needed with `caido_automate_task_control`

### Reviewing what Caido captured
1. `caido_list_requests` with an HTTPQL filter like `req.path.cont:"admin" OR req.path.cont:"internal"`
2. Pull full detail on interesting hits with `caido_get_request`
3. Replay modified versions via `caido_send_request`

## Rules
- Always send test requests through Caido (`@caido/caido_send_request`) — never use curl for actual testing
- Keep intercept resumed during automated testing to avoid blocking (`caido_intercept_control action: "resume"`)
- Query proxy history with HTTPQL before re-testing — Caido may have already captured the request
- Use `caido_create_finding` to log anything worth reporting, tied to the request id
- Tool parameter names are inconsistent across the server (`sessionId` vs `session_id`, `httpql` vs `filter`, `requestId` vs `request_id`) — match the exact name shown for each tool above
