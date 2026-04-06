---
name: fastapi-hexagonal
description: |
  FastAPI with hexagonal architecture patterns in Python.
  Use when: building Python APIs — only when Python-only libraries are required (LangGraph, PyTorch, transformers, etc.).
  Covers: API design (Pydantic + auto OpenAPI), domain modeling, ports & adapters, service layer, error handling, async patterns, testing, Alembic migrations, pagination, healthcheck endpoints.
  Do not use for: database schema design (use database-design skill). Default to axum-hexagonal unless Python-only libraries are needed.
references:
  - references/examples-domain.md
  - references/examples-adapters.md
  - references/examples-bootstrap.md
  - references/api-design.md
  - references/api-patterns.md
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
│       ├── health.py            # /healthz, /readyz — no domain involvement
│       ├── response.py          # ApiSuccess, Created, Ok, PaginatedList
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
├── alembic/                     # DB migrations — infrastructure, not a hex layer
│   ├── env.py
│   └── versions/
tests/
├── conftest.py                  # Fixtures: test_config, db_engine, client
└── mocks.py                     # Stub, Saboteur, Spy, NoOp
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
- **Never raise `HTTPException` in domain** — that leaks transport concerns. Use domain error classes; map to HTTP responses in the inbound layer.

### Ports (Protocols)

Use `typing.Protocol` for structural subtyping — no inheritance required from implementors.

Three categories: **Repository** (data), **Metrics** (observability), **Notifier** (side effects).

### Service
- `Protocol` declaring business API + class `AuthorServiceImpl` implementing it.
- Orchestrates: repo → metrics → notifications → return result.
- Handlers call Service, never Repository directly.
- **Evolution path:** Direct calls (repo → metrics → notifier) keep the flow visible in one place — good for simple apps. As side effects grow, the service has to know about every consequence, raising coupling. When this becomes a pain, refactor to domain events: the service emits `AuthorCreatedEvent`, independent handlers react. Adding a new side effect no longer requires touching the service. Trade-off: flow is spread across files, harder to trace.

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
- **API docs** — use Pydantic models for request/response definition. FastAPI auto-generates OpenAPI docs at `/docs`. Consult `references/api-design.md` for conventions and `references/api-patterns.md` for HTTP patterns.
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

## Pagination

List endpoints need pagination. **Default to cursor-based pagination.** The pattern flows through all three layers:
- **Domain port**: `list_authors(cursor: str | None, limit: int) -> CursorPage[Author]`
- **Outbound adapter**: `WHERE (created_at, id) > (:cursor) ORDER BY created_at, id LIMIT :limit`
- **Inbound handler**: return `CursorPageResponse[T]` with `data`, `limit`, `next_cursor`, `has_more`

Cap `limit` at the handler level (e.g. `Query(20, ge=1, le=100)`). The domain doesn't care about max page size — that's a transport concern.

### Cursor vs Offset

**Cursor** (default) — `WHERE (created_at, id) > (:cursor) ORDER BY created_at, id LIMIT :limit`.
Consistent performance regardless of dataset size. Ideal for feeds, timelines, and large/mutable data. Always use a **composite cursor** `(sort_field, id)`. Cursor is an opaque base64-encoded string in the API; decode in the adapter only.

**Offset** — `OFFSET` / `LIMIT` + `COUNT(*)`.
Use for admin panels and small/static datasets. Provides `total` count for page number UIs. Downside: deeper pages get slower, and row mutations between requests cause duplicates or skips.

> Full pagination examples (port, adapter, handler): `references/examples-adapters.md`

---

## Healthcheck

Healthcheck endpoints are infrastructure — they bypass the domain entirely. Wire them directly in Shell.

- `/healthz` — always returns 200 (liveness, "is the process alive?")
- `/readyz` — checks DB connectivity (readiness, "can it serve traffic?")

> Healthcheck example: `references/examples-adapters.md`

---

## Migrations (Alembic)

Migrations are infrastructure. They sit alongside the app, not inside any hex layer. Alembic reads ORM metadata from `outbound/` models to generate migrations.

```
src/alembic/
├── env.py          # Reads Base.metadata from outbound/postgres/models.py
└── versions/       # Generated migration files
```

Use async engine in `env.py` since the app is async throughout.

> Full Alembic setup (env.py, commands): `references/examples-bootstrap.md`

---

## Logging

Use stdlib `logging` throughout. Each module gets its own logger via `logging.getLogger(__name__)`.

- **Domain**: log business events at INFO, wrap unexpected exceptions at ERROR
- **Inbound**: exception handlers log server errors before returning generic messages
- **Outbound**: log DB errors, slow queries

For structured logging (JSON output), add `structlog` and configure it once in `main.py`. The domain code stays the same — `structlog` wraps stdlib loggers.

---

## App Orchestrator

For apps with background workers, use `Application` class with `asyncio.TaskGroup`.
`TaskGroup` cancels sibling tasks on failure. HTTP-only apps can skip this.
Ensure `engine.dispose()` in a `finally` block for clean shutdown.

---

## Security

| Item | Value |
|------|-------|
| Password hashing | `pwdlib[argon2]` (default), `bcrypt` (fallback) |
| JWT library | `PyJWT` (not python-jose, which is unmaintained) |
| JWT access token | 15 min |
| JWT refresh (web) | 90 days |
| JWT refresh (mobile) | 1 year |
| Refresh token rotation | **Required** — issue new refresh token on each use, revoke old immediately |
| Refresh token storage | DB table with `jti`, `user_id`, `revoked_at`, `expires_at` |
| Timestamps | `datetime.now(UTC)` (not deprecated `utcnow()`) |
| CORS | Explicit origins only (no wildcard) |

Auth dependency (`get_current_user`) lives in inbound layer. Domain never handles raw tokens.

---

## Bootstrap (main.py)

Construct adapters → assemble service → start. **No FastAPI/SQLAlchemy imports.**

Package management: `uv`. Commit `uv.lock`. Use `uv run` to execute.

→ Full bootstrap, Application orchestrator, Alembic setup, and CI examples: `references/examples-bootstrap.md`

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
| `utcnow()` deprecation | Python 3.12+ | Use `datetime.now(UTC)` |
| jose/passlib issues | Unmaintained deps | Use `PyJWT` + `bcrypt` |
| No migrations | Missing Alembic | Set up `alembic/` alongside app |

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
| ORM type for UUID? | `sqlalchemy.Uuid` (native, not dialect-specific) |
| Test app? | `Shell.build_test_app()` + `httpx.AsyncClient` |
| Background workers? | `Application` + `asyncio.TaskGroup` |
| Migrations? | Alembic, lives alongside app (not in hex layers) |
| Healthcheck? | `/healthz` + `/readyz` in inbound, no domain |
| Pagination? | `CursorPageResponse[T]` wrapper, cursor in adapter |
| JWT / passwords? | `PyJWT` + `bcrypt` (not jose/passlib) |

---

## Checklist

### Architecture
- [ ] Domain never imports from inbound/ or outbound/
- [ ] Ports as `Protocol` classes, services orchestrate
- [ ] All handlers (HTTP, tasks, webhooks): parse → service → respond
- [ ] Transactions in adapters only, ORM ↔ domain mapper in outbound
- [ ] Errors: domain hierarchy → exception handlers → RFC 9457
- [ ] If phase-tagged schema exists, implement Phase 1 endpoints only

### Framework
- [ ] Shell wraps FastAPI, `build_test_app()` for tests
- [ ] DI via `lifespan` state + `request.state`
- [ ] `expire_on_commit=False`, `selectinload()`, `pool_timeout` set
- [ ] No blocking calls in async routes, CORS before routers
- [ ] `/healthz` and `/readyz` endpoints
- [ ] ORM uses `sqlalchemy.Uuid` (not dialect-specific `PG_UUID`)

### Dependencies
- [ ] `PyJWT` for JWT (not `python-jose`)
- [ ] `bcrypt` for passwords (not `passlib`)
- [ ] `datetime.now(UTC)` everywhere (not `utcnow()`)

### Database
- [ ] Alembic configured with async engine
- [ ] Migrations import ORM metadata from outbound models
- [ ] `from_engine()` on adapters for test injection

### Testing
**TDD**: Write all tests first as a spec, then implement, then verify all pass. (Tests → Impl → Green)
- [ ] `conftest.py` with fixtures: `test_config`, `db_engine`, `client`
- [ ] `asyncio_mode = "auto"` in pytest config
→ Test mocks (stub, saboteur, spy, noop) and test app helper: `references/examples-bootstrap.md`

### Setup
- [ ] `main.py` has no FastAPI/SQLAlchemy imports
- [ ] `uv.lock` committed
- [ ] `engine.dispose()` in shutdown path
