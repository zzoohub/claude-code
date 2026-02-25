# Core API Examples

CRUD operations, error responses, pagination, and filtering — the patterns every API uses.

---

## CRUD

### Create (POST)

```http
POST /v1/users HTTP/2
Content-Type: application/json

{
  "name": "Ada Lovelace",
  "email": "ada@example.com"
}
```

```http
HTTP/2 201 Created
Location: /v1/users/usr_123

{
  "data": {
    "id": "usr_123",
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "createdAt": "2024-10-24T12:00:00Z"
  }
}
```

### Create with Idempotency Key

For operations that must not duplicate on retry (payments, transfers):

```http
POST /v1/payments HTTP/2
Content-Type: application/json
Idempotency-Key: txn_8a3b2c1d

{
  "amount": 5000,
  "currency": "USD",
  "recipientId": "usr_456"
}
```

```http
HTTP/2 201 Created
Location: /v1/payments/pay_789

{
  "data": {
    "id": "pay_789",
    "amount": 5000,
    "currency": "USD",
    "status": "completed",
    "createdAt": "2024-10-24T12:00:00Z"
  }
}
```

Retry with the same `Idempotency-Key` returns the original response without creating a duplicate.

### Read Single (GET)

```http
GET /v1/users/usr_123 HTTP/2
```

```http
HTTP/2 200 OK
ETag: "9f62089e"

{
  "data": {
    "id": "usr_123",
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "createdAt": "2024-10-24T12:00:00Z"
  }
}
```

### Read Collection (GET)

```http
GET /v1/users?role=admin&limit=20 HTTP/2
```

```http
HTTP/2 200 OK

{
  "data": [
    { "id": "usr_123", "name": "Ada Lovelace", "email": "ada@example.com" },
    { "id": "usr_124", "name": "Grace Hopper", "email": "grace@example.com" }
  ],
  "meta": {
    "limit": 20,
    "nextCursor": "eyJpZCI6MTQ0fQ==",
    "hasMore": true
  }
}
```

### Update (PATCH)

```http
PATCH /v1/users/usr_123 HTTP/2
Content-Type: application/json

{
  "name": "Ada Byron Lovelace"
}
```

```http
HTTP/2 200 OK

{
  "data": {
    "id": "usr_123",
    "name": "Ada Byron Lovelace",
    "email": "ada@example.com",
    "createdAt": "2024-10-24T12:00:00Z",
    "updatedAt": "2024-10-25T09:30:00Z"
  }
}
```

### Delete (DELETE)

```http
DELETE /v1/users/usr_123 HTTP/2
```

```http
HTTP/2 204 No Content
```

---

## Error Responses (RFC 9457)

All errors use `Content-Type: application/problem+json`.

### Validation Error (422)

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 422,
  "detail": "One or more fields failed validation",
  "instance": "/v1/users",
  "errors": [
    { "field": "name", "code": "min_length", "message": "Name must be at least 1 character" },
    { "field": "email", "code": "required", "message": "Email is required" }
  ],
  "requestId": "req_abc123"
}
```

### Not Found (404)

```json
{
  "type": "https://api.example.com/errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User with id 'usr_999' does not exist",
  "instance": "/v1/users/usr_999",
  "requestId": "req_def456"
}
```

### Conflict (409)

```json
{
  "type": "https://api.example.com/errors/duplicate",
  "title": "Resource Already Exists",
  "status": 409,
  "detail": "A user with email 'ada@example.com' already exists",
  "instance": "/v1/users",
  "requestId": "req_ghi789"
}
```

### Unauthorized (401)

```json
{
  "type": "https://api.example.com/errors/unauthorized",
  "title": "Authentication Required",
  "status": 401,
  "detail": "Valid authentication token is required",
  "instance": "/v1/users/me",
  "requestId": "req_jkl012"
}
```

### Rate Limited (429)

Response headers: `Retry-After: 30`, `X-RateLimit-Limit: 100`, `X-RateLimit-Remaining: 0`

```json
{
  "type": "https://api.example.com/errors/rate-limited",
  "title": "Too Many Requests",
  "status": 429,
  "detail": "Rate limit exceeded. Try again in 30 seconds",
  "instance": "/v1/users",
  "requestId": "req_mno345"
}
```

---

## Pagination

### Cursor-based (default)

```http
GET /v1/posts?limit=10&cursor=eyJpZCI6MTAwfQ== HTTP/2
```

```json
{
  "data": [
    { "id": "post_101", "title": "Post 101" },
    { "id": "post_102", "title": "Post 102" }
  ],
  "meta": {
    "limit": 10,
    "nextCursor": "eyJpZCI6MTEwfQ==",
    "prevCursor": "eyJpZCI6MTAwfQ==",
    "hasMore": true
  }
}
```

### Offset-based

```http
GET /v1/posts?page=3&limit=10 HTTP/2
```

```json
{
  "data": ["..."],
  "meta": {
    "page": 3,
    "limit": 10,
    "total": 156,
    "totalPages": 16
  }
}
```

---

## Filtering & Sorting

```http
GET /v1/products?category=electronics&minPrice=100&maxPrice=500&inStock=true HTTP/2
GET /v1/products?sort=-createdAt,name HTTP/2
GET /v1/users/usr_123?fields=id,name,email HTTP/2
```

`-` prefix = descending, no prefix = ascending.

---

## Caching

### Conditional Request (ETag)

```http
GET /v1/users/usr_123 HTTP/2
If-None-Match: "9f62089e"
```

```http
HTTP/2 304 Not Modified
ETag: "9f62089e"
```

### Cache Headers

```http
HTTP/2 200 OK
Cache-Control: public, max-age=3600
ETag: "9f62089e"
Last-Modified: Wed, 24 Oct 2024 12:00:00 GMT
Vary: Accept, Authorization
```

---

## Authentication

### Bearer Token (JWT)

```http
GET /v1/users/me HTTP/2
Authorization: Bearer eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9...
```

### API Key

```http
GET /v1/data HTTP/2
Authorization: Bearer sk_live_abc123def456
```

Prefer `Authorization` header over custom headers like `X-API-Key` — it's standard HTTP and works well with proxies and logging.
