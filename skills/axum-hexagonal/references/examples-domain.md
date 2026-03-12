# Examples: Domain Layer

Models, errors, ports, and service implementation.

---

## Domain Models

```rust
// src/domain/authors/models.rs
use std::fmt;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Author {
    id: Uuid,
    name: AuthorName,
}

impl Author {
    pub fn new(id: Uuid, name: AuthorName) -> Self { Self { id, name } }
    pub fn id(&self) -> &Uuid { &self.id }
    pub fn name(&self) -> &AuthorName { &self.name }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AuthorName(String);

#[derive(Clone, Debug, Error)]
#[error("author name cannot be empty")]
pub struct AuthorNameEmptyError;

impl AuthorName {
    pub fn new(raw: &str) -> Result<Self, AuthorNameEmptyError> {
        let trimmed = raw.trim();
        if trimmed.is_empty() { Err(AuthorNameEmptyError) }
        else { Ok(Self(trimmed.to_string())) }
    }
}

// Display needed — .to_string() is called in adapters and error messages.
// Derive won't work on newtypes; implement manually.
impl fmt::Display for AuthorName {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(f)
    }
}

// AsRef<str> for zero-cost access to the inner string
impl AsRef<str> for AuthorName {
    fn as_ref(&self) -> &str { &self.0 }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CreateAuthorRequest { name: AuthorName }

impl CreateAuthorRequest {
    pub fn new(name: AuthorName) -> Self { Self { name } }
    pub fn name(&self) -> &AuthorName { &self.name }
}
```

## Domain Errors

```rust
// src/domain/authors/error.rs
#[derive(Debug, Error)]
pub enum CreateAuthorError {
    #[error("author with name {name} already exists")]
    Duplicate { name: AuthorName },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}
```

## Ports

```rust
// src/domain/authors/ports.rs
pub trait AuthorRepository: Clone + Send + Sync + 'static {
    fn create_author(
        &self, req: &CreateAuthorRequest,
    ) -> impl Future<Output = Result<Author, CreateAuthorError>> + Send;

    fn find_author(
        &self, id: &Uuid,
    ) -> impl Future<Output = Result<Option<Author>, anyhow::Error>> + Send;

    fn list_authors(
        &self, pagination: &Pagination,
    ) -> impl Future<Output = Result<Page<Author>, anyhow::Error>> + Send;
}

pub trait AuthorMetrics: Clone + Send + Sync + 'static {
    fn record_creation_success(&self) -> impl Future<Output = ()> + Send;
    fn record_creation_failure(&self) -> impl Future<Output = ()> + Send;
}

pub trait AuthorNotifier: Clone + Send + Sync + 'static {
    fn author_created(&self, author: &Author) -> impl Future<Output = ()> + Send;
}

pub trait AuthorService: Clone + Send + Sync + 'static {
    fn create_author(
        &self, req: &CreateAuthorRequest,
    ) -> impl Future<Output = Result<Author, CreateAuthorError>> + Send;

    fn list_authors(
        &self, pagination: &Pagination,
    ) -> impl Future<Output = Result<Page<Author>, anyhow::Error>> + Send;
}
```

## Pagination (Domain Types)

```rust
// src/domain/pagination.rs — shared across all domains
#[derive(Clone, Debug)]
pub struct Pagination {
    page: u32,
    per_page: u32,
}

impl Pagination {
    pub fn new(page: u32, per_page: u32) -> Self {
        Self {
            page: page.max(1),
            per_page: per_page.clamp(1, 100),
        }
    }
    pub fn page(&self) -> u32 { self.page }
    pub fn per_page(&self) -> u32 { self.per_page }
    pub fn offset(&self) -> u32 { (self.page - 1) * self.per_page }
}

impl Default for Pagination {
    fn default() -> Self { Self { page: 1, per_page: 20 } }
}

#[derive(Clone, Debug)]
pub struct Page<T> {
    pub items: Vec<T>,
    pub total: u64,
    pub page: u32,
    pub per_page: u32,
}

impl<T> Page<T> {
    pub fn total_pages(&self) -> u32 {
        ((self.total as f64) / (self.per_page as f64)).ceil() as u32
    }
}
```

## Service Implementation

```rust
// src/domain/authors/service.rs
#[derive(Debug, Clone)]
pub struct AuthorServiceImpl<R: AuthorRepository, M: AuthorMetrics, N: AuthorNotifier> {
    repo: R, metrics: M, notifier: N,
}

impl<R: AuthorRepository, M: AuthorMetrics, N: AuthorNotifier>
    AuthorServiceImpl<R, M, N>
{
    pub fn new(repo: R, metrics: M, notifier: N) -> Self {
        Self { repo, metrics, notifier }
    }
}

impl<R: AuthorRepository, M: AuthorMetrics, N: AuthorNotifier>
    AuthorService for AuthorServiceImpl<R, M, N>
{
    async fn create_author(&self, req: &CreateAuthorRequest) -> Result<Author, CreateAuthorError> {
        let result = self.repo.create_author(req).await;
        match &result {
            Ok(author) => {
                self.metrics.record_creation_success().await;
                self.notifier.author_created(author).await;
            }
            Err(_) => self.metrics.record_creation_failure().await,
        }
        result
    }

    async fn list_authors(&self, pagination: &Pagination) -> Result<Page<Author>, anyhow::Error> {
        self.repo.list_authors(pagination).await
    }
}
```
