---
name: burp
description: >
  Burp Suite proxy integration via MCP. Use when sending HTTP requests, replaying requests,
  reading proxy history, using Collaborator, encoding/decoding, or interacting with Burp
  Repeater/Intruder. All HTTP requests during testing should go through Burp via this skill.
---

# Burp Suite MCP Skill

## Overview
Burp is connected via MCP (`@burp`). All HTTP requests during bug bounty testing should be
sent through Burp — this keeps a full proxy history, allows manual replay, and routes traffic
through Burp's scanner if active.

## Available Tools

### Sending Requests

**HTTP/1.1**
```
@burp/send_http1_request
  targetHostname: "target.com"
  targetPort: 443
  usesHttps: true
  content: |
    GET /api/v1/users HTTP/1.1
    Host: target.com
    Authorization: Bearer <token>
    
```

**HTTP/2**
```
@burp/send_http2_request
  targetHostname: "target.com"
  targetPort: 443
  usesHttps: true
  pseudoHeaders:
    method: GET
    path: /api/v1/users
    scheme: https
    authority: target.com
  headers:
    Authorization: Bearer <token>
  requestBody: ""
```

### Repeater & Intruder

**Send to Repeater** (for manual replay/modification)
```
@burp/create_repeater_tab
  targetHostname: "target.com"
  targetPort: 443
  usesHttps: true
  tabName: "IDOR test - /api/users/123"
  content: |
    GET /api/users/123 HTTP/1.1
    Host: target.com
    Authorization: Bearer <token>
    
```

**Send to Intruder** (for fuzzing via Burp)
```
@burp/send_to_intruder
  targetHostname: "target.com"
  targetPort: 443
  usesHttps: true
  content: |
    GET /api/users/§123§ HTTP/1.1
    Host: target.com
    
```

### Proxy History

**Read full HTTP history**
```
@burp/get_proxy_http_history
  count: 50
  offset: 0
```

**Search history by regex** (very useful for finding specific patterns)
```
@burp/get_proxy_http_history_regex
  regex: "/api/v[0-9]+/users"
  count: 50
  offset: 0
```

**WebSocket history**
```
@burp/get_proxy_websocket_history
  count: 50
  offset: 0
```

### Scanner Issues (Burp Pro only)
```
@burp/get_scanner_issues
  count: 100
  offset: 0
```

### Collaborator (Burp Pro — OOB testing)

**Generate payload** (for SSRF, blind XSS, XXE, etc.)
```
@burp/generate_collaborator_payload
  customData: "ssrf-test-1"   # optional label
```
Returns: payload URL + payloadId

**Poll for interactions**
```
@burp/get_collaborator_interactions
  payloadId: "<id from above>"   # omit to get all interactions
```

### Encoding/Decoding Utilities
```
@burp/url_encode    content: "hello world&foo=bar"
@burp/url_decode    content: "hello%20world%26foo%3Dbar"
@burp/base64_encode content: "secret data"
@burp/base64_decode content: "c2VjcmV0IGRhdGE="
@burp/generate_random_string  length: 16  characterSet: "abcdefghijklmnopqrstuvwxyz0123456789"
```

### Proxy Intercept Control
```
@burp/set_proxy_intercept_state  intercepting: false   # disable intercept (recommended during automated testing)
@burp/set_proxy_intercept_state  intercepting: true    # enable for manual interception
```

### Task Engine
```
@burp/set_task_execution_engine_state  running: true    # unpause scanner
@burp/set_task_execution_engine_state  running: false   # pause scanner
```

## Workflow Patterns

### Testing an endpoint
1. Disable intercept: `set_proxy_intercept_state intercepting: false`
2. Send request via `send_http1_request` or `send_http2_request`
3. Analyse response directly
4. If interesting → `create_repeater_tab` for manual follow-up

### IDOR testing
1. Send request as user A, note the response
2. Swap the ID/token to user B's value, resend
3. Compare responses — different content = IDOR

### OOB / SSRF testing
1. `generate_collaborator_payload` → get payload URL
2. Inject payload into target parameter
3. Send request via `send_http1_request`
4. `get_collaborator_interactions` to check for DNS/HTTP callbacks

### Reviewing what Burp captured
1. `get_proxy_http_history_regex` with a pattern like `admin|internal|debug`
2. Review interesting requests
3. Replay modified versions via `send_http1_request`

## Rules
- Always send test requests through Burp (`@burp/send_http1_request`) — never use curl for actual testing
- Keep intercept OFF during automated testing to avoid blocking
- Use `create_repeater_tab` to save interesting requests for manual follow-up
- Use Collaborator for any OOB testing (SSRF, blind injection, XXE)
- Search proxy history with regex before re-testing — Burp may have already captured the request
