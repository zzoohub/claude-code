# Examples: Adapters

Inbound (createApp, handlers, task handlers, auth, errors) and outbound (Drizzle, SQLite, mapper).

---

## Outbound: Drizzle Schema + Mapper

```typescript
// src/outbound/drizzle/schema.ts
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm";

/**
 * Drizzle table definition — outbound only. Never import in domain.
 * createdAt is required by composite cursor pagination — index on (created_at, id).
 */
export const authors = sqliteTable("authors", {
  id: text("id").primaryKey(),
  name: text("name").notNull().unique(),
  createdAt: integer("created_at", { mode: "timestamp" })
    .notNull()
    .default(sql`(unixepoch())`),
});

// For Postgres, use pgTable from drizzle-orm/pg-core:
// import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";
// export const authors = pgTable("authors", {
//   id: uuid("id").primaryKey().defaultRandom(),
//   name: text("name").notNull().unique(),
//   createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
// });
```

```typescript
// src/outbound/drizzle/mapper.ts
import { AuthorName } from "../../domain/authors/models";
import type { Author } from "../../domain/authors/models";

type AuthorRow = { id: string; name: string; createdAt: Date };

/**
 * DB row <-> domain translation. Keeps domain free from Drizzle.
 * Note: domain Author intentionally omits createdAt — adapters carry it for pagination.
 */
export class AuthorMapper {
  static toDomain(row: AuthorRow): Author {
    return {
      id: row.id,
      name: AuthorName.create(row.name),
    };
  }

  static toRow(author: Author): { id: string; name: string } {
    return {
      id: author.id,
      name: author.name.value,
    };
  }
}
```

## Outbound: Cursor Helpers (composite + base64)

```typescript
// src/outbound/cursor.ts
// Composite cursor (createdAt, id) encoded as opaque base64.
// Single-column `id > X` cursors skip/duplicate rows under concurrent inserts;
// composite (createdAt, id) is stable.

// Runtime-agnostic base64url — works in Node, Bun, Deno, and Cloudflare Workers.
function base64UrlEncode(raw: string): string {
  if (typeof Buffer !== "undefined") return Buffer.from(raw).toString("base64url");
  return btoa(raw).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlDecode(raw: string): string {
  if (typeof Buffer !== "undefined") return Buffer.from(raw, "base64url").toString("utf8");
  const padded = raw.replace(/-/g, "+").replace(/_/g, "/");
  return atob(padded + "===".slice(0, (4 - (padded.length % 4)) % 4));
}

export function encodeCursor(createdAt: Date, id: string): string {
  return base64UrlEncode(`${createdAt.toISOString()}|${id}`);
}

export function decodeCursor(raw: string): { createdAt: Date; id: string } {
  const [ts, id] = base64UrlDecode(raw).split("|", 2);
  return { createdAt: new Date(ts), id };
}
```

## Outbound: Drizzle Adapter (ORM + mapper)

```typescript
// src/outbound/drizzle/repository.ts
import { and, asc, eq, gt, or } from "drizzle-orm";
import type { BunSQLiteDatabase } from "drizzle-orm/bun-sqlite";
import { authors } from "./schema";
import { AuthorMapper } from "./mapper";
import { decodeCursor, encodeCursor } from "../cursor";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";
import type {
  Author,
  CreateAuthorRequest,
  CursorPage,
} from "../../domain/authors/models";
import type { AuthorRepository } from "../../domain/authors/ports";

/**
 * Transactions encapsulated here — invisible to callers.
 */
export class DrizzleAuthorRepository implements AuthorRepository {
  constructor(private readonly db: BunSQLiteDatabase) {}

  static fromClient(db: BunSQLiteDatabase): DrizzleAuthorRepository {
    return new DrizzleAuthorRepository(db);
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    const id = crypto.randomUUID();
    try {
      await this.db.insert(authors).values({
        id,
        name: req.name.value,
      });
    } catch (error) {
      if (this.isUniqueConstraintError(error)) {
        throw new DuplicateAuthorError(req.name.value);
      }
      throw new UnknownAuthorError(error);
    }
    return { id, name: req.name };
  }

  async findAuthor(authorId: string): Promise<Author | null> {
    const rows = await this.db
      .select()
      .from(authors)
      .where(eq(authors.id, authorId));
    if (rows.length === 0) return null;
    return AuthorMapper.toDomain(rows[0]);
  }

  async listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>> {
    // Fetch limit+1 to detect whether more rows exist beyond the boundary.
    const fetchLimit = limit + 1;

    // Drizzle has no native tuple-comparison operator — emulate
    // (createdAt, id) > (cursorAt, cursorId) via OR + AND.
    const rows = cursor
      ? await (() => {
          const { createdAt, id } = decodeCursor(cursor);
          return this.db
            .select()
            .from(authors)
            .where(
              or(
                gt(authors.createdAt, createdAt),
                and(eq(authors.createdAt, createdAt), gt(authors.id, id)),
              ),
            )
            .orderBy(asc(authors.createdAt), asc(authors.id))
            .limit(fetchLimit);
        })()
      : await this.db
          .select()
          .from(authors)
          .orderBy(asc(authors.createdAt), asc(authors.id))
          .limit(fetchLimit);

    // Drop overflow row; cursor points at the LAST RETURNED row so the
    // next page resumes AFTER it (no duplicates, no skips).
    const hasMore = rows.length > limit;
    const pageRows = rows.slice(0, limit);
    const items = pageRows.map(AuthorMapper.toDomain);
    const last = pageRows[pageRows.length - 1];
    const nextCursor = hasMore && last ? encodeCursor(last.createdAt, last.id) : null;

    return { items, nextCursor, hasMore };
  }

  private isUniqueConstraintError(error: unknown): boolean {
    if (error instanceof Error) {
      // SQLite: UNIQUE constraint failed
      // Postgres: duplicate key value violates unique constraint (code 23505)
      return (
        error.message.includes("UNIQUE constraint failed") ||
        error.message.includes("23505")
      );
    }
    return false;
  }
}
```

## Outbound: Drizzle Postgres Adapter with Transactions

```typescript
// src/outbound/drizzle/postgres-repository.ts
import { and, asc, eq, gt, or } from "drizzle-orm";
import type { NodePgDatabase } from "drizzle-orm/node-postgres";
import { authors } from "./schema";
import { AuthorMapper } from "./mapper";
import { decodeCursor, encodeCursor } from "../cursor";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";
import type {
  Author,
  CreateAuthorRequest,
  CursorPage,
} from "../../domain/authors/models";
import type { AuthorRepository } from "../../domain/authors/ports";

export class PostgresAuthorRepository implements AuthorRepository {
  constructor(private readonly db: NodePgDatabase) {}

  static fromClient(db: NodePgDatabase): PostgresAuthorRepository {
    return new PostgresAuthorRepository(db);
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    const id = crypto.randomUUID();
    try {
      // Transaction scoped to adapter — domain doesn't know
      await this.db.transaction(async (tx) => {
        await tx.insert(authors).values({
          id,
          name: req.name.value,
        });
      });
    } catch (error) {
      if (this.isUniqueConstraintError(error)) {
        throw new DuplicateAuthorError(req.name.value);
      }
      throw new UnknownAuthorError(error);
    }
    return { id, name: req.name };
  }

  async findAuthor(authorId: string): Promise<Author | null> {
    const rows = await this.db
      .select()
      .from(authors)
      .where(eq(authors.id, authorId));
    if (rows.length === 0) return null;
    return AuthorMapper.toDomain(rows[0]);
  }

  async listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>> {
    const fetchLimit = limit + 1;

    const rows = cursor
      ? await (() => {
          const { createdAt, id } = decodeCursor(cursor);
          return this.db
            .select()
            .from(authors)
            .where(
              or(
                gt(authors.createdAt, createdAt),
                and(eq(authors.createdAt, createdAt), gt(authors.id, id)),
              ),
            )
            .orderBy(asc(authors.createdAt), asc(authors.id))
            .limit(fetchLimit);
        })()
      : await this.db
          .select()
          .from(authors)
          .orderBy(asc(authors.createdAt), asc(authors.id))
          .limit(fetchLimit);

    const hasMore = rows.length > limit;
    const pageRows = rows.slice(0, limit);
    const items = pageRows.map(AuthorMapper.toDomain);
    const last = pageRows[pageRows.length - 1];
    const nextCursor = hasMore && last ? encodeCursor(last.createdAt, last.id) : null;

    return { items, nextCursor, hasMore };
  }

  private isUniqueConstraintError(error: unknown): boolean {
    if (error instanceof Error) {
      return error.message.includes("23505");
    }
    return false;
  }
}
```

## Outbound: Raw SQL Adapter (no ORM)

```typescript
// src/outbound/sqlite/repository.ts
import { Database } from "bun:sqlite";
import { AuthorName } from "../../domain/authors/models";
import type {
  Author,
  CreateAuthorRequest,
  CursorPage,
} from "../../domain/authors/models";
import type { AuthorRepository } from "../../domain/authors/ports";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";
import { decodeCursor, encodeCursor } from "../cursor";

type AuthorRow = { id: string; name: string; created_at: number };

/**
 * Raw SQL — demonstrates that adapters choose their own data access strategy.
 * SQLite stores timestamps as unix epoch integers (seconds).
 */
export class SqliteAuthorRepository implements AuthorRepository {
  constructor(private readonly db: Database) {}

  static fromClient(db: Database): SqliteAuthorRepository {
    return new SqliteAuthorRepository(db);
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    const id = crypto.randomUUID();
    try {
      // created_at uses DEFAULT (unixepoch()) declared in schema.
      this.db
        .prepare("INSERT INTO authors (id, name) VALUES (?, ?)")
        .run(id, req.name.value);
    } catch (error) {
      if (
        error instanceof Error &&
        error.message.includes("UNIQUE constraint failed")
      ) {
        throw new DuplicateAuthorError(req.name.value);
      }
      throw new UnknownAuthorError(error);
    }
    return { id, name: req.name };
  }

  async findAuthor(authorId: string): Promise<Author | null> {
    const row = this.db
      .prepare("SELECT id, name, created_at FROM authors WHERE id = ?")
      .get(authorId) as AuthorRow | null;
    if (!row) return null;
    return { id: row.id, name: AuthorName.create(row.name) };
  }

  async listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>> {
    const fetchLimit = limit + 1;
    const rows = (cursor
      ? (() => {
          const { createdAt, id } = decodeCursor(cursor);
          // Composite (created_at, id) tuple comparison via SQLite row-value syntax.
          return this.db
            .prepare(
              "SELECT id, name, created_at FROM authors " +
                "WHERE (created_at, id) > (?, ?) " +
                "ORDER BY created_at ASC, id ASC LIMIT ?",
            )
            .all(Math.floor(createdAt.getTime() / 1000), id, fetchLimit);
        })()
      : this.db
          .prepare(
            "SELECT id, name, created_at FROM authors ORDER BY created_at ASC, id ASC LIMIT ?",
          )
          .all(fetchLimit)) as AuthorRow[];

    const hasMore = rows.length > limit;
    const pageRows = rows.slice(0, limit);
    const items = pageRows.map((r) => ({
      id: r.id,
      name: AuthorName.create(r.name),
    }));
    const last = pageRows[pageRows.length - 1];
    const nextCursor = hasMore && last
      ? encodeCursor(new Date(last.created_at * 1000), last.id)
      : null;

    return { items, nextCursor, hasMore };
  }
}
```

---

## Inbound: createApp (wraps Hono)

```typescript
// src/inbound/http/app.ts
import { OpenAPIHono } from "@hono/zod-openapi";
import { swaggerUI } from "@hono/swagger-ui";
import { cors } from "hono/cors";
import { secureHeaders } from "hono/secure-headers";
import { logger } from "hono/logger";

import type { AuthorService } from "../../domain/authors/ports";
import { authorRoutes } from "./authors/routes";
import { registerErrorHandler } from "./errors";
import { healthRoutes, type HealthPing } from "./health";
import { injectServices } from "./middleware";

/**
 * App-wide type for context variables.
 * Handlers access services via c.var.authorService — fully typed.
 */
export type AppEnv = {
  Variables: {
    authorService: AuthorService;
  };
};

export type AppContext = OpenAPIHono<AppEnv>;

export type AppDeps = {
  authorService: AuthorService;
  /** Readiness ping — typically `() => db.execute(sql`SELECT 1`)`. */
  healthPing: HealthPing;
};

/**
 * Creates the Hono app. Bootstrap (server.ts) never imports Hono/OpenAPIHono.
 */
export function createApp(deps: AppDeps): OpenAPIHono<AppEnv> {
  const app = new OpenAPIHono<AppEnv>();

  // Global middleware — order matters: CORS must come first
  app.use("*", cors({ origin: ["http://localhost:3000"] }));
  app.use("*", secureHeaders());
  app.use("*", logger());

  // DI middleware — sets services on context for all downstream handlers
  app.use("*", injectServices(deps.authorService));

  // Health endpoints (infrastructure — no domain)
  app.route("/", healthRoutes(deps.healthPing));

  // Domain routes — generates OpenAPI from createRoute() definitions
  app.route("/authors", authorRoutes());

  // OpenAPI document + Swagger UI
  app.doc("/openapi.json", {
    openapi: "3.0.0",
    info: { title: "Authors API", version: "1.0.0" },
  });
  app.get("/docs", swaggerUI({ url: "/openapi.json" }));

  // Error handler — runs after routes
  registerErrorHandler(app);

  return app;
}

/**
 * For tests: same app, no server binding. Pass a stub ping that always resolves.
 */
export function createTestApp(deps: AppDeps): OpenAPIHono<AppEnv> {
  return createApp(deps);
}
```

## Inbound: DI Middleware

```typescript
// src/inbound/http/middleware.ts
import { createMiddleware } from "hono/factory";
import type { AuthorService } from "../../domain/authors/ports";
import type { AppEnv } from "./app";

/**
 * Sets services on context variables for downstream handlers.
 * Type-safe: c.var.authorService is typed via AppEnv.
 */
export function injectServices(authorService: AuthorService) {
  return createMiddleware<AppEnv>(async (c, next) => {
    c.set("authorService", authorService);
    await next();
  });
}
```

## Inbound: Auth Middleware

```typescript
// src/inbound/http/auth.ts
/**
 * Auth lives entirely in the inbound layer. Domain never handles tokens.
 */
import { createMiddleware } from "hono/factory";
import { HTTPException } from "hono/http-exception";
import { verify } from "hono/jwt";

import type { AppEnv } from "./app";

type AuthEnv = AppEnv & {
  Variables: AppEnv["Variables"] & {
    userId: string;
  };
};

export function requireAuth(secret: string) {
  return createMiddleware<AuthEnv>(async (c, next) => {
    const authHeader = c.req.header("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      throw new HTTPException(401, { message: "Missing token" });
    }

    const token = authHeader.slice(7);
    try {
      const payload = await verify(token, secret);
      c.set("userId", payload.sub as string);
    } catch {
      throw new HTTPException(401, { message: "Invalid token" });
    }

    await next();
  });
}
```

## Inbound: Request / Response Schemas

```typescript
// src/inbound/http/authors/request.ts
// `z` from @hono/zod-openapi is the same Zod with .openapi() metadata extension.
import { z } from "@hono/zod-openapi";
import { AuthorName, type CreateAuthorRequest } from "../../../domain/authors/models";

/**
 * Zod schema for HTTP request body — decoupled from domain.
 * Validates shape at transport boundary. Domain validates business rules.
 */
export const createAuthorBodySchema = z.object({
  name: z.string().min(1, "name is required"),
});

export type CreateAuthorBody = z.infer<typeof createAuthorBodySchema>;

/**
 * Convert validated HTTP body into domain type.
 * AuthorName.create() enforces domain invariants (trimming, non-empty).
 */
export function toDomain(body: CreateAuthorBody): CreateAuthorRequest {
  return { name: AuthorName.create(body.name) };
}

/**
 * Pagination query params schema — maps to domain pagination.
 */
export const paginationSchema = z.object({
  cursor: z.string().nullish().transform(v => v ?? null),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
```

```typescript
// src/inbound/http/authors/response.ts
import type { Author } from "../../../domain/authors/models";

/**
 * Public API representation — never expose domain models directly.
 */
export interface AuthorResponse {
  id: string;
  name: string;
}

export function fromDomain(author: Author): AuthorResponse {
  return {
    id: author.id,
    name: author.name.value,
  };
}
```

## Inbound: Handlers (Routes with OpenAPI)

Routes use `@hono/zod-openapi` (`OpenAPIHono` + `createRoute`) so the OpenAPI
spec is generated from the same schemas that validate requests — no
separate API spec to drift from the implementation.

```typescript
// src/inbound/http/authors/routes.ts
import { createRoute, OpenAPIHono, z } from "@hono/zod-openapi";

import type { AppEnv } from "../app";
import {
  createAuthorBodySchema,
  paginationSchema,
  toDomain,
} from "./request";
import { fromDomain } from "./response";

const AuthorSchema = z.object({
  id: z.string().openapi({ example: "01HX9G..." }),
  name: z.string().openapi({ example: "Ada Lovelace" }),
}).openapi("Author");

const AuthorResultSchema = z.object({ data: AuthorSchema }).openapi("AuthorResult");

const AuthorPageSchema = z.object({
  data: z.array(AuthorSchema),
  next_cursor: z.string().nullable(),
  has_more: z.boolean(),
}).openapi("AuthorPage");

const ProblemSchema = z.object({
  type: z.string(),
  title: z.string(),
  status: z.number(),
  detail: z.string(),
}).openapi("ProblemDetails");

const createAuthorRoute = createRoute({
  method: "post",
  path: "/",
  tags: ["authors"],
  request: {
    body: { content: { "application/json": { schema: createAuthorBodySchema } } },
  },
  responses: {
    201: { content: { "application/json": { schema: AuthorResultSchema } }, description: "Created" },
    409: { content: { "application/json": { schema: ProblemSchema } }, description: "Duplicate" },
  },
});

const listAuthorsRoute = createRoute({
  method: "get",
  path: "/",
  tags: ["authors"],
  request: { query: paginationSchema },
  responses: {
    200: { content: { "application/json": { schema: AuthorPageSchema } }, description: "Page of authors" },
  },
});

const getAuthorRoute = createRoute({
  method: "get",
  path: "/{id}",
  tags: ["authors"],
  request: { params: z.object({ id: z.string() }) },
  responses: {
    200: { content: { "application/json": { schema: AuthorResultSchema } }, description: "Author" },
    404: { content: { "application/json": { schema: ProblemSchema } }, description: "Not found" },
  },
});

export function authorRoutes() {
  const app = new OpenAPIHono<AppEnv>();

  app.openapi(createAuthorRoute, async (c) => {
    const body = c.req.valid("json");
    const author = await c.var.authorService.createAuthor(toDomain(body));
    return c.json({ data: fromDomain(author) }, 201);
  });

  app.openapi(listAuthorsRoute, async (c) => {
    const { cursor, limit } = c.req.valid("query");
    const page = await c.var.authorService.listAuthors(cursor, limit);
    return c.json(
      {
        data: page.items.map(fromDomain),
        next_cursor: page.nextCursor,
        has_more: page.hasMore,
      },
      200,
    );
  });

  app.openapi(getAuthorRoute, async (c) => {
    const { id } = c.req.valid("param");
    const author = await c.var.authorService.findAuthor(id);
    if (!author) {
      return c.json(
        {
          type: "https://api.example.com/errors/not-found",
          title: "Not Found",
          status: 404,
          detail: `author with id "${id}" not found`,
        },
        404,
      );
    }
    return c.json({ data: fromDomain(author) }, 200);
  });

  return app;
}
```

## Inbound: API Error Handler (RFC 9457)

```typescript
// src/inbound/http/errors.ts
import type { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import {
  AuthorNameEmptyError,
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";
import type { AppEnv } from "./app";

interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail: string;
}

function problem(
  typeSlug: string,
  title: string,
  status: number,
  detail: string,
): ProblemDetails {
  return {
    type: `https://api.example.com/errors/${typeSlug}`,
    title,
    status,
    detail,
  };
}

export function registerErrorHandler(app: Hono<AppEnv>): void {
  app.onError((err, c) => {
    // Zod validation errors (thrown by zValidator)
    if (err instanceof HTTPException) {
      return c.json(
        problem(
          "validation-error",
          err.message || "Request Error",
          err.status,
          err.message,
        ),
        err.status as 400,
      );
    }

    // Domain errors — match on tag for exhaustive handling
    if (err instanceof DuplicateAuthorError) {
      return c.json(
        problem(
          "duplicate-author",
          "Conflict",
          409,
          err.message,
        ),
        409,
      );
    }

    if (err instanceof AuthorNameEmptyError) {
      return c.json(
        problem(
          "validation-error",
          "Unprocessable Entity",
          422,
          err.message,
        ),
        422,
      );
    }

    if (err instanceof UnknownAuthorError) {
      console.error("Unexpected error:", err.cause);
    } else {
      console.error("Unhandled error:", err);
    }

    return c.json(
      problem(
        "internal-error",
        "Internal Server Error",
        500,
        "An unexpected error occurred",
      ),
      500,
    );
  });
}
```

## Inbound: Response Helpers

```typescript
// src/inbound/http/response.ts

/**
 * Standard response wrappers.
 * Use these types for documenting the API contract — not required at runtime
 * since Hono's c.json() handles serialization directly.
 */
export interface ApiSuccess<T> {
  data: T;
}

export interface CursorPageResponse<T> {
  data: T[];
  next_cursor: string | null;
  has_more: boolean;
}
```

## Inbound: Healthcheck

```typescript
// src/inbound/http/health.ts
/**
 * Healthcheck is infrastructure — not a domain concern.
 * Wire directly in createApp. The readiness probe takes a small
 * "ping" callback so the inbound layer doesn't import drizzle/postgres directly.
 */
import { Hono } from "hono";

export type HealthPing = () => Promise<void>;

export function healthRoutes(ping: HealthPing) {
  const app = new Hono();

  // Liveness — is the process alive?
  app.get("/healthz", (c) => c.json({ status: "ok" }));

  // Readiness — can it serve traffic? Returns 503 if the DB is unreachable
  // so k8s/load balancers can drain a node before it accepts more traffic.
  app.get("/readyz", async (c) => {
    try {
      await ping();
      return c.json({ status: "ready" });
    } catch (err) {
      console.error("readiness check failed:", err);
      return c.json({ status: "not ready" }, 503);
    }
  });

  return app;
}

// In createApp(): pass a ping function constructed at bootstrap.
// e.g. `() => db.execute(sql`SELECT 1`).then(() => undefined)`
```

## Inbound: Task Handler (non-HTTP inbound adapter)

```typescript
// src/inbound/tasks/handler.ts
/**
 * Task queue handler — inbound adapter.
 * Same pattern as HTTP: typed payload -> toDomain() -> service -> ack.
 */
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { AuthorName } from "../../domain/authors/models";
import type { AppEnv } from "../http/app";

const syncAuthorPayloadSchema = z.object({
  author_name: z.string().min(1),
  source: z.string(),
});

export function taskRoutes() {
  const app = new Hono<AppEnv>();

  app.post(
    "/tasks/sync-author",
    zValidator("json", syncAuthorPayloadSchema),
    async (c) => {
      const payload = c.req.valid("json");
      const domainReq = { name: AuthorName.create(payload.author_name) };
      await c.var.authorService.createAuthor(domainReq);
      return c.json({ status: "ok" });
    },
  );

  return app;
}

// In createApp():
// app.route("/", taskRoutes());    // task queue endpoints
// app.route("/", webhookRoutes()); // webhook endpoints
```

---

## Outbound: Outbox Adapter (transactional, Drizzle)

The outbox row must be inserted inside the same `db.transaction` callback as the aggregate write. Drizzle's tx callback is the natural unit-of-work scope.

```typescript
// src/domain/shared/events.ts — plain data, no infra deps
export interface DomainEvent {
  readonly aggregateType: string;
  readonly aggregateId: string;
  readonly eventType: string;
  readonly payload: Record<string, unknown>;
}
```

```typescript
// src/domain/authors/ports.ts — port carries events to persist atomically
export interface AuthorRepository {
  createAuthor(
    req: CreateAuthorRequest,
    events: readonly DomainEvent[],
  ): Promise<Author>;
  // ...
}
```

```typescript
// src/outbound/postgres-author-repository.ts
import { authors, outbox } from "./schema";
import { currentTraceparent } from "./tracing";

export class PostgresAuthorRepository implements AuthorRepository {
  constructor(private readonly db: NodePgDatabase) {}

  async createAuthor(
    req: CreateAuthorRequest,
    events: readonly DomainEvent[],
  ): Promise<Author> {
    return this.db.transaction(async (tx) => {
      const [row] = await tx
        .insert(authors)
        .values({ id: crypto.randomUUID(), name: req.name.value })
        .returning();

      if (events.length > 0) {
        // Trace context captured at write time, not at relay time.
        const traceparent = currentTraceparent();
        await tx.insert(outbox).values(
          events.map((e) => ({
            id: crypto.randomUUID(),
            aggregateType: e.aggregateType,
            aggregateId: e.aggregateId,
            eventType: e.eventType,
            payload: e.payload,
            traceparent,
          })),
        );
      }

      return Author.from(row);
    });
  }
}
```

```typescript
// Application service composes the events
async createAuthor(req: CreateAuthorRequest): Promise<Author> {
  const events: DomainEvent[] = [{
    aggregateType: "author",
    aggregateId: req.name.value,
    eventType: "AuthorCreated",
    payload: { name: req.name.value },
  }];
  const author = await this.repo.createAuthor(req, events);
  await this.metrics.recordCreation();
  return author;
}
```

**Outbox relay** is a separate worker (a Node process, a Cloudflare Cron Worker, or a queue consumer). It polls `WHERE published_at IS NULL ORDER BY id LIMIT N`, publishes to the broker, and updates `published_at` on success. Failures move to a `outbox_dead` table after N attempts.

### Edge runtime gotcha (Cloudflare D1)

D1's transaction model is per-request and not transferable across `waitUntil` boundaries. If you defer the broker publish into `waitUntil`, the publish runs *outside* any tx — which is exactly what the outbox is for. Don't try to skip the outbox by using `waitUntil` directly; it loses durability if the worker is evicted before the publish completes.

### Common gotchas

- Don't make `Outbox` a separate port that takes a `tx` parameter — leaks Drizzle types into the domain. Keep both writes in the same adapter method.
- Don't publish to the broker inside the tx. Outbox relay is the only thing that talks to the broker.

---

## Outbound: Idempotency Store

A KV-shaped table keyed by `(scope, key)` with a unique constraint.

```typescript
// src/domain/shared/idempotency.ts
export type Acquire =
  | { tag: "new" }
  | { tag: "replay"; response: Uint8Array }
  | { tag: "conflict" };

export interface IdempotencyStore {
  acquire(scope: string, key: string, requestHash: string): Promise<Acquire>;
  store(scope: string, key: string, response: Uint8Array): Promise<void>;
}
```

```typescript
// src/outbound/postgres-idempotency.ts
export class PostgresIdempotencyStore implements IdempotencyStore {
  constructor(private readonly db: NodePgDatabase) {}

  async acquire(scope: string, key: string, hash: string): Promise<Acquire> {
    // Insert-or-fetch — unique (scope, key) collapses races to one winner.
    const inserted = await this.db
      .insert(idempotency)
      .values({ scope, key, requestHash: hash })
      .onConflictDoNothing()
      .returning({ ok: idempotency.scope });

    if (inserted.length === 1) return { tag: "new" };

    const [row] = await this.db
      .select()
      .from(idempotency)
      .where(and(eq(idempotency.scope, scope), eq(idempotency.key, key)));

    if (row.requestHash !== hash) return { tag: "conflict" };
    if (row.response) return { tag: "replay", response: row.response };
    return { tag: "new" }; // in-flight; caller blocks or 409
  }
  // store(...) updates the row with the response bytes.
}
```

---

## Outbound: Tracer Port (OTel)

Don't import `@opentelemetry/*` into the domain. Define a minimal interface; the OTel adapter implements it. Tests use a no-op or capturing adapter.

```typescript
// src/domain/shared/tracing.ts
export interface Span {
  addEvent(name: string, attrs?: Record<string, string>): void;
  recordError(err: unknown): void;
  end(): void;
}
export interface Tracer {
  startSpan(name: string, attrs?: Record<string, string>): Span;
}
```

The Node adapter (`src/outbound/otel.ts`) wraps `@opentelemetry/api`'s tracer.

**Edge variant** (Cloudflare Workers): wrap `otel-cf-workers` instead, or implement a minimal `Tracer` that emits spans via `fetch` to the OTel Collector. Same port, different adapter — no domain code changes. This is exactly the kind of swap the port abstraction earns its keep on.

For sampling, cardinality budgets, and span attribute conventions, see `software-architecture/references/observability.md`.
