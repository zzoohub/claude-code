# Advanced API Patterns

Patterns beyond basic CRUD. Read the relevant section when your API needs it.

## Table of Contents

- [File Upload](#file-upload)
- [State Transitions](#state-transitions)
- [Search](#search)
- [Relationship Expansion](#relationship-expansion)
- [Async Operations](#async-operations)
- [Bulk Operations](#bulk-operations)
- [Server-Sent Events (SSE)](#server-sent-events-sse)
- [Webhooks](#webhooks)

---

## File Upload

Use `multipart/form-data` for file uploads. Separate metadata from file content.

### Direct upload

```http
POST /v1/documents HTTP/2
Content-Type: multipart/form-data; boundary=----FormBoundary

------FormBoundary
Content-Disposition: form-data; name="file"; filename="report.pdf"
Content-Type: application/pdf

<binary data>
------FormBoundary
Content-Disposition: form-data; name="title"

Q4 Report
------FormBoundary--
```

```http
HTTP/2 201 Created
Location: /v1/documents/doc_456

{
  "data": {
    "id": "doc_456",
    "title": "Q4 Report",
    "filename": "report.pdf",
    "size": 204800,
    "mimeType": "application/pdf",
    "url": "https://cdn.example.com/docs/doc_456.pdf",
    "createdAt": "2024-10-24T12:00:00Z"
  }
}
```

### OpenAPI schema for file upload

```yaml
/v1/documents:
  post:
    operationId: createDocument
    tags: [documents]
    summary: Upload a document
    requestBody:
      required: true
      content:
        multipart/form-data:
          schema:
            type: object
            required: [file]
            properties:
              file:
                type: string
                format: binary
              title:
                type: string
    responses:
      '201':
        description: Document created
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Document'
```

### Presigned URL (large files)

For files over ~10MB, use a two-step flow so clients upload directly to storage:

```http
POST /v1/uploads HTTP/2
Content-Type: application/json

{ "filename": "video.mp4", "contentType": "video/mp4", "size": 52428800 }
```

```http
HTTP/2 200 OK

{
  "data": {
    "uploadId": "upl_789",
    "uploadUrl": "https://storage.example.com/presigned?token=...",
    "expiresAt": "2024-10-24T12:15:00Z"
  }
}
```

Client uploads directly to `uploadUrl`, then confirms:

```http
POST /v1/uploads/upl_789/complete HTTP/2
```

---

## State Transitions

Model explicit state changes as custom actions — not PATCH with magic field values. This makes the intent clear and allows validation of valid transitions.

### Pattern: `POST /resources/{id}/{action}`

```http
POST /v1/orders/ord_123/cancel HTTP/2
Content-Type: application/json

{ "reason": "Customer changed mind" }
```

```http
HTTP/2 200 OK

{
  "data": {
    "id": "ord_123",
    "status": "cancelled",
    "cancelledAt": "2024-10-24T12:00:00Z",
    "cancelReason": "Customer changed mind"
  }
}
```

### Invalid transition → 409

```http
POST /v1/orders/ord_123/ship HTTP/2
```

```http
HTTP/2 409 Conflict

{
  "type": "https://api.example.com/errors/invalid-transition",
  "title": "Invalid State Transition",
  "status": 409,
  "detail": "Cannot ship order in 'cancelled' state. Allowed transitions from 'cancelled': none"
}
```

### OpenAPI for state transitions

```yaml
/v1/orders/{orderId}/cancel:
  post:
    operationId: cancelOrder
    tags: [orders]
    summary: Cancel an order
    parameters:
      - name: orderId
        in: path
        required: true
        schema:
          type: string
    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              reason:
                type: string
    responses:
      '200':
        description: Order cancelled
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Order'
      '409':
        $ref: '#/components/responses/Conflict'
```

---

## Search

For queries beyond simple field filtering, use a dedicated search endpoint.

### GET for simple search

```http
GET /v1/products/search?q=mechanical+keyboard&category=electronics&minPrice=50 HTTP/2
```

### POST for complex search

When the query structure is too complex for URL parameters:

```http
POST /v1/products/search HTTP/2
Content-Type: application/json

{
  "query": "mechanical keyboard",
  "filters": {
    "category": ["electronics", "office"],
    "price": { "min": 50, "max": 300 },
    "inStock": true
  },
  "sort": [{ "field": "relevance", "order": "desc" }],
  "limit": 20
}
```

```http
HTTP/2 200 OK

{
  "data": [
    { "id": "prod_1", "name": "MX Keys", "relevanceScore": 0.95 }
  ],
  "meta": {
    "total": 42,
    "limit": 20,
    "nextCursor": "...",
    "facets": {
      "category": [{ "value": "electronics", "count": 30 }],
      "brand": [{ "value": "Logitech", "count": 15 }]
    }
  }
}
```

POST search is not creating a resource — it's querying. This is an acceptable use of POST when GET query strings become unwieldy.

---

## Relationship Expansion

Allow clients to include related resources in a single request to reduce round trips.

```http
GET /v1/posts/post_123?include=author,comments HTTP/2
```

```http
HTTP/2 200 OK

{
  "data": {
    "id": "post_123",
    "title": "API Design Guide",
    "authorId": "usr_456",
    "author": {
      "id": "usr_456",
      "name": "Ada Lovelace"
    },
    "comments": [
      { "id": "cmt_1", "body": "Great post!", "authorId": "usr_789" }
    ]
  }
}
```

### OpenAPI for include

```yaml
parameters:
  - name: include
    in: query
    required: false
    description: Comma-separated related resources to include (e.g., author,comments)
    schema:
      type: string
```

Keep the set of includable relations explicit and documented. Don't allow arbitrary depth — one level is usually enough.

---

## Async Operations

For long-running tasks, return 202 Accepted and provide a job resource to poll.

### Start

```http
POST /v1/reports/generate HTTP/2
Content-Type: application/json

{ "type": "monthly-sales", "month": "2024-10" }
```

```http
HTTP/2 202 Accepted
Location: /v1/jobs/job_456

{
  "data": {
    "jobId": "job_456",
    "status": "pending",
    "estimatedCompletion": "2024-10-24T12:05:00Z"
  }
}
```

### Poll

```http
GET /v1/jobs/job_456 HTTP/2
```

```http
HTTP/2 200 OK

{
  "data": {
    "jobId": "job_456",
    "status": "completed",
    "result": {
      "downloadUrl": "https://cdn.example.com/reports/monthly-2024-10.pdf"
    },
    "completedAt": "2024-10-24T12:03:22Z"
  }
}
```

---

## Bulk Operations

### Batch create

```http
POST /v1/users/batch HTTP/2
Content-Type: application/json

{
  "items": [
    { "name": "User 1", "email": "u1@example.com" },
    { "name": "User 2", "email": "u2@example.com" }
  ]
}
```

```http
HTTP/2 200 OK

{
  "data": {
    "results": [
      { "status": 201, "data": { "id": "usr_124", "name": "User 1" } },
      { "status": 409, "error": { "detail": "Email already exists" } }
    ],
    "summary": { "total": 2, "succeeded": 1, "failed": 1 }
  }
}
```

### Batch delete

```http
POST /v1/users/batch-delete HTTP/2
Content-Type: application/json

{ "ids": ["usr_124", "usr_125", "usr_999"] }
```

```http
HTTP/2 200 OK

{
  "data": {
    "results": [
      { "id": "usr_124", "status": 204 },
      { "id": "usr_125", "status": 204 },
      { "id": "usr_999", "status": 404 }
    ],
    "summary": { "total": 3, "succeeded": 2, "failed": 1 }
  }
}
```

Use 200 (not 201 or 204) for batch endpoints because each item may have a different outcome. The per-item `status` field communicates individual results.

---

## Server-Sent Events (SSE)

For real-time one-way streaming (notifications, live updates, progress).

```http
GET /v1/events/stream HTTP/2
Accept: text/event-stream
```

```http
HTTP/2 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache

event: order.updated
data: {"orderId": "ord_123", "status": "shipped"}
id: evt_001

event: notification
data: {"message": "New comment on your post"}
id: evt_002
```

### OpenAPI for SSE

```yaml
/v1/events/stream:
  get:
    operationId: streamEvents
    tags: [events]
    summary: Stream real-time events
    parameters:
      - name: lastEventId
        in: header
        required: false
        description: Resume from this event ID (for reconnection)
        schema:
          type: string
    responses:
      '200':
        description: Event stream
        content:
          text/event-stream:
            schema:
              type: string
              description: SSE event stream
```

---

## Webhooks

### Sending a webhook

```http
POST https://customer.example.com/webhooks HTTP/2
Content-Type: application/json
X-Webhook-Signature: sha256=a1b2c3d4e5f6...
X-Webhook-Timestamp: 1699900000
X-Webhook-Id: evt_abc123

{
  "event": "order.completed",
  "data": {
    "orderId": "ord_789",
    "total": 4999,
    "currency": "USD"
  },
  "occurredAt": "2024-10-24T12:00:00Z"
}
```

### Verification (receiver side)

```
expected = HMAC-SHA256(secret, timestamp + "." + raw_body)
if expected != signature_header: reject (401)
if now() - timestamp > 300: reject (replay attack)
```

### Webhook registration endpoint

```yaml
/v1/webhooks:
  post:
    operationId: createWebhook
    tags: [webhooks]
    summary: Register a webhook endpoint
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/CreateWebhook'
    responses:
      '201':
        description: Webhook registered
```

```yaml
CreateWebhook:
  type: object
  required: [url, events]
  properties:
    url:
      type: string
      format: uri
    events:
      type: array
      items:
        type: string
      description: "Events to subscribe to (e.g., order.completed, user.created)"
    secret:
      type: string
      description: "Shared secret for HMAC signature verification"
      readOnly: true
```
