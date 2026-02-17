---
name: z-postgresql
description: >
  PostgreSQL query writing, optimization, and production problem-solving patterns.
  Implements schemas designed by z-database-design skill with correct query patterns.
  Use when: writing SELECT/INSERT/UPDATE/DELETE queries, optimizing slow queries,
  debugging EXPLAIN plans, implementing pagination, full-text search, bulk operations,
  concurrency control, zero-downtime migrations, connection pooling, VACUUM strategy,
  or any PostgreSQL query-level work.
  Do NOT use for: schema design or data modeling (use z-database-design skill first),
  basic SQL syntax lookup (use context7).
  Workflow: z-database-design (design) → this skill (implement queries).
metadata:
  author: custom
  version: 2.0.0
  database: postgresql
---

# PostgreSQL Query & Optimization Skill

Implements schemas designed by `z-database-design` skill. Focuses on writing correct, performant queries and solving production PostgreSQL problems.

## Core Principles

### 1. Design First, Query Second
Schema must be designed using `z-database-design` skill before writing queries. This skill assumes:
- Naming follows snake_case convention (tables singular, FKs as `referenced_table_id`)
- PKs are `BIGINT GENERATED ALWAYS AS IDENTITY` unless UUID is justified
- All tables have `created_at` and `updated_at` (TIMESTAMPTZ)
- Columns ordered largest-to-smallest for alignment optimization
- FK columns are indexed (PostgreSQL does NOT auto-index FKs)

### 2. Measure Before Optimizing
Never optimize without evidence. Always:
1. Run `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` on the actual query
2. Identify the bottleneck (Seq Scan, Filter vs Index Cond, Sort, high buffer reads)
3. Apply the targeted fix
4. Verify with EXPLAIN again

### 3. Match Index to Query Pattern
Indexes are only useful when query WHERE/ORDER BY matches index structure exactly.
Consult `references/indexing-pitfalls.md` for common mismatches.

### 4. Keep Resultsets Reasonable
Every query should aim for under 10,000 rows returned. Use LIMIT, keyset pagination, or encourage filtering from the application layer. Consult `references/query-patterns.md` for patterns.

## Workflow: When Writing Queries

### Step 1: Understand the Access Pattern
- Which columns are filtered (WHERE)?
- Which columns are sorted (ORDER BY)?
- How many rows expected in result?
- Read frequency vs write frequency?
- Concurrent access patterns?

### Step 2: Write the Query
- SELECT only needed columns (never `SELECT *` in production)
- Filter early to reduce intermediate data volume
- Use CTEs for readability; be aware of CTE materialization behavior
- Use appropriate JOIN type and ensure join columns are indexed
- Consult `references/query-patterns.md` for pattern-specific guidance

### Step 3: Verify with EXPLAIN
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
```
Consult `references/explain-guide.md` for reading plans.

Key checks:
- No Seq Scan on large tables (unless intentional full-table operation)
- Index Cond covers all filter columns (no leftover Filter step)
- Rows estimated ≈ actual (if not, run ANALYZE)
- No external Sort (add index or increase work_mem)

### Step 4: Index Strategy
→ Consult `references/indexing-pitfalls.md`
- Composite index column order: equality first → range next → sort last
- Partial index for low-selectivity columns (boolean, status)
- Covering index (INCLUDE) for index-only scans
- Expression index for function-based filters

### Step 5: Production Readiness
→ Consult `references/production-ops.md`
- Connection pooling configured
- VACUUM/ANALYZE strategy in place
- Monitoring for slow queries and lock contention

## Quick Decision Table

| Problem | Solution | Reference |
|---------|----------|-----------|
| Deep pagination | Keyset/cursor pagination | `references/query-patterns.md` |
| Full-text search | tsvector + GIN index | `references/query-patterns.md` |
| N+1 queries | JSON aggregation or LATERAL join | `references/query-patterns.md` |
| Slow query | EXPLAIN ANALYZE → targeted index | `references/explain-guide.md` |
| Index not used | Check pitfalls (order, collation, stats) | `references/indexing-pitfalls.md` |
| High contention | SKIP LOCKED / advisory locks / batching | `references/query-patterns.md` |
| Schema migration | NOT VALID + VALIDATE / CONCURRENTLY | `references/production-ops.md` |
| Bulk import | COPY + staging table | `references/query-patterns.md` |
| Caching aggregates | Materialized views | `references/query-patterns.md` |
| Multi-tenant | Row-level security | `references/query-patterns.md` |
| Hierarchical data | Recursive CTE with depth limit | `references/query-patterns.md` |
| JSONB queries | GIN or expression index | `references/query-patterns.md` |
| Concurrent edits | Optimistic locking (version column) | `references/query-patterns.md` |
| Stale planner stats | ANALYZE after bulk operations | `references/production-ops.md` |

## Critical Rules

- **Never `SELECT *` in production** — specify columns explicitly
- **Always EXPLAIN before and after optimization** — measure, don't guess
- **Composite index order matters** — equality → range → sort (leftmost prefix rule)
- **Partial index WHERE must match query WHERE exactly** — PostgreSQL won't infer implied conditions
- **Run ANALYZE after bulk DELETE/INSERT** — stale statistics cause wrong plan choices
- **Index FK columns** — PostgreSQL does not auto-index foreign keys; missing FK indexes cause slow CASCADE deletes
- **Use TIMESTAMPTZ** — never bare TIMESTAMP (inherited from z-database-design)
- **Use NUMERIC for money** — never FLOAT/REAL (inherited from z-database-design)
- **Keyset pagination over OFFSET** — OFFSET has O(n) cost
- **CONCURRENTLY for production indexes** — regular CREATE INDEX blocks writes
