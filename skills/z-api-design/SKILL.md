---
name: z-api-design
description: |
  REST API design principles, conventions, and patterns.
  Use when: designing APIs, choosing status codes, error handling, caching, auth patterns,
  structuring endpoints, naming resources, deciding pagination strategy, or any time the user
  is building a new API — even if they don't explicitly say "design". If someone asks
  "what status code should I return", "how should I structure my endpoints", "REST best practices",
  or is planning any HTTP API, use this skill.
  Do not use for: framework-specific implementation (use z-fastapi, z-axum skills).
  Workflow: This skill (design) -> z-fastapi-hexagonal | z-axum-hexagonal (implementation).
references:
  - references/examples.md    # Full request/response examples
---

# API Design

## Resource Naming

**Rule: Model nouns, not verbs. HTTP methods express actions.**

URLs identify resources (things), not operations. The HTTP method already tells you what action to perform — putting verbs in URLs creates redundancy and inconsistency.

```
# Bad: Verbs in URL
POST /createUser
GET /getUsers

# Good: RESTful
POST /users
GET /users
DELETE /users/123
```

| Pattern | Example |
|---------|---------|
| Collection | `/users` |
| Single resource | `/users/{id}` |
| Nested (shallow) | `/users/{id}/orders` |
| Filter via query | `/orders?userId=123` |

**Rule: Plural nouns, lowercase, max 2 levels deep.**

Deep nesting couples resources tightly together and makes URLs fragile — if any intermediate resource changes, all child URLs break. Flatten with query parameters instead.

```
# Bad: Too deep — tightly coupled, hard to cache independently
/companies/{id}/departments/{id}/users/{id}/orders

# Good: Flatten — each resource is independently addressable
/orders?userId=123
```

---

## HTTP Methods

| Method | Action | Idempotent | Success Code |
|--------|--------|------------|--------------|
| GET | Read | Yes | 200 |
| POST | Create | No | 201 |
| PUT | Replace | Yes | 200 |
| PATCH | Partial update | No | 200 |
| DELETE | Remove | Yes | 204 |

**Idempotent** means calling the same request multiple times produces the same result as calling it once — safe to retry on network failure. POST is not idempotent because each call creates a new resource. PATCH is not guaranteed idempotent per RFC 5789 — it depends on the operation (e.g., "set name to X" is idempotent, but "append to list" is not).

**Rule: Use `Idempotency-Key` header for safe POST retries.** When a client needs to retry a POST without creating duplicates (e.g., payment processing), the client sends a unique key and the server deduplicates.

```http
POST /payments HTTP/2
Idempotency-Key: txn_8a3b2c1d
Content-Type: application/json

{ "amount": 5000, "currency": "USD" }
```

---

## Status Codes

### Success (2xx)

| Code | When |
|------|------|
| 200 OK | Generic success |
| 201 Created | Resource created + `Location` header |
| 202 Accepted | Async processing started |
| 204 No Content | Success, no body (DELETE) |

### Client Error (4xx)

| Code | When |
|------|------|
| 400 Bad Request | Malformed syntax |
| 401 Unauthorized | No/invalid auth |
| 403 Forbidden | No permission |
| 404 Not Found | Resource doesn't exist |
| 409 Conflict | Duplicate, state conflict |
| 410 Gone | Permanently deleted |
| 422 Unprocessable | Validation failed |
| 429 Too Many Requests | Rate limited |

### Server Error (5xx)

| Code | When |
|------|------|
| 500 Internal Server Error | Unexpected failure |
| 502 Bad Gateway | Upstream down |
| 503 Service Unavailable | Temporarily unavailable |

**Rule: 4xx = client's fault (fix the request). 5xx = server's fault (retry later).**

---

## Response Format

### Success

```json
{
  "data": { "id": 123, "name": "Ada" },
  "meta": { "requestId": "abc123" }
}
```

### Error (RFC 9457 Problem Details)

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 422,
  "detail": "Email is required",
  "errors": [{ "field": "email", "code": "required" }]
}
```

**Rule: Use `Content-Type: application/problem+json` for errors.** RFC 9457 gives clients a machine-readable, consistent structure to parse errors across all endpoints.

---

## Content Negotiation

Use `Accept` header to let clients request specific response formats. Server responds with `Content-Type` matching the chosen format.

```http
GET /users/123 HTTP/2
Accept: application/json
```

If the server cannot produce the requested format, respond with `406 Not Acceptable`. For most APIs, JSON is the only format — but always set `Content-Type` explicitly.

---

## Request/Response Consistency

**Rule: Request shape should match response shape.**

Response may have read-only fields (`id`, `createdAt`), but structure must be identical. Never change field types or nesting between request/response.

---

## Pagination

| Type | Use for | Example |
|------|---------|---------|
| Cursor-based | Feeds, timelines, large data | `?cursor=xyz&limit=20` |
| Offset-based | Admin panels, small data | `?page=2&limit=20` |

**Rule: Prefer cursor-based.** Offset pagination uses SQL `OFFSET N` which forces the database to scan and discard N rows before returning results — this gets progressively slower as pages increase. Cursor-based pagination uses a `WHERE id > cursor` approach which leverages indexes and has consistent performance regardless of how deep you paginate.

---

## Filtering & Sorting

```
GET /users?role=admin&status=active
GET /users?sort=-createdAt
GET /users?fields=id,name,email
```

**Rule: Filters in query string, not URL path.** Path segments identify resources; query parameters modify the representation or filter collections.

---

## Caching

| Header | Purpose |
|--------|---------|
| `ETag` | Version fingerprint for conditional requests (`If-None-Match`) |
| `Cache-Control` | `public`, `private`, `no-store` |
| `Last-Modified` | Timestamp for `If-Modified-Since` checks |

**Rule: Cache public data. `private, no-store` for user-specific.** Caching reduces server load and improves latency. `ETag` enables conditional requests — the server returns `304 Not Modified` when the resource hasn't changed, saving bandwidth.

---

## Security

| Item | Recommended | Why |
|------|-------------|-----|
| Password hashing | argon2id (64MB, 3 iter, 4 parallel) | Memory-hard, resistant to GPU/ASIC attacks |
| JWT algorithm | ES256 or EdDSA | Asymmetric — verifiers don't need the signing key |
| JWT access token | 15-30 minutes | Short-lived limits damage from token theft |
| JWT refresh token (web) | 90 days | Balances security with user convenience |
| JWT refresh token (mobile) | 1 year | Mobile users expect persistent sessions |
| TLS | 1.3+ only | Removes insecure cipher suites, faster handshake |
| CORS | Explicit origins only | Wildcard `*` allows any site to make requests |
| Rate limit (auth) | 5/min | Prevents brute-force credential stuffing |
| Rate limit (API) | 100/min baseline | Protects against abuse while allowing normal usage |

| API Type | Auth Pattern |
|----------|--------------|
| User-facing | JWT |
| Public API | API keys, OAuth 2.0 |
| Service-to-service | mTLS |
| Webhooks | HMAC signature |

**Rate limit headers:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 75
Retry-After: 30
```

**Rule: Stateless auth enables horizontal scaling. Return `Retry-After` with 429.**

---

## Versioning

```
/v1/users
/v2/users
```

**Rule: Version in URL path. Only for breaking changes.**

URL versioning is the most practical approach — it's visible in logs, easy to route at the load balancer, and obvious to developers. Header-based versioning (`Accept: application/vnd.api+json;version=2`) is harder to test, debug, and cache.

Only bump the version for breaking changes (removing fields, changing types, restructuring). Additive changes (new optional fields, new endpoints) don't need a new version.

Use `Sunset` header to signal deprecation:
```http
Sunset: Sat, 01 Mar 2026 00:00:00 GMT
Link: </v2/users>; rel="successor-version"
```

---

## API Documentation

**Rule: Design API-first with OpenAPI spec before writing code.**

Writing the OpenAPI spec first forces you to think through the contract before implementation. It enables parallel frontend/backend development, auto-generated client SDKs, and request validation.

Keep the spec as the source of truth — generate docs from it, not the other way around.

---

## Health Checks

Expose health endpoints for load balancers and monitoring:

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Basic liveness — returns 200 if the process is running |
| `GET /health/ready` | Readiness — returns 200 only if dependencies (DB, cache) are reachable |

Health endpoints should not require authentication and should respond fast (no heavy queries).

---

## Webhooks

When your API notifies external systems about events:

- Sign payloads with HMAC-SHA256 so receivers can verify authenticity
- Include a `timestamp` to prevent replay attacks
- Retry with exponential backoff (1s, 2s, 4s, 8s... up to a cap)
- Provide a way for consumers to list/replay failed deliveries

> Full examples for all patterns above: `references/examples.md`

---

## Quick Checklist

### URL Design
- [ ] Plural nouns, no verbs
- [ ] Max 2 levels nesting
- [ ] Filters in query string

### HTTP
- [ ] Correct methods and status codes
- [ ] 201 + Location for create
- [ ] 204 for delete
- [ ] Idempotency-Key for non-idempotent retries

### Response
- [ ] Consistent envelope (`data`, `meta`)
- [ ] RFC 9457 for errors
- [ ] Request/response shapes match

### Performance
- [ ] Pagination on collections
- [ ] Cache headers (ETag, Cache-Control)
- [ ] Field selection

### Security
- [ ] HTTPS only
- [ ] Stateless auth
- [ ] Rate limiting with Retry-After
- [ ] CORS explicit origins

### Operations
- [ ] OpenAPI spec maintained
- [ ] Health check endpoints
- [ ] Webhook signatures (if applicable)
