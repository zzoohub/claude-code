# PostgreSQL Data Types Guide

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
CREATE TABLE payment_bad (
    amount REAL  -- 0.1 + 0.2 != 0.3
);

-- CORRECT: fixed-point for exact values
CREATE TABLE payment (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD'
);

-- Alternative: store as smallest unit (cents, won)
CREATE TABLE payment_int (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    amount_cents BIGINT NOT NULL CHECK (amount_cents >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD'
);
```

### PK Type Selection

The full decision table (UUID v7 default, BIGINT IDENTITY for high-volume internal tables) lives in SKILL.md → "Primary Key Type Decision". Generation patterns:

```sql
-- Default: UUID v7 (PG18+ — native uuidv7() function)
CREATE TABLE example (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7()
);

-- Pre-PG18: generate UUID v7 at the application layer and pass into INSERT
CREATE TABLE example_pre18 (
    id UUID NOT NULL PRIMARY KEY  -- no DEFAULT; app generates v7
);

-- High-volume internal table where 8-byte savings measurably matter
-- (event logs, metrics, billion-row append-only tables)
CREATE TABLE example_internal (
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

CREATE TABLE user_account (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    email TEXT NOT NULL,
    username TEXT NOT NULL,
    bio TEXT,
    CONSTRAINT chk_email_length CHECK (char_length(email) <= 255),
    CONSTRAINT chk_username_length CHECK (char_length(username) BETWEEN 3 AND 50)
);
```

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
CREATE TABLE event (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- DATE when only the date matters
CREATE TABLE employee (
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

CREATE TABLE "order" (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Adding values is possible; removing/renaming is difficult
ALTER TYPE order_status ADD VALUE 'refunded' AFTER 'cancelled';
```

**ENUM alternative**: Use a lookup table when values change frequently

```sql
-- Lookup table — SMALLINT IDENTITY is fine here (small, internal, never exposed)
CREATE TABLE order_status (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO order_status (name) VALUES
    ('pending'), ('confirmed'), ('shipped'), ('delivered'), ('cancelled');

CREATE TABLE "order" (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    status_id SMALLINT NOT NULL REFERENCES order_status(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## JSONB Type

Best for data with a flexible or frequently changing structure.

```sql
CREATE TABLE product (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    -- Category-specific attributes as JSONB
    attributes JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- GIN index for JSONB search optimization
CREATE INDEX idx_product_attributes ON product USING GIN (attributes);

-- Expression Index for frequently queried keys
CREATE INDEX idx_product_attr_color ON product ((attributes->>'color'));

-- Query examples
SELECT * FROM product WHERE attributes @> '{"color": "red"}';
SELECT * FROM product WHERE attributes->>'brand' = 'Apple';
```

**JSONB rules**:
- Core data that can be modeled relationally → use proper columns
- JSONB is for supplementary data, metadata, flexible attributes only
- Never store FK-like IDs inside JSONB (no referential integrity)

## Boolean

```sql
CREATE TABLE feature_flag (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL UNIQUE,
    is_enabled BOOLEAN NOT NULL DEFAULT false
);

-- Partial Index combines well with Boolean
CREATE INDEX idx_feature_flag_enabled ON feature_flag (name) WHERE is_enabled = true;
```

## Arrays

```sql
CREATE TABLE article (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    title TEXT NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_article_tags ON article USING GIN (tags);

-- Queries
SELECT * FROM article WHERE 'postgresql' = ANY(tags);
SELECT * FROM article WHERE tags @> ARRAY['postgresql', 'design'];
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
CREATE TABLE user_account (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    email email NOT NULL,
    website url,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE invoice (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    amount positive_amount NOT NULL,
    recipient_email email NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**When to use domains**: When the same constrained type appears in 3+ columns across different tables. It avoids duplicating CHECK constraints and ensures consistent validation.

**When NOT to use**: For one-off constraints on a single column — just use inline CHECK.

## Generated Columns (PostgreSQL 12+)

Computed columns stored on disk, automatically maintained by PostgreSQL.

```sql
CREATE TABLE product (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    tax_rate NUMERIC(5, 4) NOT NULL DEFAULT 0.10,
    -- Automatically computed and stored
    price_with_tax NUMERIC(12, 2) GENERATED ALWAYS AS (price * (1 + tax_rate)) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Full-text search vector (avoids recomputing on every query)
CREATE TABLE article (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', title || ' ' || body)
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_article_search ON article USING GIN (search_vector);

-- Query using the stored vector (no runtime computation)
SELECT * FROM article WHERE search_vector @@ to_tsquery('english', 'postgresql & design');
```

**When to use**: Computed values queried frequently (full-text vectors, derived amounts, normalized strings). Trades write-time computation for read-time performance.

**Limitation**: Only `STORED` is supported (not virtual). The expression cannot reference other tables or use subqueries.
