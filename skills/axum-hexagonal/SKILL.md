---
name: axum-hexagonal
description: |
  Axum 0.8+ with hexagonal architecture patterns in Rust.
  Use when: building any Rust API — this is the default backend implementation skill.
  Covers: API design (utoipa-axum + OpenApiRouter), domain modeling, ports & adapters, service layer, error handling, testing.
  Do not use for: database schema design (use database-design skill).
references:
  - references/examples-domain.md
  - references/examples-adapters.md
  - references/examples-bootstrap.md
  - references/api-design.md
  - references/api-patterns.md
---

# Axum + Hexagonal Architecture

**For latest Axum/SQLx APIs, use context7.**

## Core Philosophy

Separate **business domain** from **infrastructure**. Domain defines *what*; adapters decide *how*.

```
[Inbound Adapter: HTTP handler] → [Port: Service trait] → [Domain Logic]
    → [Port: Repository trait] → [Outbound Adapter: SQLx/Redis/etc.]
```

**Dependencies always point inward.** Domain code never imports axum, sqlx, or any infrastructure crate.

---

## Project Structure

```
src/
├── bin/server/main.rs           # Bootstrap only — no axum/sqlx imports
├── config.rs                    # Config struct, from_env()
├── domain/
│   └── authors/
│       ├── models.rs            # Author, AuthorName, CreateAuthorRequest
│       ├── error.rs             # CreateAuthorError
│       ├── ports.rs             # AuthorRepository, AuthorService traits
│       └── service.rs           # Service<R, M, N> impl
├── inbound/http/
│   ├── server.rs                # HttpServer wrapper around axum
│   ├── error.rs                 # ApiError → RFC 9457
│   ├── response.rs              # ApiSuccess, Created, Ok, NoContent
│   └── authors/
│       ├── handlers.rs          # Parse → call service → map response
│       ├── request.rs           # CreateAuthorHttpRequestBody
│       └── response.rs          # AuthorResponseData
└── outbound/
    ├── sqlite.rs                # impl AuthorRepository for Sqlite
    ├── postgres.rs              # impl AuthorRepository for Postgres
    ├── prometheus.rs            # impl AuthorMetrics
    └── email_client.rs          # impl AuthorNotifier
.sqlx/                 # Commit this (one file per query in SQLx 0.8+)
```

**Rule:** `domain/` never imports from `inbound/` or `outbound/`.

---

## Domain Layer

### Models
- Validate on construction (newtype pattern). Private fields, public getters.
- Implement `Display` for newtypes that need `.to_string()` — derive won't work on newtypes.
- No `serde::Deserialize` — Serde bypasses constructors, creating invalid objects.
  Exception: Serde is OK if the model performs no validation (any field value is valid).
- Separate `CreateAuthorRequest` from `Author` — they WILL diverge as app grows.

### Errors
- Exhaustive enum: one variant per business rule violation + `Unknown(anyhow::Error)`.
- Don't panic on unexpected errors — poisons mutexes, surprises other devs. Return errors.
- Domain errors = complete description of what can go wrong in an operation.
- **Domain ports return `Result<T, E>` exclusively — never panic on business errors.** Adapters map infrastructure errors (e.g. sqlx) into domain error types before returning.

### Ports (Traits)

All port traits require: `Clone + Send + Sync + 'static`

```rust
fn method(&self, ...) -> impl Future<Output = Result<T, E>> + Send;
```

> `async fn` in traits doesn't auto-add `Send`. Spell it out for web apps.

Three categories: **Repository** (data), **Metrics** (observability), **Notifier** (side effects).

### Service
- Trait declaring business API + struct `Service<R, M, N>` implementing it.
- Constructor takes all dependencies: `fn new(repo: R, metrics: M, notifier: N) -> Self`.
- Orchestrates: repo → metrics → notifications → return result.
- Handlers call Service, never Repository directly.
- **Evolution path:** Direct calls (repo → metrics → notifier) keep the flow visible in one place — good for simple apps. As side effects grow, the service has to know about every consequence, raising coupling. When this becomes a pain, refactor to domain events: the service emits `AuthorCreatedEvent`, independent handlers react. Adding a new side effect no longer requires touching the service. Trade-off: flow is spread across files, harder to trace.

→ Full domain examples (models, errors, ports, service): `references/examples-domain.md`

---

## Inbound Layer

- **HttpServer wrapper** — use `utoipa_axum::router::OpenApiRouter` instead of `axum::Router`.
  `main` never imports axum. Expose `build_router()` for tests.
  ```rust
  // Each domain module returns its own OpenApiRouter
  pub fn router() -> OpenApiRouter<AppState> {
      OpenApiRouter::new()
          .routes(routes!(list_authors, create_author))
          .routes(routes!(get_author, update_author, delete_author))
  }

  // Top-level composes modules and splits for axum
  let (router, api) = OpenApiRouter::with_openapi(ApiDoc::openapi())
      .nest("/api/v1/authors", authors::router())
      .nest("/api/v1/posts", posts::router())
      .split_for_parts();
  ```
- **Path params use `{id}` syntax** (not `:id`). Axum 0.8 changed this.
  Wildcards: `{*path}` (not `*path`). Literal braces: `{{` / `}}`.
- **DI via State** — services wrapped in `Arc` inside `AppState`.
  - **Single service:** generic `AppState<AS>`.
  - **Multiple services:** concrete `AppState` with `FromRef` for sub-extraction.
- **Handlers** annotated with `#[utoipa::path]` for OpenAPI generation. Do three things only: parse input → call service → map response. No SQL.
- **Request types** decoupled from domain — `try_into_domain()` validates into domain type. Derive `ToSchema` + `Deserialize`.
- **Response types** built via `From<&Author>` — never expose domain structs. Derive `ToSchema` + `Serialize`.
- **`ToSchema` / `IntoParams`** are inbound-layer concerns only. Domain models never derive utoipa traits.
- **API errors** mapped manually from domain errors. Never leak domain strings to users.
  `Unknown` → log server-side, return generic message. Use RFC 9457 ProblemDetails.
- **API docs** — `utoipa-axum` generates OpenAPI from code via `OpenApiRouter` + `routes!` + `split_for_parts()`. Serve with `utoipa-swagger-ui` or `utoipa-scalar`. Consult `references/api-design.md` for conventions and `references/api-patterns.md` for HTTP patterns.
- **Middleware (Tower layers)** — lives in inbound layer, invisible to domain.
  Layers wrap services: `TraceLayer → TimeoutLayer → CompressionLayer → CorsLayer`.
- **Health checks** live in the inbound layer (not domain). Readiness probes check DB pool.

### Non-HTTP Inbound Adapters

The inbound layer isn't limited to REST API routes. Any external trigger that drives the domain is an inbound adapter:

| Trigger | Examples | Still HTTP? |
|---------|----------|-------------|
| Task/Job queue | Cloud Tasks, SQS, RabbitMQ | Yes (HTTP callback) or No (consumer) |
| Webhook | Stripe, GitHub, external service callback | Yes |
| Cron/Scheduler | Cloud Scheduler, cron | Yes (HTTP) or No (direct invoke) |
| Event stream | NATS, Kafka, Redis Streams | No (pull/push consumer) |

All follow the same pattern: **parse input → call service → respond.**

Key differences from REST routes:
- Verify caller identity (task queue headers, webhook signatures) instead of user auth.
- Return simple ack (200 OK) — no user-facing response body.
- Must be idempotent — task queues retry on failure.
- Register in HttpServer alongside REST routes.

```
src/inbound/
├── http/            # User-facing REST API
├── tasks/           # Task queue handlers
└── webhooks/        # External service callbacks
```

All three are wired into the same HttpServer. Domain doesn't know which triggered it.

→ Full inbound examples (HttpServer, handlers, request/response, auth, task handlers, API errors): `references/examples-adapters.md`

---

## Outbound Layer

- Wrap connection pool in own type (`Sqlite`, `Postgres`).
- Expose `from_pool()` constructor for tests.
- **Transactions encapsulated in adapter**, invisible to callers.
- Keep transactions short. **No external calls (HTTP, queues) inside tx.**
- **SQLx 0.8+**: `Transaction` and `PoolConnection` no longer implement `Executor` directly.
  Use `&mut **tx` when executing queries inside a transaction.
- Map DB-specific errors (e.g. unique constraint codes) to domain error variants.
- Unknown DB errors wrapped with `anyhow` context.
- For complex row types or ORM (diesel, sea-orm), use explicit `to_domain()` mapper in outbound.
  For simple `sqlx::query!` rows, inline mapping in the adapter is fine.

→ Full outbound examples (SQLite, Postgres adapters, row mapper): `references/examples-adapters.md`

### Pagination

**Default to cursor-based pagination.** The pattern flows through all three layers:
- **Domain port**: `list_authors(&self, cursor: Option<&str>, limit: usize) -> Result<CursorPage<Author>, anyhow::Error>`
- **Outbound adapter**: `WHERE (created_at, id) > ($1, $2) ORDER BY created_at, id LIMIT $3`
- **Inbound handler**: return `CursorPageResponse<T>` with data, limit, next_cursor, has_more

Cap `limit` at the handler level (e.g. clamp to 1..100, default 20). The domain doesn't care about max page size — that's a transport concern.

#### Cursor vs Offset

**Cursor** (default) — `WHERE (created_at, id) > ($1, $2) ORDER BY created_at, id LIMIT $3`.
Consistent performance regardless of dataset size. Ideal for feeds, timelines, and large/mutable data. Always use a **composite cursor** `(sort_field, id)`. Cursor is an opaque base64-encoded string in the API; decode in the adapter only.

**Offset** — `LIMIT` / `OFFSET` + `COUNT(*)`.
Use for admin panels and small/static datasets. Provides `total` count for page number UIs. Downside: deeper pages get slower, and row mutations between requests cause duplicates or skips.

### Query Method

| Situation | Method |
|-----------|--------|
| Must exist | `fetch_one` |
| May not exist | `fetch_optional` → map to domain `Option` or error |
| List | `fetch_all` |

### Pool Config

```rust
PgPoolOptions::new()
    .max_connections(10)
    .acquire_timeout(Duration::from_secs(3))  // Always set this
```

---

## Security

| Item | Value |
|------|-------|
| Password hashing | `argon2` crate (RustCrypto) |
| JWT access token | 15 min |
| JWT refresh (web) | 90 days |
| JWT refresh (mobile) | 1 year |
| Refresh token rotation | **Required** — issue new refresh token on each use, revoke old immediately |
| Refresh token storage | DB table with `jti`, `user_id`, `revoked_at`, `expires_at` |
| CORS | Explicit origins only |

Auth middleware lives in the inbound layer. Domain never handles raw tokens.

---

## Bootstrap (main.rs)

Construct adapters → assemble service → start server. **No axum/sqlx imports.**
Include graceful shutdown with `SIGINT`/`SIGTERM` handling.

```rust
// Construct the pool once — used by both the repository AND the readiness probe.
let pool = SqlitePoolOptions::new().connect(&config.database_url).await?;
let sqlite = Sqlite::from_pool(pool.clone());
let service = AuthorServiceImpl::new(sqlite, metrics, notifier);
let server = HttpServer::new(service, pool, HttpServerConfig { port: &config.port }).await?;
server.run().await
```

→ Full bootstrap, config, graceful shutdown, and CI examples: `references/examples-bootstrap.md`

---

## Graceful Shutdown

- Use `axum::serve(...).with_graceful_shutdown(signal)`.
- **Always pair with `TimeoutLayer`** — without it, in-flight requests hang forever during drain.
- Handle both `SIGINT` (Ctrl+C) and `SIGTERM` (container orchestration).
- Shutdown logic lives in `HttpServer::run()` — invisible to domain.

→ Full shutdown signal example: `references/examples-bootstrap.md`

---

## Scaling to Multiple Domains

When `AppState` grows beyond one service, switch from generic `AppState<AS>` to a concrete struct with `FromRef`:

```rust
#[derive(Clone)]
struct AppState {
    author_service: Arc<dyn AuthorService>,
    billing_service: Arc<dyn BillingService>,
}

// Each handler extracts only what it needs via FromRef
impl FromRef<AppState> for Arc<dyn AuthorService> { ... }
```

**Rules:**
- All merged/nested routers must share the same `AppState` type.
- Handlers extract substates via `State<Arc<dyn AuthorService>>` — still depends on trait, not concrete.
- Switch from generics to trait objects (`Arc<dyn Trait>`) when you have 3+ services.

→ Full multi-domain example: `references/examples-adapters.md`

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
| `Future is not Send` | Async trait method missing `+ Send` | Use `impl Future<Output = ...> + Send` |
| `T is not Clone` | Port trait needs `Clone` bound | Wrap in `Arc` or derive `Clone` |
| `anyhow::Error` not `Clone` | Used in mock results | Wrap mock result in `Arc<Mutex<R>>` |
| Compile error on `sqlx::query!` | Missing `.sqlx/` offline data | Run `cargo sqlx prepare` |
| Handler can't extract `State` | Missing `.with_state(state)` | Add state to router |
| Middleware not running | Layer order wrong | `route_layer` for per-route, `layer` for global |
| Mutex poisoned | Panic while holding lock | Never panic — return errors |
| DB pool exhausted | No acquire timeout | Set `acquire_timeout(Duration::from_secs(3))` |
| `execute(tx)` won't compile | SQLx 0.8 removed `Executor` on `Transaction` | Use `execute(&mut **tx)` |
| Path `/:id` panics | Axum 0.8 changed syntax | Use `/{id}` (and `{*path}` for wildcards) |
| Handlers not `Sync` | Axum 0.8 requires `Sync` on all handlers | Ensure all captured state is `Sync` |
| `Option<T>` extracts always `None` | Axum 0.8 stricter `Option` extraction | Inner type must impl `OptionalFromRequestParts` |

---

## Quick Reference

| Question | Answer |
|----------|--------|
| Transactions? | Adapter (repository impl), use `&mut **tx` |
| Validation? | Domain model constructors |
| Error mapping? | `From<DomainError> for ApiError` in inbound |
| Business orchestration? | Service impl |
| Handler responsibility? | Parse → service → response |
| main responsibility? | Construct adapters → assemble → start |
| DI (single service)? | `State<AppState<AS>>` with `Arc` |
| DI (multi service)? | Concrete `AppState` with `FromRef` |
| DB row ↔ domain? | `to_domain()` mapper in outbound |
| Test app? | `HttpServer::build_router()` + `tower::oneshot` |
| Health checks? | Inbound layer, not domain |
| Graceful shutdown? | `with_graceful_shutdown()` + `TimeoutLayer` |
| OpenAPI generation? | `utoipa-axum`: `OpenApiRouter` + `routes!` + `split_for_parts()` |
| ToSchema/IntoParams? | Inbound request/response types only, never domain models |

---

## Checklist

### Architecture
- [ ] Domain never imports from inbound/ or outbound/
- [ ] Port traits: `Clone + Send + Sync + 'static`, futures `+ Send`
- [ ] All handlers (HTTP, tasks, webhooks): parse → service → respond
- [ ] Transactions in adapters only, `&mut **tx` for SQLx 0.8+
- [ ] Errors: domain enum → `From<DomainError> for ApiError` → RFC 9457

### Framework
- [ ] Axum wrapped in `HttpServer`, `build_router()` for tests
- [ ] Path params use `{id}` syntax (not `:id`)
- [ ] DI via `State<AppState<AS>>` with `Arc` (or `FromRef` for multi-service)
- [ ] Tower layers: trace, timeout, compression, CORS
- [ ] `acquire_timeout` set on pool
- [ ] Graceful shutdown with `SIGINT`/`SIGTERM` + `TimeoutLayer`
- [ ] Health check endpoint (readiness probe checks DB)

### Testing
**TDD**: Write all tests first as a spec, then implement, then verify all pass. (Tests → Impl → Green)
→ Test mocks (stub, saboteur, spy, noop) and test app helper: `references/examples-bootstrap.md`

### Setup
- [ ] `main.rs` has no axum/sqlx imports
- [ ] `.sqlx/` committed (one file per query in SQLx 0.8+)
- [ ] `Config` struct with `from_env()` in `config.rs`
