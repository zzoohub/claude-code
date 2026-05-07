# Examples: Bootstrap & Testing

Config, server entry points, multi-runtime adapters, Drizzle Kit setup, and hex-specific test mocks.

---

## Config

```typescript
// src/app/config.ts
import { z } from "zod";

/**
 * Typed config — validates env once at startup.
 * No Hono, no Drizzle imports.
 */
const configSchema = z.object({
  DATABASE_URL: z.string().min(1),
  PORT: z.coerce.number().default(3000),
  CORS_ORIGIN: z.string().default("http://localhost:3000"),
  JWT_SECRET: z.string().min(16),
});

export type AppConfig = z.infer<typeof configSchema>;

export function loadConfig(): AppConfig {
  return configSchema.parse(process.env);
}

// For Bun: process.env works natively.
// For Cloudflare Workers: pass c.env from handler, don't use process.env.
```

## Bootstrap (Bun)

```typescript
// src/app/server.ts — no Hono, no Drizzle imports
import { sql } from "drizzle-orm";
import { loadConfig } from "./config";
import { AuthorServiceImpl } from "../domain/authors/service";
import { createApp } from "../inbound/http/app";
import { DrizzleAuthorRepository } from "../outbound/drizzle/repository";
import { NoOpMetrics, NoOpNotifier } from "../outbound/noop";
import { createDb } from "../outbound/drizzle/client";

const config = loadConfig();
const db = createDb(config.DATABASE_URL);
const repo = DrizzleAuthorRepository.fromClient(db);
const service = new AuthorServiceImpl(repo, new NoOpMetrics(), new NoOpNotifier());
const app = createApp({
  authorService: service,
  healthPing: async () => { await db.run(sql`SELECT 1`); },
});

export default {
  fetch: app.fetch,
  port: config.PORT,
};
```

## Bootstrap (Node.js)

```typescript
// src/app/server.ts — Node.js with @hono/node-server
import { serve } from "@hono/node-server";
import { sql } from "drizzle-orm";
import { loadConfig } from "./config";
import { AuthorServiceImpl } from "../domain/authors/service";
import { createApp } from "../inbound/http/app";
import { DrizzleAuthorRepository } from "../outbound/drizzle/repository";
import { NoOpMetrics, NoOpNotifier } from "../outbound/noop";
import { createDb } from "../outbound/drizzle/client";

const config = loadConfig();
const db = createDb(config.DATABASE_URL);
const repo = DrizzleAuthorRepository.fromClient(db);
const service = new AuthorServiceImpl(repo, new NoOpMetrics(), new NoOpNotifier());
const app = createApp({
  authorService: service,
  healthPing: async () => { await db.execute(sql`SELECT 1`); },
});

serve(
  { fetch: app.fetch, port: config.PORT },
  (info) => {
    console.log(`Server running at http://localhost:${info.port}`);
  },
);

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down...");
  process.exit(0);
});
process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down...");
  process.exit(0);
});
```

## Bootstrap (Cloudflare Workers)

Cloudflare bindings are per-request (`c.env`), so the worker entry point has
to construct adapters inside a request handler. To keep `src/app/` free of
Hono/Drizzle imports (the hex rule), put the wiring in
`src/inbound/http/cloudflare.ts` and re-export from `src/app/server.ts`.

```typescript
// src/inbound/http/cloudflare.ts — inbound layer (allowed to import Hono/D1)
import { drizzle } from "drizzle-orm/d1";
import { sql } from "drizzle-orm";
import { AuthorServiceImpl } from "../../domain/authors/service";
import { DrizzleAuthorRepository } from "../../outbound/drizzle/repository";
import { NoOpMetrics, NoOpNotifier } from "../../outbound/noop";
import * as schema from "../../outbound/drizzle/schema";
import { createApp } from "./app";

export type Bindings = {
  DB: D1Database;
  JWT_SECRET: string;
};

export default {
  async fetch(req: Request, env: Bindings, ctx: ExecutionContext): Promise<Response> {
    const db = drizzle(env.DB, { schema });
    const repo = DrizzleAuthorRepository.fromClient(db);
    const service = new AuthorServiceImpl(repo, new NoOpMetrics(), new NoOpNotifier());
    const app = createApp({
      authorService: service,
      healthPing: async () => { await db.run(sql`SELECT 1`); },
    });
    return app.fetch(req, env, ctx);
  },
};
```

```typescript
// src/app/server.ts — bootstrap stays free of framework imports
export { default } from "../inbound/http/cloudflare";
```

## Drizzle Client Factory

```typescript
// src/outbound/drizzle/client.ts
import { drizzle } from "drizzle-orm/bun-sqlite";
import { Database } from "bun:sqlite";
import * as schema from "./schema";

export function createDb(url: string) {
  const sqlite = new Database(url);
  sqlite.run("PRAGMA journal_mode = WAL;");
  sqlite.run("PRAGMA foreign_keys = ON;");
  return drizzle(sqlite, { schema });
}

// For Postgres with node-postgres:
// import { drizzle } from "drizzle-orm/node-postgres";
// import { Pool } from "pg";
// export function createDb(url: string) {
//   const pool = new Pool({ connectionString: url, max: 10 });
//   return drizzle(pool, { schema });
// }

// For Postgres with postgres.js (Bun/Node):
// import { drizzle } from "drizzle-orm/postgres-js";
// import postgres from "postgres";
// export function createDb(url: string) {
//   const sql = postgres(url, { max: 10, idle_timeout: 20, connect_timeout: 3 });
//   return drizzle(sql, { schema });
// }
```

## NoOp Adapters

```typescript
// src/outbound/noop.ts
import type { AuthorMetrics, AuthorNotifier } from "../domain/authors/ports";
import type { Author } from "../domain/authors/models";

/**
 * No-op implementations for metrics/notifications.
 * Used when you don't need real observability (dev, simple deploys).
 */
export class NoOpMetrics implements AuthorMetrics {
  async recordCreationSuccess(): Promise<void> {}
  async recordCreationFailure(): Promise<void> {}
}

export class NoOpNotifier implements AuthorNotifier {
  async authorCreated(_author: Author): Promise<void> {}
}
```

---

## Drizzle Kit Migrations

Migrations are infrastructure — they live outside the hex layers alongside config.

### drizzle.config.ts

```typescript
// drizzle.config.ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/outbound/drizzle/schema.ts",
  out: "./drizzle/migrations",
  dialect: "sqlite",
  // For Postgres:
  // dialect: "postgresql",
  // dbCredentials: { url: process.env.DATABASE_URL! },
});
```

### Usage

```bash
# Generate migration from schema changes
bun drizzle-kit generate

# Apply migrations
bun drizzle-kit migrate

# Open Drizzle Studio (visual DB browser)
bun drizzle-kit studio
```

---

## package.json

```json
{
  "name": "myapp",
  "type": "module",
  "scripts": {
    "dev": "bun --hot src/app/server.ts",
    "start": "bun src/app/server.ts",
    "test": "bun test",
    "db:generate": "bun drizzle-kit generate",
    "db:migrate": "bun drizzle-kit migrate",
    "db:studio": "bun drizzle-kit studio"
  },
  "dependencies": {
    "hono": "^4.7",
    "@hono/zod-openapi": "^0.18",
    "@hono/swagger-ui": "^0.5",
    "@hono/zod-validator": "^0.5",
    "zod": "^3.24",
    "drizzle-orm": "^0.39",
    "@node-rs/argon2": "^2.0",
    "jose": "^6.0"
  },
  "devDependencies": {
    "drizzle-kit": "^0.30",
    "typescript": "^5.7",
    "@types/bun": "latest"
  }
}
```

For Node.js, also add:
```json
{
  "dependencies": {
    "@hono/node-server": "^1.14"
  }
}
```

```bash
bun install                    # install all deps
bun run dev                    # hot-reload development
bun test                       # run tests
bun add some-package           # add dependency
bun add -d some-tool           # add dev dependency
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

### Mocks (Interface-compatible, no framework needed)

```typescript
// tests/mocks.ts
import type {
  Author,
  CreateAuthorRequest,
  CursorPage,
} from "../src/domain/authors/models";
import type {
  AuthorRepository,
  AuthorMetrics,
  AuthorNotifier,
  AuthorService,
} from "../src/domain/authors/ports";
import {
  UnknownAuthorError,
  type CreateAuthorError,
} from "../src/domain/authors/errors";

/**
 * Stub — returns configured results.
 */
export class MockAuthorRepository implements AuthorRepository {
  createCalls: CreateAuthorRequest[] = [];

  constructor(
    private createResult?: Author | CreateAuthorError,
  ) {}

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    this.createCalls.push(req);
    if (this.createResult instanceof Error) {
      throw this.createResult;
    }
    return this.createResult!;
  }

  async findAuthor(_id: string): Promise<Author | null> {
    return null;
  }

  async listAuthors(
    _cursor: string | null,
    _limit: number,
  ): Promise<CursorPage<Author>> {
    return { items: [], nextCursor: null, hasMore: false };
  }
}

/**
 * Saboteur — always throws to test error paths.
 */
export class SaboteurRepository implements AuthorRepository {
  constructor(private error?: Error) {}

  async createAuthor(_req: CreateAuthorRequest): Promise<Author> {
    throw this.error ?? new UnknownAuthorError(new Error("db on fire"));
  }

  async findAuthor(_id: string): Promise<Author | null> {
    throw this.error ?? new UnknownAuthorError(new Error("db on fire"));
  }

  async listAuthors(
    _cursor: string | null,
    _limit: number,
  ): Promise<CursorPage<Author>> {
    throw this.error ?? new UnknownAuthorError(new Error("db on fire"));
  }
}

/**
 * Spy — counts side effects.
 */
export class SpyMetrics implements AuthorMetrics {
  successes = 0;
  failures = 0;

  async recordCreationSuccess(): Promise<void> {
    this.successes++;
  }
  async recordCreationFailure(): Promise<void> {
    this.failures++;
  }
}

export class SpyNotifier implements AuthorNotifier {
  notifications: Author[] = [];

  async authorCreated(author: Author): Promise<void> {
    this.notifications.push(author);
  }
}

/**
 * NoOp — for E2E tests where side effects don't matter.
 */
export class NoOpMetrics implements AuthorMetrics {
  async recordCreationSuccess(): Promise<void> {}
  async recordCreationFailure(): Promise<void> {}
}

export class NoOpNotifier implements AuthorNotifier {
  async authorCreated(_author: Author): Promise<void> {}
}
```

### Test App Helper

```typescript
// tests/helpers.ts
import { createTestApp } from "../src/inbound/http/app";
import { AuthorServiceImpl } from "../src/domain/authors/service";
import type { AuthorRepository, AuthorService } from "../src/domain/authors/ports";
import { NoOpMetrics, NoOpNotifier } from "./mocks";

/**
 * Build a test app with a given repository.
 * Uses app.request() — Hono's built-in test utility.
 * Stub healthPing always succeeds in tests.
 */
export function buildTestApp(repo: AuthorRepository) {
  const service = new AuthorServiceImpl(repo, new NoOpMetrics(), new NoOpNotifier());
  return createTestApp({ authorService: service, healthPing: async () => {} });
}

/**
 * Build a test app with a mock service directly.
 * Use when testing handler behavior in isolation.
 */
export function buildTestAppWithService(service: AuthorService) {
  return createTestApp({ authorService: service, healthPing: async () => {} });
}
```

### Handler Tests (app.request)

```typescript
// tests/handlers.test.ts
import { describe, it, expect } from "bun:test";
import { buildTestApp } from "./helpers";
import { MockAuthorRepository } from "./mocks";
import { AuthorName } from "../src/domain/authors/models";
import { DuplicateAuthorError } from "../src/domain/authors/errors";

describe("POST /authors", () => {
  it("creates an author and returns 201", async () => {
    const author = { id: "123", name: AuthorName.create("Alice") };
    const repo = new MockAuthorRepository(author);
    const app = buildTestApp(repo);

    const res = await app.request("/authors", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Alice" }),
    });

    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.data.name).toBe("Alice");
    expect(repo.createCalls).toHaveLength(1);
  });

  it("returns 409 for duplicate author", async () => {
    const repo = new MockAuthorRepository(
      new DuplicateAuthorError("Alice"),
    );
    const app = buildTestApp(repo);

    const res = await app.request("/authors", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Alice" }),
    });

    expect(res.status).toBe(409);
    const body = await res.json();
    expect(body.type).toContain("duplicate-author");
  });

  it("returns 400 for empty name (Zod validation)", async () => {
    const repo = new MockAuthorRepository();
    const app = buildTestApp(repo);

    const res = await app.request("/authors", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "" }),
    });

    // zValidator returns 400 by default for Zod failures
    expect(res.status).toBe(400);
  });
});

describe("GET /authors", () => {
  it("returns empty list with pagination", async () => {
    const repo = new MockAuthorRepository();
    const app = buildTestApp(repo);

    const res = await app.request("/authors?limit=10");

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data).toEqual([]);
    expect(body.has_more).toBe(false);
  });
});
```

### Service Tests (unit tests with mocks)

```typescript
// tests/service.test.ts
import { describe, it, expect } from "bun:test";
import { AuthorServiceImpl } from "../src/domain/authors/service";
import { AuthorName } from "../src/domain/authors/models";
import { DuplicateAuthorError, UnknownAuthorError } from "../src/domain/authors/errors";
import { MockAuthorRepository, SpyMetrics, SpyNotifier, SaboteurRepository } from "./mocks";

describe("AuthorServiceImpl", () => {
  it("creates author, records success, notifies", async () => {
    const author = { id: "1", name: AuthorName.create("Alice") };
    const repo = new MockAuthorRepository(author);
    const metrics = new SpyMetrics();
    const notifier = new SpyNotifier();
    const service = new AuthorServiceImpl(repo, metrics, notifier);

    const result = await service.createAuthor({ name: AuthorName.create("Alice") });

    expect(result.name.value).toBe("Alice");
    expect(metrics.successes).toBe(1);
    expect(metrics.failures).toBe(0);
    expect(notifier.notifications).toHaveLength(1);
  });

  it("records failure on duplicate", async () => {
    const repo = new MockAuthorRepository(new DuplicateAuthorError("Alice"));
    const metrics = new SpyMetrics();
    const notifier = new SpyNotifier();
    const service = new AuthorServiceImpl(repo, metrics, notifier);

    try {
      await service.createAuthor({ name: AuthorName.create("Alice") });
    } catch (e) {
      expect(e).toBeInstanceOf(DuplicateAuthorError);
    }
    expect(metrics.failures).toBe(1);
    expect(notifier.notifications).toHaveLength(0);
  });

  it("wraps unknown errors", async () => {
    const repo = new SaboteurRepository();
    const metrics = new SpyMetrics();
    const notifier = new SpyNotifier();
    const service = new AuthorServiceImpl(repo, metrics, notifier);

    try {
      await service.createAuthor({ name: AuthorName.create("Bob") });
    } catch (e) {
      expect(e).toBeInstanceOf(UnknownAuthorError);
    }
  });
});
```

### Integration Tests (real DB)

```typescript
// tests/integration.test.ts
import { describe, it, expect, beforeEach } from "bun:test";
import { Database } from "bun:sqlite";
import { drizzle } from "drizzle-orm/bun-sqlite";
import * as schema from "../src/outbound/drizzle/schema";
import { DrizzleAuthorRepository } from "../src/outbound/drizzle/repository";
import { AuthorName } from "../src/domain/authors/models";
import { DuplicateAuthorError } from "../src/domain/authors/errors";

function createTestDb() {
  const sqlite = new Database(":memory:");
  sqlite.run(`
    CREATE TABLE authors (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      created_at INTEGER NOT NULL DEFAULT (unixepoch())
    );
    CREATE INDEX idx_authors_created_at_id ON authors(created_at, id);
  `);
  return drizzle(sqlite, { schema });
}

describe("DrizzleAuthorRepository", () => {
  let repo: DrizzleAuthorRepository;

  beforeEach(() => {
    const db = createTestDb();
    repo = DrizzleAuthorRepository.fromClient(db);
  });

  it("creates and finds an author", async () => {
    const author = await repo.createAuthor({ name: AuthorName.create("Alice") });
    expect(author.name.value).toBe("Alice");

    const found = await repo.findAuthor(author.id);
    expect(found).not.toBeNull();
    expect(found!.name.value).toBe("Alice");
  });

  it("throws DuplicateAuthorError on unique constraint", async () => {
    await repo.createAuthor({ name: AuthorName.create("Alice") });
    try {
      await repo.createAuthor({ name: AuthorName.create("Alice") });
      expect(true).toBe(false); // should not reach here
    } catch (e) {
      expect(e).toBeInstanceOf(DuplicateAuthorError);
    }
  });

  it("lists authors with cursor pagination", async () => {
    await repo.createAuthor({ name: AuthorName.create("Alice") });
    await repo.createAuthor({ name: AuthorName.create("Bob") });
    await repo.createAuthor({ name: AuthorName.create("Charlie") });

    const page1 = await repo.listAuthors(null, 2);
    expect(page1.items).toHaveLength(2);
    expect(page1.hasMore).toBe(true);
    expect(page1.nextCursor).not.toBeNull();

    const page2 = await repo.listAuthors(page1.nextCursor, 2);
    expect(page2.items).toHaveLength(1);
    expect(page2.hasMore).toBe(false);
  });
});
```

---

## tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "rootDir": "src",
    "declaration": true,
    "paths": {
      "~/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "drizzle"]
}
```

Key: `"strict": true` is required for RPC type inference and `testClient` types to work.
