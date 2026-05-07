# Examples: Bootstrap & Testing

Config, main.rs, graceful shutdown, CI, and hex-specific test mocks.

---

## Config

```rust
// src/config.rs
#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub server_port: String,
    pub cors_origin: String,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            database_url: std::env::var("DATABASE_URL")
                .context("DATABASE_URL must be set")?,
            server_port: std::env::var("PORT")
                .unwrap_or_else(|_| "3000".to_string()),
            cors_origin: std::env::var("CORS_ORIGIN")
                .unwrap_or_else(|_| "http://localhost:3000".to_string()),
        })
    }
}
```

## Bootstrap

```rust
// src/bin/server/main.rs — `sqlx` import is allowed in bootstrap because
// the pool is the one infrastructure handle the readiness probe needs.
// Domain code never sees it.
use sqlx::sqlite::SqlitePoolOptions;

use myapp::config::Config;
use myapp::domain::authors::service::AuthorServiceImpl;
use myapp::inbound::http::{HttpServer, HttpServerConfig};
use myapp::outbound::{sqlite::Sqlite, prometheus::Prometheus, email_client::EmailClient};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let config = Config::from_env()?;
    tracing_subscriber::fmt::init();

    // Construct the pool once so we can reuse it for both the repository
    // adapter AND the readiness probe.
    let pool = SqlitePoolOptions::new()
        .max_connections(10)
        .acquire_timeout(std::time::Duration::from_secs(3))
        .connect(&config.database_url).await?;

    let sqlite = Sqlite::from_pool(pool.clone());
    let service = AuthorServiceImpl::new(sqlite, Prometheus::new(), EmailClient::new());
    HttpServer::new(service, pool, HttpServerConfig {
        port: &config.server_port,
        cors_origin: &config.cors_origin,
    }).await?.run().await
}
```

## CI/CD

```bash
# SQLx 0.8+: one file per query (not merged). Commit .sqlx/ directory.
cargo sqlx prepare && git add .sqlx/    # generate offline query data
SQLX_OFFLINE=true cargo build           # CI without DB
```

---

## Testing: Hex-Specific Mocks

### Strategy

| Layer | Mock | What to test |
|-------|------|--------------|
| Handler | Mock service | HTTP parsing, status codes, error format |
| Service | Mock repo/metrics/notifier | Orchestration, side-effect ordering |
| Adapter | Real DB | SQL, error mapping, transactions |
| E2E | Nothing mocked | Critical happy paths |

### Stub — returns configured results

`Arc<Mutex<Result>>` needed because `Clone` bound + `anyhow::Error` isn't `Clone`.

```rust
#[derive(Clone)]
struct MockAuthorService {
    create_result: Arc<Mutex<Result<Author, CreateAuthorError>>>,
}

impl AuthorService for MockAuthorService {
    async fn create_author(&self, _: &CreateAuthorRequest) -> Result<Author, CreateAuthorError> {
        let mut guard = self.create_result.lock().await;
        let mut result = Err(CreateAuthorError::Unknown(anyhow!("placeholder")));
        mem::swap(guard.deref_mut(), &mut result);
        result
    }
    async fn find_author(&self, _: &Uuid) -> Result<Option<Author>, anyhow::Error> {
        Ok(None)
    }
    async fn list_authors(&self, _: Option<&str>, _: usize) -> Result<CursorPage<Author>, anyhow::Error> {
        Ok(CursorPage { items: vec![], next_cursor: None, has_more: false })
    }
}
```

### Saboteur — always fails

```rust
#[derive(Clone)]
struct SaboteurRepository;

impl AuthorRepository for SaboteurRepository {
    async fn create_author(&self, _: &CreateAuthorRequest) -> Result<Author, CreateAuthorError> {
        Err(anyhow!("db on fire").into())
    }
    async fn find_author(&self, _: &Uuid) -> Result<Option<Author>, anyhow::Error> {
        Err(anyhow!("db on fire"))
    }
    async fn list_authors(&self, _: Option<&str>, _: usize) -> Result<CursorPage<Author>, anyhow::Error> {
        Err(anyhow!("db on fire"))
    }
}
```

### Spy — side-effect counting

```rust
#[derive(Clone)]
struct SpyMetrics { success: Arc<AtomicU32>, failure: Arc<AtomicU32> }

impl AuthorMetrics for SpyMetrics {
    async fn record_creation_success(&self) { self.success.fetch_add(1, Ordering::SeqCst); }
    async fn record_creation_failure(&self) { self.failure.fetch_add(1, Ordering::SeqCst); }
}
```

### NoOp — for E2E tests

```rust
#[derive(Clone)]
struct NoOpMetrics;
impl AuthorMetrics for NoOpMetrics {
    async fn record_creation_success(&self) {}
    async fn record_creation_failure(&self) {}
}

#[derive(Clone)]
struct NoOpNotifier;
impl AuthorNotifier for NoOpNotifier {
    async fn author_created(&self, _: &Author) {}
}
```

### Test app helper

```rust
async fn test_app() -> Router {
    let pool = setup_test_db().await;
    let service = AuthorServiceImpl::new(Sqlite::from_pool(pool), NoOpMetrics, NoOpNotifier);
    HttpServer::build_router(service, test_config()).unwrap()
}

// Pattern 1: oneshot — single request per test
let app = test_app().await;
let res = app.oneshot(
    Request::post("/authors")
        .header("Content-Type", "application/json")
        .body(Body::from(r#"{"name":"Test"}"#)).unwrap(),
).await.unwrap();
assert_eq!(res.status(), StatusCode::CREATED);

// Read response body
let body = res.into_body().collect().await.unwrap().to_bytes();
let data: serde_json::Value = serde_json::from_slice(&body).unwrap();
```

### Multiple requests in one test

```rust
// Pattern 2: ready().call() — reuse the same service for multiple requests
use tower::{Service, ServiceExt};

let mut app = test_app().await.into_service();

// First request
let req = Request::post("/authors")
    .header("Content-Type", "application/json")
    .body(Body::from(r#"{"name":"Alice"}"#)).unwrap();
let res = ServiceExt::<Request<Body>>::ready(&mut app)
    .await.unwrap().call(req).await.unwrap();
assert_eq!(res.status(), StatusCode::CREATED);

// Second request on same service
let req = Request::get("/authors").body(Body::empty()).unwrap();
let res = ServiceExt::<Request<Body>>::ready(&mut app)
    .await.unwrap().call(req).await.unwrap();
assert_eq!(res.status(), StatusCode::OK);
```

### Integration test with `#[sqlx::test]`

```rust
#[sqlx::test]
async fn sqlite_duplicate_returns_domain_error(pool: SqlitePool) {
    let repo = Sqlite::from_pool(pool);
    let req = CreateAuthorRequest::new(AuthorName::new("Dup").unwrap());
    repo.create_author(&req).await.unwrap();
    let err = repo.create_author(&req).await.unwrap_err();
    assert!(matches!(err, CreateAuthorError::Duplicate { .. }));
}
```
