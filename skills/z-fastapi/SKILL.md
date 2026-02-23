---
name: z-fastapi
description: |
  FastAPI production patterns with Pydantic v2 and SQLAlchemy async.
  Use when: setup or building Python APIs, async database, JWT auth.
  Do not use for: API design decisions (use z-api-design skill).
  Workflow: z-api-design (design) → this skill (implementation).
  When to graduate: If you need testable architecture with ports/adapters, use z-fastapi-hexagonal.
references:
  - references/examples.md    # JWT auth, middleware, pagination, testing patterns
---

# FastAPI

**For latest FastAPI/Pydantic APIs, use context7.**

---

## Project Structure

```
src/
├── app/
│   ├── main.py              # FastAPI app, lifespan
│   └── config.py            # pydantic-settings
├── domains/
│   ├── [domain]/
│   │   ├── router.py
│   │   ├── schemas.py       # Pydantic models
│   │   ├── models.py        # SQLAlchemy models
│   │   ├── service.py       # service layer
│   │   └── dependencies.py  # dependency injection
│   └── [domain]/
│       └── ...
├── shared/
│   ├── database.py
│   ├── exceptions.py
│   └── middleware.py
└── tests/
```

---

## Critical Patterns

### Pydantic v2 + SQLAlchemy

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.ext.asyncio import AsyncAttrs

class Base(AsyncAttrs, DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(unique=True, index=True)
    name: Mapped[str]
```

```python
from pydantic import BaseModel, ConfigDict

class UserResponse(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(from_attributes=True)  # Required for ORM
```

**Rule: Use `Mapped[]` + `mapped_column()` for SQLAlchemy models. Use `from_attributes=True` for ORM conversion.**

**Pydantic v2 deprecations** (will be removed in v3):

| Deprecated | Use instead |
|---|---|
| `class Config:` | `model_config = ConfigDict(...)` |
| `@validator` | `@field_validator` |
| `@root_validator` | `@model_validator` |
| `.from_orm()` | `.model_validate(obj, from_attributes=True)` |

### Database Session

```python
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_timeout=3,
    pool_pre_ping=True,
)
async_session = async_sessionmaker(engine, expire_on_commit=False)

async def get_db():
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

**Rule: Always set `pool_timeout` and `pool_pre_ping`. `expire_on_commit=False` prevents detached instance errors.**

### Lifespan (App Lifecycle)

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown
    await engine.dispose()

app = FastAPI(lifespan=lifespan)
```

**Rule: Use lifespan, not deprecated `@app.on_event`.**

### Eager Loading (N+1 Prevention)

```python
# Lazy loading fails in async
result = await db.execute(
    select(User).options(selectinload(User.items))
)
```

**Rule: Always use `selectinload()` for relationships in async.**

### Query Parameter Models (FastAPI 0.115+)

```python
from pydantic import BaseModel, ConfigDict

class FilterParams(BaseModel):
    model_config = ConfigDict(extra="forbid")
    skip: int = 0
    limit: int = 100
    tag: str | None = None

@app.get("/items/")
async def list_items(filters: FilterParams = Query()):
    return filters
```

**Rule: Group related query params into a Pydantic model with `Query()`.**

---

## Middleware

### Request ID

```python
import uuid
from starlette.middleware.base import BaseHTTPMiddleware

class RequestIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response
```

**Rule: Add middleware in order — CORS first, then request ID, then routers.**

```python
app.add_middleware(CORSMiddleware, allow_origins=settings.CORS_ORIGINS, ...)
app.add_middleware(RequestIdMiddleware)
```

---

## Error Handling (RFC 9457)

```python
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "type": "https://api.example.com/errors/validation-failed",
            "title": "Validation Failed",
            "status": 422,
            "detail": "One or more fields failed validation",
            "errors": [
                {"field": ".".join(str(loc) for loc in err["loc"]), "message": err["msg"]}
                for err in exc.errors()
            ],
        },
        media_type="application/problem+json",
    )
```

**Rule: Use RFC 9457 Problem Details with `application/problem+json` content type.**

---

## Health Checks

```python
@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/health/ready")
async def readiness(db: AsyncSession = Depends(get_db)):
    await db.execute(text("SELECT 1"))
    return {"status": "ready"}
```

---

## Background Tasks

```python
from fastapi import BackgroundTasks

@router.post("/orders", status_code=201)
async def create_order(order_in: OrderCreate, background_tasks: BackgroundTasks):
    order = await order_service.create(order_in)
    background_tasks.add_task(send_confirmation_email, order.id)
    return order
```

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
| Pool exhausted | No timeout set | `pool_timeout=3` |
| DeprecationWarning | `datetime.utcnow()` | `datetime.now(UTC)` |

### Async Blocking (Critical)

```python
# ❌ Blocks entire event loop
@app.get("/")
async def bad():
    time.sleep(5)
    requests.get(...)  # sync HTTP

# ✅ Proper async
@app.get("/")
async def good():
    await asyncio.sleep(5)
    async with httpx.AsyncClient() as client:
        await client.get(...)
```

**Rule: In async routes, ALL I/O must be async. For sync libs, use sync def (thread pool).**

> JWT auth, testing patterns, middleware, and pagination examples: `references/examples.md`

---

## Quick Checklist

### Setup
- [ ] `lifespan` context manager (not on_event)
- [ ] `expire_on_commit=False` in session
- [ ] `pool_timeout`, `pool_pre_ping` set on engine
- [ ] CORS middleware before routers
- [ ] Request ID middleware

### Async Safety
- [ ] No blocking calls in async routes
- [ ] `selectinload()` for relationships
- [ ] httpx/aiohttp for HTTP calls (not requests)

### Models
- [ ] `Mapped[]` + `mapped_column()` for SQLAlchemy
- [ ] `AsyncAttrs` mixin on DeclarativeBase
- [ ] `from_attributes=True` for ORM schemas
- [ ] `str | None = None` for optional fields
- [ ] Separate Create/Update/Response schemas
- [ ] No `@validator` or `class Config:` (Pydantic v1 style)

### API
- [ ] RFC 9457 error responses with `application/problem+json`
- [ ] Health check endpoints (`/health`, `/health/ready`)
- [ ] Cursor-based pagination on list endpoints

### Auth
- [ ] `PyJWT` for tokens (not python-jose)
- [ ] `datetime.now(UTC)` (not `utcnow()`)
- [ ] `OAuth2PasswordBearer` for JWT
- [ ] `Depends(get_current_user)` on protected routes

> JWT auth flow, protected route patterns, and testing examples: `references/examples.md`

## Security Configuration

| Item | Value |
|------|-------|
| Password hashing | bcrypt, 12 rounds |
| JWT access token | 15 min |
| JWT refresh token (web) | 90 days |
| JWT refresh token (mobile) | 1 year |
| JWT algorithm | HS256 |
| Rate limit (auth) | 5/min |
| Rate limit (API) | 100/min |
| CORS | Explicit origins only (no wildcard) |
