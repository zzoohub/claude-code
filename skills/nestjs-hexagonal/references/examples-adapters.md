# Examples: Adapters

Inbound (controller, DTOs, exception filter, auth guard, pipes, healthcheck) and outbound (TypeORM SQL + Mongoose MongoDB repositories, mappers).

---

## Outbound: TypeORM — Entity

```typescript
// src/outbound/typeorm/entities/author.entity.ts
import {
  Entity, Column, PrimaryGeneratedColumn,
  CreateDateColumn, UpdateDateColumn, Index,
} from "typeorm";

/**
 * TypeORM entity — outbound only. NEVER imported in domain.
 * This is a persistence representation of `Author`, not the domain model itself.
 */
@Entity({ name: "authors" })
export class AuthorEntity {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Index({ unique: true })
  @Column({ type: "text" })
  name!: string;

  @CreateDateColumn({ name: "created_at", type: "timestamptz" })
  createdAt!: Date;

  @UpdateDateColumn({ name: "updated_at", type: "timestamptz" })
  updatedAt!: Date;
}
```

## Outbound: TypeORM — Module

```typescript
// src/outbound/typeorm/typeorm.module.ts
import { Global, Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";
import { AuthorEntity } from "./entities/author.entity";
import { TypeOrmAuthorRepository } from "./author.repository";
import { AuthorRepository } from "../../domain/authors/ports";
import type { AppConfig } from "../../config";

@Global()
@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<AppConfig, true>) => ({
        type: "postgres",
        url: config.get("DATABASE_URL"),
        entities: [AuthorEntity],
        migrations: ["dist/migrations/*.js"],
        // synchronize MUST stay false in every deployed env — migrations only.
        synchronize: false,
        logging: config.get("NODE_ENV") === "development" ? ["query", "error"] : ["error"],
        poolSize: 10,
      }),
    }),
    TypeOrmModule.forFeature([AuthorEntity]),
  ],
  providers: [
    { provide: AuthorRepository, useClass: TypeOrmAuthorRepository },
  ],
  exports: [AuthorRepository, TypeOrmModule],
})
export class TypeOrmPersistenceModule {}
```

## Outbound: TypeORM — Mapper + Repository

```typescript
// src/outbound/typeorm/mapper.ts
import { AuthorName } from "../../domain/authors/models";
import type { Author, CreateAuthorRequest } from "../../domain/authors/models";
import { AuthorEntity } from "./entities/author.entity";

/**
 * Maps in BOTH directions so the entity stays sealed inside the adapter.
 * Domain code only ever sees `Author`.
 */
export class AuthorMapper {
  static toDomain(entity: AuthorEntity): Author {
    return { id: entity.id, name: AuthorName.create(entity.name) };
  }

  static toEntity(req: CreateAuthorRequest): AuthorEntity {
    const entity = new AuthorEntity();
    entity.name = req.name.value;
    return entity;
  }
}
```

```typescript
// src/outbound/typeorm/author.repository.ts
import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { MoreThan, QueryFailedError, Repository } from "typeorm";
import { AuthorEntity } from "./entities/author.entity";
import { AuthorMapper } from "./mapper";
import { AuthorRepository } from "../../domain/authors/ports";
import type { Author, CreateAuthorRequest, CursorPage } from "../../domain/authors/models";
import {
  DuplicateAuthorError,
  UnknownAuthorError,
} from "../../domain/authors/errors";

const PG_UNIQUE_VIOLATION = "23505";

@Injectable()
export class TypeOrmAuthorRepository extends AuthorRepository {
  constructor(
    @InjectRepository(AuthorEntity)
    private readonly repo: Repository<AuthorEntity>,
  ) {
    super();
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    const entity = AuthorMapper.toEntity(req);
    try {
      // Data Mapper style: repository.save(entity), never entity.save().
      const saved = await this.repo.save(entity);
      return AuthorMapper.toDomain(saved);
    } catch (error) {
      if (this.isUniqueConstraintError(error)) {
        throw new DuplicateAuthorError(req.name.value);
      }
      throw new UnknownAuthorError(error);
    }
  }

  async findAuthor(authorId: string): Promise<Author | null> {
    const entity = await this.repo.findOneBy({ id: authorId });
    return entity ? AuthorMapper.toDomain(entity) : null;
  }

  async listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>> {
    const fetchLimit = limit + 1;

    const entities = await this.repo.find({
      where: cursor ? { id: MoreThan(cursor) } : {},
      order: { id: "ASC" },
      take: fetchLimit,
    });

    const hasMore = entities.length > limit;
    const items = entities.slice(0, limit).map(AuthorMapper.toDomain);
    const nextCursor = hasMore && items.length > 0 ? items[items.length - 1].id : null;

    return { items, nextCursor, hasMore };
  }

  private isUniqueConstraintError(error: unknown): boolean {
    return (
      error instanceof QueryFailedError &&
      (error as QueryFailedError & { driverError?: { code?: string } }).driverError?.code === PG_UNIQUE_VIOLATION
    );
  }
}
```

## Outbound: TypeORM — Transaction Example

```typescript
// Multi-step operations that need atomicity.
// EntityManager.transaction() wraps everything in a single connection;
// throwing inside the callback rolls the whole thing back.
async createAuthorWithProfile(req: CreateAuthorWithProfileRequest): Promise<Author> {
  try {
    const saved = await this.repo.manager.transaction(async (manager) => {
      const author = await manager.save(AuthorEntity, { name: req.name.value });
      await manager.save(ProfileEntity, { authorId: author.id, bio: req.bio });
      return author;
    });
    return AuthorMapper.toDomain(saved);
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
    } catch (error: unknown) {
      if (error instanceof Error && 'code' in error && (error as any).code === 11000) {
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
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>> {
    const query = cursor
      ? this.model.find({ _id: { $gt: cursor } })
      : this.model.find();

    const docs = await query
      .sort({ _id: 1 })
      .limit(limit + 1)
      .exec();

    const hasMore = docs.length > limit;
    const items = docs.slice(0, limit).map(AuthorMapper.toDomain);
    const nextCursor = hasMore && items.length > 0 ? items[items.length - 1].id : null;

    return { items, nextCursor, hasMore };
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
  } catch (error: unknown) {
    if (error instanceof Error && 'code' in error && (error as any).code === 11000) throw new DuplicateAuthorError(req.name.value);
    throw new UnknownAuthorError(error);
  } finally {
    await session.endSession();
  }
}
```

---

## Inbound: ValidationPipe Exception Factory

The built-in `ValidationPipe` (registered globally in `main.ts`) handles validation. The factory below converts class-validator errors to RFC 9457 ProblemDetails so error bodies match the rest of the API.

```typescript
// src/inbound/http/validation-exception.factory.ts
import { BadRequestException } from "@nestjs/common";
import type { ValidationError } from "class-validator";

interface FieldError { field: string; messages: string[] }

function flatten(errors: ValidationError[], parent = ""): FieldError[] {
  return errors.flatMap((err) => {
    const path = parent ? `${parent}.${err.property}` : err.property;
    const own = err.constraints
      ? [{ field: path, messages: Object.values(err.constraints) }]
      : [];
    const children = err.children?.length ? flatten(err.children, path) : [];
    return [...own, ...children];
  });
}

export function validationExceptionFactory(errors: ValidationError[]): BadRequestException {
  return new BadRequestException({
    type: "https://api.example.com/errors/validation-failed",
    title: "Validation Failed",
    status: 400,
    errors: flatten(errors),
  });
}
```

`DomainExceptionFilter` already serves `HttpException` bodies as `application/problem+json`, so the body shape above flows through unchanged.

## Inbound: Request DTOs

DTO classes carry class-validator decorators. The controller parameter **must** be type-annotated with the DTO class — without it the global pipe has no metadata to validate against.

```typescript
// src/inbound/http/authors/request.dto.ts
import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from "class-validator";
import { Type } from "class-transformer";
import { AuthorName, type CreateAuthorRequest } from "../../../domain/authors/models";

export class CreateAuthorBody {
  @IsString()
  @IsNotEmpty({ message: "name is required" })
  name!: string;
}

export function toDomain(body: CreateAuthorBody): CreateAuthorRequest {
  return { name: AuthorName.create(body.name) };
}

export class PaginationQuery {
  @IsOptional()
  @IsString()
  cursor?: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 20;
}
```

> Nested DTOs need `@ValidateNested() @Type(() => ChildDto)`; arrays of DTOs need `@ValidateNested({ each: true })`. class-validator has no first-class discriminated-union; for those, validate the discriminator field with `@IsIn([...])` and branch in `toDomain()`.

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

export class CursorPageResponse {
  @ApiProperty({ type: [AuthorResponse] })
  data: AuthorResponse[];

  @ApiProperty({ nullable: true })
  next_cursor: string | null;

  @ApiProperty()
  has_more: boolean;
}
```

## Inbound: Controller

```typescript
// src/inbound/http/authors/authors.controller.ts
import {
  Controller, Get, Post, Param, Body, Query,
  HttpCode, HttpStatus,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiResponse } from "@nestjs/swagger";
import { AuthorService } from "../../../domain/authors/ports";
import {
  CreateAuthorBody, PaginationQuery, toDomain,
} from "./request.dto";
import { AuthorResponse, CursorPageResponse } from "./response.dto";
import { AuthorNotFoundError } from "../../../domain/authors/errors";

@ApiTags("authors")
@Controller("v1/authors")
export class AuthorsController {
  constructor(private readonly authorService: AuthorService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: "Create an author" })
  @ApiResponse({ status: 201, type: AuthorResponse })
  async create(
    @Body() body: CreateAuthorBody,
  ): Promise<{ data: AuthorResponse }> {
    const author = await this.authorService.createAuthor(toDomain(body));
    return { data: AuthorResponse.fromDomain(author) };
  }

  @Get()
  @ApiOperation({ summary: "List authors" })
  async list(
    @Query() query: PaginationQuery,
  ): Promise<CursorPageResponse> {
    const page = await this.authorService.listAuthors(query.cursor ?? null, query.limit);
    return {
      data: page.items.map(AuthorResponse.fromDomain),
      next_cursor: page.nextCursor,
      has_more: page.hasMore,
    };
  }

  @Get(":id")
  @ApiOperation({ summary: "Get an author by ID" })
  async findOne(@Param("id") id: string): Promise<{ data: AuthorResponse }> {
    const author = await this.authorService.findAuthor(id);
    if (!author) {
      throw new AuthorNotFoundError(id);
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
          response.status(409).header("Content-Type", "application/problem+json")
            .json(problem("duplicate-author", "Conflict", 409, exception.message));
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

// For TypeORM — use the built-in indicator:
// import { TypeOrmHealthIndicator } from "@nestjs/terminus";
// For Mongoose:
// import { InjectConnection } from "@nestjs/mongoose";
// import { Connection } from "mongoose";

@ApiTags("health")
@Controller("health")
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    // TypeORM: private readonly db: TypeOrmHealthIndicator,
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
      // TypeORM: ping the default DataSource
      // () => this.db.pingCheck("database"),
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
