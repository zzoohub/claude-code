---
name: z-fastapi-hexagonal
description: |
  FastAPI with hexagonal architecture patterns in Python.
  Use when: building Python APIs that need testability, maintainability, and scalability.
  Covers: domain modeling, ports & adapters, service layer, error handling, async patterns, testing.
  Do not use for: API design decisions (use z-api-design skill), thin CRUD apps (use z-fastapi skill).
  Workflow: z-api-design (design) → this skill (implementation).
references:
  - references/examples-domain.md
  - references/examples-adapters.md
  - references/examples-bootstrap.md
---

# FastAPI + Hexagonal Architecture

**For latest FastAPI/Pydantic/SQLAlchemy APIs, use context7.**

## Core Philosophy

Separate **business domain** from **infrastructure**. Domain defines *what*; adapters decide *how*.

```
[Inbound Adapter: FastAPI router] → [Port: Service Protocol] → [Domain Logic]
    → [Port: Repository Protocol] → [Outbound Adapter: SQLAlchemy/Redis/etc.]
```

**Dependencies always point inward.** Domain code never imports FastAPI, SQLAlchemy, or any infrastructure package.

---

## Project Structure

```
src/
├── app/
│   ├── main.py                  # Bootstrap only — no FastAPI/SQLAlchemy imports
│   ├── application.py           # App orchestrator — runs Shell + workers via TaskGroup
│   └── config.py                # pydantic-settings
├── domain/
│   └── authors/
│       ├── models.py            # Author, AuthorName, CreateAuthorRequest
│       ├── errors.py            # DuplicateAuthorError, UnknownAuthorError
│       ├── ports.py             # AuthorRepository, AuthorService (Protocol)
│       └── service.py           # AuthorServiceImpl
├── inbound/
│   └── http/
│       ├── shell.py             # Shell class — wraps FastAPI, owns uvicorn
│       ├── errors.py            # exception handlers → RFC 9457
│       ├── dependencies.py      # with_author_service
│       ├── response.py          # ApiSuccess, Created, Ok, NoContent
│       └── authors/
│           ├── router.py        # Parse → call service → map response
│           ├── request.py       # CreateAuthorHttpRequestBody
│           └── response.py      # AuthorResponseData
├── outbound/
│   ├── postgres/
│   │   ├── repository.py       # impl AuthorRepository for Postgres
│   │   ├── models.py           # SQLAlchemy ORM models (outbound only)
│   │   └── mapper.py           # ORM ↔ domain translation
│   ├── sqlite/
│   │   └── repository.py       # impl AuthorRepository for SQLite
│   ├── prometheus.py            # impl AuthorMetrics
│   └── email_client.py          # impl AuthorNotifier
```

**Rule:** `domain/` never imports from `inbound/` or `outbound/`.

---

## Domain Layer

### Models
- Validate on construction (value object pattern). Use `@dataclass(frozen=True)`.
- **No ORM models in domain** — SQLAlchemy models live in `outbound/` only.
- Domain models may use Pydantic for validation, but MUST NOT use `from_attributes=True`.
- Separate `CreateAuthorRequest` from `Author` — they WILL diverge as app grows.

### Errors
- Exhaustive hierarchy: one class per business rule violation + generic `UnknownAuthorError`.
- **Never raise `HTTPException` in domain** — that leaks transport concerns.

### Ports (Protocols)

Use `typing.Protocol` for structural subtyping — no inheritance required from implementors.

Three categories: **Repository** (data), **Metrics** (observability), **Notifier** (side effects).

### Service
- `Protocol` declaring business API + class `AuthorServiceImpl` implementing it.
- Orchestrates: repo → metrics → notifications → return result.
- Handlers call Service, never Repository directly.

→ Full domain examples (models, errors, ports, service): `references/examples-domain.md`

---

## Inbound Layer

- **Shell class** — wraps FastAPI + uvicorn so `main.py` never imports them.
  Expose `build_test_app()` for tests — returns ASGI app without uvicorn.
- **Use `lifespan` context manager**, not deprecated `@app.on_event`.
- **DI via lifespan state** — `yield {"author_service": service}` → `request.state.author_service`.
  Uses ASGI spec `request.state` — framework-agnostic.
- **Handlers** do three things only: parse input → call service → map response. No SQL. No ORM.
- **Request types** decoupled from domain — `try_into_domain()` validates into domain type.
- **Response types** built via `from_domain()` classmethod — never expose domain models directly.
- **API errors** mapped via `@app.exception_handler`. Never leak domain strings to users.
  `UnknownAuthorError` → log server-side, return generic message. Use RFC 9457 ProblemDetails.
- **Middleware** — lives in inbound layer, invisible to domain.
  **CORS middleware before routers** (order matters).

### Non-HTTP Inbound Adapters

The inbound layer isn't limited to REST API routes. Any external trigger that drives the domain is an inbound adapter:

| Trigger | Examples | Still HTTP? |
|---------|----------|-------------|
| Task/Job queue | Cloud Tasks, SQS, Celery | Yes (HTTP callback) or No (consumer) |
| Webhook | Stripe, GitHub, external service callback | Yes |
| Cron/Scheduler | Cloud Scheduler, cron | Yes (HTTP) or No (direct invoke) |
| Event stream | Pub/Sub, Kafka, EventBridge | No (pull/push consumer) |

All follow the same pattern: **parse input → call service → respond.**

Key differences from REST routes:
- Verify caller identity (task queue headers, webhook signatures) instead of user auth.
- Return simple ack (200 OK) — no user-facing response body.
- Must be idempotent — task queues retry on failure.
- Register in Shell alongside REST routes.

```
src/inbound/
├── http/            # User-facing REST API
├── tasks/           # Task queue handlers
└── webhooks/        # External service callbacks
```

All three are wired into the same Shell. Domain doesn't know which triggered it.

→ Full inbound examples (Shell, handlers, request/response, auth, exception handlers): `references/examples-adapters.md`

---

## Outbound Layer

- Wrap engine/session factory in own class (`PostgresAuthorRepository`).
- Expose `from_engine()` constructor for tests.
- **Transactions encapsulated in adapter**, invisible to callers.
- Keep transactions short. **No external calls (HTTP, queues) inside tx.**
- Map DB-specific errors (e.g. `IntegrityError`) to domain error types.
- ORM models live in `outbound/`. Use explicit mapper (`AuthorMapper.to_domain()`) to translate.
  For raw SQL adapters, inline mapping is fine.

→ Full outbound examples (Postgres/SQLite adapters, ORM mapper): `references/examples-adapters.md`

### Async Safety (Critical)

```python
# ❌ Blocks entire event loop
async def bad():
    time.sleep(5)          # blocks!
    requests.get(...)      # sync HTTP!

# ✅ Proper async
async def good():
    await asyncio.sleep(5)
    async with httpx.AsyncClient() as client:
        await client.get(...)
```

**Rule: In async routes, ALL I/O must be async. For sync libs, use `def` (thread pool).**

### SQLAlchemy Async

| Setting | Value | Why |
|---------|-------|-----|
| `expire_on_commit` | `False` | Prevents detached instance errors |
| Relationship loading | `selectinload()` | Lazy loading fails in async |
| Session scope | Per-request in adapter | Adapter creates/closes session |

### Pool Config

```python
create_async_engine(url, pool_size=10, pool_timeout=3, pool_pre_ping=True)
```

---

## App Orchestrator

For apps with background workers, use `Application` class with `asyncio.TaskGroup`.
`TaskGroup` cancels sibling tasks on failure. HTTP-only apps can skip this.

---

## Security

| Item | Value |
|------|-------|
| Password hashing | bcrypt, 12 rounds |
| JWT access token | 15 min |
| JWT refresh (web) | 90 days |
| JWT refresh (mobile) | 1 year |
| CORS | Explicit origins only (no wildcard) |

Auth dependency (`get_current_user`) lives in inbound layer. Domain never handles raw tokens.

---

## Bootstrap (main.py)

Construct adapters → assemble service → start. **No FastAPI/SQLAlchemy imports.**

Package management: `uv`. Commit `uv.lock`. Use `uv run` to execute.

→ Full bootstrap, Application orchestrator, and CI examples: `references/examples-bootstrap.md`

---

## Domain Boundaries

1. **Domain = tangible arm of your business** (blogging, billing, identity)
2. **Entities that change atomically → same domain**
3. **Cross-domain operations are never atomic** — service calls or async events
4. **Start large, decompose when friction is observed**

> If you leak transactions into business logic for cross-domain atomicity, your boundaries are wrong.

---

## Common Gotchas

| Problem | Cause | Fix |
|---------|-------|-----|
| 422 Unprocessable | Schema mismatch | Test in `/docs` first |
| CORS not working | Middleware order | Add CORS before routers |
| All requests hang | Blocking in async | No `time.sleep()`, use `await` |
| "Field required" | Optional without default | `str \| None = None` |
| Detached instance | Session closed | `expire_on_commit=False` |
| Lazy load error | Async SQLAlchemy | Use `selectinload()` |
| Domain imports FastAPI | Leaky boundary | Move to inbound layer |
| HTTPException in domain | Transport leak | Use domain error classes |
| ORM model in handler | Missing mapper | Translate in adapter via mapper |

---

## Quick Reference

| Question | Answer |
|----------|--------|
| Transactions? | Adapter (repository impl) |
| Validation? | Domain model constructors / value objects |
| Error mapping? | `@app.exception_handler` in inbound |
| Business orchestration? | Service impl |
| Handler responsibility? | Parse → service → response |
| main responsibility? | Construct adapters → assemble → start |
| DI mechanism? | Lifespan state + `request.state` |
| ORM ↔ domain? | `AuthorMapper.to_domain()` in outbound |
| Test app? | `Shell.build_test_app()` + `httpx.AsyncClient` |
| Background workers? | `Application` + `asyncio.TaskGroup` |

---

## Checklist

### Architecture
- [ ] Domain never imports from inbound/ or outbound/
- [ ] Ports as `Protocol` classes, services orchestrate
- [ ] All handlers (HTTP, tasks, webhooks): parse → service → respond
- [ ] Transactions in adapters only, ORM ↔ domain mapper in outbound
- [ ] Errors: domain hierarchy → exception handlers → RFC 9457

### Framework
- [ ] Shell wraps FastAPI, `build_test_app()` for tests
- [ ] DI via `lifespan` state + `request.state`
- [ ] `expire_on_commit=False`, `selectinload()`, `pool_timeout` set
- [ ] No blocking calls in async routes, CORS before routers

### Testing
→ Test mocks (stub, saboteur, spy, noop) and test app helper: `references/examples-bootstrap.md`

### Setup
- [ ] `main.py` has no FastAPI/SQLAlchemy imports
- [ ] `uv.lock` committed
