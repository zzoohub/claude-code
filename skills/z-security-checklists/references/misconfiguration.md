# Security Misconfiguration

> OWASP: A02 (Security Misconfiguration)

---

## Default Credentials & Settings

| Check | Why | CWE |
|-------|-----|-----|
| No default passwords in any deployed system | Trivial access | CWE-1393 |
| Admin panel credentials changed from defaults | Default admin takeover | CWE-1393 |
| Database default users disabled or re-credentialed | Direct DB access | CWE-1393 |
| Default API keys and sample tokens removed | Shared known credentials | CWE-798 |
| "Admin/admin", "root/root", "test/test" patterns absent | Common default pairs | CWE-1393 |

**Patterns to catch:**
- `password: "admin"`, `password: "password"`, `password: "123456"` in config
- Default MongoDB (no auth), Redis (no auth), Elasticsearch (no auth) configuration
- Docker Compose with default database credentials
- `.env.example` values copied directly to `.env` without changing secrets
- Default JWT secret: `"secret"`, `"jwt-secret"`, `"your-secret-here"`
- Default ports with default services (phpMyAdmin, Adminer, Kibana without auth)

---

## Debug & Development Settings

| Check | Why | CWE |
|-------|-----|-----|
| Debug mode disabled in production | Stack traces, memory dumps | CWE-489 |
| Verbose error messages off in production | Internal path disclosure | CWE-209 |
| Development tools/endpoints removed or gated | Unintended access | CWE-489 |
| Source maps not served in production | Source code exposure | CWE-540 |
| Hot reload / file watcher disabled in production | File system manipulation | CWE-489 |

**Patterns to catch:**
- `DEBUG=True` (Django), `debug: true` (Express), `FLASK_DEBUG=1`
- `NODE_ENV=development` in production deployment
- `/debug`, `/console`, `/__debug__/`, `/elmah.axd` endpoints accessible
- Source maps (`.js.map`) in production build output
- GraphQL Playground / Swagger UI accessible without auth in production
- `RAILS_ENV=development` or `APP_ENV=local` in production
- Webpack dev server or HMR enabled in production builds
- `phpinfo()` or `print_r()` debug statements in production code

---

## HTTP Security Headers

| Check | Why | CWE |
|-------|-----|-----|
| `Content-Security-Policy` present and restrictive | XSS mitigation layer | CWE-693 |
| `Strict-Transport-Security` with `max-age≥31536000` | HTTPS downgrade prevention | CWE-319 |
| `X-Content-Type-Options: nosniff` | MIME sniffing attacks | CWE-693 |
| `X-Frame-Options: DENY` or CSP `frame-ancestors 'none'` | Clickjacking | CWE-1021 |
| `Referrer-Policy: strict-origin-when-cross-origin` or stricter | URL leakage | CWE-200 |
| `Permissions-Policy` restricting camera, microphone, geolocation | Feature abuse | CWE-693 |
| `X-Powered-By` header removed | Framework fingerprinting | CWE-200 |
| `Server` header minimized or removed | Server fingerprinting | CWE-200 |

**Patterns to catch:**
- No security headers at all (check with `curl -I`)
- CSP with `unsafe-inline` and `unsafe-eval` (defeats most XSS protection)
- CSP with `*` as source (allows everything)
- HSTS max-age less than 1 year (31536000 seconds)
- Express app without `helmet` or equivalent middleware
- `X-Powered-By: Express` header present (default, must explicitly disable)
- Missing `frame-ancestors` on pages with sensitive actions

---

## CORS Misconfiguration

| Check | Why | CWE |
|-------|-----|-----|
| Specific origin allowlist, not wildcard | Cross-origin data theft | CWE-942 |
| No wildcard (`*`) with credentials (`Access-Control-Allow-Credentials: true`) | Browser blocks this, but misconfig exposes intent | CWE-942 |
| Origin validated against strict allowlist (not reflected from request) | Arbitrary origin acceptance | CWE-942 |
| Allowed methods restricted to what's needed | Unnecessary method exposure | CWE-942 |
| Preflight cache reasonable (`Access-Control-Max-Age`) | Reduced preflight requests | CWE-942 |

**Patterns to catch:**
- Origin reflected directly from request: `res.setHeader('ACAO', req.headers.origin)`
- Regex-based origin validation with bypasses: `/\.example\.com$/` matches `evil-example.com`
- `Access-Control-Allow-Origin: null` (exploitable via sandboxed iframes)
- CORS configured but CSRF protection missing (CORS alone doesn't prevent CSRF)
- Internal APIs with `Access-Control-Allow-Origin: *` (should be restricted)

---

## Cloud Storage & Service Configuration

| Check | Why | CWE |
|-------|-----|-----|
| S3/GCS/Azure Blob buckets not publicly accessible | Data exposure | CWE-284 |
| Bucket policies use least privilege | Over-permissive access | CWE-269 |
| No public write access to any storage bucket | Data tampering, hosting abuse | CWE-284 |
| Pre-signed URLs have short expiration (minutes, not days) | URL sharing/leaking | CWE-613 |
| Server-side encryption enabled for sensitive buckets | Data at rest protection | CWE-311 |
| Bucket versioning enabled for critical data | Accidental deletion recovery | CWE-284 |

**Patterns to catch:**
- S3 bucket policy with `"Principal": "*"` (public access)
- ACL set to `public-read` or `public-read-write`
- Pre-signed URLs with expiration >1 hour for sensitive content
- Cloud storage credentials in application code (use IAM roles)
- No server-side encryption configured
- Bucket name matching company/project name (easy to discover)
- Cloud function with `allUsers` invoke permission

---

## Directory & File Exposure

| Check | Why | CWE |
|-------|-----|-----|
| Directory listing disabled on web servers | File enumeration | CWE-548 |
| No sensitive files accessible via web (`.env`, `.git`, `backup.sql`) | Configuration/data exposure | CWE-538 |
| `.git` directory not accessible via web | Source code exposure | CWE-538 |
| Backup files not in web-accessible directories | Data exposure | CWE-538 |
| Error pages customized (no default framework pages) | Framework fingerprinting | CWE-209 |

**Patterns to catch:**
- `/.git/config` accessible via HTTP (entire repo can be reconstructed)
- `/.env` accessible via HTTP
- `/backup.sql`, `/dump.sql`, `/db.sql` in webroot
- `/wp-config.php.bak`, `.DS_Store`, `Thumbs.db` accessible
- Default Nginx/Apache/IIS error pages
- `robots.txt` revealing sensitive paths (admin panels, internal tools)
- `/server-status`, `/server-info` (Apache) accessible without auth

---

## Infrastructure Misconfiguration

| Check | Why | CWE |
|-------|-----|-----|
| Unnecessary ports closed (only 80, 443 + needed services) | Expanded attack surface | CWE-284 |
| Management interfaces (SSH, RDP) restricted to VPN/bastion | Direct management access | CWE-284 |
| Database not directly accessible from internet | Direct DB exploitation | CWE-284 |
| Message queues and caches require authentication | Unauthenticated access | CWE-306 |
| Load balancer terminates TLS properly | Cleartext between LB and backend | CWE-319 |
| DNS records don't expose internal infrastructure | Internal network mapping | CWE-200 |

**Patterns to catch:**
- MongoDB/Redis/Elasticsearch exposed on public IP without auth
- SSH on port 22 open to `0.0.0.0/0` (should be restricted)
- Database port (3306, 5432, 27017) open to public
- Internal service names in public DNS (`internal-api.company.com`)
- Load balancer health check endpoint returns sensitive information
- Kubernetes dashboard accessible without auth on public IP

---

## Environment Separation

| Check | Why | CWE |
|-------|-----|-----|
| Production secrets different from dev/staging | Cross-environment compromise | CWE-798 |
| Production database not accessible from dev environments | Accidental data access | CWE-284 |
| Test data doesn't contain real user data | PII in non-production | CWE-200 |
| Feature flags for dev features not leaking to production | Unfinished feature exposure | CWE-489 |
| Environment clearly identified in UI/logging | Wrong environment actions | CWE-489 |

**Patterns to catch:**
- Same database connection string in dev and prod config
- Same API keys used across environments
- Production user emails visible in staging database
- `if (env === 'development')` with no server-side enforcement
- Missing environment indicator in admin interfaces (easy to mistake prod for staging)
