# bugbounty-agents-config — Project Steering

## What This Repo Is
This is the Kiro agent configuration repo for bug bounty operations.
It lives at `/root/bugbounty-agents-config/` and is tracked at `ff-sec-here/BUGBOUNTY-AGENTS-CONFIG`.

The contents of this repo are synced to `~/.kiro/` (which is where Kiro reads agents, skills, and prompts at runtime).
To apply changes: run `./sync-to-kiro.sh` from this directory.

## Directory Layout

```
bugbounty-agents-config/
├── agents/               → Kiro agent definitions (.json)
│   ├── bugbounty.json    → Main bug bounty hunting agent
│   └── bb-manager-dev.json → BB-Manager backend dev agent
├── prompts/
│   └── bugbounty.txt     → System prompt for the bugbounty agent
├── skills/               → Skill files loaded as context by agents
│   ├── bug-bounty-mapper-skill/SKILL.md  ← see below
│   ├── burp-skill/SKILL.md
│   ├── fuzzing-skill/SKILL.md
│   ├── js-recon-skill/SKILL.md
│   ├── portscan-skill/SKILL.md
│   └── recon-skill/SKILL.md
├── custom-scripts/
│   └── new-target.sh
└── sync-to-kiro.sh       → Syncs this repo → ~/.kiro
```

## Skills Reference

### bug-bounty-mapper-skill
- **What it is**: Full API reference for BB-Manager at `mapper.fhdsec.info`
- **BB-Manager location**: `/root/BB-Manager/` (Docker-based, backend + frontend)
- **Purpose**: All bug bounty data lives in BB-Manager — targets, subdomains, notes, findings, fuzzing results, port scans, JS recon, alerts, checklists, dorking
- **When editing this skill**: Changes here must reflect the actual BB-Manager API. Cross-check with `/root/BB-Manager/backend/` routes before updating endpoints or request formats.

### burp-skill
- **What it is**: Burp Suite MCP integration instructions
- **All HTTP requests to targets go through Burp** — never curl directly

### fuzzing-skill
- **What it is**: ffuf methodology, wordlists, flags, filter strategies
- **Helper script**: `skills/fuzzing-skill/ffuf_helper.py` — analyzes ffuf JSON output

### recon-skill
- **What it is**: Subdomain enumeration methodology (subfinder, amass, httpx)

### portscan-skill
- **What it is**: Port scanning methodology (nmap, masscan) + BB-Mapper import

### js-recon-skill
- **What it is**: JavaScript recon workflow — secrets, endpoints, API keys

## Agents Reference

### bugbounty.json
- Main hunting agent — loads all 6 skills
- System prompt: `prompts/bugbounty.txt`
- Defines note-taking hierarchy: Notes → Leads → Primitives → Findings → Reports
- Reports are saved as `.md` files under `reports/` in the target's working directory

### bb-manager-dev.json
- Dev agent for working on the BB-Manager application itself (`/root/BB-Manager/`)

## Workflow for Editing Skills

1. Edit the skill file here in `/root/bugbounty-agents-config/skills/<skill>/SKILL.md`
2. Run `./sync-to-kiro.sh` to push to `~/.kiro`
3. Commit and push to GitHub:
   ```bash
   git add -A && git commit -m "..." && git push
   ```

## Key Paths on This Server

| Path | What |
|------|------|
| `/root/bugbounty-agents-config/` | This repo (edit skills/agents/prompts here) |
| `/root/.kiro/` | Live Kiro config (synced from this repo) |
| `/root/BB-Manager/` | BB-Manager app (backend API + frontend) |
| `/root/BugBounty/` | Active bug bounty target working directories |
| `mapper.fhdsec.info` | BB-Manager live instance |
