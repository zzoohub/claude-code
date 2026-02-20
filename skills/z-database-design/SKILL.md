---
name: z-database-design
description: >
  Expert guide for PostgreSQL database design, modeling, and optimization.
  Covers table design, schema modeling, index strategy, normalization/denormalization
  decisions, ACID transaction design, migration planning, and performance tuning.
  Use when user asks to "design a database", "create tables",
  "model data", "optimize queries", "add indexes", "normalize",
  "denormalize", "plan migration", "review schema", "design ERD",
  or discusses database architecture, data modeling, or PostgreSQL performance.
  Do NOT use for simple SELECT queries, one-off SQL syntax questions,
  or non-database application logic.
metadata:
  author: custom
  version: 1.2.0
  database: postgresql
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

### 3. Naming Convention (mandatory)
```
Schemas:      snake_case, abbreviated (fin, hr, mkt)
Tables:       snake_case, singular (user_account, NOT user_accounts)
Columns:      snake_case, no table prefix (name, NOT user_name in user table)
PK:           id (surrogate) or meaningful natural key
FK:           referenced_table_id (e.g., user_id, order_id)
Indexes:      idx_{table}_{columns} (e.g., idx_order_created_at)
Constraints:  {type}_{table}_{columns} (e.g., uq_user_email, chk_order_amount)
Enums:        snake_case (order_status, NOT OrderStatus)
```

## Workflow: When a Database Design Is Requested

### Step 1: Gather Requirements

**If a Software Architecture Design Document (SADD) exists**, read it first and extract:
- Domain entities and data flows (from Sections 1, 3, 4)
- Storage strategy and database choice (from Section 4.2)
- Performance/scalability expectations (from Section 6.5)
- Consistency model (from Section 4.1, 4.2)
- Ingestion patterns and data volume (from Section 4.1, 6.5)

For most decisions, follow the SADD as-is — it represents system-level decisions already made. However, **independently evaluate** decisions where database domain expertise is more appropriate:

| DB-domain decisions (evaluate independently) | System-level decisions (follow SADD) |
|---|---|
| Normalization level per table | Database platform choice (e.g., Neon PostgreSQL) |
| Partitioning strategy and partition key | System architecture pattern (e.g., event-driven) |
| Index types and index design | Which data goes in which store |
| Transaction isolation level per operation | Consistency model (strong vs eventual) |
| Column ordering and physical layout | Data retention policies |
| Materialized view refresh strategy | Read/write separation boundaries |
| Locking strategy (optimistic vs pessimistic) | Multi-tenancy approach |

If a DB-domain decision differs from what the SADD implies, **state the deviation and the reason explicitly**. Example: "SADD specifies strong consistency for order processing. For the order listing query, we use a materialized view with eventual consistency (refreshed every 30s) because the read volume makes synchronous joins impractical at the expected scale."

**If no SADD exists**, confirm the following with the user (ask if unknown):
- Domain and core entities
- Read/write ratio (read-heavy vs write-heavy)
- Expected data volume (thousands? millions? billions?)
- Ingestion pattern (append-only, backfill, frequent updates)
- Transaction requirements (ACID strictness)
- Scaling plans (single server vs distributed)

### Step 2: Schema Design
1. Identify core entities and relationships
2. Normalize to at least 3NF
3. Evaluate denormalization needs → consult `references/normalization-guide.md`
4. Choose appropriate data types → consult `references/data-types-guide.md`
5. Define constraints (PK, FK, UNIQUE, CHECK, NOT NULL)
6. Order columns from largest to smallest data type to minimize alignment padding → consult `references/performance-patterns.md`

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
-- Always follow this structure
-- Order columns largest-to-smallest for optimal storage alignment
CREATE TABLE schema_name.table_name (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
- Optimize column ordering for storage efficiency
- Design around query patterns: filter early, limit resultsets, cache computed data

### Step 7: Migration Plan
→ consult `references/migration-patterns.md`
- Version-controlled migration scripts
- Rollback scripts are mandatory
- Zero-downtime migration strategies

## When Reviewing an Existing Schema

Use this checklist:

1. **Naming**: Convention consistency
2. **Data types**: Appropriate type and size for each column
3. **Column ordering**: Largest to smallest for alignment padding optimization
4. **Constraints**: PK, FK, NOT NULL, CHECK, UNIQUE
5. **Indexes**: Missing indexes (especially on FK columns), unused indexes
6. **Normalization**: Unnecessary data duplication
7. **Transactions**: Appropriate isolation levels and locking for critical operations
8. **Security**: Sensitive data encryption, access control
9. **Scalability**: Partitioning, read replicas
10. **Ingestion pattern**: Append-only vs backfill vs update-heavy implications

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
| Temporal Data | Time-validity ranges, price history | `references/design-patterns.md` |
| Pessimistic Locking | High contention, short transactions | `references/acid-transactions.md` |
| Optimistic Locking | Low contention, user-facing workflows | `references/acid-transactions.md` |
| Queue (SKIP LOCKED) | Task/job queue processing | `references/acid-transactions.md` |

## Output

Produce **3 files**:

| File | Content |
|---|---|
| `database/database-design.md` | Requirements summary → ERD (Mermaid) → Schema decisions & trade-offs → Transaction design → Index strategy → Performance notes → Migration plan. SADD deviations noted inline. |
| `database/migrations/001_initial_schema.sql` | Executable DDL (tables, indexes, constraints, comments) + matching `_rollback.sql` |
| `database/erd.mermaid` | Standalone Mermaid ERD (also embedded in the design doc) |

## Critical Rules

- **Never use FLOAT for monetary values** → use NUMERIC(precision, scale)
- **Prefer TEXT over VARCHAR** (no performance difference in PostgreSQL; enforce length via CHECK)
- **Use ENUM only when values rarely change** (ALTER TYPE is expensive)
- **Always use TIMESTAMPTZ** for timestamps (timezone-aware)
- **Include created_at and updated_at on every table**
- **Default to surrogate keys** (BIGINT GENERATED ALWAYS AS IDENTITY); use natural keys only when clearly appropriate
- **Always create indexes on FK columns** — PostgreSQL does not do this automatically
- **Order columns largest-to-smallest** in CREATE TABLE to minimize alignment padding waste
- **Design around your query patterns** — filter early, keep resultsets reasonable, cache computed data
- **Choose isolation levels deliberately** — default Read Committed is fine for most OLTP; use Repeatable Read or Serializable only where correctness demands it, with retry logic
