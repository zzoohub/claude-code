# Reliability Patterns

Patterns that keep state correct under failure, retry, and concurrency. Reference these whenever the system has writes that must not be lost, duplicated, or interleaved incorrectly.

This file covers four tightly-related concerns:

1. **Transaction boundaries** — where ACID starts and ends
2. **Idempotency** — surviving retries without duplication
3. **Outbox pattern** — atomic state change + message publish
4. **Concurrency control** — protecting against lost updates

These are not "advanced" — they are the floor for any system that takes money, sends notifications, or coordinates with external services.

---

## 1. Transaction Boundaries

**Rule**: One command = one transaction. The application service (use case) owns the transaction; the domain layer never sees it.

```
Inbound Adapter --> Application Service --> Domain --> Outbound Adapters
                    [ BEGIN TX                                          ]
                    [   load aggregate -> mutate -> persist -> emit msg ]
                    [ COMMIT TX                                         ]
```

### Where to put `begin/commit`

| Location | When |
|---|---|
| **Application service / use case** | Default. The service knows the unit of work. |
| **Inbound adapter (controller/handler)** | Only for trivial pass-through endpoints — discouraged because it leaks tx into transport layer. |
| **Outbound adapter (repository)** | Never. Repositories don't know what other writes need to be atomic with theirs. |
| **Domain entity** | Never. Domain must remain ignorant of persistence. |

### What belongs inside a single transaction

**Inside**: writes to the *same* logical aggregate, outbox row insertion, idempotency record insertion.

**Outside**: external HTTP/RPC calls, message broker publishes, email sends, anything that can't be rolled back. If you need these to feel atomic with the DB write, use the **Outbox pattern** (§3) instead of `try/commit/then publish`.

### The dual-write problem

The most common production bug:

```
BEGIN TX
  insert order
COMMIT
publish OrderCreated to Kafka   <-- crash here = silent data loss
```

If the process crashes between commit and publish, the order exists but no consumer ever knows. **Symmetric failure** (publish first, then commit) creates phantom events. Never write code that needs both. Use the outbox.

### Long-running transactions

Don't. Hold a DB transaction only while you have rows you need to mutate atomically. External calls, file uploads, and human approval steps must happen *outside* the transaction. If a workflow is inherently long-running, model it as a **saga** (see `system-architecture.md`) or a **durable execution** (see `operational-patterns.md`).

### Read-your-writes inside the same request

After `COMMIT`, a subsequent read on a replica may not see the write. If the same request needs to read what it just wrote, route the read to the primary, or pass the data through in-memory rather than re-querying.

---

## 2. Idempotency

A request is idempotent if repeating it produces the same observable result. **Without idempotency, retries are unsafe.** Every non-`GET` endpoint that a client may retry — directly or via a queue — needs an idempotency strategy.

### Three implementation strategies

| Strategy | How | Best For |
|---|---|---|
| **Natural idempotency** | Operation is `PUT`-shaped — same input always produces same state (e.g., "set user email to X") | Configuration writes, upserts |
| **Idempotency key** | Client sends `Idempotency-Key` header; server stores `(key -> response)` and replays on repeat | Payments, money movement, externally-triggered writes |
| **Dedup by event id** | Consumer tracks processed `event.id`s and skips duplicates | Async consumers, webhook handlers |

### Idempotency-Key contract (Stripe-style)

```
POST /payments
Idempotency-Key: 7f9c2-...-abc
Body: { amount: 1000, currency: "usd", customer: "cus_123" }
```

Server behavior:

| Case | Response |
|---|---|
| First time seeing key | Process normally, store `(key, request_hash, response)` with TTL |
| Same key, same `request_hash` | Return stored response (replay) |
| Same key, **different** `request_hash` | `409 Conflict` — client bug, refuse |
| Same key, request still in-flight | `409 Conflict` or block until original finishes |

### Storage decisions

| Decision | Recommended Default |
|---|---|
| **Scope** | `(tenant_id, user_id, key)` — keys are per-account, not global |
| **TTL** | 24h for sync APIs, 7d for async/webhook receivers |
| **What to hash** | Method + path + body (canonicalized JSON), excluding volatile headers |
| **Storage** | Same DB as the resource being written — must commit in the *same transaction* |
| **Index** | Unique constraint on `(scope, key)` — concurrent retry races collapse to one winner |

### Idempotency as a port

In hexagonal: model an `IdempotencyStore` port. The application service wraps the use case:

```
IdempotencyStore.acquire(key, request_hash) ->
  | NewExecution(token)        -> run use case, store result, release
  | Replay(stored_response)    -> return stored_response
  | Conflict                   -> return 409
```

This keeps idempotency out of every controller and out of the domain.

### What NOT to use as the key

- **Request body hash alone** — clients legitimately retry the same body and expect the second response (e.g., "create user with email X" twice = same user, but you must surface the *original* response, not 200 OK with a new user id).
- **Trace id / request id** — these change on each retry; defeats the purpose.
- **User id** — too coarse; user can only do one operation ever.

The key must be **client-chosen** (UUID v4 or v7), included in the request, and stable across retries of the *same intent*.

---

## 3. Transactional Outbox

The outbox pattern solves the dual-write problem (§1). Instead of "commit DB, then publish to broker," you commit DB **and** an outbox row in the same transaction. A relay process publishes outbox rows asynchronously.

```
+---- Application Service (one TX) ----+
|  INSERT INTO orders ...               |
|  INSERT INTO outbox (payload, ...)    |
|  COMMIT                               |
+---------------------------------------+
                |
        +---------------+
        | Outbox Relay  |  polls or tails the table
        +-------+-------+
                v
         Message Broker (Kafka / SQS / NATS)
```

### Outbox table shape

```
outbox (
  id            uuid primary key,
  aggregate_type text,          -- "order", "user"
  aggregate_id   text,          -- for partition keys / ordering
  event_type     text,          -- "OrderCreated"
  payload        jsonb,
  headers        jsonb,         -- trace context, tenant, etc.
  created_at     timestamptz default now(),
  published_at   timestamptz null,   -- or use a separate `outbox_dead` table
)
index on (published_at) where published_at is null
```

### Relay strategies

| Strategy | How | Trade-off |
|---|---|---|
| **Polling** | Worker queries `WHERE published_at IS NULL ORDER BY id LIMIT N` every N seconds | Simple, works on any DB. Adds query load and latency floor. |
| **Transactional log tailing (CDC)** | Debezium / pg `wal2json` reads WAL and emits events | Lower latency, no polling load. Operational complexity, requires CDC infra. |
| **Listen/notify** (Postgres) | `LISTEN outbox_new` + `NOTIFY` in trigger | Low latency on a single DB. Doesn't survive worker restart without a polling fallback. |

**Default**: Start with polling at 1-5s interval. Move to CDC only when latency requires it.

### Delivery semantics

The outbox guarantees **at-least-once**. The consumer must be idempotent (§2) — process by `event.id` with dedup. Exactly-once across systems is a fiction; design for at-least-once + idempotent consumers.

### Ordering

Per-aggregate ordering is preserved if you partition the broker by `aggregate_id`. Global ordering is not — and you almost never need it.

### Inbox pattern (the consumer side)

Mirror image: the consumer records `(message_id, processed_at)` in an inbox table inside the same transaction as its state change. Duplicates are dropped on insert by the unique constraint. Required when the consumer cannot be made naturally idempotent.

### Common mistakes

- **Outbox in a separate database** from the source of truth. Then you're back to dual-writes.
- **Deleting outbox rows immediately after publish.** Keep them for a retention window — useful for debugging and replay.
- **Publishing inside the transaction** ("just emit to Kafka before COMMIT"). Broker hiccup blocks your DB transaction; broker timeout poisons your write path.
- **No DLQ on relay failures.** A poison message will jam the relay forever. Move to a dead-letter table after N attempts.

### When NOT to use outbox

If the only "side effect" is an internal background job in the same database, use a **job table** (the simplest outbox). Don't bring in Kafka just to send an email — a `pending_emails` table polled by a worker is the same pattern at a tenth of the complexity.

---

## 4. Concurrency Control

Two clients read the same row, both compute new state, both write. Last write wins — and the first user's change is silently lost. This is the **lost update** problem. Every system with mutable shared state needs a strategy.

### Strategy selection

```
Are conflicts rare AND clients can retry?
  YES -> Optimistic concurrency (version column / ETag)
  NO  -> Pessimistic locking (SELECT FOR UPDATE) for short critical sections

Is the write a counter / aggregate?
  -> Atomic DB operation: UPDATE balance = balance + :amount WHERE id = :id

Is the entity collaboratively edited (multiple users typing)?
  -> CRDT or operational transform (out of scope for typical CRUD systems)
```

### Optimistic concurrency (default)

Each row carries a `version` (integer or timestamp). Writes are conditional:

```sql
UPDATE orders
SET status = 'paid', version = version + 1
WHERE id = :id AND version = :expected_version
```

If `rows_affected = 0`, somebody else wrote first. The application returns `409 Conflict` (or retries internally if the operation is associative).

**HTTP equivalent**: `ETag` + `If-Match` header. Client `GET`s and gets `ETag: "v7"`. Client `PUT`s with `If-Match: "v7"`. Server compares and rejects if version moved.

| Decision | Recommended |
|---|---|
| **Where the version lives** | Column on the aggregate root, never on child rows |
| **Type** | Monotonic integer. Don't use `updated_at` — clock skew, identical timestamps under load |
| **Initial value** | `1` on insert, increment on every write (even no-op writes that touch the row) |
| **Domain visibility** | Yes — the domain entity carries `version` so the application service can pass it back to the repo |

### Pessimistic locking

Use only for short critical sections, when conflicts are common and retries are expensive (e.g., inventory decrement under flash sale).

```sql
BEGIN;
SELECT * FROM inventory WHERE sku = :sku FOR UPDATE;
-- compute new value
UPDATE inventory SET qty = :new_qty WHERE sku = :sku;
COMMIT;
```

**Watch for**:
- **Deadlocks** — always lock rows in a consistent order across the codebase.
- **Lock duration** — never hold a row lock across a network call.
- **Connection pool starvation** — a long-held lock can block every other writer.

### Atomic operations

When the new value is a function of the old value (`balance += amount`, `views += 1`), don't read-modify-write. Push the math into the DB:

```sql
UPDATE accounts SET balance = balance + :amount WHERE id = :id AND balance + :amount >= 0
```

This is conflict-free by construction. Use it for counters, balances, and aggregates whenever possible.

### Idempotency vs concurrency

These solve different problems and you usually need both:

| Problem | Tool |
|---|---|
| Same client retries the same intent | Idempotency key |
| Different clients race on the same resource | Optimistic version / pessimistic lock |

A payment endpoint typically has both: idempotency key on the request, version on the wallet row.

---

## Self-Check

When designing any write path, answer:

- [ ] Where does the transaction begin and end? Is it in the application service?
- [ ] Are there external side effects (broker, HTTP, email)? If yes, is there an outbox?
- [ ] Can the client safely retry? If yes, is there an idempotency key or natural idempotency?
- [ ] Can two clients race on the same row? If yes, is there a version column or atomic update?
- [ ] On the consumer side: is the handler idempotent by `event.id`?

If any answer is "no" or "we'll handle it later," document it as a known risk in `docs/arch/decisions.md`.
