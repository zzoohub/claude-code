# Examples: Adapters

Inbound (createApp, handlers, task handlers, auth, errors) and outbound (Drizzle, SQLite, mapper).

---

## Outbound: Drizzle Schema + Mapper

```typescript
// src/outbound/drizzle/schema.ts
import { sqliteTable, text } from "drizzle-orm/sqlite-core";

/**
 * Drizzle table definition — outbound only. Never import in domain.
 */
export const authors = sqliteTable("authors", {
  id: text("id").primaryKey(),
  name: text("name").notNull().unique(),
});

// For Postgres, use pgTable from drizzle-orm/pg-core:
// import { pgTable, text, uuid } from "drizzle-orm/pg-core";
// export const authors = pgTable("authors", {
//   id: uuid("id").primaryKey().defaultRandom(),
//   name: text("name").notNull().unique(),
// });
```

```typescript
// src/outbound/drizzle/mapper.ts
import { AuthorName } from "../../domain/authors/models";
import type { Author } from "../../domain/authors/models";

/**
 * DB row <-> domain translation. Keeps domain free from Drizzle.
 */
export class AuthorMapper {
  static toDomain(row: { id: string; name: string }): Author {
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

## Outbound: Drizzle Adapter (ORM + mapper)

```typescript
// src/outbound/drizzle/repository.ts
import { eq, asc, gt } from "drizzle-orm";
import type { BunSQLiteDatabase } from "drizzle-orm/bun-sqlite";
import { authors } from "./schema";
import { AuthorMapper } from "./mapper";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";
import type { Author, CreateAuthorRequest } from "../../domain/authors/models";
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
    const fetchLimit = limit + 1;

    const rows = cursor
      ? await this.db.select().from(authors).where(gt(authors.id, cursor)).orderBy(asc(authors.id)).limit(fetchLimit)
      : await this.db.select().from(authors).orderBy(asc(authors.id)).limit(fetchLimit);

    const hasMore = rows.length > limit;
    const items = rows.slice(0, limit).map(AuthorMapper.toDomain);
    const nextCursor = hasMore && items.length > 0 ? items[items.length - 1].id : null;

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
import { eq, asc, gt } from "drizzle-orm";
import type { NodePgDatabase } from "drizzle-orm/node-postgres";
import { authors } from "./schema";
import { AuthorMapper } from "./mapper";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";
import type { Author, CreateAuthorRequest } from "../../domain/authors/models";
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
      ? await this.db.select().from(authors).where(gt(authors.id, cursor)).orderBy(asc(authors.id)).limit(fetchLimit)
      : await this.db.select().from(authors).orderBy(asc(authors.id)).limit(fetchLimit);

    const hasMore = rows.length > limit;
    const items = rows.slice(0, limit).map(AuthorMapper.toDomain);
    const nextCursor = hasMore && items.length > 0 ? items[items.length - 1].id : null;

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
import type { Author, CreateAuthorRequest } from "../../domain/authors/models";
import type { AuthorRepository } from "../../domain/authors/ports";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";

/**
 * Raw SQL — demonstrates that adapters choose their own data access strategy.
 */
export class SqliteAuthorRepository implements AuthorRepository {
  constructor(private readonly db: Database) {}

  static fromClient(db: Database): SqliteAuthorRepository {
    return new SqliteAuthorRepository(db);
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    const id = crypto.randomUUID();
    try {
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
      .prepare("SELECT id, name FROM authors WHERE id = ?")
      .get(authorId) as { id: string; name: string } | null;
    if (!row) return null;
    return { id: row.id, name: AuthorName.create(row.name) };
  }

  async listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>> {
    const fetchLimit = limit + 1;
    const rows = cursor
      ? (this.db
          .prepare("SELECT id, name FROM authors WHERE id > ? ORDER BY id ASC LIMIT ?")
          .all(cursor, fetchLimit) as { id: string; name: string }[])
      : (this.db
          .prepare("SELECT id, name FROM authors ORDER BY id ASC LIMIT ?")
          .all(fetchLimit) as { id: string; name: string }[]);

    const hasMore = rows.length > limit;
    const items = rows.slice(0, limit).map((r) => ({
      id: r.id,
      name: AuthorName.create(r.name),
    }));
    const nextCursor = hasMore && items.length > 0 ? items[items.length - 1].id : null;

    return { items, nextCursor, hasMore };
  }
}
```

---

## Inbound: createApp (wraps Hono)

```typescript
// src/inbound/http/app.ts
import { Hono } from "hono";
import { cors } from "hono/cors";
import { secureHeaders } from "hono/secure-headers";
import { logger } from "hono/logger";

import type { AuthorService } from "../../domain/authors/ports";
import { authorRoutes } from "./authors/routes";
import { registerErrorHandler } from "./errors";
import { healthRoutes } from "./health";
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

export type AppContext = Hono<AppEnv>;

/**
 * Creates the Hono app. Bootstrap (server.ts) never imports Hono.
 */
export function createApp(authorService: AuthorService): Hono<AppEnv> {
  const app = new Hono<AppEnv>();

  // Global middleware — order matters: CORS must come first
  app.use("*", cors({ origin: ["http://localhost:3000"] }));
  app.use("*", secureHeaders());
  app.use("*", logger());

  // DI middleware — sets services on context for all downstream handlers
  app.use("*", injectServices(authorService));

  // Health endpoints (infrastructure — no domain)
  app.route("/", healthRoutes());

  // Domain routes
  app.route("/authors", authorRoutes());

  // Error handler
  registerErrorHandler(app);

  return app;
}

/**
 * For tests: same app, no server binding.
 */
export function createTestApp(authorService: AuthorService): Hono<AppEnv> {
  return createApp(authorService);
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
import { z } from "zod";
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

## Inbound: Handlers (Routes)

```typescript
// src/inbound/http/authors/routes.ts
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";

import type { AppEnv } from "../app";
import { createAuthorBodySchema, paginationSchema, toDomain } from "./request";
import { fromDomain } from "./response";

/**
 * Author routes as a sub-application.
 * Each handler: parse -> call service -> map response.
 */
export function authorRoutes() {
  const app = new Hono<AppEnv>();

  // POST /authors
  app.post(
    "/",
    zValidator("json", createAuthorBodySchema),
    async (c) => {
      const body = c.req.valid("json");
      const domainReq = toDomain(body);
      const author = await c.var.authorService.createAuthor(domainReq);
      return c.json({ data: fromDomain(author) }, 201);
    },
  );

  // GET /authors
  app.get(
    "/",
    zValidator("query", paginationSchema),
    async (c) => {
      const { cursor, limit } = c.req.valid("query");
      const page = await c.var.authorService.listAuthors(cursor, limit);
      return c.json({
        data: page.items.map(fromDomain),
        next_cursor: page.nextCursor,
        has_more: page.hasMore,
      });
    },
  );

  // GET /authors/:id
  app.get("/:id", async (c) => {
    const id = c.req.param("id");
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
    return c.json({ data: fromDomain(author) });
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
 * Wire directly in createApp, no service needed.
 */
import { Hono } from "hono";

export function healthRoutes() {
  const app = new Hono();

  // Liveness — is the process alive?
  app.get("/healthz", (c) => c.json({ status: "ok" }));

  // Readiness — can it serve traffic?
  // In real apps: check DB connectivity, external service health
  app.get("/readyz", async (c) => {
    // Example: await db.execute(sql`SELECT 1`);
    return c.json({ status: "ready" });
  });

  return app;
}
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
