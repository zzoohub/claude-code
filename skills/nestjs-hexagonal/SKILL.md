---
name: nestjs-hexagonal
description: |
  NestJS with hexagonal architecture patterns in TypeScript.
  Use when: building TypeScript APIs with NestJS — for modular backends with built-in dependency injection.
  Covers: API design (@nestjs/swagger), domain modeling, ports & adapters (abstract class injection tokens), NestJS module wiring, class-validator with the global ValidationPipe, exception filters (RFC 9457), @nestjs/testing patterns, TypeORM (PostgreSQL) persistence, cursor pagination, @nestjs/terminus healthcheck endpoints.
  Do not use for: database schema design (use database-design skill). Use hono-hexagonal for lightweight multi-runtime APIs. Use fastapi-hexagonal for Python-only APIs. Use axum-hexagonal for Rust APIs.
references:
  - references/examples-domain.md
  - references/examples-adapters.md
  - references/examples-bootstrap.md
  - references/api-design.md
  - references/api-patterns.md
---

# NestJS + Hexagonal Architecture

**For latest NestJS/TypeORM/class-validator APIs, use context7.**

## Core Philosophy

Separate **business domain** from **infrastructure**. Domain defines *what*; adapters decide *how*.

```
[Inbound Adapter: NestJS Controller] -> [Port: Service abstract class] -> [Domain Logic]
    -> [Port: Repository abstract class] -> [Outbound Adapter: TypeORM/etc.]
```

**Dependencies always point inward.** Domain code never imports NestJS, TypeORM, or any infrastructure package.

---

## Project Structure

```
src/
├── domain/
│   └── authors/
│       ├── models.ts            # Author, AuthorName, CreateAuthorRequest
│       ├── errors.ts            # DuplicateAuthorError, UnknownAuthorError
│       ├── ports.ts             # abstract AuthorRepository, abstract AuthorService
│       └── service.ts           # AuthorServiceImpl (plain class — no @Injectable)
├── inbound/
│   └── http/
│       ├── authors/
│       │   ├── authors.controller.ts   # Parse -> call service -> map response
│       │   ├── request.dto.ts          # class-validator DTO classes + toDomain()
│       │   └── response.dto.ts         # fromDomain() + Swagger decorators
│       ├── filters/
│       │   └── domain-exception.filter.ts  # Domain errors -> RFC 9457
│       ├── validation-exception.factory.ts # class-validator errors -> RFC 9457
│       └── health/
│           └── health.controller.ts        # @nestjs/terminus
├── outbound/
│   ├── typeorm/                # PostgreSQL adapter
│   │   ├── typeorm.module.ts   #   @Global, TypeOrmModule.forRootAsync + forFeature
│   │   ├── entities/
│   │   │   └── author.entity.ts #  @Entity class — outbound only, NEVER imported in domain
│   │   ├── author.repository.ts #  Implements domain port; @InjectRepository(AuthorEntity)
│   │   └── mapper.ts            #  AuthorEntity <-> Author (domain) translation
│   └── noop.ts                 # NoOp metrics/notifier for dev
├── authors.module.ts           # Feature module: wires controller + service
├── app.module.ts               # Root module: imports persistence module + config
├── config.ts                   # Typed config validated with class-validator
└── main.ts                     # Bootstrap — NestFactory, global middleware
data-source.ts                  # TypeORM CLI DataSource (entities + migrations path)
migrations/                     # TypeORM-generated migration files
tests/
├── helpers.ts                  # Test module factory
└── mocks.ts                    # Stub, Saboteur, Spy, NoOp
```

**Rule:** `domain/` never imports from `inbound/`, `outbound/`, or `@nestjs/*`.

---

## Domain Layer

### Models
- Validate on construction (value object pattern). Classes with private constructors or factory functions.
- **No TypeORM entities in domain** — those live in `outbound/` only. Domain `Author` and outbound `AuthorEntity` are *different types*.
- Domain models are plain TypeScript. No decorators, no framework dependencies.
- Separate `CreateAuthorRequest` from `Author` — they WILL diverge as app grows.

### Errors & Result Type
- Exhaustive hierarchy: one class per business rule violation + generic `UnknownAuthorError`.
- **Never throw NestJS `HttpException` in domain** — that leaks transport concerns.
- Use custom error classes extending `Error` with a `readonly tag` discriminant for exhaustive matching in exception filters.

### Ports (Abstract Classes)

Use abstract classes as both interface contract AND DI injection token. The abstract class works directly in NestJS module `providers` without needing symbols or `@Inject()` — this is the idiomatic NestJS approach.

Three categories: **Repository** (data), **Metrics** (observability), **Notifier** (side effects).

Abstract classes in the domain layer have zero NestJS imports — they're plain TypeScript.

### Service
- Abstract class `AuthorService` declaring business API + plain class `AuthorServiceImpl` extending it.
- Constructor takes all dependencies: `new AuthorServiceImpl(repo, metrics, notifier)`.
- **No `@Injectable()` on the service** — wired via `useFactory` in the feature module. This keeps domain free from NestJS imports entirely.
- Orchestrates: repo -> metrics -> notifications -> return result.
- Controllers call Service, never Repository directly.
- **Evolution path:** Direct calls (repo -> metrics -> notifier) keep the flow visible in one place. As side effects grow, refactor to domain events via `@nestjs/event-emitter`.

> Full domain examples (models, errors, ports, service): `references/examples-domain.md`

---

## Inbound Layer

- **Controllers** annotated with `@Controller('v1/authors')`. Each method: parse input -> call service -> map response. No TypeORM. No ORM. **Never** return entities directly — always go through the response DTO.
- **DI** — Controllers inject the abstract service class directly. NestJS resolves it to the concrete implementation registered in the feature module.
- **Request DTOs** decoupled from domain — class with class-validator decorators + `toDomain()` function. Validation handled by the global `ValidationPipe`. Type-annotate the controller parameter (`@Body() body: CreateAuthorBody`); without an explicit class type the pipe has no metadata to validate against.
- **Response DTOs** built via `fromDomain()` static method — never expose domain models directly. Add `@ApiProperty()` decorators for Swagger.
- **Exception Filters** map domain errors to RFC 9457 ProblemDetails. Register globally in `main.ts`. Match on `error.tag` for exhaustive handling.
- **API docs** — `@nestjs/swagger` with `@ApiOperation()`, `@ApiResponse()`. Consult `references/api-design.md` for conventions and `references/api-patterns.md` for HTTP patterns.
- **Guards** — Auth via `@UseGuards(JwtAuthGuard)`. Domain never handles tokens.
- **Pipes** — Built-in `ValidationPipe` registered globally in `main.ts` (`whitelist`, `forbidNonWhitelisted`, `transform`, `enableImplicitConversion`) drives class-validator on DTO classes. `exceptionFactory` reshapes errors to RFC 9457 ProblemDetails — see `validation-exception.factory.ts`.
- **NestJS execution order**: Guards -> Interceptors -> Pipes -> Handler -> Interceptors -> Filters.

### Non-HTTP Inbound Adapters

Any external trigger that drives the domain is an inbound adapter:

| Trigger | NestJS Pattern | Still HTTP? |
|---------|---------------|-------------|
| Task/Job queue | `@nestjs/bullmq` processor | No (consumer) |
| Webhook | Controller with signature verification guard | Yes |
| Cron/Scheduler | `@nestjs/schedule` `@Cron()` service | No |
| Event stream | `@nestjs/microservices` `@MessagePattern()` | No |

All follow the same pattern: **parse input -> call service -> respond.**

> Full inbound examples (controller, DTOs, exception filter, auth guard, pipes): `references/examples-adapters.md`

---

## Outbound Layer

### TypeORM (PostgreSQL)

- `@Injectable()` repositories that extend the abstract port class from domain.
- Inject the per-entity `Repository<AuthorEntity>` via `@InjectRepository(AuthorEntity)`.
- **Transactions encapsulated in adapter** via `repo.manager.transaction()` (or an injected `DataSource`), invisible to callers.
- Map TypeORM-specific errors (`QueryFailedError` with driver code `23505` on Postgres) to domain error types.
- Entities live in `outbound/typeorm/entities/*.entity.ts`. Use **Data Mapper** style only (`repo.save(entity)`); never Active Record (`entity.save()`). The mapper translates `AuthorEntity <-> Author`.

| Setting | Value | Why |
|---------|-------|-----|
| Module | `TypeOrmModule.forRootAsync` + `forFeature([AuthorEntity])` | Async config from `ConfigService`, per-feature repository wiring |
| Repository style | Data Mapper only (`@InjectRepository`) | Active Record leaks persistence into domain |
| Transactions | `repo.manager.transaction(async (m) => ...)` | Scoped, auto-rollback on throw |
| Relations | `repo.find({ relations: { posts: true } })` or QueryBuilder `leftJoinAndSelect` | Eager join to prevent N+1; never lazy `Promise<Related>` |
| Migrations | TypeORM CLI `migration:generate` + `migration:run` | Schema-driven SQL migrations from entity diff |
| `synchronize` | **`false`** in every environment except local sandbox | Auto-altering production schemas is a foot-gun |

> Full outbound examples (TypeORM repository, mapper, module): `references/examples-adapters.md`

---

## TypeORM Pitfalls (Hex Discipline)

TypeORM doesn't fight hexagonal — but its convenience features do. Six hard rules; one soft note. Each one of these, left unchecked, walks the codebase back toward an Active Record monolith.

| Pitfall | Hex violation | Rule |
|---------|---------------|------|
| Active Record (`entity.save()`, `Entity.find()`) | Domain learns about persistence | **Data Mapper only** — call `repo.save(entity)` from the adapter |
| Lifecycle hooks (`@BeforeInsert`, `@AfterLoad`) | Business logic hides inside the adapter | **Forbidden** — put logic in the domain service |
| `cascade: true` on relations | Auto-save/delete hides side effects | **Off by default** — call related saves explicitly inside a transaction |
| TypeORM Subscribers / EventSubscribers | Competing event system inside the adapter | **Forbidden** — use `@nestjs/event-emitter` or domain events |
| Lazy relations (`Promise<Related>`) | `Promise` leaks into the mapped domain object | **Forbidden** — eager-join in the adapter or mapper resolves before returning |
| Returning entities to the controller | Domain ⇄ DTO boundary collapses | **Always** map entity → domain → response DTO |

> **Note (soft):** `repo.save()` infers insert vs update from the presence of an id. When the intent matters for readability or for an audit trail, prefer `repo.insert()` / `repo.update()` explicitly.

> **One-liner to remember:** *TypeORM isn't incompatible with hex — TypeORM's conveniences make hex discipline easy to erode.*

---

## Validation

class-validator decorators on DTO classes define the contract at the transport boundary. Domain models validate business rules separately.

```
[HTTP body] -> [Global ValidationPipe + class-validator decorators] -> [toDomain() validates business rules] -> [Domain model]
```

Two-layer validation is intentional: class-validator catches malformed input (missing fields, wrong types) before it reaches domain code. Domain constructors enforce business invariants (non-empty names, valid ranges).

Register the pipe once in `main.ts`:

```typescript
app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
```

`transform: true` is required so `@Type(() => Number)` coercions on query params (e.g. `limit`) actually run.

> Request DTO and config validation examples: `references/examples-adapters.md`, `references/examples-bootstrap.md`

---

## Pagination

List endpoints need pagination. **Default to cursor-based pagination.** The pattern flows through all three layers:
- **Domain port**: `listAuthors(cursor: string | null, limit: number) => Promise<CursorPage<Author>>`
- **TypeORM adapter**: QueryBuilder `where("(author.created_at, author.id) > (:cursorAt, :cursorId)", ...).orderBy({ "author.created_at": "ASC", "author.id": "ASC" }).limit(:limit)`
- **Inbound controller**: return `CursorPageResponse<T>` with `data`, `limit`, `next_cursor`, `has_more`

Cap `limit` at the controller level via class-validator on the query DTO (e.g. `@IsInt() @Min(1) @Max(100) limit: number = 20;` with `@Type(() => Number)` for query-string coercion).

### Cursor vs Offset

**Cursor** (default) — Consistent performance regardless of dataset size. Use composite cursor `(sortField, id)`. Cursor is an opaque base64-encoded string in the API; decode in the adapter only.

**Offset** — Use for admin panels and small/static datasets. Provides `total` count for page number UIs.

---

## Healthcheck

Use `@nestjs/terminus` for structured health checks. These bypass the domain entirely.

- `/health/live` — always 200 (liveness)
- `/health/ready` — checks DB connectivity (readiness) via `TypeOrmHealthIndicator.pingCheck("database")`

> Healthcheck example: `references/examples-adapters.md`

---

## Migrations

TypeORM CLI reads `data-source.ts` (with `entities` + `migrations` paths) and generates migrations from the entity-vs-DB diff.

```
data-source.ts          # DataSource: entities + migrations path + DB connection
migrations/             # Generated TypeScript migration files (run via CLI)
```

```bash
# Generate migration from current entity diff
bunx typeorm-ts-node-commonjs migration:generate -d ./data-source.ts ./migrations/CreateAuthors

# Apply pending migrations
bunx typeorm-ts-node-commonjs migration:run -d ./data-source.ts

# Revert the most recent migration
bunx typeorm-ts-node-commonjs migration:revert -d ./data-source.ts
```

`synchronize: false` in every environment except a throw-away local sandbox — migrations are the only sanctioned schema mutation path.

---

## Logging

NestJS has a built-in `Logger` class. For structured logging, use `nestjs-pino`.

- **Domain**: log business events at info, wrap unexpected exceptions at error
- **Inbound**: exception filters log server errors before returning generic messages
- **Outbound**: TypeORM query logging via `logging: ["query", "error"]` (or `"all"` in dev)

---

## Security

| Item | Value |
|------|-------|
| Password hashing | `@node-rs/argon2` (default), `bcrypt` (fallback) |
| JWT library | `jsonwebtoken` (simple), `@nestjs/passport` + `passport-jwt` (full-featured) |
| JWT access token | 15 min |
| JWT refresh (web) | 90 days |
| JWT refresh (mobile) | 1 year |
| Refresh token rotation | **Required** — issue new refresh token on each use, revoke old immediately |
| Refresh token storage | DB table/collection with `jti`, `userId`, `revokedAt`, `expiresAt` |
| CORS | `app.enableCors({ origin: [...] })` in main.ts |
| Security headers | `helmet` middleware |
| Rate limiting | `@nestjs/throttler` |

Auth guard lives in the inbound layer. Domain never handles raw tokens.

---

## Bootstrap (main.ts)

NestJS bootstrap creates the application from the root module and configures global middleware. Keep it focused — no business logic.

Key setup: CORS -> helmet -> global filter -> Swagger -> shutdown hooks -> listen.

> Full bootstrap and config examples: `references/examples-bootstrap.md`

---

## Module Organization

NestJS modules are the wiring layer — they connect ports to adapters.

### Persistence Module

In `app.module.ts`, import the persistence module:

```typescript
imports: [
  TypeOrmPersistenceModule,    // PostgreSQL
  AuthorsModule,
]
```

The persistence module provides `AuthorRepository` — the feature module and controllers depend only on the abstract port.

### Feature Module Pattern

Each domain gets a **feature module** that wires its controller, service, and repository. The service is wired via `useFactory` to keep domain free from `@Injectable()`.

### Scaling

| App size | Pattern |
|----------|---------|
| 1-3 features | Feature modules at `src/*.module.ts` |
| 4+ features | Feature modules in `src/modules/*.module.ts` |
| Cross-domain | Import another feature module, inject its exported service |

### Global Modules

Mark with `@Global()` when the module should be available everywhere without explicit imports:
- Persistence module (TypeORM) — every feature needs DB access
- `ConfigModule.forRoot({ isGlobal: true })` — config everywhere

---

## Domain Boundaries

1. **Domain = tangible arm of your business** (blogging, billing, identity)
2. **Entities that change atomically -> same domain**
3. **Cross-domain operations are never atomic** — service calls or async events
4. **Start large, decompose when friction is observed**

> If you need transactions across modules for cross-domain atomicity, your boundaries are wrong.

---

## Reliability & Observability Ports

Cross-cutting infrastructure that must not leak into the domain. Define each as an abstract class (the same DI-token pattern used for repositories); implement as outbound adapters. Architecture-level pattern lives in `software-architecture/references/reliability-patterns.md` and `observability.md`.

| Port | Purpose | Where it lives |
|---|---|---|
| **Outbox** | Atomic state change + message publish — outbox row written inside the same `EntityManager.transaction(...)` callback as the aggregate write | Outbound (combined with the repository adapter) |
| **IdempotencyStore** | Replay safe responses for `Idempotency-Key`-bearing requests | Outbound; called by an interceptor or application service |
| **Tracer** / **Meter** | OTel span / metric emission. Domain depends on the abstract class, not on `@opentelemetry/*` | Outbound (OTel adapter); no-op for tests |

**Architectural rule**: domain emits **`DomainEvent`** plain objects; the outbound adapter persists the aggregate AND the outbox rows inside one `manager.transaction(async (em) => ...)` callback. A separate **outbox relay** (a `@nestjs/bullmq` worker, a `@Cron` task, or a separate process) publishes rows asynchronously.

**Choose `EntityManager.transaction` over `@Transactional` (typeorm-transactional)**: the decorator hides the tx boundary in metadata and relies on AsyncLocalStorage magic. Explicit `manager.transaction(...)` keeps the tx boundary visible at the call site, which matches hexagonal's "side effects are explicit" stance and avoids a third-party lib whose maintenance has been spotty.

→ Adapter examples: `references/examples-adapters.md`

---

## Common Gotchas

| Problem | Cause | Fix |
|---------|-------|-----|
| Circular dependency error | Module A imports B, B imports A | Use `forwardRef(() => ModuleB)` or rethink boundaries |
| Service is `undefined` | Not provided in module | Add to `providers` with correct abstract class token |
| `@Injectable()` in domain | Framework leak | Remove it, use `useFactory` in module |
| `HttpException` in domain | Transport leak | Use domain error classes, map in exception filter |
| TypeORM types in domain | ORM leak | Use mapper in outbound, domain has own types |
| Entity returned to controller / used as domain model | Hex boundary collapse | Always map `Entity -> Author -> Response DTO` |
| `@BeforeInsert` / Subscribers carry business logic | Logic hides in adapter | Move to domain service or `@nestjs/event-emitter` |
| `cascade: true` produces surprise writes | Side effects hidden in relation graph | Off; call related saves explicitly inside a transaction |
| `synchronize: true` in any deployed env | Auto-altering production schema | Keep `false`; use `migration:run` |
| `@InjectRepository(AuthorEntity)` undefined | `TypeOrmModule.forFeature([AuthorEntity])` missing in module | Add it to the persistence module's imports |
| `enableShutdownHooks()` missing | DB disconnect not called | Add in `main.ts` before `app.listen()` |
| Tests share DB state | Missing cleanup | Reset in `beforeEach` or use transaction rollback |

---

## Quick Reference

| Question | Answer |
|----------|--------|
| Transactions? | `repo.manager.transaction()` |
| Validation? | class-validator + global `ValidationPipe` at transport boundary, domain constructors for business rules |
| Error mapping? | `@Catch()` exception filter in inbound |
| Business orchestration? | Service impl |
| Controller responsibility? | Parse -> service -> response |
| main.ts responsibility? | Create app, global middleware, Swagger, listen |
| DI mechanism? | Abstract classes as tokens + `useFactory` in modules |
| Entity <-> domain? | `AuthorMapper.toDomain(entity)` / `toEntity(domain)` in outbound |
| Test app? | `Test.createTestingModule().overrideProvider()` |
| Background workers? | `@nestjs/bullmq` or `@nestjs/schedule` |
| Migrations? | TypeORM CLI (`migration:generate` + `migration:run`) |
| Healthcheck? | `@nestjs/terminus` in inbound |
| JWT / passwords? | `@nestjs/passport` + `@node-rs/argon2` |

---

## Checklist

### Architecture
- [ ] Domain never imports from inbound/, outbound/, or @nestjs/*
- [ ] Ports as abstract classes, services orchestrate
- [ ] All handlers (HTTP, jobs, events): parse -> service -> respond
- [ ] Transactions in adapters only, entity <-> domain mapper in outbound
- [ ] Errors: domain hierarchy -> exception filter -> RFC 9457

### Framework
- [ ] Controllers in inbound/ with `@Controller()` decorators
- [ ] Services wired via `useFactory` (no `@Injectable` in domain)
- [ ] Validation via class-validator decorators + global `ValidationPipe` (`whitelist`, `transform`)
- [ ] Global `DomainExceptionFilter` registered in main.ts
- [ ] `enableShutdownHooks()` called in main.ts
- [ ] `helmet()` middleware enabled
- [ ] CORS configured with explicit origins

### Database (TypeORM + PostgreSQL)
- [ ] Entities in `outbound/typeorm/entities/*.entity.ts` (NEVER imported from domain)
- [ ] `TypeOrmPersistenceModule` is `@Global()` and registers `forFeature([...entities])`
- [ ] `synchronize: false` in every env; migrations run via TypeORM CLI
- [ ] Data Mapper only — no `entity.save()`, no `@BeforeInsert`/Subscribers, no `cascade: true`, no lazy `Promise<Related>`
- [ ] Repository extends domain port; `QueryFailedError` driver code mapped to domain errors
- [ ] Mapper handles `Entity <-> Author` in both directions

### Testing
**TDD**: Write all tests first as a spec, then implement, then verify all pass. (Tests -> Impl -> Green)
- [ ] Test helpers: `createTestModule()` factory
- [ ] Mock strategy: Stub, Saboteur, Spy, NoOp
- [ ] `overrideProvider()` for swapping adapters in tests
> Test mocks and test module helper: `references/examples-bootstrap.md`

### Setup
- [ ] `main.ts` has minimal business logic
- [ ] `bun.lock` committed
- [ ] Config validated with class-validator at startup
