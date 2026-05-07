# Examples: Domain Layer

Models, errors, ports (abstract classes), and service implementation.

---

## Domain Models

```typescript
// src/domain/authors/models.ts

import { AuthorNameEmptyError } from "./errors";

/**
 * Validated, trimmed author name. Value object.
 * Immutable — construct via AuthorName.create().
 */
export class AuthorName {
  private constructor(readonly value: string) {}

  static create(raw: string): AuthorName {
    const trimmed = raw.trim();
    if (!trimmed) {
      throw new AuthorNameEmptyError();
    }
    return new AuthorName(trimmed);
  }

  toString(): string {
    return this.value;
  }

  equals(other: AuthorName): boolean {
    return this.value === other.value;
  }
}

/**
 * A uniquely identifiable author of blog posts.
 */
export interface Author {
  readonly id: string;
  readonly name: AuthorName;
}

/**
 * Fields required to create an Author. Separate from Author — they WILL diverge.
 */
export interface CreateAuthorRequest {
  readonly name: AuthorName;
}

/**
 * Cursor-based pagination result.
 */
export interface CursorPage<T> {
  readonly items: T[];
  readonly nextCursor: string | null;
  readonly hasMore: boolean;
}
```

## Domain Errors

```typescript
// src/domain/authors/errors.ts

/**
 * Use a readonly `tag` discriminant on each error class.
 * This enables exhaustive switch/case matching in exception filters
 * without relying on instanceof (which breaks across module boundaries).
 */

export class AuthorNameEmptyError extends Error {
  readonly tag = "AuthorNameEmptyError" as const;
  constructor() {
    super("author name cannot be empty");
    this.name = "AuthorNameEmptyError";
  }
}

export class DuplicateAuthorError extends Error {
  readonly tag = "DuplicateAuthorError" as const;
  constructor(readonly authorName: string) {
    super(`author with name "${authorName}" already exists`);
    this.name = "DuplicateAuthorError";
  }
}

export class AuthorNotFoundError extends Error {
  readonly tag = "AuthorNotFoundError" as const;
  constructor(readonly authorId: string) {
    super(`author with id "${authorId}" not found`);
    this.name = "AuthorNotFoundError";
  }
}

export class UnknownAuthorError extends Error {
  readonly tag = "UnknownAuthorError" as const;
  constructor(readonly cause: unknown) {
    super("unexpected error");
    this.name = "UnknownAuthorError";
  }
}

/**
 * Union type for all create-author failures.
 * Exception filters switch on `error.tag` for exhaustive matching.
 */
export type CreateAuthorError = DuplicateAuthorError | UnknownAuthorError;
```

## Ports (Abstract Classes)

```typescript
// src/domain/authors/ports.ts

import type { Author, CreateAuthorRequest, CursorPage } from "./models";

/**
 * Abstract classes serve as BOTH interface contract AND DI injection token.
 * NestJS resolves `AuthorRepository` in constructors to whichever class
 * is registered with `{ provide: AuthorRepository, useClass: ... }`.
 *
 * No @nestjs/* imports — these are plain TypeScript.
 */

/**
 * Port shaped by use cases. Implementors MUST throw DuplicateAuthorError if name exists.
 */
export abstract class AuthorRepository {
  abstract createAuthor(req: CreateAuthorRequest): Promise<Author>;
  abstract findAuthor(authorId: string): Promise<Author | null>;
  abstract listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>>;
}

export abstract class AuthorMetrics {
  abstract recordCreationSuccess(): Promise<void>;
  abstract recordCreationFailure(): Promise<void>;
}

export abstract class AuthorNotifier {
  abstract authorCreated(author: Author): Promise<void>;
}

/**
 * Business API consumed by inbound adapters (controllers).
 */
export abstract class AuthorService {
  abstract createAuthor(req: CreateAuthorRequest): Promise<Author>;
  abstract findAuthor(authorId: string): Promise<Author | null>;
  abstract listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>>;
}
```

## Service Implementation

```typescript
// src/domain/authors/service.ts
//
// NO @Injectable() — wired via useFactory in the feature module.
// NO @nestjs/* imports — domain stays pure.

import type { Author, CreateAuthorRequest, CursorPage } from "./models";
import type { AuthorMetrics, AuthorNotifier, AuthorRepository } from "./ports";
import { AuthorService } from "./ports";
import { DuplicateAuthorError, UnknownAuthorError } from "./errors";

/**
 * Orchestrates: repo -> metrics -> notifications -> return result.
 */
export class AuthorServiceImpl extends AuthorService {
  constructor(
    private readonly repo: AuthorRepository,
    private readonly metrics: AuthorMetrics,
    private readonly notifier: AuthorNotifier,
  ) {
    super();
  }

  async createAuthor(req: CreateAuthorRequest): Promise<Author> {
    try {
      const author = await this.repo.createAuthor(req);
      await this.metrics.recordCreationSuccess();
      await this.notifier.authorCreated(author);
      return author;
    } catch (error) {
      await this.metrics.recordCreationFailure();
      if (error instanceof DuplicateAuthorError) {
        throw error;
      }
      throw new UnknownAuthorError(error);
    }
  }

  async findAuthor(authorId: string): Promise<Author | null> {
    return this.repo.findAuthor(authorId);
  }

  async listAuthors(
    cursor: string | null,
    limit: number,
  ): Promise<CursorPage<Author>> {
    return this.repo.listAuthors(cursor, limit);
  }
}
```
