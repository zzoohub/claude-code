---
name: database-design
description: |
  Expert guide for PostgreSQL database design, modeling, and optimization.
  Covers table design, schema modeling, index strategy, normalization/denormalization
  decisions, ACID transaction design, migration planning, and performance tuning.
  Use when user asks to "design a database", "create tables",
  "model data", "optimize queries", "add indexes", "normalize",
  "denormalize", "plan migration", "review schema", "design ERD",
  or discusses database architecture, data modeling, or PostgreSQL performance.
  Do NOT use for simple SELECT queries, one-off SQL syntax questions,
  or non-database application logic.
---

# PostgreSQL Database Design Skill

PostgreSQL-specific database design skill. Provides systematic guidance from schema design through performance optimization.

## Core Principles

### 1. Think First, Design Later
Database design must be completed before writing code. Always follow this sequence:

1. **Requirements analysis**: What data, who uses it, how is it accessed?
2. **Conceptual → Logical → Physical**: Design all three diagrams in order
3. **Explicit trade-offs**: Every design decision has a reason and a cost

### 2. PostgreSQL First
- All examples and DDL use PostgreSQL syntax
- Actively leverage PostgreSQL-specific features: JSONB, Array, Enum, Partial Index, CTE, Window Functions, Range Types, Row-Level Security
- Consult `references/` files for detailed guidance as needed

### 3. Naming Convention

Pick one and apply consistently — the value is uniformity, not the specific choice.

```
Schemas:      snake_case, abbreviated (fin, hr, mkt)
Tables:       snake_case, plural (`user_accounts`, `orders`). Plural is the industry default and avoids reserved-word collisions (`order` → `orders`). FK columns stay singular: `user_account_id REFERENCES user_accounts(id)`.
Columns:      snake_case, no table prefix (name, NOT user_name in user table)
PK:           id (surrogate) or meaningful natural key
FK:           referenced_table_id (e.g., user_id, order_id)
Indexes:      idx_{table}_{columns} (e.g., idx_orders_created_at)
Constraints:  {type}_{table}_{columns} (e.g., uq_user_email, chk_orders_amount)
Enums:        snake_case (order_status, NOT OrderStatus)
```

## Workflow: When a Database Design Is Requested

### Step 1: Gather Requirements

**If architecture docs exist** (`docs/arch/`), read them first and extract:
- Domain entities and data flows (from `context.md` §1, §4 and `system.md` §2)
- Storage strategy and database choice (from `system.md` §3)
- Performance/scalability expectations (from `context.md` §3 and `system.md` §5)
- Consistency model (from `system.md` §3)
- Ingestion patterns and data volume (from `context.md` §3)

For most decisions, follow the design doc as-is — it represents system-level decisions already made. However, **independently evaluate** decisions where database domain expertise is more appropriate:

| DB-domain decisions (evaluate independently) | System-level decisions (follow design doc) |
|---|---|
| Normalization level per table | Database platform choice (e.g., Neon PostgreSQL) |
| Partitioning strategy and partition key | System architecture pattern (e.g., event-driven) |
| Index types and index design | Which data goes in which store |
| Transaction isolation level per operation | Consistency model (strong vs eventual) |
| Column ordering and physical layout | Data retention policies |
| Materialized view refresh strategy | Read/write separation boundaries |
| Locking strategy (optimistic vs pessimistic) | Multi-tenancy approach |

If a DB-domain decision differs from what the design doc implies, **state the deviation and the reason explicitly**. Example: "Design doc specifies strong consistency for order processing. For the order listing query, we use a materialized view with eventual consistency (refreshed every 30s) because the read volume makes synchronous joins impractical at the expected scale."

**If no design doc exists**, confirm the following with the user (ask if unknown):
- Domain and core entities
- Read/write ratio (read-heavy vs write-heavy)
- Expected data volume (thousands? millions? billions?)
- Ingestion pattern (append-only, backfill, frequent updates)
- Transaction requirements (ACID strictness)
- Scaling plans (single server vs distributed)

**Feature-aware schema** (read before writing any DDL):

Design the **full schema for the complete product vision** (so you don't paint yourself into a corner), then split migrations by domain so features can ship independently.

If the project tracks features in planning docs (e.g. `docs/prd/features/*.md` or any similar `features/` directory), read the relevant spec and **tag tables/indexes with the feature** in comments — e.g., `[auth]`, `[billing]`, `[workspace]`. The tags drive which migration file each table lives in, and the dev order in the PRD determines file numbering (`001_create_user_accounts.sql` → `002_create_workspaces.sql` → ...).

If no such planning docs exist, ask the user which features ship in which order — that order determines numbering.

Don't collapse all of MVP into one mega-migration. Don't over-split into per-table files either — one migration per **domain/bounded context**, holding related tables together.

### Step 2: Schema Design
1. Identify core entities and relationships
2. Normalize to at least 3NF
3. Evaluate denormalization needs → consult `references/normalization-guide.md`
4. Choose appropriate data types → consult `references/data-types-guide.md`
5. Define constraints (PK, FK, UNIQUE, CHECK, NOT NULL)

### Step 3: Transaction & Concurrency Design
→ consult `references/acid-transactions.md`

Identify operations that require explicit transaction design:
- Financial or monetary operations (transfers, payments)
- Inventory or capacity management (stock, seats, quotas)
- Multi-step workflows that must be atomic
- High-contention resources (counters, queues)

For each, decide:
- Isolation level (Read Committed, Repeatable Read, Serializable)
- Locking strategy (optimistic vs pessimistic, advisory locks)
- Retry and deadlock prevention approach

### Step 4: Write DDL
```sql
-- Default skeleton — UUID v7 PK, TIMESTAMPTZ everywhere
CREATE TABLE schema_name.table_name (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),  -- PG18+; ≤17: generate at app layer
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- then INTEGER columns, then SMALLINT, BOOLEAN, etc.
);

-- Indexes go in separate statements
CREATE INDEX idx_table_column ON schema_name.table_name (column);

-- Document with comments
COMMENT ON TABLE schema_name.table_name IS 'Table description';
COMMENT ON COLUMN schema_name.table_name.column IS 'Column description';
```

⚠️ The `updated_at DEFAULT now()` only fires on INSERT. To keep it accurate on UPDATE, attach a `BEFORE UPDATE` trigger or manage it at the application/ORM layer — pick one and apply consistently. See `references/design-patterns.md` §9 "Auto-Updated Timestamps".

### Step 5: Index Strategy
→ consult `references/indexing-strategy.md`
- Verify auto-indexes on PK; manually create indexes on FK columns (PostgreSQL does NOT auto-index FK)
- Identify columns frequently used in WHERE, JOIN, ORDER BY
- Calculate selectivity: distinct values / total rows
- Consider Partial Index, Expression Index, Covering Index (INCLUDE), GIN/GiST/BRIN

### Step 6: Performance Review
→ consult `references/performance-patterns.md`
- Verify execution plans with EXPLAIN ANALYZE
- Consider connection pooling (PgBouncer)
- Evaluate partitioning needs (hundreds of millions of rows+)
- Suggest PostgreSQL configuration tuning
- Design around query patterns: ensure indexes support WHERE/JOIN, limit resultsets, cache computed data

### Step 7: Migration Plan
→ consult `references/migration-patterns.md`
- Version-controlled migration scripts
- Rollback scripts are mandatory
- Zero-downtime migration strategies

### Step 8: Pre-Output Quality Gate

Before writing `docs/arch/database.md` or any migration file, every item below must be true. A failing item either blocks output or gets explicitly called out in the document with rationale.

**Structural integrity**
- [ ] Every table has a PRIMARY KEY
- [ ] Every FK column used in JOIN or filter has an index (PG does not auto-create); FKs intentionally left unindexed are documented in a comment or ADR
- [ ] Every entity table has `created_at` (and `updated_at` unless append-only). Pure association/pivot tables may omit both when no audit trail is needed
- [ ] No FLOAT/REAL used for money — NUMERIC(p,s) only
- [ ] All timestamps are TIMESTAMPTZ, not TIMESTAMP
- [ ] ENUMs used only where value set is stable; otherwise lookup table

**Constraints and safety**
- [ ] NOT NULL on every column that logically cannot be null
- [ ] CHECK constraints on domain values (email format, positive amounts, status whitelist)
- [ ] UNIQUE constraints on every business-identity column (email, slug, external_id)
- [ ] ON DELETE behavior explicit on every FK (CASCADE / RESTRICT / SET NULL)

**Multi-tenancy (if applicable)**
- [ ] Every tenant-scoped table has `tenant_id` column AND RLS policy — or schema/database-per-tenant is chosen with ADR
- [ ] Composite indexes lead with `tenant_id` where tenant-scoped queries dominate

**Indexes**
- [ ] Partial indexes used for low-selectivity boolean/status columns (don't index `WHERE is_deleted = false` globally)
- [ ] Composite index column order follows equality → range → sort rule
- [ ] No obvious unused redundancy (e.g., `(a)` + `(a, b)` — drop `(a)`)

**Migrations**
- [ ] Every migration file has a matching `*.rollback.sql`
- [ ] Files are split per-domain (no single `001_initial_schema.sql`)
- [ ] `CREATE INDEX CONCURRENTLY` used for indexes on any table that will see production traffic before the index finishes
- [ ] Destructive operations (DROP COLUMN, RENAME) follow expand-contract pattern, not direct

**Deviations**
- [ ] Any decision that deviates from the design doc (`docs/arch/system.md`) is noted inline with reason

If any item fails and isn't justified in-document, revise before saving. Do not save substandard work.

## When Reviewing an Existing Schema

Use this checklist:

1. **Naming**: Convention consistency
2. **Data types**: Appropriate type and size for each column
3. **Constraints**: PK, FK, NOT NULL, CHECK, UNIQUE
4. **Indexes**: Missing indexes (especially on FK columns), unused indexes
5. **Normalization**: Unnecessary data duplication
6. **Transactions**: Appropriate isolation levels and locking for critical operations
7. **Security**: Sensitive data encryption, access control
8. **Scalability**: Partitioning, read replicas
9. **Ingestion pattern**: Append-only vs backfill vs update-heavy implications
10. **Storage**: Column ordering for alignment (large tables only) → `references/performance-patterns.md`

## Key Design Patterns Summary

| Pattern | When to Use | Reference |
|---------|------------|-----------|
| Table Inheritance | Common attributes + type-specific attributes | `references/design-patterns.md` |
| CQRS | Read/write model separation needed | `references/design-patterns.md` |
| Event Sourcing | Complete change history required | `references/design-patterns.md` |
| Soft Delete | Logical deletion required | `references/design-patterns.md` |
| Audit Trail | Change tracking required | `references/design-patterns.md` |
| Partitioning | Large table management | `references/performance-patterns.md` |
| JSONB Hybrid | Flexible schema + relational mix | `references/data-types-guide.md` |
| Domain Types | Reusable constrained types (email, URL, amounts) | `references/data-types-guide.md` |
| Generated Columns | Stored computed values (FTS vectors, derived amounts) | `references/data-types-guide.md` |
| Temporal Data | Time-validity ranges, price history | `references/design-patterns.md` |
| Pessimistic Locking | High contention, short transactions | `references/acid-transactions.md` |
| Optimistic Locking | Low contention, user-facing workflows | `references/acid-transactions.md` |
| Queue (SKIP LOCKED) | Task/job queue processing | `references/acid-transactions.md` |

## Output

Produce these files:

| File | Content |
|---|---|
| `docs/arch/database.md` | **Table of Contents** (linked) → Requirements summary → ERD (Mermaid, consult `references/mermaid-erd.md` for syntax) → Schema decisions & trade-offs → Transaction design → Index strategy → Performance notes → Migration plan. Design doc deviations noted inline. Start with a TOC right after the title — the document gets long and a TOC makes it navigable. |
| `db/migrations/NNN_<verb>_<domain>.sql` | Executable DDL split **per domain** (never a single "initial schema" file). Each file pairs with `NNN_<verb>_<domain>.rollback.sql`. See naming convention below. |

### Migration File Naming

Split the initial schema into **per-domain migration files** — one file per bounded context or aggregate. Never produce a single `001_initial_schema.sql` containing everything.

```
db/migrations/
├── 001_create_user_accounts.sql
├── 001_create_user_accounts.rollback.sql
├── 002_create_workspaces.sql
├── 002_create_workspaces.rollback.sql
├── 003_create_billing.sql
├── 003_create_billing.rollback.sql
└── ...
```

**Why per-domain**:
- Rollback is atomic — revert one domain without touching others
- `git blame` attributes each domain's schema history to the right PR
- PR review unit matches the feature unit
- Never modify a migration that has been applied — add a new one. Editing applied migrations creates drift between environments and breaks rollback chains

**Numbering**: Zero-padded sequential (`001`, `002`, ...). Follow the dev order from `docs/prd/prd.md` when deciding which domains migrate first.

**Verbs**: `create_` for new tables, `add_` for columns/indexes, `alter_` for type changes, `backfill_` for data migrations, `drop_` for removals (use expand-contract — see `references/migration-patterns.md`).

## Recommended Extensions

Enable these when the design requires their capabilities:

| Extension | Purpose | Enable When |
|-----------|---------|-------------|
| `btree_gist` | GiST operator support for B-tree types | Exclusion constraints (temporal data, reservations) |
| `pg_trgm` | Trigram-based similarity | Fuzzy text search, `LIKE '%keyword%'` optimization |
| `pgcrypto` | Cryptographic functions | Hashing passwords, generating UUIDs (pre-PG13) |
| `pg_stat_statements` | Query performance tracking | Production monitoring (enable always) |
| `pg_partman` | Automated partition management | Time-series partitioning in production |
| `uuid-ossp` | UUID generation functions (v1/v3/v5 only) | When you need v1/v3/v5 specifically. For v4, `gen_random_uuid()` is built-in (PG13+). For v7 (this skill's PK default), use PG18 `uuidv7()` or generate at the application layer |
| `vector` (pgvector) | Vector similarity search (HNSW, IVFFlat) | Embeddings, semantic search, RAG — up to ~100M vectors co-located with relational data |

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- needed for EXCLUDE constraints
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- needed for fuzzy search indexes
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;  -- query performance tracking
```

## Critical Rules — Data / Performance Disasters

These prevent data corruption, loss, or major regressions. Not negotiable.

- **Never use FLOAT for monetary values** → `NUMERIC(precision, scale)`. FLOAT cannot represent decimals exactly; you will lose money.
- **Always use TIMESTAMPTZ** for timestamps. `TIMESTAMP` (without tz) silently strips timezone info — a footgun across regions/clients.
- **Index every FK you JOIN or filter on.** PostgreSQL does not auto-create FK indexes. Missing FK indexes turn parent-row updates/deletes into full table scans. Intentionally unindexed FKs must be documented.
- **`ON DELETE` behavior must be explicit on every FK** (`CASCADE` / `RESTRICT` / `SET NULL` / `NO ACTION`). The default differs by tool/intent and propagates surprises silently.
- **`CREATE INDEX CONCURRENTLY`** for any index added to a table that already serves production traffic. Plain `CREATE INDEX` takes a write lock for the duration.
- **Destructive ops (`DROP COLUMN`, `RENAME`) follow expand-contract**, never direct. Direct DDL mid-deploy breaks rolling deployments.
- **Auto-DDL (`synchronize: true` and friends) is forbidden in any deployed environment.** Migrations are the only sanctioned schema-mutation path.

## Conventions — Defensible Defaults

These are choices, not mandates. The skill's defaults are defensible; teams may swap them so long as consistency holds.

- **PK default: UUID v7.** External-API-safe, distributed/offline-friendly, time-ordered (preserves index locality, unlike v4). BIGINT IDENTITY remains the right pick for internal-only IDs and megatables where 8-byte savings measurably matter — see "Primary Key Type Decision" below.
- **Strings: TEXT by default.** No performance cost in PostgreSQL. Use `VARCHAR(n)` only when the length cap carries semantic weight you want enforced at the type level. Otherwise enforce length with `CHECK`.
- **ENUM only when values are stable.** `ALTER TYPE ... ADD VALUE` runs outside transactions and propagates awkwardly. For anything user-extensible, use a lookup table.
- **Default isolation: Read Committed.** Most OLTP fits. Escalate to Repeatable Read / Serializable per-operation only where correctness demands it (with retry logic).
- **`created_at` / `updated_at` on entity tables**, except pure association/pivot tables (`user_role`) and append-only event tables (which need only `created_at`).
- **Multi-tenancy default depends on tenant shape**:
  - **Many small tenants (B2B SaaS)** → `tenant_id` column + RLS. Single DB, simple ops, isolation enforced in DB.
  - **Few large tenants (enterprise)** → schema-per-tenant or DB-per-tenant. Better blast-radius isolation, easier per-tenant tuning/backup, regulatory-friendlier.
  - Either way, record as an ADR. Tenant-scoped composite indexes lead with `tenant_id` *only when* tenant-scoped queries dominate; cross-tenant analytics paths may want the opposite ordering.
- **Design around your query patterns** — indexes serve real WHERE/JOIN, resultsets bounded, computed values cached when worthwhile.

## Primary Key Type Decision

PK type is a **one-way door** — changing it later requires rewriting every FK reference and external consumer. Record the choice as an ADR.

| Situation | Choose | Why |
|---|---|---|
| **Default** — modern app with any external surface (API, mobile, third-party integration, possible future multi-region/offline) | **UUID v7** | Time-ordered (preserves B-tree locality, unlike v4). Safe to expose externally. Distributed/offline-safe. Avoids painful BIGINT→UUID migration if requirements grow. |
| Pure internal IDs, never exposed externally, single-region only, and 8-byte savings are measurable (event logs, metrics, billion-row append-only tables) | **BIGINT IDENTITY** | 8 bytes vs 16, denser B-tree, human-readable in logs. Savings cascade through FK columns. |
| Distributed ID generation across regions/clients (no central DB assignment) | **UUID v7** | No coordination needed; clients can mint IDs |
| Offline-first clients that generate IDs before sync | **UUID v7** | Collision-safe without server round-trip |
| Merging data from multiple systems later | **UUID v7** | No renumbering at merge time |

**Never use UUID v4 for PKs on hot tables** — random ordering fragments B-tree indexes and hurts write performance. v4 is only acceptable for low-volume / low-write tables.

### UUID v7 generation

- **PostgreSQL 18+**: native `uuidv7()` — `id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7()`.
- **PostgreSQL ≤17**: generate at the application layer (Node: `uuidv7` package; Python: `uuid_utils.uuid7()`; Rust: `Uuid::now_v7()`; Go: `github.com/gofrs/uuid` v5+; Java: `com.github.f4b6a3:uuid-creator`). Pass the generated UUID into `INSERT` explicitly.
- The `uuid-ossp` extension covers v1/v3/v5 only — not v7. `gen_random_uuid()` produces v4 (the version we're avoiding).

**Mixed strategy is fine**: UUID v7 for most tables, BIGINT for the handful of high-volume internal tables where bytes measurably matter (events, audit logs). Just don't flip a whole schema's convention later.
