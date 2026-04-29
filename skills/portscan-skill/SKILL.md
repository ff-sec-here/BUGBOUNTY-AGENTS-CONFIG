---
name: portscan
description: >
  Port scanning methodology using nmap and masscan. Use when the user wants to
  discover open ports and services on subdomains. Covers scan strategies,
  service detection, and importing results into BB-Mapper.
---

# Port Scanning Skill

## Tool: masscan (fast initial sweep)

```bash
# Fast sweep of common ports across all live hosts
masscan -iL live-hosts.txt \
  -p 80,443,8080,8443,8888,9000,9090,3000,4000,5000,6379,27017,5432,3306 \
  --rate 1000 \
  -oJ masscan.json
```

## Tool: nmap (service detection)

### Quick scan on interesting ports
```bash
nmap -iL live-hosts.txt \
  -p 80,443,8080,8443,8888,9000,9090,3000,4000,5000 \
  -sV --open \
  -oX nmap.xml -oN nmap.txt
```

### Full port scan on a single target
```bash
nmap -p- TARGET \
  -sV -sC --open \
  -T4 \
  -oX nmap-full.xml
```

### UDP scan (top ports)
```bash
nmap -sU --top-ports 100 TARGET \
  -oX nmap-udp.xml
```

## Interesting Ports to Flag

| Port | Service | Why Interesting |
|------|---------|----------------|
| 22 | SSH | Brute force, key exposure |
| 21 | FTP | Anonymous login, file exposure |
| 25/587 | SMTP | Email spoofing, open relay |
| 3306 | MySQL | Exposed DB |
| 5432 | PostgreSQL | Exposed DB |
| 6379 | Redis | Unauthenticated access |
| 27017 | MongoDB | Unauthenticated access |
| 9200 | Elasticsearch | Unauthenticated access |
| 2375 | Docker | Remote API exposure |
| 8080/8443 | Alt HTTP/S | Admin panels, dev servers |
| 9090 | Prometheus | Metrics exposure |
| 4848 | GlassFish | Admin console |

## Import into BB-Mapper

```
POST /targets/{targetId}/openports/import
Body: { "results": [ { "subdomain": "sub.target.com", "port": 8080, "protocol": "tcp", "service": "http", "state": "open" } ] }
```

Review results:
```
GET /targets/{targetId}/openports/stats
GET /targets/{targetId}/all-subdomains-with-openports
```

## Workflow
1. Extract live hosts from BB-Mapper notable subdomains
2. Run masscan for fast port discovery
3. Run nmap -sV on discovered open ports for service detection
4. Import results into BB-Mapper
5. Flag subdomains with unusual/interesting ports as notable
6. Write notes on any exposed sensitive services
