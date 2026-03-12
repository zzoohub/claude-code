# API Design Decisions

Project conventions and decision frameworks for generating OpenAPI specs. Only what Claude wouldn't know or might get wrong without guidance.

---

## Resource Naming

```
POST /v1/users          # good
POST /v1/createUser     # bad — verb in path
```

| Pattern | Example |
|---------|---------|
| Collection | `/v1/users` |
| Single | `/v1/users/{userId}` |
| Nested | `/v1/users/{userId}/orders` |
| Filtered | `/v1/orders?userId=123` |
| Custom action | `POST /v1/orders/{orderId}/cancel` |

- Plural nouns, lowercase, kebab-case (`line-items`, not `lineItems`)
- Max 2 levels of nesting — flatten with query parameters beyond that
- Path = resource identity; query params = filtering / representation

---

## Response Format

### Success Envelope

Single resource:
```json
{
  "data": { "id": "usr_123", "name": "Ada" },
  "meta": { "requestId": "req_abc" }
}
```

Collection:
```json
{
  "data": [...],
  "meta": { "limit": 20, "nextCursor": "...", "hasMore": true }
}
```

### Errors (RFC 9457 Problem Details)

Content-Type: `application/problem+json`

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 422,
  "detail": "Email is required",
  "instance": "/v1/users",
  "errors": [{ "field": "email", "code": "required", "message": "Email is required" }],
  "requestId": "req_abc"
}
```

---

## Pagination

| Type | Best for | Params |
|------|----------|--------|
| Cursor (default) | Feeds, timelines, large/mutable data | `?cursor=X&limit=20` |
| Offset | Admin panels, small/static datasets | `?page=2&limit=20` |

Default to cursor-based. Offset degrades at scale and skips/duplicates rows when data mutates between pages.

---

## Filtering, Sorting, Field Selection

```
GET /v1/users?role=admin&status=active        # filter
GET /v1/users?sort=-createdAt,name            # sort (- = descending)
GET /v1/users?fields=id,name,email            # sparse fields
```

---

## Soft Delete

| Approach | When to use |
|----------|-------------|
| `DELETE` → 204, mark `deletedAt` internally | User data that may need recovery |
| `DELETE` → 204, permanent removal | Compliance, storage cleanup, no recovery needed |

For soft delete: filter out deleted records from GET by default. Allow `?includeDeleted=true` for admin endpoints.

---

## Security

| API Context | Auth Pattern |
|-------------|-------------|
| User-facing | JWT Bearer (ES256 / EdDSA) |
| Public API | API keys, OAuth 2.0 |
| Service-to-service | mTLS |
| Webhooks | HMAC-SHA256 signature |

Rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`

Use `Idempotency-Key` header for safe POST retries (payments, transfers).

---

## Caching

| Header | Purpose |
|--------|---------|
| `ETag` | Version fingerprint (`If-None-Match` → 304) |
| `Cache-Control` | `public`, `private`, `no-store` |
| `Last-Modified` | Timestamp (`If-Modified-Since`) |
| `Vary` | Which request headers affect the response |

---

## Versioning

- `/v1/` prefix in all paths
- Bump only for breaking changes (removing fields, changing types, renaming endpoints)
- Additive changes (new optional fields, new endpoints) don't require a bump
- Use `Sunset` header for deprecation with a timeline
