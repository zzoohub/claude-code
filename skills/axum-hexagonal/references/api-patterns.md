# API Patterns

HTTP request/response examples for common and advanced patterns.

---

## CRUD

### Create (POST → 201)

```http
POST /v1/users
{ "name": "Ada Lovelace", "email": "ada@example.com" }

→ 201 Created, Location: /v1/users/usr_123
{ "data": { "id": "usr_123", "name": "Ada Lovelace", "email": "ada@example.com", "createdAt": "..." } }
```

### Create with Idempotency Key

```http
POST /v1/payments
Idempotency-Key: txn_8a3b2c1d
{ "amount": 5000, "currency": "USD" }
```

Retry with same key → returns original response without duplicate.

### Read Single (GET → 200)

```http
GET /v1/users/usr_123
→ 200 OK, ETag: "9f62089e"
{ "data": { "id": "usr_123", "name": "Ada Lovelace", ... } }
```

### Read Collection (GET → 200)

```http
GET /v1/users?role=admin&limit=20
→ 200 OK
{ "data": [...], "meta": { "limit": 20, "nextCursor": "eyJ...", "hasMore": true } }
```

### Update (PATCH → 200)

```http
PATCH /v1/users/usr_123
{ "name": "Ada Byron Lovelace" }
→ 200 OK
{ "data": { ..., "updatedAt": "..." } }
```

### Delete (DELETE → 204)

```http
DELETE /v1/users/usr_123
→ 204 No Content
```

---

## Error Responses (RFC 9457)

All use `Content-Type: application/problem+json`.

**422 Validation**:
```json
{ "type": ".../validation-failed", "title": "Validation Failed", "status": 422,
  "errors": [{ "field": "email", "code": "required", "message": "Email is required" }] }
```

**404 Not Found**: `{ "type": ".../not-found", "status": 404, "detail": "User 'usr_999' not found" }`

**409 Conflict**: `{ "type": ".../duplicate", "status": 409, "detail": "Email already exists" }`

**429 Rate Limited**: Headers `Retry-After: 30`, `X-RateLimit-Remaining: 0`

---

## Pagination

### Cursor (default)

```http
GET /v1/posts?limit=10&cursor=eyJpZCI6MTAwfQ==
→ { "data": [...], "meta": { "limit": 10, "nextCursor": "eyJ...", "hasMore": true } }
```

### Offset

```http
GET /v1/posts?page=3&limit=10
→ { "data": [...], "meta": { "page": 3, "limit": 10, "total": 156, "totalPages": 16 } }
```

---

## Conditional Request (ETag)

```http
GET /v1/users/usr_123
If-None-Match: "9f62089e"
→ 304 Not Modified
```

---

## File Upload

### Direct (small files)

```http
POST /v1/documents
Content-Type: multipart/form-data
file: <binary>, title: "Q4 Report"
→ 201 Created
{ "data": { "id": "doc_456", "url": "https://cdn.example.com/...", ... } }
```

### Presigned URL (large files)

```http
POST /v1/uploads
{ "filename": "video.mp4", "contentType": "video/mp4", "size": 52428800 }
→ 200 { "data": { "uploadId": "upl_789", "uploadUrl": "https://storage.../presigned?..." } }

# Client uploads directly to uploadUrl, then:
POST /v1/uploads/upl_789/complete
```

---

## State Transitions

Use `POST /resources/{id}/{action}`, not PATCH with magic values.

```http
POST /v1/orders/ord_123/cancel
{ "reason": "Customer changed mind" }
→ 200 { "data": { "status": "cancelled", "cancelledAt": "..." } }
```

Invalid transition → **409**:
```json
{ "type": ".../invalid-transition", "status": 409,
  "detail": "Cannot ship order in 'cancelled' state" }
```

---

## Search

**GET** for simple queries:
```http
GET /v1/products/search?q=keyboard&category=electronics&minPrice=50
```

**POST** for complex queries (not creating a resource):
```http
POST /v1/products/search
{ "query": "keyboard", "filters": { "category": ["electronics"], "price": { "min": 50 } },
  "sort": [{ "field": "relevance", "order": "desc" }], "limit": 20 }
→ { "data": [...], "meta": { "total": 42, "facets": { "category": [...] } } }
```

---

## Relationship Expansion

```http
GET /v1/posts/post_123?include=author,comments
→ { "data": { ..., "author": { "id": "usr_456", "name": "Ada" }, "comments": [...] } }
```

One level deep. Keep includable relations explicit.

---

## Async Operations

```http
POST /v1/reports/generate
{ "type": "monthly-sales", "month": "2024-10" }
→ 202 Accepted, Location: /v1/jobs/job_456
{ "data": { "jobId": "job_456", "status": "pending" } }

GET /v1/jobs/job_456
→ { "data": { "status": "completed", "result": { "downloadUrl": "..." } } }
```

---

## Bulk Operations

```http
POST /v1/users/batch
{ "items": [{ "name": "User 1", "email": "u1@example.com" }, ...] }
→ 200 { "data": { "results": [{ "status": 201, "data": {...} }, { "status": 409, "error": {...} }],
         "summary": { "total": 2, "succeeded": 1, "failed": 1 } } }
```

Use 200 (not 201/204) — each item may have a different outcome.

---

## Server-Sent Events (SSE)

```http
GET /v1/events/stream
Accept: text/event-stream

→ Content-Type: text/event-stream
event: order.updated
data: {"orderId": "ord_123", "status": "shipped"}
id: evt_001
```

---

## Webhooks

### Sending

```http
POST https://customer.example.com/webhooks
X-Webhook-Signature: sha256=a1b2c3...
X-Webhook-Timestamp: 1699900000
{ "event": "order.completed", "data": { "orderId": "ord_789" } }
```

### Verification

```
expected = HMAC-SHA256(secret, timestamp + "." + raw_body)
if expected != signature: reject
if now() - timestamp > 300: reject (replay)
```

### Registration

```http
POST /v1/webhooks
{ "url": "https://...", "events": ["order.completed", "user.created"] }
→ 201 { "data": { "id": "wh_123", "secret": "whsec_..." } }
```
