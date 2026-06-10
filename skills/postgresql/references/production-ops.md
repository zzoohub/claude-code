# PostgreSQL Production Operations

Patterns for running PostgreSQL reliably in production.

For runnable diagnostic queries against a live database (slowest queries, lock waits, bloat, vacuum lag, stale planner stats), see `../scripts/query_diagnostics.sql` — psql-ready queries you can execute directly.

## Table of Contents

1. [Zero-Downtime Migrations](#1-zero-downtime-migrations)
2. [Backfilling Large Tables](#2-backfilling-large-tables)
3. [VACUUM & ANALYZE Strategy](#3-vacuum--analyze-strategy)
4. [Connection Pooling](#4-connection-pooling)
5. [Index Maintenance](#5-index-maintenance)
6. [PostgreSQL Configuration Tuning](#6-postgresql-configuration-tuning)
7. [Enabling pg_stat_statements](#7-enabling-pg_stat_statements)
8. [Monitoring Checklist](#8-monitoring-checklist)

## 1. Zero-Downtime Migrations

### The Migration Session Preamble (run first, every time)

Even "safe" DDL (`ADD COLUMN`, `ADD CONSTRAINT ... NOT VALID`) takes a **brief ACCESS EXCLUSIVE lock**. If a long-running transaction holds the table, the DDL waits — and every subsequent query on that table queues **behind the waiting DDL**. That queue, not the DDL itself, is the classic migration outage. Fail fast and retry instead:

```sql
SET lock_timeout = '2s';        -- DDL gives up instead of stalling all traffic
SET statement_timeout = '15min'; -- bound the whole step (size to the operation)
-- on lock_timeout failure: wait, retry; if it keeps failing, find the blocker
-- (long transaction / idle-in-transaction) via scripts/query_diagnostics.sql #10
```

(`CREATE/DROP/REINDEX ... CONCURRENTLY` can't run inside a transaction block — set these at session level, not inside one `BEGIN...COMMIT`.)

**Execution runbook**: backup/snapshot → session preamble → run the step → verify (invalid-index check, constraint validated) → `ANALYZE` affected tables → watch error rates and lock waits before the next step.

### Adding NOT NULL Constraint (safe pattern)
```sql
-- Step 1: Add CHECK constraint without validation (brief ACCESS EXCLUSIVE —
-- fails fast under the preamble's lock_timeout instead of queueing traffic)
ALTER TABLE user_accounts ADD CONSTRAINT chk_user_email_nn
    CHECK (email IS NOT NULL) NOT VALID;

-- Step 2: Backfill NULLs in batches (see Backfilling section)

-- Step 3: Validate (scans under SHARE UPDATE EXCLUSIVE — reads AND writes continue)
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
-- ⚠️ If it fails, find the invalid index (OID join — robust across schemas;
--    avoid casting an unqualified name to ::regclass, which resolves via search_path):
SELECT n.nspname AS schema, c.relname AS index_name, i.indisvalid
FROM pg_index i
JOIN pg_class c ON c.oid = i.indexrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT i.indisvalid;

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

**No `FOR UPDATE`, no `SKIP LOCKED`** in the batch select: the `UPDATE` takes its own row locks, and the idempotent `IS NULL` recheck makes a concurrently-modified row safe to skip. `SKIP LOCKED` in particular is for competing-worker queues, never exhaustive backfills — it silently omits locked rows, and combined with an "exit when 0 rows" loop can end the backfill with rows still unprocessed.

Walk the table by **primary-key keyset**, not by re-scanning a `WHERE new_column IS NULL` predicate: the predicate scan re-reads already-processed (now dead) pages on every batch — quadratic page reads on a big table unless you add a partial index just for the backfill. The keyset cursor visits each page once. (Same canonical shape as the database-design skill's `migration-patterns.md`.)

```sql
CREATE OR REPLACE PROCEDURE backfill_new_column(batch_size INT DEFAULT 5000)
LANGUAGE plpgsql AS $$
DECLARE
    last_id UUID := '00000000-0000-0000-0000-000000000000';
    rows_scanned INT;
BEGIN
    LOOP
        WITH batch AS (
            SELECT id FROM user_accounts
            WHERE id > last_id
            ORDER BY id
            LIMIT batch_size
        ), updated AS (
            UPDATE user_accounts u
            SET new_column = compute_value(u.old_column)
            FROM batch b
            WHERE u.id = b.id AND u.new_column IS NULL  -- idempotent: safe to re-run
            RETURNING u.id
        )
        SELECT count(*), (SELECT id FROM batch ORDER BY id DESC LIMIT 1)
        INTO rows_scanned, last_id FROM batch;

        EXIT WHEN last_id IS NULL;  -- no rows past the cursor
        COMMIT;                     -- releases locks, bounds WAL per batch
        PERFORM pg_sleep(0.1);      -- throttle between batches
    END LOOP;
END $$;

-- Run it (CALL must not be wrapped in an outer transaction — psql without -1):
CALL backfill_new_column(5000);

-- Clean up when done:
DROP PROCEDURE backfill_new_column;
```

**Throttle against replication lag**: batch backfills are WAL storms — on a replicated setup, check `pg_stat_replication` (`replay_lag`) between batches and pause/raise the sleep when replicas fall behind, or read-after-write traffic on replicas starts failing while the backfill runs.

**Alternative (simple loop from application code)** — if your migration framework doesn't support procedures, run the same keyset batch from the app, each iteration in its own transaction, carrying `last_id` forward and stopping when the batch comes back empty.

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

Each PostgreSQL backend uses roughly 2-10MB of private memory (more with large `work_mem` or many prepared statements), plus connection and context-switch overhead. Hundreds of idle connections waste RAM and CPU — put a pooler in front.

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
| transaction | Released after each TX | **Recommended**. Breaks cross-statement session state (SET, LISTEN/NOTIFY); prepared statements work with PgBouncer 1.21+ via `max_prepared_statements`, break on older versions |
| session | Held for entire session | Use for legacy apps needing session state |
| statement | Released after each statement | Only for simple read-only queries |

## 5. Index Maintenance

### Find Unused Indexes
```sql
SELECT
    s.schemaname, s.relname AS tablename, s.indexrelname AS indexname,
    s.idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size
FROM pg_stat_user_indexes s
JOIN pg_index ix ON ix.indexrelid = s.indexrelid
-- idx_scan is cumulative since the last stats reset — trust 0 only over a
-- representative window (PG16+ has last_idx_scan for recency).
WHERE s.idx_scan = 0
    -- never drop what enforces uniqueness or feeds logical replication:
    AND NOT ix.indisunique
    AND NOT ix.indisprimary
    AND NOT ix.indisreplident
    AND s.indexrelid NOT IN (
        SELECT conindid FROM pg_constraint WHERE contype IN ('p', 'u')
    )
ORDER BY pg_relation_size(s.indexrelid) DESC;
```

### Rebuild Bloated Indexes (zero-downtime)
```sql
REINDEX INDEX CONCURRENTLY idx_orders_created_at;

-- Or create-new + swap (more control)
CREATE INDEX CONCURRENTLY idx_orders_created_at_new ON orders (created_at);
DROP INDEX CONCURRENTLY idx_orders_created_at;  -- plain DROP takes ACCESS EXCLUSIVE and queues traffic
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
| shared_buffers | 25-40% RAM | 25-40% RAM | Shared memory cache — above ~40% tends to hurt: PostgreSQL also relies on the OS page cache, so oversizing causes double-buffering |
| work_mem | 4-64MB | 64MB-1GB | Per-operation sort/hash |
| maintenance_work_mem | 512MB-2GB | 1-4GB | VACUUM, CREATE INDEX |
| effective_cache_size | 75% RAM | 75% RAM | Planner estimate of OS cache |

> `work_mem` is allocated **per sort/hash node, per connection** — worst-case total ≈ `work_mem` × concurrent operations. On high-connection OLTP, keep the global default low (4-16MB) and raise it per-session/per-query where a specific query needs it.

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

### auto_explain — capture the plan, not just the aggregate

`pg_stat_statements` tells you *which* query regressed; `auto_explain` logs the *actual plan* of the slow execution — the difference between knowing and guessing during an incident:

```ini
shared_preload_libraries = 'pg_stat_statements,auto_explain'
auto_explain.log_min_duration = '500ms'   # log plans for anything slower
auto_explain.log_analyze = on             # include actual rows/timing
auto_explain.log_buffers = on
auto_explain.sample_rate = 1.0            # lower (e.g. 0.1) on very hot systems — log_analyze adds overhead
```

At minimum, set `log_min_duration_statement = '1s'` so slow statements land in the log even without the module.

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
| Replication lag | `pg_stat_replication` (`replay_lag`) | Alert past what read-after-write flows tolerate; throttle backfills against it |
| Idle-in-transaction sessions | `pg_stat_activity` (`state = 'idle in transaction'`) | Alert > 5 min — they block VACUUM, `VALIDATE`, and DDL; set `idle_in_transaction_session_timeout` as the backstop |

Run `../scripts/query_diagnostics.sql` weekly and during every incident — point-in-time reads of these same signals, plus FK/index/bloat checks.
