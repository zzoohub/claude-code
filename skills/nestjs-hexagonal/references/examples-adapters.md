# Examples: Adapters

Inbound (controller, DTOs, exception filter, auth guard, pipes, healthcheck) and outbound (Drizzle SQL + Mongoose MongoDB repositories, mappers).

---

## Outbound: Drizzle — Schema

```typescript
// src/outbound/drizzle/schema.ts
import { pgTable, text, uuid, timestamp } from "drizzle-orm/pg-core";

/**
 * Drizzle table definition — outbound only. Never import in domain.
 */
export const authors = pgTable("authors", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull().unique(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});
```

## Outbound: Drizzle — Provider + Module

```typescript
// src/outbound/drizzle/drizzle.provider.ts
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import * as schema from "./schema";

export const DRIZZLE = Symbol("DRIZZLE");

export type DrizzleDB = ReturnType<typeof drizzle<typeof schema>>;

export function createDrizzleProvider(databaseUrl: string): DrizzleDB {
  const pool = new Pool({
    connectionString: databaseUrl,
    max: 10,
    idleTimeoutMillis: 20_000,
    connectionTimeoutMillis: 3_000,
  });
  return drizzle(pool, { schema });
}
```

```typescript
// src/outbound/drizzle/drizzle.module.ts
import { Global, Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { DRIZZLE, createDrizzleProvider } from "./drizzle.provider";
import { DrizzleAuthorRepository } from "./author.repository";
import { AuthorRepository } from "../../domain/authors/ports";
import type { AppConfig } from "../../config";

@Global()
@Module({
  providers: [
    {
      provide: DRIZZLE,
      inject: [ConfigService],
      useFactory: (config: ConfigService<AppConfig, true>) =>
        createDrizzleProvider(config.get("DATABASE_URL")),
    },
    { provide: AuthorRepository, useClass: DrizzleAuthorRepository },
  ],
  exports: [DRIZZLE, AuthorRepository],
})
export class DrizzlePersistenceModule {}
```

## Outbound: Drizzle — Mapper + Repository

```typescript
// src/outbound/drizzle/mapper.ts
import { AuthorName } from "../../domain/authors/models";
import type { Author } from "../../domain/authors/models";

export class AuthorMapper {
  static toDomain(row: { id: string; name: string }): Author {
    return { id: row.id, name: AuthorName.create(row.name) };
  }
}
```

```typescript
// src/outbound/drizzle/author.repository.ts
import { Inject, Injectable } from "@nestjs/common";
import { eq, count, asc } from "drizzle-orm";
import { DRIZZLE, type DrizzleDB } from "./drizzle.provider";
import { authors } from "./schema";
import { AuthorMapper } from "./mapper";
import { AuthorRepository } from "../../domain/authors/ports";
import type { Author, CreateAuthorRequest } from "../../domain/authors/models";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";

@Injectable()
export class DrizzleAuthorRepository extends AuthorRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {
    super();
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    try {
      const [row] = await this.db
        .insert(authors)
        .values({ name: req.name.value })
        .returning();
      return AuthorMapper.toDomain(row);
    } catch (error) {
      if (this.isUniqueConstraintError(error)) {
        throw new DuplicateAuthorError(req.name.value);
      }
      throw new UnknownAuthorError(error);
    }
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
    page: number,
    pageSize: number,
  ): Promise<{ items: Author[]; total: number }> {
    const [rows, totalResult] = await Promise.all([
      this.db
        .select()
        .from(authors)
        .orderBy(asc(authors.name))
        .limit(pageSize)
        .offset((page - 1) * pageSize),
      this.db.select({ count: count() }).from(authors),
    ]);
    return {
      items: rows.map(AuthorMapper.toDomain),
      total: totalResult[0].count,
    };
  }

  private isUniqueConstraintError(error: unknown): boolean {
    return (
      error instanceof Error &&
      (error.message.includes("23505") ||
        error.message.includes("UNIQUE constraint failed"))
    );
  }
}
```

## Outbound: Drizzle — Transaction Example

```typescript
// Multi-step operations that need atomicity:
async createAuthorWithProfile(req: CreateAuthorWithProfileRequest): Promise<Author> {
  try {
    const row = await this.db.transaction(async (tx) => {
      const [author] = await tx.insert(authors).values({ name: req.name.value }).returning();
      await tx.insert(profiles).values({ authorId: author.id, bio: req.bio });
      return author;
    });
    return AuthorMapper.toDomain(row);
  } catch (error) {
    if (this.isUniqueConstraintError(error)) throw new DuplicateAuthorError(req.name.value);
    throw new UnknownAuthorError(error);
  }
}
```

---

## Outbound: Mongoose — Schema

```typescript
// src/outbound/mongoose/author.schema.ts
import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { type HydratedDocument } from "mongoose";

/**
 * Mongoose document definition — outbound only. Never import in domain.
 * @Schema decorators are infrastructure, fine in outbound layer.
 */
@Schema({ collection: "authors", timestamps: true })
export class AuthorDocument {
  /** Mongoose auto-generates _id as ObjectId. Use .id for string version. */

  @Prop({ required: true, unique: true, trim: true })
  name: string;
}

export type AuthorDoc = HydratedDocument<AuthorDocument>;
export const AuthorSchema = SchemaFactory.createForClass(AuthorDocument);
```

## Outbound: Mongoose — Module

```typescript
// src/outbound/mongoose/mongoose.module.ts
import { Global, Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { ConfigService } from "@nestjs/config";
import { AuthorDocument, AuthorSchema } from "./author.schema";
import { MongooseAuthorRepository } from "./author.repository";
import { AuthorRepository } from "../../domain/authors/ports";
import type { AppConfig } from "../../config";

@Global()
@Module({
  imports: [
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<AppConfig, true>) => ({
        uri: config.get("MONGODB_URI"),
      }),
    }),
    MongooseModule.forFeature([
      { name: AuthorDocument.name, schema: AuthorSchema },
    ]),
  ],
  providers: [
    { provide: AuthorRepository, useClass: MongooseAuthorRepository },
  ],
  exports: [AuthorRepository],
})
export class MongoosePersistenceModule {}
```

## Outbound: Mongoose — Mapper + Repository

```typescript
// src/outbound/mongoose/mapper.ts
import { AuthorName } from "../../domain/authors/models";
import type { Author } from "../../domain/authors/models";
import type { AuthorDoc } from "./author.schema";

export class AuthorMapper {
  static toDomain(doc: AuthorDoc): Author {
    return {
      id: doc.id as string, // Mongoose .id returns string of _id
      name: AuthorName.create(doc.name),
    };
  }
}
```

```typescript
// src/outbound/mongoose/author.repository.ts
import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import { AuthorDocument, type AuthorDoc } from "./author.schema";
import { AuthorMapper } from "./mapper";
import { AuthorRepository } from "../../domain/authors/ports";
import type { Author, CreateAuthorRequest } from "../../domain/authors/models";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";

@Injectable()
export class MongooseAuthorRepository extends AuthorRepository {
  constructor(
    @InjectModel(AuthorDocument.name)
    private readonly model: Model<AuthorDocument>,
  ) {
    super();
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    try {
      const doc = await this.model.create({ name: req.name.value });
      return AuthorMapper.toDomain(doc as AuthorDoc);
    } catch (error: any) {
      if (error?.code === 11000) {
        throw new DuplicateAuthorError(req.name.value);
      }
      throw new UnknownAuthorError(error);
    }
  }

  async findAuthor(authorId: string): Promise<Author | null> {
    const doc = await this.model.findById(authorId).exec();
    if (!doc) return null;
    return AuthorMapper.toDomain(doc);
  }

  async listAuthors(
    page: number,
    pageSize: number,
  ): Promise<{ items: Author[]; total: number }> {
    const [docs, total] = await Promise.all([
      this.model
        .find()
        .sort({ name: 1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .exec(),
      this.model.countDocuments().exec(),
    ]);
    return {
      items: docs.map(AuthorMapper.toDomain),
      total,
    };
  }
}
```

## Outbound: Mongoose — Transaction Example

```typescript
// Transactions require a MongoDB replica set.
async createAuthorWithProfile(req: CreateAuthorWithProfileRequest): Promise<Author> {
  const session = await this.model.db.startSession();
  try {
    let doc: AuthorDoc;
    await session.withTransaction(async () => {
      [doc] = await this.model.create([{ name: req.name.value }], { session });
      await this.profileModel.create([{ authorId: doc.id, bio: req.bio }], { session });
    });
    return AuthorMapper.toDomain(doc!);
  } catch (error: any) {
    if (error?.code === 11000) throw new DuplicateAuthorError(req.name.value);
    throw new UnknownAuthorError(error);
  } finally {
    await session.endSession();
  }
}
```

---

## Inbound: ZodValidationPipe

```typescript
// src/inbound/http/pipes/zod-validation.pipe.ts
import {
  PipeTransform,
  BadRequestException,
  Injectable,
} from "@nestjs/common";
import type { ZodSchema, ZodError } from "zod";

@Injectable()
export class ZodValidationPipe<T> implements PipeTransform<unknown, T> {
  constructor(private readonly schema: ZodSchema<T>) {}

  transform(value: unknown): T {
    const result = this.schema.safeParse(value);
    if (!result.success) {
      throw new BadRequestException({
        type: "https://api.example.com/errors/validation-failed",
        title: "Validation Failed",
        status: 400,
        errors: this.formatErrors(result.error),
      });
    }
    return result.data;
  }

  private formatErrors(error: ZodError) {
    return error.errors.map((e) => ({
      field: e.path.join("."),
      code: e.code,
      message: e.message,
    }));
  }
}
```

## Inbound: Request DTOs

```typescript
// src/inbound/http/authors/request.dto.ts
import { z } from "zod";
import { AuthorName, type CreateAuthorRequest } from "../../../domain/authors/models";

export const createAuthorSchema = z.object({
  name: z.string().min(1, "name is required"),
});
export type CreateAuthorBody = z.infer<typeof createAuthorSchema>;

export function toDomain(body: CreateAuthorBody): CreateAuthorRequest {
  return { name: AuthorName.create(body.name) };
}

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  page_size: z.coerce.number().int().min(1).max(100).default(20),
});
export type PaginationQuery = z.infer<typeof paginationSchema>;
```

## Inbound: Response DTOs

```typescript
// src/inbound/http/authors/response.dto.ts
import { ApiProperty } from "@nestjs/swagger";
import type { Author } from "../../../domain/authors/models";

export class AuthorResponse {
  @ApiProperty({ example: "550e8400-e29b-41d4-a716-446655440000" })
  id: string;

  @ApiProperty({ example: "Alice" })
  name: string;

  static fromDomain(author: Author): AuthorResponse {
    const dto = new AuthorResponse();
    dto.id = author.id;
    dto.name = author.name.value;
    return dto;
  }
}

export class PaginatedAuthorsResponse {
  @ApiProperty({ type: [AuthorResponse] })
  data: AuthorResponse[];

  @ApiProperty() total: number;
  @ApiProperty() page: number;
  @ApiProperty() page_size: number;
  @ApiProperty() has_next: boolean;
}
```

## Inbound: Controller

```typescript
// src/inbound/http/authors/authors.controller.ts
import {
  Controller, Get, Post, Param, Body, Query,
  HttpCode, HttpStatus, NotFoundException,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiResponse } from "@nestjs/swagger";
import { AuthorService } from "../../../domain/authors/ports";
import { ZodValidationPipe } from "../pipes/zod-validation.pipe";
import {
  createAuthorSchema, paginationSchema, toDomain,
  type CreateAuthorBody, type PaginationQuery,
} from "./request.dto";
import { AuthorResponse, PaginatedAuthorsResponse } from "./response.dto";

@ApiTags("authors")
@Controller("v1/authors")
export class AuthorsController {
  constructor(private readonly authorService: AuthorService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: "Create an author" })
  @ApiResponse({ status: 201, type: AuthorResponse })
  async create(
    @Body(new ZodValidationPipe(createAuthorSchema)) body: CreateAuthorBody,
  ): Promise<{ data: AuthorResponse }> {
    const author = await this.authorService.createAuthor(toDomain(body));
    return { data: AuthorResponse.fromDomain(author) };
  }

  @Get()
  @ApiOperation({ summary: "List authors" })
  async list(
    @Query(new ZodValidationPipe(paginationSchema)) query: PaginationQuery,
  ): Promise<PaginatedAuthorsResponse> {
    const result = await this.authorService.listAuthors(query.page, query.page_size);
    return {
      data: result.items.map(AuthorResponse.fromDomain),
      total: result.total,
      page: query.page,
      page_size: query.page_size,
      has_next: query.page * query.page_size < result.total,
    };
  }

  @Get(":id")
  @ApiOperation({ summary: "Get an author by ID" })
  async findOne(@Param("id") id: string): Promise<{ data: AuthorResponse }> {
    const author = await this.authorService.findAuthor(id);
    if (!author) {
      throw new NotFoundException({
        type: "https://api.example.com/errors/not-found",
        title: "Not Found",
        status: 404,
        detail: `author with id "${id}" not found`,
      });
    }
    return { data: AuthorResponse.fromDomain(author) };
  }
}
```

## Inbound: Exception Filter (RFC 9457)

```typescript
// src/inbound/http/filters/domain-exception.filter.ts
import {
  Catch, ExceptionFilter, ArgumentsHost, Logger, HttpException,
} from "@nestjs/common";
import type { Response } from "express";

interface ProblemDetails {
  type: string; title: string; status: number; detail: string;
}

function problem(slug: string, title: string, status: number, detail: string): ProblemDetails {
  return { type: `https://api.example.com/errors/${slug}`, title, status, detail };
}

@Catch()
export class DomainExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(DomainExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();
      response.status(status).header("Content-Type", "application/problem+json")
        .json(typeof body === "string" ? problem("error", body, status, body) : body);
      return;
    }

    if (exception instanceof Error && "tag" in exception) {
      const tagged = exception as Error & { tag: string };
      switch (tagged.tag) {
        case "DuplicateAuthorError":
          response.status(422).header("Content-Type", "application/problem+json")
            .json(problem("duplicate-author", "Unprocessable Entity", 422, exception.message));
          return;
        case "AuthorNameEmptyError":
          response.status(422).header("Content-Type", "application/problem+json")
            .json(problem("validation-error", "Unprocessable Entity", 422, exception.message));
          return;
        case "AuthorNotFoundError":
          response.status(404).header("Content-Type", "application/problem+json")
            .json(problem("not-found", "Not Found", 404, exception.message));
          return;
        case "UnknownAuthorError":
          this.logger.error("Unexpected error:", (exception as any).cause);
          break;
        default:
          this.logger.error("Unhandled domain error:", exception);
      }
    } else {
      this.logger.error("Unhandled error:", exception);
    }

    response.status(500).header("Content-Type", "application/problem+json")
      .json(problem("internal-error", "Internal Server Error", 500, "An unexpected error occurred"));
  }
}
```

## Inbound: Auth Guard (JWT)

```typescript
// src/inbound/http/guards/jwt-auth.guard.ts
import {
  CanActivate, ExecutionContext, Injectable, UnauthorizedException,
} from "@nestjs/common";
import type { Request } from "express";
import { verify } from "jsonwebtoken";
import type { ConfigService } from "@nestjs/config";
import type { AppConfig } from "../../../config";

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const authHeader = request.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) throw new UnauthorizedException("Missing token");

    try {
      const payload = verify(authHeader.slice(7), this.config.get("JWT_SECRET"));
      (request as any).userId = (payload as any).sub;
      return true;
    } catch {
      throw new UnauthorizedException("Invalid token");
    }
  }
}
```

## Inbound: Healthcheck

```typescript
// src/inbound/http/health/health.controller.ts
import { Controller, Get, Inject } from "@nestjs/common";
import { HealthCheck, HealthCheckService } from "@nestjs/terminus";
import { ApiTags } from "@nestjs/swagger";

// For Drizzle — raw query check:
// import { DRIZZLE, type DrizzleDB } from "../../../outbound/drizzle/drizzle.provider";
// For Mongoose:
// import { InjectConnection } from "@nestjs/mongoose";
// import { Connection } from "mongoose";

@ApiTags("health")
@Controller("health")
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    // Drizzle: @Inject(DRIZZLE) private readonly db: DrizzleDB,
    // Mongoose: @InjectConnection() private readonly connection: Connection,
  ) {}

  @Get("live")
  live() {
    return { status: "ok" };
  }

  @Get("ready")
  @HealthCheck()
  ready() {
    return this.health.check([
      // Drizzle: raw SELECT 1 via pool
      // async () => {
      //   await this.db.execute(sql`SELECT 1`);
      //   return { database: { status: "up" } };
      // },
      // Mongoose: check readyState
      // () => this.connection.readyState === 1
      //   ? Promise.resolve({ database: { status: "up" } })
      //   : Promise.reject("DB not connected"),
    ]);
  }
}
```

## Inbound: Job Handler (non-HTTP inbound adapter)

```typescript
// src/inbound/jobs/sync-author.processor.ts
import { Processor, WorkerHost } from "@nestjs/bullmq";
import type { Job } from "bullmq";
import { AuthorName } from "../../domain/authors/models";
import { AuthorService } from "../../domain/authors/ports";

@Processor("author-sync")
export class SyncAuthorProcessor extends WorkerHost {
  constructor(private readonly authorService: AuthorService) {
    super();
  }

  async process(job: Job<{ authorName: string; source: string }>) {
    const domainReq = { name: AuthorName.create(job.data.authorName) };
    await this.authorService.createAuthor(domainReq);
  }
}
```
