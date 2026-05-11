# PostgreSQL Production Operations

Patterns for running PostgreSQL reliably in production.

## 1. Zero-Downtime Migrations

### Adding NOT NULL Constraint (safe pattern)
```sql
-- Step 1: Add CHECK constraint without validation (instant, no lock)
ALTER TABLE user_accounts ADD CONSTRAINT chk_user_email_nn
    CHECK (email IS NOT NULL) NOT VALID;

-- Step 2: Backfill NULLs in batches (see Backfilling section)

-- Step 3: Validate (scans table, minimal lock — NOT ACCESS EXCLUSIVE)
ALTER TABLE user_accounts VALIDATE CONSTRAINT chk_user_email_nn;

-- Step 4: Convert to actual NOT NULL (instant, planner uses validated constraint)
ALTER TABLE user_accounts ALTER COLUMN email SET NOT NULL;
ALTER TABLE user_accounts DROP CONSTRAINT chk_user_email_nn;
```

### Adding Index (non-blocking)
```sql
-- ✅ CONCURRENTLY: does not block reads or writes
CREATE INDEX CONCURRENTLY idx_user_email ON user_accounts (email);

-- ⚠️ Cannot run inside a transaction block
-- ⚠️ If it fails, clean up the invalid index:
SELECT indexname, indisvalid FROM pg_indexes
JOIN pg_index ON pg_indexes.indexname::regclass = pg_index.indexrelid
WHERE NOT indisvalid;

DROP INDEX IF EXISTS idx_user_email;  -- then retry
```

### Adding Foreign Key (non-blocking)
```sql
ALTER TABLE orders ADD CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES user_accounts(id) NOT VALID;

-- Validate separately (scans but doesn't hold heavy lock)
ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_user;
```

### Column Rename (Expand-Contract)
```sql
-- Phase 1: Add new column
ALTER TABLE user_accounts ADD COLUMN full_name TEXT;

-- Phase 2: Dual-write (application writes to both columns)
-- Phase 3: Backfill old rows
UPDATE user_accounts SET full_name = name WHERE full_name IS NULL;

-- Phase 4: Switch reads to new column (deploy)
-- Phase 5: Drop old column
ALTER TABLE user_accounts DROP COLUMN name;
```

## 2. Backfilling Large Tables

Single UPDATE on millions of rows = table lock + WAL bloat. Always batch.

Transaction control (COMMIT between batches) requires a `PROCEDURE` — `DO` blocks run in a single transaction and cannot commit mid-execution.

```sql
CREATE OR REPLACE PROCEDURE backfill_new_column(batch_size INT DEFAULT 5000)
LANGUAGE plpgsql AS $$
DECLARE
    affected INT;
BEGIN
    LOOP
        WITH batch AS (
            SELECT id FROM user_accounts
            WHERE new_column IS NULL
            LIMIT batch_size
            FOR UPDATE SKIP LOCKED
        )
        UPDATE user_accounts u
        SET new_column = compute_value(u.old_column)
        FROM batches b WHERE u.id = b.id;

        GET DIAGNOSTICS affected = ROW_COUNT;
        EXIT WHEN affected = 0;
        COMMIT;  -- releases locks, writes WAL for this batch only
        PERFORM pg_sleep(0.1);  -- reduce load between batches
    END LOOP;
END $$;

-- Run it:
CALL backfill_new_column(5000);

-- Clean up when done:
DROP PROCEDURE backfill_new_column;
```

**Alternative (simple loop from application code)** — if your migration framework doesn't support procedures, loop from the app:
```sql
-- Run this in a loop from application code, each call in its own transaction:
WITH batch AS (
    SELECT id FROM user_accounts
    WHERE new_column IS NULL
    LIMIT 5000
    FOR UPDATE SKIP LOCKED
)
UPDATE user_accounts u
SET new_column = compute_value(u.old_column)
FROM batches b WHERE u.id = b.id;
-- Check affected rows; stop when 0
```
```

## 3. VACUUM & ANALYZE Strategy

### Why It Matters
- VACUUM reclaims dead tuples (from UPDATE/DELETE)
- ANALYZE refreshes planner statistics (row counts, value distribution)
- Without VACUUM: table/index bloat grows indefinitely
- Without ANALYZE: planner makes wrong decisions (Seq Scan instead of Index Scan)

### Monitor Dead Tuples
```sql
SELECT
    schemaname, relname,
    n_live_tup, n_dead_tup,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
    last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Per-Table Autovacuum Tuning (for hot tables)
```sql
-- More aggressive vacuum for frequently updated tables
ALTER TABLE orders SET (
    autovacuum_vacuum_scale_factor = 0.05,   -- trigger at 5% dead tuples (default 20%)
    autovacuum_analyze_scale_factor = 0.02,  -- re-analyze at 2% changes
    autovacuum_vacuum_cost_delay = 2         -- less throttling
);
```

### When to Run Manual ANALYZE
- After bulk INSERT, UPDATE, or DELETE
- After creating new indexes
- When EXPLAIN shows row estimate ≠ actual (stale stats)

```sql
ANALYZE orders;           -- specific table
ANALYZE;                   -- entire database (use sparingly)
```

## 4. Connection Pooling

PostgreSQL forks ~10MB per connection. 500 connections = 5GB RAM just for processes.

### PgBouncer Configuration
```ini
[pgbouncer]
pool_mode = transaction        # release connection after each transaction
default_pool_size = 20         # connections per user/database pair
max_client_conn = 1000         # max client connections to PgBouncer
reserve_pool_size = 5          # emergency extra connections
```

| Pool Mode | Description | Caveat |
|-----------|-------------|--------|
| transaction | Released after each TX | **Recommended**. Breaks SET, LISTEN/NOTIFY, prepared statements |
| session | Held for entire session | Use for legacy apps needing session state |
| statement | Released after each statement | Only for simple read-only queries |

## 5. Index Maintenance

### Find Unused Indexes
```sql
SELECT
    schemaname, tablename, indexname,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND indexrelid NOT IN (
        SELECT conindid FROM pg_constraint WHERE contype IN ('p', 'u')
    )
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Rebuild Bloated Indexes (zero-downtime)
```sql
REINDEX INDEX CONCURRENTLY idx_orders_created_at;

-- Or create-new + swap (more control)
CREATE INDEX CONCURRENTLY idx_orders_created_at_new ON orders (created_at);
DROP INDEX idx_orders_created_at;
ALTER INDEX idx_orders_created_at_new RENAME TO idx_orders_created_at;
```

### Check Index Sizes
```sql
SELECT
    tablename, indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 20;
```

## 6. PostgreSQL Configuration Tuning

### Key Parameters

| Parameter | OLTP | OLAP | Description |
|-----------|------|------|-------------|
| shared_buffers | 25-40% RAM | 50-70% RAM | Shared memory cache |
| work_mem | 4-64MB | 64MB-1GB | Per-operation sort/hash |
| maintenance_work_mem | 512MB-2GB | 1-4GB | VACUUM, CREATE INDEX |
| effective_cache_size | 75% RAM | 75% RAM | Planner estimate of OS cache |

### Verify Cache Hit Rate
```sql
SELECT
    sum(blks_hit) * 100.0 / nullif(sum(blks_hit) + sum(blks_read), 0) AS cache_hit_ratio
FROM pg_stat_database;
-- Should be > 99% for OLTP workloads
```

### WAL Tuning for High-Write Workloads
```sql
-- Temporarily increase during bulk loads:
wal_buffers = '64MB'
checkpoint_completion_target = 0.9
max_wal_size = '4GB'
```

## 7. Enabling pg_stat_statements

Several diagnostic queries in this skill rely on `pg_stat_statements`. It's not enabled by default.

```sql
-- 1. Add to postgresql.conf (requires restart)
-- shared_preload_libraries = 'pg_stat_statements'

-- 2. Create the extension (no restart needed after library is loaded)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 3. Verify it's working
SELECT count(*) FROM pg_stat_statements;
```

Key settings (postgresql.conf):
```ini
pg_stat_statements.max = 5000          # max tracked statements (default 5000)
pg_stat_statements.track = top         # track top-level statements only (default)
pg_stat_statements.track_utility = on  # track utility commands (CREATE, ALTER, etc.)
```

On managed PostgreSQL services (RDS, Cloud SQL, Neon, Supabase), this extension is usually pre-installed — you just need `CREATE EXTENSION`.

```sql
-- Reset statistics (useful after deploying query changes)
SELECT pg_stat_statements_reset();
```

## 8. Monitoring Checklist

| What to Monitor | Query / Tool | Threshold |
|-----------------|-------------|-----------|
| Cache hit ratio | `pg_stat_database` | > 99% |
| Dead tuple ratio | `pg_stat_user_tables` | < 10% per table |
| Unused indexes | `pg_stat_user_indexes` | Drop if idx_scan = 0 |
| Long-running transactions | `pg_stat_activity` | Alert > 5 min |
| Lock contention | `pg_locks` + `pg_stat_activity` | Alert on blocking > 30s |
| Slow queries | `pg_stat_statements` | Investigate top 10 by avg_ms |
| Connection count | `pg_stat_activity` | Alert at 80% of max_connections |
| WAL generation rate | `pg_stat_wal` (PG14+) | Baseline + alert on spikes |
