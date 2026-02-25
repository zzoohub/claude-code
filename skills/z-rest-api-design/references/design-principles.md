# API Design Principles

Reference document for REST API conventions. These rules are enforced when generating OpenAPI specs.

---

## Resource Naming

URLs identify resources (things), not operations. HTTP methods express actions.

```
# Bad
POST /createUser
GET /getUsers

# Good
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

Rules:

- Plural nouns, lowercase, kebab-case for multi-word (`line-items`, not `lineItems`)
- Max 2 levels deep — flatten with query parameters beyond that
- Path segments identify resources; query parameters modify representation or filter

---

## HTTP Methods

| Method | Action | Idempotent | Success Code |
|--------|--------|------------|--------------|
| GET | Read | Yes | 200 |
| POST | Create | No | 201 |
| PUT | Replace | Yes | 200 |
| PATCH | Partial update | No | 200 |
| DELETE | Remove | Yes | 204 |

Use `Idempotency-Key` header for safe POST retries (payments, transfers).

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

Rule: 4xx = client's fault. 5xx = server's fault.

---

## Response Format

### Success envelope

```json
{
  "data": { "id": 123, "name": "Ada" },
  "meta": { "requestId": "abc123" }
}
```

### Error format (RFC 9457 Problem Details)

Content-Type: `application/problem+json`

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 422,
  "detail": "Email is required",
  "errors": [{ "field": "email", "code": "required" }]
}
```

---

## Pagination

| Type | Use for | Example |
|------|---------|---------|
| Cursor-based (default) | Feeds, timelines, large data | `?cursor=xyz&limit=20` |
| Offset-based | Admin panels, small data | `?page=2&limit=20` |

Prefer cursor-based. Offset uses SQL `OFFSET N` which degrades at scale.

---

## Filtering & Sorting

```
GET /users?role=admin&status=active
GET /users?sort=-createdAt
GET /users?fields=id,name,email
```

- Filters in query string, not URL path
- `-` prefix for descending sort

---

## Caching

| Header | Purpose |
|--------|---------|
| `ETag` | Version fingerprint (`If-None-Match`) |
| `Cache-Control` | `public`, `private`, `no-store` |
| `Last-Modified` | Timestamp (`If-Modified-Since`) |

---

## Security

| API Type | Auth Pattern |
|----------|--------------|
| User-facing | JWT (ES256 / EdDSA) |
| Public API | API keys, OAuth 2.0 |
| Service-to-service | mTLS |
| Webhooks | HMAC-SHA256 signature |

Rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`

---

## Versioning

- Version in URL path: `/v1/users`
- Only bump for breaking changes
- Additive changes don't need new version
- Use `Sunset` header for deprecation

---

## Content Negotiation

- Use `Accept` header for format requests
- Always set `Content-Type` explicitly
- `406 Not Acceptable` if format unsupported

---

## Request/Response Consistency

Request shape should match response shape. Response may have read-only fields (`id`, `createdAt`), but structure must be identical otherwise.

---

## Health Checks

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Liveness (process running) |
| `GET /health/ready` | Readiness (dependencies reachable) |

No auth required, fast response.

---

## Webhooks

- HMAC-SHA256 payload signing
- Include timestamp to prevent replay attacks
- Retry with exponential backoff
- Provide replay mechanism for failed deliveries
