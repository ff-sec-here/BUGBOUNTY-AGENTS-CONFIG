# BB-Manager Development Agent

You are the development agent for BB-Manager, a bug bounty management platform. You work on both the local machine and the production server.

## Core Workflow — MANDATORY for every change

All code edits MUST follow this exact sequence. No exceptions.

### 1. Work on `testing-local` branch only
```bash
git checkout testing-local
```
Never commit directly to `main`.

### 2. Make the code changes
Follow project conventions from `.kiro/specs/KIRO.md`:
- Migrations → `backend/migrations/`
- Tests → `backend/tests/`
- Update `backend/migrations/run_all_migrations.sh` when adding migrations
- Database is PostgreSQL — never use SQLite syntax

### 3. Push via `force-push-and-merge.sh`
```bash
bash force-push-and-merge.sh "your commit message here"
```
This stages all changes (excluding `docker-compose.yml` and `frontend/vite.config.js`), commits, force-pushes `testing-local`, and merges to `main` via PR.

### 4. Rebuild on production
```bash
sshpass -p '9088qrccp' ssh -o StrictHostKeyChecking=no root@5.189.181.193 'cd ~/BB-Manager && bash rebuild.sh'
```

### 5. Verify the app started without errors
```bash
sshpass -p '9088qrccp' ssh -o StrictHostKeyChecking=no root@5.189.181.193 'cd ~/BB-Manager && docker-compose ps && docker-compose logs --tail=50 backend'
```
Containers to verify: `bug-bounty-mapper-backend`, `bug-bounty-mapper-frontend`, `bug-bounty-mapper-postgres`, `scan-agent-local`.

If any container is not running or logs show startup errors, go to step 6.

### 6. Fix errors and repeat
- Diagnose from logs
- Edit on `testing-local`
- Repeat steps 3–5 until clean startup

## Rules
- Never create `.md` summary/changelog files after completing work
- Never commit `docker-compose.yml` or `frontend/vite.config.js`
- Never push directly to `main`
- Always verify production is healthy after every deploy

## Project Stack
- **Backend**: FastAPI + async SQLAlchemy + PostgreSQL (container: `bug-bounty-mapper-backend`, port 8000)
- **Frontend**: React + Vite (container: `bug-bounty-mapper-frontend`, port 5173)
- **Database**: PostgreSQL 16 (container: `bug-bounty-mapper-postgres`, port 5432)
- **Scan Agent**: Python (container: `scan-agent-local`)

## Useful Docker Commands
```bash
# Run migrations
docker exec bug-bounty-mapper-backend bash migrations/run_all_migrations.sh

# Run tests
docker exec bug-bounty-mapper-backend pytest tests/

# Tail live logs on production
sshpass -p '9088qrccp' ssh -o StrictHostKeyChecking=no root@5.189.181.193 'cd ~/BB-Manager && docker-compose logs -f 2>&1'
```
