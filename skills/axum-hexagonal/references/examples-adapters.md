# Examples: Adapters

Inbound (HttpServer, handlers, task handlers, webhooks, auth, errors) and outbound (SQLite, Postgres, mapper).

---

## Outbound: SQLite Adapter

```rust
// src/outbound/sqlite.rs
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use chrono::{DateTime, Utc};

const UNIQUE_CONSTRAINT_VIOLATION: &str = "2067";

/// Composite cursor `(created_at, id)` encoded as opaque base64.
/// Stable under concurrent inserts — single-column `id > X` skips/duplicates rows.
fn encode_cursor(created_at: &DateTime<Utc>, id: &Uuid) -> String {
    URL_SAFE_NO_PAD.encode(format!("{}|{}", created_at.to_rfc3339(), id))
}

fn decode_cursor(raw: &str) -> anyhow::Result<(DateTime<Utc>, Uuid)> {
    let decoded = String::from_utf8(URL_SAFE_NO_PAD.decode(raw)?)?;
    let (ts, id) = decoded.split_once('|').context("invalid cursor")?;
    Ok((DateTime::parse_from_rfc3339(ts)?.with_timezone(&Utc), Uuid::parse_str(id)?))
}

#[derive(Debug, Clone)]
pub struct Sqlite { pool: sqlx::SqlitePool }

impl Sqlite {
    pub async fn new(path: &str) -> anyhow::Result<Self> {
        let pool = sqlx::SqlitePool::connect_with(
            SqliteConnectOptions::from_str(path)?
                .pragma("foreign_keys", "ON"),
        ).await.with_context(|| format!("failed to open db at {}", path))?;
        Ok(Self { pool })
    }
    pub fn from_pool(pool: sqlx::SqlitePool) -> Self { Self { pool } }
}

impl AuthorRepository for Sqlite {
    async fn create_author(&self, req: &CreateAuthorRequest) -> Result<Author, CreateAuthorError> {
        // SQLx 0.8+: Transaction no longer implements Executor.
        // Use &mut **tx when executing queries inside a transaction.
        let mut tx = self.pool.begin().await.context("failed to start tx")?;
        let id = Uuid::new_v4();
        sqlx::query!("INSERT INTO authors (id, name) VALUES ($1, $2)",
            id.to_string(), req.name().to_string())
            .execute(&mut **tx).await  // Note: &mut **tx, not &mut *tx
            .map_err(|e| {
                if let sqlx::Error::Database(ref db_err) = e {
                    if db_err.code().map_or(false, |c| c == UNIQUE_CONSTRAINT_VIOLATION) {
                        return CreateAuthorError::Duplicate { name: req.name().clone() };
                    }
                }
                anyhow!(e).context(format!("failed to save author {:?}", req.name())).into()
            })?;
        tx.commit().await.context("failed to commit tx")?;
        Ok(Author::new(id, req.name().clone()))
    }

    async fn find_author(&self, id: &Uuid) -> Result<Option<Author>, anyhow::Error> {
        let id_str = id.to_string();
        let row = sqlx::query!("SELECT id, name FROM authors WHERE id = $1", id_str)
            .fetch_optional(&self.pool).await.context("failed to query author")?;
        match row {
            Some(r) => Ok(Some(Author::new(
                Uuid::parse_str(&r.id)?,
                AuthorName::new(&r.name).map_err(|e| anyhow!(e))?,
            ))),
            None => Ok(None),
        }
    }

    async fn list_authors(&self, cursor: Option<&str>, limit: usize) -> Result<CursorPage<Author>, anyhow::Error> {
        // Fetch limit+1 to detect whether more rows exist beyond the page boundary.
        let fetch_limit = (limit + 1) as i64;

        let rows = if let Some(raw) = cursor {
            let (cursor_at, cursor_id) = decode_cursor(raw)?;
            let cursor_id_str = cursor_id.to_string();
            sqlx::query!(
                "SELECT id, name, created_at FROM authors \
                 WHERE (created_at, id) > ($1, $2) \
                 ORDER BY created_at ASC, id ASC LIMIT $3",
                cursor_at, cursor_id_str, fetch_limit,
            )
            .fetch_all(&self.pool).await.context("failed to list authors")?
        } else {
            sqlx::query!(
                "SELECT id, name, created_at FROM authors \
                 ORDER BY created_at ASC, id ASC LIMIT $1",
                fetch_limit,
            )
            .fetch_all(&self.pool).await.context("failed to list authors")?
        };

        // Boundary: if we got the extra row, there are more pages.
        // Drop the overflow row; cursor points at the LAST RETURNED row so
        // the next page starts AFTER it (no duplicate, no skip).
        let has_more = rows.len() > limit;
        let truncated: Vec<_> = rows.into_iter().take(limit).collect();

        let next_cursor = if has_more {
            truncated.last().and_then(|r| {
                let id = Uuid::parse_str(&r.id).ok()?;
                Some(encode_cursor(&r.created_at, &id))
            })
        } else {
            None
        };

        let items: Vec<Author> = truncated
            .into_iter()
            .map(|r| Ok(Author::new(
                Uuid::parse_str(&r.id)?,
                AuthorName::new(&r.name).map_err(|e| anyhow!(e))?,
            )))
            .collect::<Result<Vec<_>, anyhow::Error>>()?;

        Ok(CursorPage { items, next_cursor, has_more })
    }
}
```

## Outbound: Postgres Adapter (same trait, swap in main)

```rust
// src/outbound/postgres.rs
#[derive(Debug, Clone)]
pub struct Postgres { pool: sqlx::PgPool }

impl Postgres {
    pub async fn new(url: &str) -> anyhow::Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(10)
            .acquire_timeout(Duration::from_secs(3))
            .connect(url).await
            .with_context(|| format!("failed to connect to {}", url))?;
        Ok(Self { pool })
    }
    pub fn from_pool(pool: sqlx::PgPool) -> Self { Self { pool } }
}

impl AuthorRepository for Postgres {
    async fn create_author(&self, req: &CreateAuthorRequest) -> Result<Author, CreateAuthorError> {
        let id = Uuid::new_v4();
        sqlx::query!("INSERT INTO authors (id, name) VALUES ($1, $2)",
            id, req.name().to_string())
            .execute(&self.pool).await
            .map_err(|e| {
                if e.as_database_error().map_or(false, |d| d.is_unique_violation()) {
                    CreateAuthorError::Duplicate { name: req.name().clone() }
                } else {
                    anyhow!(e).into()
                }
            })?;
        Ok(Author::new(id, req.name().clone()))
    }
    // find_author, list_authors omitted — same pattern as SQLite
}
```

## Outbound: Row ↔ Domain Mapper (for complex rows or ORM)

```rust
// src/outbound/mapper.rs — use when rows have many fields or when using diesel/sea-orm
#[derive(Debug, sqlx::FromRow)]
pub struct AuthorRow { pub id: String, pub name: String }

impl AuthorRow {
    pub fn to_domain(self) -> Result<Author, anyhow::Error> {
        Ok(Author::new(
            Uuid::parse_str(&self.id)?,
            AuthorName::new(&self.name).map_err(|e| anyhow!(e))?,
        ))
    }
}

// Usage in adapter:
let row: Option<AuthorRow> = sqlx::query_as!(AuthorRow,
    "SELECT id, name FROM authors WHERE id = $1", id_str)
    .fetch_optional(&self.pool).await?;
row.map(|r| r.to_domain()).transpose()
```

---

## Inbound: Task Handler (non-HTTP inbound adapter)

```rust
// src/inbound/tasks/handler.rs
/// Task queue handler — inbound adapter.
/// Same pattern as HTTP: typed payload → try_into_domain() → service → ack.

#[derive(Debug, Deserialize)]
pub struct SyncAuthorTaskPayload {
    pub author_name: String,
    pub source: String,
}

impl SyncAuthorTaskPayload {
    pub fn try_into_domain(self) -> Result<CreateAuthorRequest, AuthorNameEmptyError> {
        Ok(CreateAuthorRequest::new(AuthorName::new(&self.author_name)?))
    }
}

pub async fn handle_sync_author(
    State(state): State<AppState>,
    Json(payload): Json<SyncAuthorTaskPayload>,
) -> Result<Json<serde_json::Value>, ApiError> {
    let domain_req = payload.try_into_domain()?;
    state.author_service.create_author(&domain_req).await
        .map_err(ApiError::from)?;
    Ok(Json(serde_json::json!({"status": "ok"})))
}

// In HttpServer::build_router() — wire alongside REST routes via routes!():
// .routes(routes!(handlers::create_author))         // user-facing
// .routes(routes!(tasks::handle_sync_author))       // task queue
```

---

## Composition Root

```rust
// src/composition.rs
// The single place that names the concrete adapter combination. Domain ports
// stay generic (RPITIT, zero-cost static dispatch); only this alias spells
// out which adapters the production binary uses. When native dyn-async lands
// in stable Rust, swap to `dyn AuthorService` here without touching anything else.
pub type AppAuthorService = AuthorServiceImpl<Sqlite, Prometheus, EmailClient>;
```

## Inbound: HttpServer Wrapper

```rust
// src/inbound/http/server.rs
use utoipa::OpenApi;
use utoipa_axum::router::OpenApiRouter;
use utoipa_axum::routes;
use crate::composition::AppAuthorService;

#[derive(OpenApi)]
#[openapi(info(title = "MyApp API", version = "1.0.0"))]
pub struct ApiDoc;

pub struct HttpServer { router: Router, listener: TcpListener }

/// `routes!()` collects concrete handler items, so `AppState` must be a single
/// concrete type. We use `Arc<AppAuthorService>` (the composition-root alias)
/// rather than `Arc<dyn AuthorService>` because:
/// 1. The domain port uses RPITIT (`fn -> impl Future + Send`) which is not
///    dyn-compatible in stable Rust today.
/// 2. A binary has one production composition — type erasure earns nothing.
/// 3. Static dispatch: no vptr, no boxed futures.
#[derive(Clone)]
pub struct AppState {
    pub author_service: Arc<AppAuthorService>,
    /// Held by the readiness probe to ping the DB. For Postgres, change to `sqlx::PgPool`.
    pub db_pool: sqlx::SqlitePool,
}

#[derive(Debug, Clone)]
pub struct HttpServerConfig<'a> {
    pub port: &'a str,
    pub cors_origin: &'a str,
}

impl HttpServer {
    pub async fn new(
        author_service: Arc<AppAuthorService>,
        db_pool: sqlx::SqlitePool,
        config: HttpServerConfig<'_>,
    ) -> anyhow::Result<Self> {
        let router = Self::build_router(author_service, db_pool, &config)?;
        let listener = TcpListener::bind(format!("0.0.0.0:{}", config.port)).await?;
        Ok(Self { router, listener })
    }

    /// For tests: returns Router without binding a port.
    /// `OpenApiRouter` collects route metadata; `split_for_parts()` yields the
    /// runtime `Router` plus an `OpenApi` document for swagger/scalar serving.
    pub fn build_router(
        author_service: Arc<AppAuthorService>,
        db_pool: sqlx::SqlitePool,
        config: &HttpServerConfig<'_>,
    ) -> anyhow::Result<Router> {
        let state = AppState { author_service, db_pool };
        let origin = config.cors_origin.parse::<HeaderValue>()?;

        // Axum 0.8+: path params use {id} (not :id), wildcards {*path}.
        let (router, _api) = OpenApiRouter::with_openapi(ApiDoc::openapi())
            .routes(routes!(handlers::create_author, handlers::list_authors))
            .routes(routes!(handlers::get_author))
            .route("/health", get(|| async { StatusCode::OK }))
            .route("/ready", get(Self::readiness_check))
            .layer(
                ServiceBuilder::new()
                    .layer(TraceLayer::new_for_http())
                    .layer(TimeoutLayer::new(Duration::from_secs(10)))
                    .layer(CompressionLayer::new())
                    .layer(CorsLayer::new().allow_origin([origin])),
            )
            .with_state(state)
            .split_for_parts();

        // To serve OpenAPI docs, merge a swagger/scalar router with `_api`:
        //   .merge(utoipa_swagger_ui::SwaggerUi::new("/swagger").url("/api-docs/openapi.json", _api))
        // or use `utoipa-scalar` for a lighter UI.
        Ok(router)
    }

    pub async fn run(self) -> anyhow::Result<()> {
        axum::serve(self.listener, self.router)
            .with_graceful_shutdown(Self::shutdown_signal())
            .await?;
        Ok(())
    }

    async fn shutdown_signal() {
        let ctrl_c = async {
            tokio::signal::ctrl_c().await.expect("failed to install Ctrl+C handler");
        };
        #[cfg(unix)]
        let terminate = async {
            tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
                .expect("failed to install SIGTERM handler")
                .recv().await;
        };
        #[cfg(not(unix))]
        let terminate = std::future::pending::<()>();
        tokio::select! { _ = ctrl_c => {}, _ = terminate => {} }
    }
}

// Health check — readiness probe (lives in inbound, not domain)
impl HttpServer {
    async fn readiness_check(State(state): State<AppState>) -> StatusCode {
        match sqlx::query("SELECT 1").execute(&state.db_pool).await {
            Ok(_) => StatusCode::OK,
            Err(e) => {
                tracing::warn!("readiness check failed: {}", e);
                StatusCode::SERVICE_UNAVAILABLE
            }
        }
    }
}
```

## Inbound: Multi-Service AppState with FromRef

For 3+ services, split the state via `FromRef` so each handler depends on only what it needs. Each service gets its own composition-root type alias — same principle as the single-service case:

```rust
// src/composition.rs — one alias per bounded context
pub type AppAuthorService  = AuthorServiceImpl<Sqlite, Prometheus, EmailClient>;
pub type AppBillingService = BillingServiceImpl<Postgres, Prometheus, StripeClient>;
```

```rust
// src/inbound/http/server.rs — multi-domain variant
use axum::extract::FromRef;
use crate::composition::{AppAuthorService, AppBillingService};

#[derive(Clone)]
struct AppState {
    author_service: Arc<AppAuthorService>,
    billing_service: Arc<AppBillingService>,
}

// Each handler extracts only the service it needs
impl FromRef<AppState> for Arc<AppAuthorService> {
    fn from_ref(state: &AppState) -> Self { state.author_service.clone() }
}
impl FromRef<AppState> for Arc<AppBillingService> {
    fn from_ref(state: &AppState) -> Self { state.billing_service.clone() }
}

// Handlers depend on the concrete service alias — still hides adapter combination
// behind a single name in `composition.rs`.
async fn create_author(
    State(service): State<Arc<AppAuthorService>>,
    Json(body): Json<CreateAuthorHttpRequestBody>,
) -> Result<ApiSuccess<AuthorResponseData>, ApiError> {
    let domain_req = body.try_into_domain()?;
    service.create_author(&domain_req).await
        .map_err(ApiError::from)
        .map(|ref author| ApiSuccess::new(StatusCode::CREATED, author.into()))
}

// All routers share the same AppState
fn build_router(state: AppState) -> Router {
    // Each domain module owns its `OpenApiRouter`; the top level merges them
    // and calls `split_for_parts()` to recover the runtime `Router`.
    let (router, _api) = OpenApiRouter::with_openapi(ApiDoc::openapi())
        .nest("/api/v1/authors", authors::router())
        .nest("/api/v1/billing", billing::router())
        .with_state(state)
        .split_for_parts();
    router
}

// Inside each domain module:
mod authors {
    use super::*;
    pub fn router() -> OpenApiRouter<AppState> {
        OpenApiRouter::new()
            .routes(routes!(create_author, get_author))
    }
}
```

> **When to switch:** the single-service `AppState` (above) is simpler for 1-2 services. Add `FromRef` impls when you have 3+ services so each handler extracts only the alias it needs. Type erasure (`Arc<dyn ...>`) is only worth it once native dyn-async stabilizes or you genuinely need runtime swapping.

## Inbound: Auth Middleware

```rust
// src/inbound/http/middleware.rs
// Auth middleware: takes the same AppState as handlers. If auth needs its
// own service (e.g. a session repository), add a field to AppState — keep
// this layer agnostic of token verification details.
pub async fn require_auth(
    State(_state): State<AppState>,
    mut req: Request,
    next: Next,
) -> Result<Response, ApiError> {
    let token = req.headers()
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .and_then(|h| h.strip_prefix("Bearer "))
        .ok_or(ApiError::Unauthorized)?;
    let user = verify_token(token).await?.ok_or(ApiError::Unauthorized)?;
    req.extensions_mut().insert(user);
    Ok(next.run(req).await)
}

// Apply per-route — Axum 0.8+: {id} syntax
OpenApiRouter::new()
    .routes(routes!(create_author))
    .route_layer(middleware::from_fn_with_state(state.clone(), require_auth))
```

## Inbound: Request / Response

```rust
// src/inbound/http/authors/request.rs
use utoipa::{IntoParams, ToSchema};

#[derive(Debug, Deserialize, ToSchema)]
pub struct CreateAuthorHttpRequestBody { pub name: String }

impl CreateAuthorHttpRequestBody {
    pub fn try_into_domain(self) -> Result<CreateAuthorRequest, AuthorNameEmptyError> {
        Ok(CreateAuthorRequest::new(AuthorName::new(&self.name)?))
    }
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct ListParams {
    pub cursor: Option<String>,
    #[serde(default = "default_limit")]
    pub limit: usize,
}
fn default_limit() -> usize { 20 }

impl ListParams {
    pub fn validated(self) -> (Option<String>, usize) {
        (self.cursor, self.limit.clamp(1, 100))
    }
}

// src/inbound/http/authors/response.rs
#[derive(Debug, Serialize, ToSchema)]
pub struct AuthorResponseData { pub id: String, pub name: String }

impl From<&Author> for AuthorResponseData {
    fn from(a: &Author) -> Self {
        Self { id: a.id().to_string(), name: a.name().to_string() }
    }
}

#[derive(Debug, Serialize, ToSchema)]
#[aliases(AuthorListResponse = CursorPageResponse<AuthorResponseData>)]
pub struct CursorPageResponse<T: Serialize + ToSchema> {
    pub data: Vec<T>,
    pub next_cursor: Option<String>,
    pub has_more: bool,
}
```

## Inbound: Handlers

```rust
// src/inbound/http/authors/handlers.rs
// `#[utoipa::path]` annotations let `routes!()` collect each handler into the
// generated OpenAPI document. Path values must match the route registered in
// the router (Axum 0.8 `{id}` syntax).

#[utoipa::path(
    post,
    path = "/authors",
    request_body = CreateAuthorHttpRequestBody,
    responses(
        (status = 201, description = "Author created", body = AuthorResponseData),
        (status = 409, description = "Duplicate", body = ProblemDetails),
        (status = 422, description = "Validation failed", body = ProblemDetails),
    ),
    tag = "authors",
)]
pub async fn create_author(
    State(state): State<AppState>,
    Json(body): Json<CreateAuthorHttpRequestBody>,
) -> Result<ApiSuccess<AuthorResponseData>, ApiError> {
    let domain_req = body.try_into_domain()?;
    let author = state.author_service.create_author(&domain_req).await
        .map_err(ApiError::from)?;
    Ok(ApiSuccess::new(StatusCode::CREATED, (&author).into()))
}

#[utoipa::path(
    get,
    path = "/authors/{id}",
    params(("id" = Uuid, Path, description = "Author ID")),
    responses(
        (status = 200, description = "Author", body = AuthorResponseData),
        (status = 404, description = "Not found", body = ProblemDetails),
    ),
    tag = "authors",
)]
pub async fn get_author(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<ApiSuccess<AuthorResponseData>, ApiError> {
    let maybe = state.author_service.find_author(&id).await
        .map_err(ApiError::from)?;
    let author = maybe.ok_or(ApiError::NotFound)?;
    Ok(ApiSuccess::new(StatusCode::OK, (&author).into()))
}

#[utoipa::path(
    get,
    path = "/authors",
    params(ListParams),
    responses(
        (status = 200, description = "Author page", body = AuthorListResponse),
    ),
    tag = "authors",
)]
pub async fn list_authors(
    State(state): State<AppState>,
    Query(params): Query<ListParams>,
) -> Result<ApiSuccess<CursorPageResponse<AuthorResponseData>>, ApiError> {
    let (cursor, limit) = params.validated();
    let page = state.author_service.list_authors(cursor.as_deref(), limit).await
        .map_err(ApiError::from)?;
    Ok(ApiSuccess::new(StatusCode::OK, CursorPageResponse {
        data: page.items.iter().map(AuthorResponseData::from).collect(),
        next_cursor: page.next_cursor,
        has_more: page.has_more,
    }))
}
```

## Inbound: API Error (RFC 9457)

```rust
// src/inbound/http/error.rs
#[derive(Debug)]
pub enum ApiError {
    InternalServerError(String),
    UnprocessableEntity(String),
    Conflict(String),
    NotFound,
    Unauthorized,
}

impl fmt::Display for ApiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InternalServerError(msg) => write!(f, "{}", msg),
            Self::UnprocessableEntity(msg) => write!(f, "{}", msg),
            Self::Conflict(msg) => write!(f, "{}", msg),
            Self::NotFound => write!(f, "Not Found"),
            Self::Unauthorized => write!(f, "Unauthorized"),
        }
    }
}

impl From<CreateAuthorError> for ApiError {
    fn from(e: CreateAuthorError) -> Self {
        match e {
            CreateAuthorError::Duplicate { name } =>
                Self::Conflict(format!("author with name {} already exists", name)),
            CreateAuthorError::Unknown(cause) => {
                tracing::error!("{:?}\n{}", cause, cause.backtrace());
                Self::InternalServerError("An unexpected error occurred".into())
            }
        }
    }
}

impl From<AuthorNameEmptyError> for ApiError {
    fn from(_: AuthorNameEmptyError) -> Self {
        Self::UnprocessableEntity("author name cannot be empty".into())
    }
}

// Generic anyhow → ISE (for list operations that return anyhow::Error)
impl From<anyhow::Error> for ApiError {
    fn from(e: anyhow::Error) -> Self {
        tracing::error!("{:?}", e);
        Self::InternalServerError("An unexpected error occurred".into())
    }
}

#[derive(Serialize, ToSchema)]
pub struct ProblemDetails {
    /// URL identifying the problem type
    #[serde(rename = "type")]
    pub problem_type: String,
    pub title: String,
    pub status: u16,
    pub detail: String,
    /// Path of the request that failed
    #[serde(skip_serializing_if = "Option::is_none")]
    pub instance: Option<String>,
    /// Field-level validation errors (RFC 9457 extension)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub errors: Option<Vec<FieldError>>,
    /// Correlation id pulled from request extensions / tracing
    #[serde(skip_serializing_if = "Option::is_none")]
    pub request_id: Option<String>,
}

#[derive(Serialize, ToSchema)]
pub struct FieldError {
    pub field: String,
    pub code: String,
    pub message: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, problem, title) = match &self {
            Self::NotFound => (StatusCode::NOT_FOUND, "not-found", "Not Found"),
            Self::Unauthorized => (StatusCode::UNAUTHORIZED, "unauthorized", "Unauthorized"),
            Self::UnprocessableEntity(_) =>
                (StatusCode::UNPROCESSABLE_ENTITY, "unprocessable-entity", "Unprocessable Entity"),
            Self::Conflict(_) =>
                (StatusCode::CONFLICT, "conflict", "Conflict"),
            Self::InternalServerError(_) =>
                (StatusCode::INTERNAL_SERVER_ERROR, "internal-error", "Internal Server Error"),
        };
        let detail = match &self {
            Self::InternalServerError(_) => "An unexpected error occurred".into(),
            other => other.to_string(),
        };
        let body = ProblemDetails {
            problem_type: format!("https://api.example.com/errors/{}", problem),
            title: title.into(),
            status: status.as_u16(),
            detail,
            instance: None,    // populate from `Request::uri().path()` in middleware
            errors: None,      // populate for 422 from validator output
            request_id: None,  // populate from `x-request-id` header / tracing span
        };
        (
            status,
            [(header::CONTENT_TYPE, "application/problem+json")],
            Json(body),
        ).into_response()
    }
}
```

## Inbound: Response Wrappers

```rust
// src/inbound/http/response.rs
pub struct ApiSuccess<T: Serialize> { status: StatusCode, data: T }

impl<T: Serialize> ApiSuccess<T> {
    pub fn new(status: StatusCode, data: T) -> Self { Self { status, data } }
}
impl<T: Serialize> IntoResponse for ApiSuccess<T> {
    fn into_response(self) -> Response { (self.status, Json(self.data)).into_response() }
}

pub struct Created<T>(pub T);
pub struct Ok<T>(pub T);
pub struct NoContent;

impl<T: Serialize> IntoResponse for Created<T> {
    fn into_response(self) -> Response { (StatusCode::CREATED, Json(self.0)).into_response() }
}
impl<T: Serialize> IntoResponse for Ok<T> {
    fn into_response(self) -> Response { Json(self.0).into_response() }
}
impl IntoResponse for NoContent {
    fn into_response(self) -> Response { StatusCode::NO_CONTENT.into_response() }
}
```

---

## Outbound: Outbox Adapter (transactional, sqlx)

The outbox row must be inserted in the **same** transaction as the aggregate write — otherwise a crash between commit and publish drops the event silently. In Rust + sqlx the cleanest pattern is to keep both writes inside one repository method; the domain passes events as plain data.

```rust
// src/domain/shared/events.rs — plain data, no infra deps
#[derive(Debug, Clone)]
pub struct DomainEvent {
    pub aggregate_type: &'static str,
    pub aggregate_id: String,
    pub event_type: &'static str,
    pub payload: serde_json::Value,
}
```

```rust
// src/domain/authors/ports.rs — port carries the events the caller wants persisted atomically
pub trait AuthorRepository: Clone + Send + Sync + 'static {
    fn create_author(
        &self,
        req: &CreateAuthorRequest,
        events: &[DomainEvent],
    ) -> impl Future<Output = Result<Author, CreateAuthorError>> + Send;
    // ... other methods
}
```

```rust
// src/outbound/postgres.rs — both writes in one tx, &mut **tx for sqlx 0.8+
impl AuthorRepository for Postgres {
    async fn create_author(
        &self,
        req: &CreateAuthorRequest,
        events: &[DomainEvent],
    ) -> Result<Author, CreateAuthorError> {
        let mut tx = self.pool.begin().await.context("begin tx")?;

        let id = Uuid::new_v4();
        sqlx::query!(
            "INSERT INTO authors (id, name) VALUES ($1, $2)",
            id, req.name().to_string(),
        )
        .execute(&mut **tx).await
        .map_err(|e| match e {
            sqlx::Error::Database(ref db) if db.is_unique_violation() =>
                CreateAuthorError::Duplicate { name: req.name().clone() },
            other => anyhow!(other).context("insert author").into(),
        })?;

        // Trace context captured at write time, not at relay time —
        // so consumers can stitch the producing request to downstream work.
        let traceparent = current_traceparent();

        for ev in events {
            sqlx::query!(
                "INSERT INTO outbox \
                   (id, aggregate_type, aggregate_id, event_type, payload, traceparent) \
                 VALUES ($1, $2, $3, $4, $5, $6)",
                Uuid::new_v4(),
                ev.aggregate_type,
                ev.aggregate_id,
                ev.event_type,
                ev.payload,
                traceparent.as_deref(),
            )
            .execute(&mut **tx).await
            .context("insert outbox row")?;
        }

        tx.commit().await.context("commit tx")?;
        Ok(Author::new(id, req.name().clone()))
    }
}
```

**Service composes it**: the application service builds `DomainEvent`s from the result and passes them in.

```rust
// src/domain/authors/service.rs
async fn create_author(&self, req: CreateAuthorRequest)
    -> Result<Author, CreateAuthorError>
{
    let events = vec![DomainEvent {
        aggregate_type: "author",
        aggregate_id: req.name().to_string(),
        event_type: "AuthorCreated",
        payload: json!({ "name": req.name().to_string() }),
    }];
    let author = self.repo.create_author(&req, &events).await?;
    self.metrics.record_creation();
    Ok(author)
}
```

**Outbox relay** is a separate binary (`bin/outbox_relay`), not an inbound HTTP handler. It polls `WHERE published_at IS NULL ORDER BY id LIMIT N`, publishes to the broker, and updates `published_at` on success. Failures move to a `outbox_dead` table after N attempts.

### Common gotchas

- `&mut **tx`, not `&mut *tx`. SQLx 0.8+ removed `Executor` from `Transaction`.
- Don't make `Outbox` a separate port that takes a `Transaction` — leaks sqlx into the domain. Keep both writes in the same adapter method.
- Don't publish to the broker inside the tx. Outbox relay is the only thing that talks to the broker.

---

## Outbound: Idempotency Store

A KV-shaped table keyed by `(scope, key)` with a unique constraint. The application service (or an inbound middleware) wraps the use case.

```rust
// src/domain/shared/idempotency.rs
pub trait IdempotencyStore: Clone + Send + Sync + 'static {
    fn acquire(
        &self,
        scope: &str,
        key: &str,
        request_hash: &str,
    ) -> impl Future<Output = Result<Acquire, anyhow::Error>> + Send;

    fn store(
        &self,
        scope: &str,
        key: &str,
        response_bytes: &[u8],
    ) -> impl Future<Output = Result<(), anyhow::Error>> + Send;
}

pub enum Acquire {
    NewExecution,
    Replay(Vec<u8>),
    Conflict, // same key, different request_hash
}
```

```rust
// src/outbound/postgres.rs
impl IdempotencyStore for Postgres {
    async fn acquire(&self, scope: &str, key: &str, hash: &str) -> Result<Acquire, anyhow::Error> {
        // Insert-or-fetch — unique constraint collapses races to one winner.
        let inserted = sqlx::query!(
            "INSERT INTO idempotency (scope, key, request_hash) \
             VALUES ($1, $2, $3) ON CONFLICT (scope, key) DO NOTHING",
            scope, key, hash,
        ).execute(&self.pool).await?;

        if inserted.rows_affected() == 1 {
            return Ok(Acquire::NewExecution);
        }
        let row = sqlx::query!(
            "SELECT request_hash, response FROM idempotency WHERE scope = $1 AND key = $2",
            scope, key,
        ).fetch_one(&self.pool).await?;

        if row.request_hash != hash {
            return Ok(Acquire::Conflict);
        }
        match row.response {
            Some(bytes) => Ok(Acquire::Replay(bytes)),
            None => Ok(Acquire::NewExecution), // in-flight; caller blocks or 409
        }
    }
    // store(...) updates the row.
}
```

---

## Outbound: Tracer Port (OTel)

Don't import `opentelemetry::*` types into the domain. Define a minimal port; the OTel adapter implements it. Tests use a no-op or capturing adapter.

```rust
// src/domain/shared/tracing.rs
pub trait Tracer: Clone + Send + Sync + 'static {
    type Span: Span;
    fn start_span(&self, name: &str, attrs: &[(&str, &str)]) -> Self::Span;
}
pub trait Span: Send {
    fn add_event(&self, name: &str, attrs: &[(&str, &str)]);
    fn record_error(&self, err: &(dyn std::error::Error + 'static));
    fn end(self);
}
```

The OTel adapter (`src/outbound/otel.rs`) wraps `opentelemetry_sdk::trace::Tracer`. The application service depends on the `Tracer` trait, never on the SDK directly. This keeps domain compile times low, lets tests run with zero observability cost, and makes vendor swap a one-file change.

For sampling, span attributes, and the broader strategy, see `software-architecture/references/observability.md`.
