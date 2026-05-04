---
name: nestjs-hexagonal
description: |
  NestJS with hexagonal architecture patterns in TypeScript.
  Use when: building TypeScript APIs with NestJS — for modular backends with built-in dependency injection.
  Covers: API design (@nestjs/swagger), domain modeling, ports & adapters (abstract class injection tokens), NestJS module wiring, Zod validation pipes, exception filters (RFC 9457), @nestjs/testing patterns, Drizzle ORM (SQL) and Mongoose (MongoDB) dual-database support, cursor pagination, @nestjs/terminus healthcheck endpoints.
  Do not use for: database schema design (use database-design skill). Use hono-hexagonal for lightweight multi-runtime APIs. Use fastapi-hexagonal for Python-only APIs. Use axum-hexagonal for Rust APIs.
references:
  - references/examples-domain.md
  - references/examples-adapters.md
  - references/examples-bootstrap.md
  - references/api-design.md
  - references/api-patterns.md
---

# NestJS + Hexagonal Architecture

**For latest NestJS/Drizzle/Mongoose/Zod APIs, use context7.**

## Core Philosophy

Separate **business domain** from **infrastructure**. Domain defines *what*; adapters decide *how*.

```
[Inbound Adapter: NestJS Controller] -> [Port: Service abstract class] -> [Domain Logic]
    -> [Port: Repository abstract class] -> [Outbound Adapter: Drizzle/Mongoose/etc.]
```

**Dependencies always point inward.** Domain code never imports NestJS, Drizzle, Mongoose, or any infrastructure package.

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
│       │   ├── request.dto.ts          # Zod schemas + toDomain()
│       │   └── response.dto.ts         # fromDomain() + Swagger decorators
│       ├── filters/
│       │   └── domain-exception.filter.ts  # Domain errors -> RFC 9457
│       ├── pipes/
│       │   └── zod-validation.pipe.ts      # Zod schema -> NestJS pipe
│       └── health/
│           └── health.controller.ts        # @nestjs/terminus
├── outbound/
│   ├── drizzle/                # SQL adapter (pick this OR mongoose)
│   │   ├── drizzle.module.ts   #   @Global, provides DRIZZLE token + repositories
│   │   ├── drizzle.provider.ts #   Factory: Pool -> drizzle(pool, { schema })
│   │   ├── schema.ts           #   Drizzle table definitions
│   │   ├── author.repository.ts
│   │   └── mapper.ts
│   ├── mongoose/               # MongoDB adapter (pick this OR drizzle)
│   │   ├── mongoose.module.ts  #   @Global, MongooseModule.forFeature + repositories
│   │   ├── author.schema.ts    #   @Schema/@Prop document definition
│   │   ├── author.repository.ts
│   │   └── mapper.ts
│   └── noop.ts                 # NoOp metrics/notifier for dev
├── authors.module.ts           # Feature module: wires controller + service
├── app.module.ts               # Root module: imports ONE persistence module + config
├── config.ts                   # Typed config with Zod
└── main.ts                     # Bootstrap — NestFactory, global middleware
drizzle/                        # SQL only: Drizzle Kit migrations
├── migrations/
drizzle.config.ts
tests/
├── helpers.ts                  # Test module factory
└── mocks.ts                    # Stub, Saboteur, Spy, NoOp
```

**Rule:** `domain/` never imports from `inbound/`, `outbound/`, or `@nestjs/*`.

**Swapping databases** is one import change in `app.module.ts` — the hexagonal boundary makes this trivial.

---

## Domain Layer

### Models
- Validate on construction (value object pattern). Classes with private constructors or factory functions.
- **No Drizzle schemas or Mongoose documents in domain** — those live in `outbound/` only.
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

- **Controllers** annotated with `@Controller('v1/authors')`. Each method: parse input -> call service -> map response. No Drizzle. No Mongoose. No ORM.
- **DI** — Controllers inject the abstract service class directly. NestJS resolves it to the concrete implementation registered in the feature module.
- **Request DTOs** decoupled from domain — Zod schema + `toDomain()` function. Use `ZodValidationPipe` on parameters.
- **Response DTOs** built via `fromDomain()` static method — never expose domain models directly. Add `@ApiProperty()` decorators for Swagger.
- **Exception Filters** map domain errors to RFC 9457 ProblemDetails. Register globally in `main.ts`. Match on `error.tag` for exhaustive handling.
- **API docs** — `@nestjs/swagger` with `@ApiOperation()`, `@ApiResponse()`. Consult `references/api-design.md` for conventions and `references/api-patterns.md` for HTTP patterns.
- **Guards** — Auth via `@UseGuards(JwtAuthGuard)`. Domain never handles tokens.
- **Pipes** — `ZodValidationPipe` for body/query/param validation.
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

Choose **one** persistence module per project (or per domain if you mix databases):

### Drizzle (SQL — PostgreSQL/SQLite)

- `@Injectable()` repositories that extend the abstract port class from domain.
- Inject `DRIZZLE` token (symbol) — the Drizzle client wrapped in a NestJS factory provider.
- **Transactions encapsulated in adapter** via `db.transaction()`, invisible to callers.
- Map Drizzle-specific errors (unique constraint codes) to domain error types.
- Drizzle table schemas live in `outbound/drizzle/schema.ts`. Use explicit mapper (`AuthorMapper.toDomain()`).

| Setting | Value | Why |
|---------|-------|-----|
| Client | `drizzle(pool, { schema })` | Pass your own pool for control |
| Transactions | `db.transaction(async (tx) => ...)` | Scoped, auto-rollback on throw |
| Relations | `db.query.authors.findMany({ with: { posts: true } })` | Eager load to prevent N+1 |
| Migrations | Drizzle Kit `generate` + `migrate` | Schema-driven SQL migrations |

### Mongoose (MongoDB)

- `@Injectable()` repositories that extend the abstract port class from domain.
- Inject Mongoose model via `@InjectModel(AuthorDocument.name)`.
- **Transactions encapsulated in adapter** via `session.withTransaction()`, invisible to callers.
- Map MongoDB-specific errors (duplicate key code `11000`) to domain error types.
- Mongoose schemas live in `outbound/mongoose/author.schema.ts` with `@Schema()`/`@Prop()` decorators. Use explicit mapper.

| Setting | Value | Why |
|---------|-------|-----|
| Schema | `@Schema({ timestamps: true })` class | NestJS-integrated schema definition |
| Transactions | `connection.startSession()` + `withTransaction()` | Multi-document atomicity (requires replica set) |
| Population | `populate('posts')` | Eager load references |
| Indexes | `@Prop({ unique: true, index: true })` | Declared on schema |
| Migrations | Not needed | Schema-less; use migration scripts for data transforms |

> Full outbound examples (Drizzle + Mongoose repositories, mappers, modules): `references/examples-adapters.md`

---

## Validation

Zod schemas define the contract at the transport boundary. Domain models validate business rules separately.

```
[HTTP body] -> [ZodValidationPipe validates shape] -> [toDomain() validates business rules] -> [Domain model]
```

Two-layer validation is intentional: Zod catches malformed input (missing fields, wrong types) before it reaches domain code. Domain constructors enforce business invariants (non-empty names, valid ranges).

> ZodValidationPipe implementation: `references/examples-adapters.md`

---

## Pagination

List endpoints need pagination. **Default to cursor-based pagination.** The pattern flows through all three layers:
- **Domain port**: `listAuthors(cursor: string | null, limit: number) => Promise<CursorPage<Author>>`
- **Drizzle adapter**: `WHERE (created_at, id) > (:cursor) ORDER BY created_at, id LIMIT :limit`
- **Mongoose adapter**: `find({ _id: { $gt: cursor } }).sort({ _id: 1 }).limit(limit)`
- **Inbound controller**: return `CursorPageResponse<T>` with `data`, `limit`, `nextCursor`, `hasMore`

Cap `limit` at the controller level via Zod (e.g. `z.number().min(1).max(100).default(20)`).

### Cursor vs Offset

**Cursor** (default) — Consistent performance regardless of dataset size. Use composite cursor `(sortField, id)`. Cursor is an opaque base64-encoded string in the API; decode in the adapter only.

**Offset** — Use for admin panels and small/static datasets. Provides `total` count for page number UIs.

---

## Healthcheck

Use `@nestjs/terminus` for structured health checks. These bypass the domain entirely.

- `/health/live` — always 200 (liveness)
- `/health/ready` — checks DB connectivity (readiness)
  - **Drizzle**: raw `SELECT 1` via pool
  - **Mongoose**: `mongoose.connection.readyState`

> Healthcheck example: `references/examples-adapters.md`

---

## Migrations

### Drizzle (SQL)

Drizzle Kit reads schema definitions from `outbound/drizzle/schema.ts` to generate SQL migrations.

```
drizzle/
├── migrations/         # Generated SQL migration files
drizzle.config.ts       # Points to outbound/drizzle/schema.ts
```

```bash
bunx drizzle-kit generate    # Generate migration from schema changes
bunx drizzle-kit migrate     # Apply migrations
bunx drizzle-kit studio      # Visual DB browser
```

### Mongoose (MongoDB)

MongoDB is schema-less — no structural migrations needed. For data transformations (rename fields, reshape documents), write one-off migration scripts.

---

## Logging

NestJS has a built-in `Logger` class. For structured logging, use `nestjs-pino`.

- **Domain**: log business events at info, wrap unexpected exceptions at error
- **Inbound**: exception filters log server errors before returning generic messages
- **Outbound**: Drizzle query logging via `logger` option / Mongoose `debug` mode

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

### Choosing a Database

In `app.module.ts`, import **one** persistence module:

```typescript
imports: [
  DrizzlePersistenceModule,    // SQL (PostgreSQL/SQLite)
  // MongoosePersistenceModule, // MongoDB — swap by toggling these imports
  AuthorsModule,
]
```

Both modules provide `AuthorRepository` — the feature module and controllers don't know which DB is backing them.

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
- Persistence module (Drizzle or Mongoose) — every feature needs DB access
- `ConfigModule.forRoot({ isGlobal: true })` — config everywhere

---

## Domain Boundaries

1. **Domain = tangible arm of your business** (blogging, billing, identity)
2. **Entities that change atomically -> same domain**
3. **Cross-domain operations are never atomic** — service calls or async events
4. **Start large, decompose when friction is observed**

> If you need transactions across modules for cross-domain atomicity, your boundaries are wrong.

---

## Common Gotchas

| Problem | Cause | Fix |
|---------|-------|-----|
| Circular dependency error | Module A imports B, B imports A | Use `forwardRef(() => ModuleB)` or rethink boundaries |
| Service is `undefined` | Not provided in module | Add to `providers` with correct abstract class token |
| `@Injectable()` in domain | Framework leak | Remove it, use `useFactory` in module |
| `HttpException` in domain | Transport leak | Use domain error classes, map in exception filter |
| Drizzle/Mongoose types in domain | ORM leak | Use mapper in outbound, domain has own types |
| Drizzle `DRIZZLE` token not found | Missing `@Inject(DRIZZLE)` | Use symbol injection in repository constructor |
| Mongoose transaction fails | No replica set | MongoDB transactions require replica set (use `rs.initiate()` or Atlas) |
| `enableShutdownHooks()` missing | DB disconnect not called | Add in `main.ts` before `app.listen()` |
| Tests share DB state | Missing cleanup | Reset in `beforeEach` or use transaction rollback |

---

## Quick Reference

| Question | Answer |
|----------|--------|
| Transactions? | Drizzle: `db.transaction()` / Mongoose: `session.withTransaction()` |
| Validation? | Zod pipe at transport boundary, domain constructors for business rules |
| Error mapping? | `@Catch()` exception filter in inbound |
| Business orchestration? | Service impl |
| Controller responsibility? | Parse -> service -> response |
| main.ts responsibility? | Create app, global middleware, Swagger, listen |
| DI mechanism? | Abstract classes as tokens + `useFactory` in modules |
| DB row <-> domain? | `AuthorMapper.toDomain()` in outbound |
| Test app? | `Test.createTestingModule().overrideProvider()` |
| Background workers? | `@nestjs/bullmq` or `@nestjs/schedule` |
| Migrations? | Drizzle Kit for SQL / not needed for MongoDB |
| Healthcheck? | `@nestjs/terminus` in inbound |
| JWT / passwords? | `@nestjs/passport` + `@node-rs/argon2` |
| Swap database? | Change one import in `app.module.ts` |

---

## Checklist

### Architecture
- [ ] Domain never imports from inbound/, outbound/, or @nestjs/*
- [ ] Ports as abstract classes, services orchestrate
- [ ] All handlers (HTTP, jobs, events): parse -> service -> respond
- [ ] Transactions in adapters only, DB row <-> domain mapper in outbound
- [ ] Errors: domain hierarchy -> exception filter -> RFC 9457
- [ ] If phase-tagged schema exists, implement Phase 1 endpoints only

### Framework
- [ ] Controllers in inbound/ with `@Controller()` decorators
- [ ] Services wired via `useFactory` (no `@Injectable` in domain)
- [ ] Zod validation via `ZodValidationPipe` on route params
- [ ] Global `DomainExceptionFilter` registered in main.ts
- [ ] `enableShutdownHooks()` called in main.ts
- [ ] `helmet()` middleware enabled
- [ ] CORS configured with explicit origins

### Database (pick one)
**Drizzle (SQL)**:
- [ ] Schema in `outbound/drizzle/schema.ts`
- [ ] Migrations in `drizzle/migrations/`
- [ ] `DrizzlePersistenceModule` is `@Global()`
- [ ] Pool configured with connection limit

**Mongoose (MongoDB)**:
- [ ] Schemas in `outbound/mongoose/*.schema.ts`
- [ ] `MongoosePersistenceModule` is `@Global()`
- [ ] Indexes declared on schema (`@Prop({ unique: true })`)
- [ ] Replica set configured if transactions needed

### Testing
**TDD**: Write all tests first as a spec, then implement, then verify all pass. (Tests -> Impl -> Green)
- [ ] Test helpers: `createTestModule()` factory
- [ ] Mock strategy: Stub, Saboteur, Spy, NoOp
- [ ] `overrideProvider()` for swapping adapters in tests
> Test mocks and test module helper: `references/examples-bootstrap.md`

### Setup
- [ ] `main.ts` has minimal business logic
- [ ] `bun.lock` committed
- [ ] Config validated with Zod at startup
