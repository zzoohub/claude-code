# API Security

> OWASP: A01 (Broken Access Control), A05 (Injection)

---

## Input Validation

| Check | Why | CWE |
|-------|-----|-----|
| Schema validation on all inputs (zod, joi, pydantic, etc.) | Unexpected data types, injection | CWE-20 |
| Explicit type coercion (no implicit string-to-number) | Type confusion attacks | CWE-843 |
| Size limits on strings, arrays, files, nested objects | DoS, buffer issues | CWE-770 |
| Reject unexpected fields (strict schema, no extra properties) | Mass assignment via extra fields | CWE-915 |
| Validate content-type matches actual body | Content-type mismatch attacks | CWE-436 |
| Canonicalize input before validation (Unicode, encoding) | Validation bypass via encoding | CWE-180 |

**Patterns to catch:**
- Request body used directly without validation: `db.create(req.body)`
- No max length on string fields (allows multi-MB strings)
- Dynamic field names from user input: `obj[req.body.field]`
- Array input without max items limit (100,000 item array)
- Nested object depth unbounded (deeply nested JSON for DoS)
- Regex validation without anchors: `/[a-z]+/` instead of `/^[a-z]+$/`
- Missing validation on query parameters and path parameters (not just body)

---

## Mass Assignment

| Check | Why | CWE |
|-------|-----|-----|
| Explicit allowlist of updatable fields per endpoint | Privilege escalation via hidden fields | CWE-915 |
| Separate DTOs for create vs update operations | Different allowed fields per operation | CWE-915 |
| Role-based field restrictions | Admin fields writable by regular users | CWE-915 |
| Nested object assignment reviewed | Deep property override | CWE-915 |

**Patterns to catch:**
- Full request body spread into model update: `User.update({...req.body})`
- Same input DTO for user and admin endpoints
- Fields like `role`, `isAdmin`, `balance`, `verified`, `emailVerified` not explicitly blocked
- Prototype pollution via `__proto__` or `constructor` in request body (Node.js)
- ORM `update` called with raw request body without field filtering

---

## Injection Prevention

| Check | Why | CWE |
|-------|-----|-----|
| Parameterized queries for all database operations | SQL Injection | CWE-89 |
| ORM used correctly (no raw query with string interpolation) | SQL Injection via ORM | CWE-89 |
| No user input in shell commands | Command Injection | CWE-78 |
| Template engine auto-escaping enabled | XSS | CWE-79 |
| LDAP queries use parameterized API | LDAP Injection | CWE-90 |
| XML parsing disables external entities (XXE) | XXE | CWE-611 |
| NoSQL queries use typed operators, not string concat | NoSQL Injection | CWE-943 |

**Patterns to catch:**
- String concatenation in SQL: `` `SELECT * FROM users WHERE id = ${id}` ``
- ORM raw query mode with interpolation: `sequelize.query("SELECT..."+input)`
- `child_process.exec(userInput)` instead of `execFile` with args array
- `dangerouslySetInnerHTML` with unsanitized input (React)
- MongoDB query with `$where`, `$regex` from user input
- XML parser without `disableEntityExpansion` or `noent: false`
- Path traversal in file operations: `fs.readFile(basePath + userInput)`

---

## Data Exposure

| Check | Why | CWE |
|-------|-----|-----|
| Response contains only needed fields (explicit serialization) | Sensitive data leakage | CWE-200 |
| No internal IDs, metadata, or debug info leaked | Information disclosure | CWE-200 |
| Error messages sanitized for production | Stack traces reveal internals | CWE-209 |
| Pagination enforced on all list endpoints | DoS via large responses | CWE-770 |
| Sensitive data not cached (Cache-Control headers) | Cached sensitive responses | CWE-524 |
| Response headers don't leak server info (X-Powered-By, Server) | Fingerprinting | CWE-200 |

**Patterns to catch:**
- Full database object returned: `res.json(user)` instead of `res.json(pick(user, ['id','name']))`
- Stack traces in production error responses
- List endpoint returns all records without limit/offset
- API version header reveals internal framework version
- Sensitive fields (password hash, SSN, tokens) in response body
- Debug endpoints left enabled in production (`/debug`, `/phpinfo`, `/__debug__`)
- Internal service URLs or IP addresses in response data

---

## GraphQL Specific

| Check | Why | CWE |
|-------|-----|-----|
| Introspection disabled in production | Schema disclosure | CWE-200 |
| Query depth limiting (max 7-10 levels) | Nested query DoS | CWE-770 |
| Query complexity/cost analysis | Resource exhaustion | CWE-770 |
| Field-level authorization on resolvers | Data access bypass | CWE-285 |
| Batch query limiting | Batch attack amplification | CWE-770 |
| Alias-based attack prevention | Rate limit bypass via aliases | CWE-770 |

**Patterns to catch:**
- `__schema` query enabled in production
- Deeply nested queries without limit: `{user{posts{comments{author{posts{...}}}}}}`
- Same resolver for public and private fields without auth check
- No cost calculation before query execution
- Mutations exposed without proper authorization
- Subscriptions without authentication or rate limiting

---

## File Upload

| Check | Why | CWE |
|-------|-----|-----|
| Validate type by magic bytes/content, not just extension | Extension spoofing | CWE-434 |
| Size limits enforced server-side (not just client) | Storage DoS | CWE-770 |
| Filename sanitized (strip path separators, special chars) | Path traversal | CWE-22 |
| Stored outside webroot with random generated names | Direct execution | CWE-434 |
| Content-Type header set correctly on serve (not from upload) | MIME confusion | CWE-436 |
| Image files re-processed/re-encoded | Embedded malicious content | CWE-434 |
| Antivirus scan for applicable file types | Malware upload | CWE-434 |

**Patterns to catch:**
- Extension-only validation: `if (file.ext === '.jpg')` (rename .php to .jpg)
- User-provided filename used directly in file path
- Uploads stored in publicly accessible directory with original names
- No content-type verification (trust client Content-Type header)
- SVG uploads allowed without sanitization (SVG can contain JavaScript)
- ZIP file upload without bomb detection (zip bomb DoS)
- Double extension bypass: `file.php.jpg` if server processes first extension

---

## Webhook Security

| Check | Why | CWE |
|-------|-----|-----|
| Webhook signatures verified (HMAC) | Forged webhook payloads | CWE-345 |
| Replay protection (timestamp + nonce validation) | Replay attacks | CWE-294 |
| Webhook URLs validated against allowlist | SSRF via webhook | CWE-918 |
| Timeout on webhook delivery | Slow-loris DoS | CWE-400 |
| Webhook payload size limited | Memory exhaustion | CWE-770 |
| Idempotent webhook processing | Duplicate delivery handling | CWE-837 |

**Patterns to catch:**
- Webhook endpoint accepts any POST without signature verification
- No timestamp check (allows replay of old webhooks indefinitely)
- User-configurable webhook URL without SSRF protection
- Webhook processing modifies state without idempotency key
- Webhook secret shared across multiple consumers

---

## API Key & Token Management

| Check | Why | CWE |
|-------|-----|-----|
| API keys have scoped permissions (not full access) | Over-privileged keys | CWE-269 |
| Key rotation mechanism exists | Long-lived compromised keys | CWE-324 |
| Revocation is immediate and complete | Delayed revocation window | CWE-324 |
| Keys are high-entropy, cryptographically random | Predictable keys | CWE-330 |
| Keys transmitted only via headers, never URL params | Log exposure | CWE-598 |
| Different keys for different environments | Prod key in dev | CWE-798 |

**Patterns to catch:**
- Single "god key" with all permissions
- API keys in URL query parameters (logged in server logs, proxy logs)
- No key expiration or rotation policy
- Keys generated with `Math.random()` or sequential patterns
- Same API key used across dev/staging/production
- No audit log of key usage

---

## CORS & Security Headers

| Check | Why | CWE |
|-------|-----|-----|
| Specific origins, no wildcard with credentials | Cross-origin attacks | CWE-942 |
| Content-Security-Policy header present and restrictive | XSS mitigation | CWE-693 |
| Strict-Transport-Security (HSTS) with long max-age | Downgrade attacks | CWE-319 |
| X-Frame-Options or CSP frame-ancestors | Clickjacking | CWE-1021 |
| X-Content-Type-Options: nosniff | MIME sniffing attacks | CWE-693 |
| Referrer-Policy set appropriately | URL leakage via referrer | CWE-200 |
| Permissions-Policy restricting browser features | Feature abuse | CWE-693 |

**Patterns to catch:**
- `Access-Control-Allow-Origin: *` combined with `Access-Control-Allow-Credentials: true`
- Origin reflected from request without validation: `res.setHeader('ACAO', req.headers.origin)`
- Missing Content-Security-Policy entirely
- CSP with `unsafe-inline` or `unsafe-eval` (defeats purpose)
- Missing X-Frame-Options on pages with sensitive actions
- HSTS max-age too short (should be >= 1 year / 31536000)

---

## Rate Limiting & DoS Prevention

| Check | Why | CWE |
|-------|-----|-----|
| Global rate limits per IP/user | Resource exhaustion | CWE-770 |
| Stricter limits on expensive operations (export, report, search) | Targeted DoS | CWE-770 |
| Request body size limits | Memory exhaustion | CWE-770 |
| Timeout on long-running operations | Thread/connection exhaustion | CWE-400 |
| Regex patterns reviewed for catastrophic backtracking | ReDoS | CWE-1333 |
| Batch endpoints limit items per request | Amplification attacks | CWE-770 |

**Patterns to catch:**
- No rate limiting middleware at all
- Expensive operations (CSV export, PDF generation, report) without limits
- Regex with nested quantifiers: `(a+)+`, `(a|b)*c` (ReDoS vulnerable)
- No request body size limit (default may be very large)
- Long-running database queries without timeout
- Search endpoint without query complexity limits
- Batch API accepts unlimited items: `POST /api/batch` with 100,000 items
