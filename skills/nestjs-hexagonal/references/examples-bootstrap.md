# Examples: Bootstrap & Testing

Config, main.ts, module wiring, Drizzle/Mongoose setup, and hex-specific test mocks.

---

## Config

```typescript
// src/config.ts
import { z } from "zod";

/**
 * Typed config — validates env once at startup.
 * Include DATABASE_URL for SQL or MONGODB_URI for MongoDB (or both).
 */
const configSchema = z.object({
  DATABASE_URL: z.string().min(1).optional(),    // Drizzle (SQL)
  MONGODB_URI: z.string().min(1).optional(),     // Mongoose (MongoDB)
  PORT: z.coerce.number().default(3000),
  CORS_ORIGIN: z.string().default("http://localhost:3000"),
  JWT_SECRET: z.string().min(16),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
}).refine(
  (c) => c.DATABASE_URL || c.MONGODB_URI,
  { message: "At least one of DATABASE_URL or MONGODB_URI must be set" },
);

export type AppConfig = z.infer<typeof configSchema>;

export function validateConfig(config: Record<string, unknown>): AppConfig {
  return configSchema.parse(config);
}
```

## Bootstrap (main.ts)

```typescript
// src/main.ts
import { NestFactory } from "@nestjs/core";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import helmet from "helmet";
import { AppModule } from "./app.module";
import { DomainExceptionFilter } from "./inbound/http/filters/domain-exception.filter";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security
  app.use(helmet());
  app.enableCors({ origin: [process.env.CORS_ORIGIN ?? "http://localhost:3000"] });

  // Global exception filter — maps domain errors to RFC 9457
  app.useGlobalFilters(new DomainExceptionFilter());

  // Swagger
  const config = new DocumentBuilder()
    .setTitle("Author API")
    .setVersion("1")
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup("docs", app, document);

  // Graceful shutdown — triggers onModuleDestroy
  app.enableShutdownHooks();

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
}
bootstrap();
```

## Root Module (AppModule)

```typescript
// src/app.module.ts
import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { TerminusModule } from "@nestjs/terminus";
import { validateConfig } from "./config";

// Pick ONE persistence module:
import { DrizzlePersistenceModule } from "./outbound/drizzle/drizzle.module";
// import { MongoosePersistenceModule } from "./outbound/mongoose/mongoose.module";

import { AuthorsModule } from "./authors.module";
import { HealthController } from "./inbound/http/health/health.controller";

@Module({
  imports: [
    ConfigModule.forRoot({ validate: validateConfig, isGlobal: true }),
    DrizzlePersistenceModule,       // SQL
    // MongoosePersistenceModule,    // MongoDB — swap by toggling these
    TerminusModule,
    AuthorsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
```

## Feature Module (AuthorsModule)

```typescript
// src/authors.module.ts
import { Module } from "@nestjs/common";
import { AuthorsController } from "./inbound/http/authors/authors.controller";
import { AuthorService, AuthorRepository, AuthorMetrics, AuthorNotifier } from "./domain/authors/ports";
import { AuthorServiceImpl } from "./domain/authors/service";
import { NoOpMetrics, NoOpNotifier } from "./outbound/noop";

/**
 * Feature module: wires controller + service.
 * AuthorRepository comes from the persistence module (@Global).
 * Service is wired via useFactory — keeps domain free from @Injectable().
 */
@Module({
  controllers: [AuthorsController],
  providers: [
    { provide: AuthorMetrics, useClass: NoOpMetrics },
    { provide: AuthorNotifier, useClass: NoOpNotifier },
    {
      provide: AuthorService,
      useFactory: (
        repo: AuthorRepository,
        metrics: AuthorMetrics,
        notifier: AuthorNotifier,
      ) => new AuthorServiceImpl(repo, metrics, notifier),
      inject: [AuthorRepository, AuthorMetrics, AuthorNotifier],
    },
  ],
  exports: [AuthorService],
})
export class AuthorsModule {}
```

## NoOp Adapters

```typescript
// src/outbound/noop.ts
import { Injectable } from "@nestjs/common";
import { AuthorMetrics, AuthorNotifier } from "../domain/authors/ports";
import type { Author } from "../domain/authors/models";

@Injectable()
export class NoOpMetrics extends AuthorMetrics {
  async recordCreationSuccess(): Promise<void> {}
  async recordCreationFailure(): Promise<void> {}
}

@Injectable()
export class NoOpNotifier extends AuthorNotifier {
  async authorCreated(_author: Author): Promise<void> {}
}
```

---

## Drizzle Kit Config + Migrations

```typescript
// drizzle.config.ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/outbound/drizzle/schema.ts",
  out: "./drizzle/migrations",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DATABASE_URL! },
});
```

```bash
bunx drizzle-kit generate    # Generate migration from schema changes
bunx drizzle-kit migrate     # Apply migrations
bunx drizzle-kit studio      # Visual DB browser
```

---

## package.json

### SQL variant (Drizzle + PostgreSQL)

```json
{
  "name": "myapp",
  "private": true,
  "scripts": {
    "build": "nest build",
    "dev": "nest start --watch",
    "start": "node dist/main.js",
    "test": "jest",
    "test:e2e": "jest --config jest-e2e.json",
    "db:generate": "bunx drizzle-kit generate",
    "db:migrate": "bunx drizzle-kit migrate",
    "db:studio": "bunx drizzle-kit studio"
  },
  "dependencies": {
    "@nestjs/common": "^10.0",
    "@nestjs/core": "^10.0",
    "@nestjs/platform-express": "^10.0",
    "@nestjs/config": "^3.0",
    "@nestjs/swagger": "^7.0",
    "@nestjs/terminus": "^10.0",
    "@nestjs/passport": "^10.0",
    "drizzle-orm": "^0.39",
    "pg": "^8.13",
    "passport": "^0.7",
    "passport-jwt": "^4.0",
    "zod": "^3.24",
    "helmet": "^8.0",
    "reflect-metadata": "^0.2",
    "rxjs": "^7.0"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0",
    "@nestjs/testing": "^10.0",
    "drizzle-kit": "^0.30",
    "typescript": "^5.7",
    "jest": "^29.0",
    "@types/jest": "^29.0",
    "ts-jest": "^29.0",
    "@types/express": "^4.0",
    "@types/pg": "^8.0"
  }
}
```

### MongoDB variant (Mongoose)

Replace the Drizzle deps with:

```json
{
  "dependencies": {
    "@nestjs/mongoose": "^10.0",
    "mongoose": "^8.0"
  }
}
```

Remove `drizzle-orm`, `drizzle-kit`, `pg`, and the `db:*` scripts.

```bash
bun install                    # install all deps
bun run dev                    # watch mode development
bun run test                   # run unit tests
```

---

## tsconfig.json

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2022",
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strict": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "forceConsistentCasingInFileNames": true,
    "paths": { "~/*": ["./src/*"] }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "drizzle"]
}
```

Key: `emitDecoratorMetadata` and `experimentalDecorators` are required for NestJS DI.

---

## Testing: Hex-Specific Mocks

### Strategy

| Layer | Mock | What to test |
|-------|------|--------------|
| Controller | Mock service | HTTP parsing, status codes, error format |
| Service | Mock repo/metrics/notifier | Orchestration, side-effect ordering |
| Repository | Real DB | SQL/queries, error mapping, transactions |
| E2E | Nothing mocked | Critical happy paths |

### Mocks (extend abstract port classes)

```typescript
// tests/mocks.ts
import type { Author, CreateAuthorRequest } from "../src/domain/authors/models";
import {
  AuthorRepository, AuthorMetrics, AuthorNotifier, AuthorService,
} from "../src/domain/authors/ports";
import { UnknownAuthorError } from "../src/domain/authors/errors";

/** Stub — returns configured results. */
export class MockAuthorRepository extends AuthorRepository {
  createCalls: CreateAuthorRequest[] = [];
  constructor(private createResult?: Author | Error) { super(); }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    this.createCalls.push(req);
    if (this.createResult instanceof Error) throw this.createResult;
    return this.createResult!;
  }
  async findAuthor(_id: string): Promise<Author | null> { return null; }
  async listAuthors(_p: number, _ps: number): Promise<{ items: Author[]; total: number }> {
    return { items: [], total: 0 };
  }
}

/** Saboteur — always throws to test error paths. */
export class SaboteurRepository extends AuthorRepository {
  constructor(private error?: Error) { super(); }
  async createAuthor(_req: CreateAuthorRequest): Promise<Author> {
    throw this.error ?? new UnknownAuthorError(new Error("db on fire"));
  }
  async findAuthor(_id: string): Promise<Author | null> {
    throw this.error ?? new UnknownAuthorError(new Error("db on fire"));
  }
  async listAuthors(_p: number, _ps: number): Promise<{ items: Author[]; total: number }> {
    throw this.error ?? new UnknownAuthorError(new Error("db on fire"));
  }
}

/** Spy — counts side effects. */
export class SpyMetrics extends AuthorMetrics {
  successes = 0; failures = 0;
  async recordCreationSuccess(): Promise<void> { this.successes++; }
  async recordCreationFailure(): Promise<void> { this.failures++; }
}

export class SpyNotifier extends AuthorNotifier {
  notifications: Author[] = [];
  async authorCreated(author: Author): Promise<void> { this.notifications.push(author); }
}

/** NoOp — for E2E tests where side effects don't matter. */
export class NoOpMockMetrics extends AuthorMetrics {
  async recordCreationSuccess(): Promise<void> {}
  async recordCreationFailure(): Promise<void> {}
}
export class NoOpMockNotifier extends AuthorNotifier {
  async authorCreated(_author: Author): Promise<void> {}
}
```

### Test Module Helper

```typescript
// tests/helpers.ts
import { Test, type TestingModule } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { AppModule } from "../src/app.module";
import { AuthorRepository } from "../src/domain/authors/ports";
import { DomainExceptionFilter } from "../src/inbound/http/filters/domain-exception.filter";
import type { MockAuthorRepository } from "./mocks";

/**
 * Build a test app with overridden providers.
 * Uses the real AppModule but swaps adapters via overrideProvider().
 */
export async function createTestApp(overrides?: {
  repo?: MockAuthorRepository;
}): Promise<{ app: INestApplication; module: TestingModule }> {
  let builder = Test.createTestingModule({ imports: [AppModule] });

  if (overrides?.repo) {
    builder = builder.overrideProvider(AuthorRepository).useValue(overrides.repo);
  }

  const module = await builder.compile();
  const app = module.createNestApplication();
  app.useGlobalFilters(new DomainExceptionFilter());
  await app.init();
  return { app, module };
}
```

### Controller Tests (supertest)

```typescript
// tests/controllers/authors.controller.spec.ts
import * as request from "supertest";
import { AuthorName } from "../../src/domain/authors/models";
import { DuplicateAuthorError } from "../../src/domain/authors/errors";
import { createTestApp } from "../helpers";
import { MockAuthorRepository } from "../mocks";
import type { INestApplication } from "@nestjs/common";

describe("AuthorsController", () => {
  let app: INestApplication;
  afterEach(async () => { await app?.close(); });

  describe("POST /v1/authors", () => {
    it("creates an author and returns 201", async () => {
      const author = { id: "123", name: AuthorName.create("Alice") };
      const repo = new MockAuthorRepository(author);
      ({ app } = await createTestApp({ repo }));

      const res = await request(app.getHttpServer())
        .post("/v1/authors").send({ name: "Alice" }).expect(201);

      expect(res.body.data.name).toBe("Alice");
      expect(repo.createCalls).toHaveLength(1);
    });

    it("returns 422 for duplicate author", async () => {
      const repo = new MockAuthorRepository(new DuplicateAuthorError("Alice"));
      ({ app } = await createTestApp({ repo }));

      const res = await request(app.getHttpServer())
        .post("/v1/authors").send({ name: "Alice" }).expect(422);
      expect(res.body.type).toContain("duplicate-author");
    });

    it("returns 400 for empty name (Zod validation)", async () => {
      const repo = new MockAuthorRepository();
      ({ app } = await createTestApp({ repo }));
      await request(app.getHttpServer())
        .post("/v1/authors").send({ name: "" }).expect(400);
    });
  });

  describe("GET /v1/authors", () => {
    it("returns empty list with pagination", async () => {
      const repo = new MockAuthorRepository();
      ({ app } = await createTestApp({ repo }));

      const res = await request(app.getHttpServer())
        .get("/v1/authors?page=1&page_size=10").expect(200);
      expect(res.body.data).toEqual([]);
      expect(res.body.total).toBe(0);
    });
  });
});
```

### Service Tests (unit tests with mocks)

```typescript
// tests/services/author.service.spec.ts
import { AuthorServiceImpl } from "../../src/domain/authors/service";
import { AuthorName } from "../../src/domain/authors/models";
import { DuplicateAuthorError, UnknownAuthorError } from "../../src/domain/authors/errors";
import { MockAuthorRepository, SpyMetrics, SpyNotifier, SaboteurRepository } from "../mocks";

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
    expect(notifier.notifications).toHaveLength(1);
  });

  it("records failure on duplicate", async () => {
    const repo = new MockAuthorRepository(new DuplicateAuthorError("Alice"));
    const metrics = new SpyMetrics();
    const notifier = new SpyNotifier();
    const service = new AuthorServiceImpl(repo, metrics, notifier);

    await expect(
      service.createAuthor({ name: AuthorName.create("Alice") }),
    ).rejects.toBeInstanceOf(DuplicateAuthorError);
    expect(metrics.failures).toBe(1);
  });

  it("wraps unknown errors", async () => {
    const repo = new SaboteurRepository();
    const metrics = new SpyMetrics();
    const notifier = new SpyNotifier();
    const service = new AuthorServiceImpl(repo, metrics, notifier);

    await expect(
      service.createAuthor({ name: AuthorName.create("Bob") }),
    ).rejects.toBeInstanceOf(UnknownAuthorError);
  });
});
```

### Integration Tests (real DB — Drizzle example)

```typescript
// tests/integration/drizzle-author.repository.spec.ts
import { Test } from "@nestjs/testing";
import { DRIZZLE, createDrizzleProvider, type DrizzleDB } from "../../src/outbound/drizzle/drizzle.provider";
import { DrizzleAuthorRepository } from "../../src/outbound/drizzle/author.repository";
import { AuthorRepository } from "../../src/domain/authors/ports";
import { AuthorName } from "../../src/domain/authors/models";
import { DuplicateAuthorError } from "../../src/domain/authors/errors";

describe("DrizzleAuthorRepository (integration)", () => {
  let db: DrizzleDB;
  let repo: AuthorRepository;

  beforeAll(async () => {
    db = createDrizzleProvider(process.env.TEST_DATABASE_URL!);
    const module = await Test.createTestingModule({
      providers: [
        { provide: DRIZZLE, useValue: db },
        { provide: AuthorRepository, useClass: DrizzleAuthorRepository },
      ],
    }).compile();
    repo = module.get(AuthorRepository);
  });

  beforeEach(async () => {
    await db.delete((await import("../../src/outbound/drizzle/schema")).authors);
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
    await expect(
      repo.createAuthor({ name: AuthorName.create("Alice") }),
    ).rejects.toBeInstanceOf(DuplicateAuthorError);
  });
});
```

### Integration Tests (real DB — Mongoose example)

```typescript
// tests/integration/mongoose-author.repository.spec.ts
import { Test } from "@nestjs/testing";
import { MongooseModule } from "@nestjs/mongoose";
import { MongooseAuthorRepository } from "../../src/outbound/mongoose/author.repository";
import { AuthorDocument, AuthorSchema } from "../../src/outbound/mongoose/author.schema";
import { AuthorRepository } from "../../src/domain/authors/ports";
import { AuthorName } from "../../src/domain/authors/models";
import { DuplicateAuthorError } from "../../src/domain/authors/errors";
import { Model } from "mongoose";

describe("MongooseAuthorRepository (integration)", () => {
  let repo: AuthorRepository;
  let model: Model<AuthorDocument>;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        MongooseModule.forRoot(process.env.TEST_MONGODB_URI!),
        MongooseModule.forFeature([{ name: AuthorDocument.name, schema: AuthorSchema }]),
      ],
      providers: [
        { provide: AuthorRepository, useClass: MongooseAuthorRepository },
      ],
    }).compile();
    repo = module.get(AuthorRepository);
    model = module.get(`${AuthorDocument.name}Model`);
  });

  beforeEach(async () => {
    await model.deleteMany({});
  });

  it("creates and finds an author", async () => {
    const author = await repo.createAuthor({ name: AuthorName.create("Alice") });
    expect(author.name.value).toBe("Alice");
    const found = await repo.findAuthor(author.id);
    expect(found!.name.value).toBe("Alice");
  });

  it("throws DuplicateAuthorError on unique constraint", async () => {
    await repo.createAuthor({ name: AuthorName.create("Alice") });
    await expect(
      repo.createAuthor({ name: AuthorName.create("Alice") }),
    ).rejects.toBeInstanceOf(DuplicateAuthorError);
  });
});
```

---

## .env.example

```bash
# SQL (Drizzle)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/myapp?schema=public"

# MongoDB (Mongoose)
MONGODB_URI="mongodb://localhost:27017/myapp"

PORT=3000
CORS_ORIGIN="http://localhost:3000"
JWT_SECRET="your-secret-key-at-least-16-chars"
NODE_ENV="development"
```
