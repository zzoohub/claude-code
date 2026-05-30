# PostgreSQL Data Types Guide

## Table of Contents

1. [Type Selection Principles](#type-selection-principles)
2. [Numeric Types](#numeric-types)
3. [String Types](#string-types)
4. [Date/Time Types](#datetime-types)
5. [ENUM Type](#enum-type)
6. [JSONB Hybrid (relational + flexible)](#jsonb-hybrid-relational--flexible)
7. [Boolean](#boolean)
8. [Arrays](#arrays)
9. [Domain Types](#domain-types)
10. [Generated Columns (PostgreSQL 12+; VIRTUAL added in 18)](#generated-columns-postgresql-12-virtual-added-in-18)

## Type Selection Principles

The right data type affects storage, performance, and data integrity.
The difference is negligible at thousands of rows but decisive at hundreds of millions.

> Examples in this guide use the skill's PK default (`UUID NOT NULL PRIMARY KEY DEFAULT uuidv7()`, PG18+). For pre-PG18 or BIGINT IDENTITY trade-offs, see SKILL.md → "Primary Key Type Decision".

## Numeric Types

| Type | Size | Range | When to Use |
|------|------|-------|-------------|
| SMALLINT | 2 bytes | -32,768 to 32,767 | Status codes, small counters, lookup-table PKs |
| INTEGER | 4 bytes | -2.1B to 2.1B | General-purpose integers |
| BIGINT | 8 bytes | ±9.2 × 10^18 | Large counters; PKs only for high-volume internal tables (events, audit logs) — see SKILL.md PK decision |
| NUMERIC(p,s) | variable | arbitrary precision | **Monetary values, financial data** |
| REAL | 4 bytes | 6-digit precision | Scientific calcs (precision not critical) |
| DOUBLE PRECISION | 8 bytes | 15-digit precision | Coordinates, statistics (precision not critical) |

### Monetary Values — Never Use FLOAT

```sql
-- WRONG: floating-point rounding errors
CREATE TABLE payments_bad (
    amount REAL  -- 0.1 + 0.2 != 0.3
);

-- CORRECT: fixed-point for exact values
CREATE TABLE payments (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD'
);
-- Multi-currency note: scale must match the currency minor-unit exponent (JPY/KRW = 0, most = 2, BHD/KWD = 3). A fixed NUMERIC(_,2) is wrong for those — store integer minor units (BIGINT) with the currency code and resolve the exponent from the currency, or constrain the table to a single currency.

-- Alternative: store as smallest unit (cents, won)
CREATE TABLE payments_int (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    amount_cents BIGINT NOT NULL CHECK (amount_cents >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD'
);
```

### PK Type Selection

The full decision table (UUID v7 default, BIGINT IDENTITY for high-volume internal tables) lives in SKILL.md → "Primary Key Type Decision". Generation patterns:

```sql
-- Default: UUID v7 (PG18+ — native uuidv7() function)
CREATE TABLE examples (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7()
);

-- Pre-PG18: generate UUID v7 at the application layer and pass into INSERT
CREATE TABLE examples_pre18 (
    id UUID NOT NULL PRIMARY KEY  -- no DEFAULT; app generates v7
);

-- High-volume internal table where 8-byte savings measurably matter
-- (event logs, metrics, billion-row append-only tables)
CREATE TABLE examples_internal (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);
```

⚠️ **Avoid `gen_random_uuid()` for PKs on hot tables** — it generates UUID v4 (random), which fragments B-tree indexes and hurts write performance. See SKILL.md "Critical Rules".

## String Types

| Type | Description | When to Use |
|------|------------|-------------|
| TEXT | Variable length, no limit | **Default choice in PostgreSQL** |
| VARCHAR(n) | Variable length, max n | Only when external system requires length constraint |
| CHAR(n) | Fixed length, padded to n | Fixed-length codes only (KR, USD, ISO codes) |

```sql
-- In PostgreSQL, TEXT vs VARCHAR has zero performance difference
-- Enforce length limits via CHECK constraints instead

CREATE TABLE user_accounts (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    email TEXT NOT NULL,
    username TEXT NOT NULL,
    bio TEXT,
    CONSTRAINT chk_email_length CHECK (char_length(email) <= 255),
    CONSTRAINT chk_username_length CHECK (char_length(username) BETWEEN 3 AND 50)
);
```

> **CHAR(n) caveat:** CHAR blank-pads a too-short value to width rather than rejecting it (`'US'` is
> stored as `'US '`) and strips trailing blanks on read, so `CHAR(3)` does NOT guarantee three
> meaningful characters. For currency/ISO codes prefer `CHAR(3)`/`TEXT` with a real check, e.g.
> `CHECK (currency ~ '^[A-Z]{3}$')`.

> **Case-insensitive identity (email, username):** a plain `UNIQUE` on `TEXT` is case-sensitive, so
> `Alice@x.com` and `alice@x.com` both insert — a classic auth footgun. Enforce a **partial unique
> index on `lower(email)`** (see `references/indexing-strategy.md`), or use the `citext` extension or a
> nondeterministic ICU collation
> (`CREATE COLLATION ... (provider = icu, locale = 'und-u-ks-level2', deterministic = false)`, PG12+).

## Date/Time Types

| Type | Description | When to Use |
|------|------------|-------------|
| TIMESTAMPTZ | Timezone-aware | **Always use this** |
| TIMESTAMP | No timezone | Do not use |
| DATE | Date only | Birth dates, event dates |
| TIME | Time only | Rarely needed |
| INTERVAL | Duration | Subscription periods, expiry durations |

```sql
-- Always TIMESTAMPTZ
CREATE TABLE events (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- DATE when only the date matters
CREATE TABLE employees (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    birth_date DATE,
    hired_date DATE NOT NULL DEFAULT CURRENT_DATE
);
```

## ENUM Type

Use only when values change very rarely and there are roughly 3-10 options.

```sql
-- ENUM when appropriate
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled');

CREATE TABLE orders (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Adding values is easy; a label can be renamed (ALTER TYPE ... RENAME VALUE, PG10+); removing a value or reordering is not supported
ALTER TYPE order_status ADD VALUE 'refunded' AFTER 'cancelled';
```

Since PG12, `ADD VALUE` can run inside a transaction, but the new value cannot be referenced (INSERT/compare) until that transaction commits — a migration that adds AND uses a value in one transaction will fail; split it into two migrations/transactions, or run `ADD VALUE` in its own transaction first.

**ENUM alternative**: Use a lookup table when values change frequently

```sql
-- Lookup table — SMALLINT IDENTITY is fine here (small, internal, never exposed)
CREATE TABLE order_statuses (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO order_statuses (name) VALUES
    ('pending'), ('confirmed'), ('shipped'), ('delivered'), ('cancelled');

CREATE TABLE orders (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    status_id SMALLINT NOT NULL REFERENCES order_statuses(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## JSONB Hybrid (relational + flexible)

Best for data with a flexible or frequently changing structure.

```sql
CREATE TABLE products (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    -- Category-specific attributes as JSONB
    attributes JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- GIN index for JSONB search optimization
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);

-- Expression Index for frequently queried keys
CREATE INDEX idx_products_attr_color ON products ((attributes->>'color'));

-- Query examples
SELECT * FROM products WHERE attributes @> '{"color": "red"}';
SELECT * FROM products WHERE attributes->>'brand' = 'Apple';
```

**JSONB rules**:
- Core data that can be modeled relationally → use proper columns
- JSONB is for supplementary data, metadata, flexible attributes only
- Never store an ID inside JSONB as the *live system of record* for a relationship — PostgreSQL cannot enforce a FOREIGN KEY into a JSONB value, so there is no referential integrity. (Snapshotted IDs in immutable audit/event payloads are the deliberate exception.)

## Boolean

```sql
CREATE TABLE feature_flags (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL UNIQUE,
    is_enabled BOOLEAN NOT NULL DEFAULT false
);

-- Partial Index combines well with Boolean
CREATE INDEX idx_feature_flags_enabled ON feature_flags (name) WHERE is_enabled = true;
```

## Arrays

```sql
CREATE TABLE articles (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    title TEXT NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_articles_tags ON articles USING GIN (tags);

-- Queries
SELECT * FROM articles WHERE 'postgresql' = ANY(tags);
SELECT * FROM articles WHERE tags @> ARRAY['postgresql', 'design'];
```

**ARRAY rules**:
- Simple value lists only (tags, categories)
- If you need joins or FK on array elements, split into a separate table

## Domain Types

Reusable constrained types for consistency across tables. Define once, enforce everywhere.

```sql
-- Email domain: enforced via CHECK on every column that uses it
CREATE DOMAIN email AS TEXT
    CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

-- Positive money amount
CREATE DOMAIN positive_amount AS NUMERIC(15, 2)
    CHECK (VALUE > 0);

-- URL
CREATE DOMAIN url AS TEXT
    CHECK (VALUE ~ '^https?://');

-- Use in tables
CREATE TABLE user_accounts (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    email email NOT NULL,
    website url,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE invoices (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    amount positive_amount NOT NULL,
    recipient_email email NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**When to use domains**: When the same constrained type appears in 3+ columns across different tables. It avoids duplicating CHECK constraints and ensures consistent validation.

**When NOT to use**: For one-off constraints on a single column — just use inline CHECK.

**Caveats** (PostgreSQL does not make domains airtight):
- A domain's CHECK/NOT NULL is **not** applied to the elements of an array of that domain — a column typed `email[]` does not validate each element. Validate array contents at the application or trigger layer.
- Domain `NOT NULL` can be bypassed by NULLs introduced without a direct insert (e.g. a `LEFT JOIN` or a scalar subquery yielding NULL). Still put an explicit `NOT NULL` on the column where null is invalid — don't rely on the domain alone.

## Generated Columns (PostgreSQL 12+; VIRTUAL added in 18)

Computed columns stored on disk, automatically maintained by PostgreSQL.

```sql
CREATE TABLE products (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    tax_rate NUMERIC(5, 4) NOT NULL DEFAULT 0.10,
    -- Automatically computed and stored
    price_with_tax NUMERIC(12, 2) GENERATED ALWAYS AS (price * (1 + tax_rate)) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Full-text search vector (avoids recomputing on every query)
CREATE TABLE articles (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,''))
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_articles_search ON articles USING GIN (search_vector);

-- Query using the stored vector (no runtime computation)
SELECT * FROM articles WHERE search_vector @@ to_tsquery('english', 'postgresql & design');
```

**When to use**: Computed values queried frequently (full-text vectors, derived amounts, normalized strings). Trades write-time computation for read-time performance.

⚠️ Concatenating a NULL operand yields NULL, collapsing the whole `tsvector` to NULL and silently excluding the row from full-text results — `coalesce` each nullable operand. The regconfig must be a constant literal (`'english'`): `to_tsvector(constant_config, text)` is IMMUTABLE and legal in a generated column, but a column-driven config is only STABLE and the `CREATE TABLE` is rejected.

**Storage modes**: `STORED` (computed on write, persisted, **indexable**) and `VIRTUAL` (computed on read, no storage; PostgreSQL 18+). On PG18, `VIRTUAL` is the **default** when the keyword is omitted — so always write `STORED` explicitly whenever you intend to index the column (e.g. the `search_vector` GIN index above) or amortize compute. On PG12–17 only `STORED` exists and the keyword is mandatory. In both modes the expression cannot reference other tables, other generated columns, or subqueries; `STORED` additionally requires the expression to be `IMMUTABLE`.
