---
name: generate-report
description: >
  Generate a bug bounty report from a confirmed finding using a strict protocol: first-person
  voice, fixed title format, exactly three sections (Summary, Steps to Reproduce, Impact), and a
  mandatory triager dry-run that makes every step reproducible with zero prior knowledge.
  Trigger phrases: "write the report", "generate report", "create a report for this finding",
  "draft the bug bounty report", "report this".
---

# Bug Bounty Report Generator

Turn a confirmed finding into a report a triager can reproduce from the Steps to Reproduce
section alone, with no prior knowledge of the target, company, or application.

Follow the protocol in order. Do not skip the dry-run in Phase 3.

## Phase 1: Gather facts

Before writing, collect everything the report needs. Pull it from the session, tool output,
saved requests/responses, and notes. If a fact is missing, ask the user or re-verify it; never invent it.

- Target: domain, product name, environment, account types involved
- Vulnerable endpoint(s), method, parameters, headers, and exact request/response
- Accounts used (attacker, victim) with credentials or how to create them
- Every value that moves between steps (tokens, UUIDs, IDs, cookies, CSRF values) and where each comes from
- Observed result that proves the bug (status code, response body, state change)
- Real-world consequence, grounded in what was actually demonstrated

## Phase 2: Write the report

### Voice

- First person, always: "I found that...", "I noticed that...", "I was able to...".
- Describe what you did and observed. Past tense for findings, imperative for steps.
- State facts directly. No hedging ("might", "could possibly") about things you verified.
- No recommendations, remediation, or fix advice anywhere in the report.

### Title

Format:

```
<Vulnerability/OWASP/category>: <xyz> allows <doing xyz> leading to <xyz>
```

Examples:

- `IDOR: GET /api/v2/invoices/{id} allows reading any user's invoice leading to disclosure of billing PII`
- `Stored XSS: Profile "display name" field allows script execution leading to account takeover`
- `Broken Access Control: /admin/export allows unauthenticated CSV download leading to full user database exposure`

The title names the vulnerable component, the capability gained, and the end result. Keep it to one line.

### Structure

The report has exactly three sections, in this order. No other sections. No title block,
severity, CVSS, references, remediation, or "conclusion".

```
## Summary
## Steps to Reproduce
## Impact
```

Use these exact heading levels.

#### ## Summary

A brief paragraph (or two) in first person covering:

- What the target is and what it does (domain, product, relevant feature)
- What the issue is and where it lives (endpoint, parameter, feature)
- How it can be exploited, in one or two sentences

Example style: "I found that `app.example.com` uses the `/api/v2/tokens` endpoint to issue
API tokens for the dashboard, and that the `/api/v2/users/{uuid}/profile` endpoint accepts any
valid token without checking that the UUID belongs to the token's owner. This allows me to read
another user's profile data using my own token and the victim's UUID."

#### ## Steps to Reproduce

Two parts, in this order.

**Requirements** (short list): everything the triager needs before step 1.

- Accounts needed and their roles (e.g. Attacker, Victim), with credentials or signup instructions
- Tools (browser, Burp, curl, version if it matters)
- Any setup state (plan tier, feature flags, an existing object that must be created first)

**Steps** (numbered, one action per line):

- One action per step. A triager must never have to guess what to click, type, or send.
- Give exact URLs, menu paths, field names, button labels, header names, and parameter names.
- Include the full raw request (or a copy-pasteable `curl`) in a code block when a request is sent,
  with placeholders marked clearly (`<API_TOKEN>`, `<VICTIM_UUID>`).
- Say where every value comes from before it is used: "Copy the `uuid` field from the response
  of step 4".
- State the expected result after the key steps, especially the final one: status code, response
  body snippet, or visible UI change that proves the bug.
- Do not reference "as usual", "the endpoint", "the token" without having defined it earlier.

Example shape for an IDOR:

```
**Requirements**
- Two accounts on https://app.example.com
  - Attacker: attacker@example.com / Passw0rd!1
  - Victim: victim@example.com / Passw0rd!2
- curl or Burp Suite

**Steps**
1. Log in to https://app.example.com/login as the attacker (attacker@example.com / Passw0rd!1).
2. Go to https://app.example.com/settings/api and click "Generate API token". Copy the token. This is `<API_TOKEN>`.
3. In a separate browser session, log in as the victim (victim@example.com / Passw0rd!2).
4. Go to https://app.example.com/settings/profile and copy the "User ID" shown at the top. This is `<VICTIM_UUID>`.
5. From the attacker side, send:
   ```
   curl -s https://app.example.com/api/v2/users/<VICTIM_UUID>/profile \
     -H "Authorization: Bearer <API_TOKEN>"
   ```
6. The response is `200 OK` and contains the victim's `email`, `phone`, and `address`.
```

#### ## Impact

An **ordered list**. Each item is one concrete consequence, in first person where natural,
based on what the bug actually enables. Order from most to least severe.

1. State the direct effect (what data/action the attacker gets).
2. State who is affected and at what scale (one user, any user, all tenants), if demonstrated.
3. State the chained or business consequence (account takeover, fraud, compliance exposure).

Do not overclaim. Anything not demonstrated or not directly implied by the finding stays out.

## Negative examples (never write these)

### Bad titles

| Bad | Why | Good |
|-----|-----|------|
| `IDOR in API` | No endpoint, no capability, no result | `IDOR: GET /api/v2/users/{uuid}/profile allows reading any user's profile leading to PII disclosure` |
| `Critical vulnerability found on example.com` | No vulnerability class, no detail, claims severity | `Broken Access Control: /admin/export allows unauthenticated CSV download leading to full user database exposure` |
| `XSS` | One word | `Stored XSS: Profile "display name" field allows script execution leading to account takeover` |
| `Possible SQL injection might be present in search` | Hedged, wrong format | `SQL Injection: GET /search?q= allows injecting UNION queries leading to extraction of the users table` |

### Bad summaries

- Third person or passive: "A vulnerability was discovered in the application where the endpoint is not properly validated." Write: "I found that `/api/v2/users/{uuid}/profile` does not check that the UUID belongs to the caller's token."
- Vague: "There is an access control issue that attackers can exploit." Name the endpoint, the parameter, and the exploit path.
- No target info: never leave out the domain and what the feature does.
- Padded with severity talk, CVSS scores, or "this is a serious issue".

### Bad steps to reproduce

Bad:

```
1. Log in.
2. Get the token.
3. Use the token on the endpoint with the victim's ID.
4. Observe the issue.
```

Why it fails: which account? which credentials? where is the token obtained? which endpoint? where does the victim's ID come from? what is "the issue"?

Good:

```
1. Log in to https://app.example.com/login as the attacker (attacker@example.com / Passw0rd!1).
2. Go to https://app.example.com/settings/api and click "Generate API token". Copy the token. This is `<API_TOKEN>`.
3. In a separate browser session, log in as the victim (victim@example.com / Passw0rd!2).
4. Go to https://app.example.com/settings/profile and copy the "User ID" at the top. This is `<VICTIM_UUID>`.
5. Send: `curl -s https://app.example.com/api/v2/users/<VICTIM_UUID>/profile -H "Authorization: Bearer <API_TOKEN>"`
6. The response is `200 OK` and contains the victim's `email`, `phone`, and `address`.
```

Other step failures to avoid:

- Bundling several actions in one step ("Log in, create a project, then invite a user and capture the request").
- Pointing to attachments instead of writing the request: "see attached Burp file".
- Using a value before it exists, or never saying where it came from.
- Skipping the expected result, so the triager cannot tell if the bug triggered.
- Steps that need knowledge only the researcher has ("use the usual admin panel").

### Bad impact

- Unordered bullets or one big paragraph. Use an ordered list.
- Overclaiming: "Attacker can take over the entire company infrastructure" when only one profile read was shown.
- Generic filler: "This can lead to reputational damage and loss of customer trust."
- Recommendations: "The developer should add an ownership check." Remove them. The report has no remediation.

### Bad structure

- Extra sections: Recommendation, Remediation, References, Conclusion, Severity, CVSS, Timeline, Attachments.
- Wrong heading levels or reordered sections.
- A preamble such as "Hi team, I hope you are well" or a sign-off.
- Placeholder text left in the report (`xyz`, `TODO`, `<insert here>`).

## Phase 2.5: Evidence images (optional)

Add images only when they remove a question the text cannot answer: a flow diagram for a
multi-account or multi-hop chain, and a screenshot of the proof of impact. Skip this phase for
simple single-request findings.

- Render diagrams locally with `scripts/render_diagram.sh` (Mermaid to PNG).
- Redact and annotate screenshots with `scripts/redact.py` (solid fills, metadata stripped).
- Save to `report-assets/NN-name.png` and reference by filename inside Steps to Reproduce.
- Never use hosted diagram or whiteboard services (cnvs.app, Excalidraw cloud, etc.): report
  content is confidential.
- The three-section rule still holds. Images are attachments, not a new section, and the text
  must reproduce the bug without them.

Full workflow, commands, and redaction rules: [references/evidence-images.md](references/evidence-images.md).

## Phase 3: Triager dry-run (mandatory)

After the draft exists, switch roles. You are now the triager. You know nothing about the
company, the application, or the target. You have only the Steps to Reproduce section.

Walk through it line by line, from Requirements to the last step:

1. Read one line. Try to perform it literally.
2. Ask: do I know exactly where to go, what to click, what to type, which value to use?
3. Ask: do I know where every value in this line came from?
4. If anything is unclear, ambiguous, or missing, fix that line right now. Add the missing
   detail: the URL, the credential, the source of a value, the exact request, the expected result.
5. Move to the next line and repeat.

Things dry-runs usually catch:

- A token, ID, or cookie used in a step but never obtained in an earlier step
- "Log in" without saying which account or credentials
- A request with no method, URL, header, or body
- Navigation without a URL or menu path
- Missing prerequisite objects (a project, an invoice, an organization that must exist first)
- No expected result, so the triager cannot tell whether the bug triggered
- Steps that depend on state from a different account or session without saying so

Repeat the pass until a full read-through needs no additions. Then run the Final checklist.

## Final checklist

- [ ] Title matches `Category: xyz allows xyz leading to xyz`
- [ ] Exactly three sections: `## Summary`, `## Steps to Reproduce`, `## Impact`
- [ ] First-person voice throughout
- [ ] Summary names the target, the issue, and how it is exploited
- [ ] Requirements list exists and covers accounts, tools, and setup
- [ ] Steps are numbered, one action each, with exact URLs and full requests
- [ ] Every value used is introduced before it is used
- [ ] Final step states the observable proof
- [ ] Impact is an ordered list and contains only demonstrated or directly implied consequences
- [ ] No remediation or recommendation text anywhere
- [ ] No secrets from unrelated targets, no placeholder text left over (`xyz`, `TODO`)
- [ ] Any images: rendered locally, secrets redacted with solid fills, named `NN-name.png`, referenced inside existing sections, text works without them
- [ ] Triager dry-run completed with no further edits needed
- [ ] Nothing in the report matches the negative examples above


## Prose style

Keep prose plain and direct. Avoid filler, hedging, and AI-sounding phrasing. See
[references/phrases.md](references/phrases.md), [references/structures.md](references/structures.md),
and [references/examples.md](references/examples.md). The report format rules above override
any style rule that conflicts with them (for example, first person is required here).
