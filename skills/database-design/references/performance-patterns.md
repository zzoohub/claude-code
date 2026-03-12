# PostgreSQL Performance Patterns

## 1. Column Ordering for Storage Optimization

PostgreSQL enforces alignment padding based on data type size. An 8-byte BIGINT must start
at an 8-byte boundary. If a 2-byte SMALLINT precedes it, 6 bytes are wasted as padding.

**Rule: Order columns from largest to smallest data type in CREATE TABLE.**

```sql
-- BAD: wastes ~8 bytes per row from alignment padding
CREATE TABLE bad_column_order (
    id BIGINT NOT NULL,          -- 8 bytes, starts at 0
    val_a SMALLINT NOT NULL,     -- 2 bytes, starts at 8 → padding at 10-15
    val_b INTEGER NOT NULL,      -- 4 bytes, starts at 16 → padding at 12-15
    val_c SMALLINT NOT NULL,     -- 2 bytes
    created_at TIMESTAMPTZ NOT NULL  -- 8 bytes, needs 8-byte alignment → more padding
);
-- Per-row size: 56 bytes

-- GOOD: minimal padding waste
CREATE TABLE good_column_order (
    id BIGINT NOT NULL,              -- 8 bytes
    created_at TIMESTAMPTZ NOT NULL, -- 8 bytes
    val_b INTEGER NOT NULL,          -- 4 bytes
    val_a SMALLINT NOT NULL,         -- 2 bytes
    val_c SMALLINT NOT NULL          -- 2 bytes
);
-- Per-row size: 48 bytes (~14% savings)
```

At millions of rows, this difference adds up to gigabytes of storage and proportionally
faster sequential scans (less data to read from disk).

**Alignment size by type:**
| Size | Types |
|------|-------|
| 8 bytes | BIGINT, TIMESTAMPTZ, TIMESTAMP, DOUBLE PRECISION, BIGSERIAL |
| 4 bytes | INTEGER, REAL, DATE, SERIAL |
| 2 bytes | SMALLINT |
| 1 byte | BOOLEAN, CHAR(1) |
| Variable | TEXT, VARCHAR, NUMERIC, JSONB, BYTEA (start on 4-byte boundary) |

**Recommended column order in CREATE TABLE:**
1. Fixed 8-byte columns (BIGINT, TIMESTAMPTZ)
2. Fixed 4-byte columns (INTEGER, DATE)
3. Fixed 2-byte columns (SMALLINT)
4. Fixed 1-byte columns (BOOLEAN)
5. Variable-length columns (TEXT, JSONB, NUMERIC)

## 2. postgresql.conf Tuning

### Memory Configuration

| Parameter | OLTP (transaction-heavy) | OLAP (analytics-heavy) | Description |
|-----------|--------------------------|------------------------|-------------|
| shared_buffers | 25-40% of RAM | 50-70% of RAM | Shared memory cache |
| work_mem | 4-64MB | 64MB-1GB | Per-operation sort/hash memory |
| maintenance_work_mem | 512MB-2GB | 1-4GB | VACUUM, CREATE INDEX memory |
| effective_cache_size | 75% of RAM | 75% of RAM | Planner's estimate of OS cache |

```sql
-- Check current settings
SHOW shared_buffers;
SHOW work_mem;

-- Verify buffer cache hit rate (should be > 99%)
SELECT
    sum(blks_hit) * 100.0 / nullif(sum(blks_hit) + sum(blks_read), 0) AS cache_hit_ratio
FROM pg_stat_database;
```

### WAL Configuration for High-Write Workloads

```sql
-- Defaults are often too conservative for high-throughput writes
-- Consider adjusting during heavy ingestion or backfill:
wal_buffers = '64MB'          -- buffer WAL data in memory (default 16MB)
checkpoint_completion_target = 0.9  -- spread checkpoint writes
max_wal_size = '4GB'          -- allow larger WAL before forced checkpoint
commit_delay = 100            -- microseconds; group more transactions per WAL flush
```

⚠️ These WAL settings can be temporarily increased during bulk data loads
and reverted to defaults afterward.

## 3. Connection Pooling

PostgreSQL forks a new process per connection (~10MB each).
Without pooling, 500 connections = 5GB of memory just for processes.

```
# PgBouncer configuration (recommended)
[pgbouncer]
pool_mode = transaction        # release connection after each transaction
default_pool_size = 20         # connections per user/database pair
max_client_conn = 1000         # max client connections to PgBouncer
reserve_pool_size = 5          # emergency extra connections
```

| Pool Mode | Description | When to Use |
|-----------|-------------|-------------|
| session | Connection held for entire session | Legacy apps, PREPARE |
| transaction | Released after each transaction | **Recommended default** |
| statement | Released after each statement | Simple read-only queries |

## 4. Partitioning

### When to Partition
- Table exceeds hundreds of millions of rows
- Queries typically filter by time range or category
- Need to drop old data efficiently (DROP partition vs DELETE rows)
- Write throughput needs to scale across partitions

### Partition Types

```sql
-- Range Partitioning (most common: time-series, logs)
CREATE TABLE access_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    url TEXT NOT NULL,
    status_code SMALLINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (created_at);

CREATE TABLE access_log_2025_01 PARTITION OF access_log
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE access_log_2025_02 PARTITION OF access_log
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- Automate with pg_partman for production use

-- List Partitioning (region, category)
CREATE TABLE "order" (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    region TEXT NOT NULL,
    total NUMERIC(15, 2)
) PARTITION BY LIST (region);

CREATE TABLE order_us PARTITION OF "order" FOR VALUES IN ('US');
CREATE TABLE order_eu PARTITION OF "order" FOR VALUES IN ('EU');
CREATE TABLE order_apac PARTITION OF "order" FOR VALUES IN ('APAC');

-- Hash Partitioning (even distribution when no natural key)
CREATE TABLE session (
    id UUID DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    data JSONB
) PARTITION BY HASH (user_id);

CREATE TABLE session_p0 PARTITION OF session FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE session_p1 PARTITION OF session FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE session_p2 PARTITION OF session FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE session_p3 PARTITION OF session FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### Partition Sizing
- Partitions that fit in memory = optimal write performance
- For time-series: partition interval should keep recent partitions "hot" in shared_buffers
- Rule of thumb: each partition between 100MB-1GB

## 5. Query Performance Patterns

### Keyset Pagination (avoid OFFSET)
```sql
-- BAD: OFFSET scans and discards rows (O(n) cost)
SELECT * FROM product ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 10000;

-- GOOD: Keyset pagination (constant performance regardless of page depth)
SELECT * FROM product
WHERE (created_at, id) < ('2025-01-15 10:30:00+00', 99500)
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Requires index
CREATE INDEX idx_product_pagination ON product (created_at DESC, id DESC);
```

### Design Queries Around These Guidelines

1. **Return reasonable resultsets** — aim for under 10,000 rows per query.
   Use LIMIT, pagination, or encourage filtering from the application layer.

2. **Help the planner filter early** — PostgreSQL's query planner is good at
   pushing predicates into joins, but it needs the right indexes to act on them.
   Ensure every column in WHERE and JOIN ON has appropriate indexes.
   ```sql
   -- The planner will push these filters down automatically if indexed:
   SELECT o.id, o.total
   FROM "order" o
   JOIN order_item oi ON oi.order_id = o.id
   JOIN product p ON p.id = oi.product_id
   WHERE p.category = 'electronics'
   AND o.created_at > '2025-01-01';

   -- Required indexes for the planner to filter efficiently:
   CREATE INDEX idx_order_created_at ON "order" (created_at);
   CREATE INDEX idx_order_item_order_id ON order_item (order_id);
   CREATE INDEX idx_order_item_product_id ON order_item (product_id);
   CREATE INDEX idx_product_category ON product (category);
   ```

   Use EXISTS instead of JOIN when you only need to check existence (not retrieve columns):
   ```sql
   -- BETTER than JOIN when you don't need product columns:
   SELECT o.id, o.total
   FROM "order" o
   WHERE o.created_at > '2025-01-01'
   AND EXISTS (
       SELECT 1 FROM order_item oi
       JOIN product p ON p.id = oi.product_id
       WHERE oi.order_id = o.id AND p.category = 'electronics'
   );
   ```

   Note: since PostgreSQL 12, CTEs are inlined by default and the planner
   optimizes them like subqueries. Wrapping filters in CTEs does not help
   the planner — proper indexes do.

3. **Cache computed data** — avoid recomputing expensive aggregations repeatedly.
   Use Materialized Views or dedicated summary tables refreshed on a schedule.

### Batch Processing
```sql
-- Process large datasets in chunks (e.g., 1000 rows at a time)
-- Prevents long-running transactions and excessive lock holding

-- Queue pattern with SKIP LOCKED
SELECT id, payload
FROM task_queue
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1000
FOR UPDATE SKIP LOCKED;
```

## 6. Materialized Views

```sql
CREATE MATERIALIZED VIEW mv_daily_revenue AS
SELECT
    date_trunc('day', o.created_at) AS day,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    COUNT(DISTINCT o.id) AS order_count
FROM "order" o
JOIN order_item oi ON oi.order_id = o.id
GROUP BY date_trunc('day', o.created_at);

-- Required for REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_daily_revenue_day ON mv_daily_revenue (day);

-- Non-blocking refresh (requires the UNIQUE index above)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue;
```

## 7. VACUUM Monitoring

```sql
-- Check tables needing VACUUM
SELECT
    schemaname, relname,
    n_live_tup,
    n_dead_tup,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Per-Table Autovacuum Tuning (for hot tables)
```sql
-- Reduce autovacuum threshold for frequently updated tables
ALTER TABLE "order" SET (
    autovacuum_vacuum_scale_factor = 0.05,   -- trigger at 5% dead tuples (default 20%)
    autovacuum_analyze_scale_factor = 0.02,  -- re-analyze at 2% changes
    autovacuum_vacuum_cost_delay = 2         -- less throttling = faster vacuum
);
```

## 8. Backfill / Bulk Load Optimization

When loading large volumes of historical data:

```sql
-- 1. Drop non-essential indexes before bulk load
DROP INDEX idx_order_created_at;

-- 2. Bulk insert in batches (1000-5000 rows per INSERT)
INSERT INTO "order" (user_id, status, total, created_at)
VALUES
    (...), (...), (...),  -- batch of rows
    ...;

-- 3. Recreate indexes after load (CONCURRENTLY for zero downtime)
CREATE INDEX CONCURRENTLY idx_order_created_at ON "order" (created_at);

-- 4. Analyze after bulk load for fresh statistics
ANALYZE "order";
```

**Additional tips for large backfills:**
- Schedule during lowest database load periods
- Temporarily increase `shared_buffers` and `work_mem` (revert after)
- Increase `wal_buffers` and adjust `commit_delay` to reduce WAL flush overhead
- Use parallel insert processes targeting different partitions
- If using COPY command, it's faster than INSERT for bulk loads:
  ```sql
  COPY "order" (user_id, status, total, created_at)
  FROM '/path/to/data.csv' WITH (FORMAT csv, HEADER true);
  ```
- After backfill: VACUUM ANALYZE to update statistics and reclaim space

## 9. Ingestion Patterns

### Append-Only (best performance)
- New records added chronologically to the most recent partition
- No UPDATE or DELETE on existing rows
- Minimal index maintenance overhead
- Ideal for: logs, events, metrics, time-series

### Upsert (INSERT ... ON CONFLICT)
```sql
-- Requires a uniqueness constraint
INSERT INTO product (sku, name, price, updated_at)
VALUES ('ABC-123', 'Widget', 29.99, now())
ON CONFLICT (sku) DO UPDATE SET
    name = EXCLUDED.name,
    price = EXCLUDED.price,
    updated_at = EXCLUDED.updated_at;
```
- The uniqueness check on every insert adds overhead
- Performance depends on whether conflicting rows are in the same partition / cache
- Order inserts to keep recently accessed data "hot" in memory

### Update-Heavy
- Generates dead tuples → requires aggressive VACUUM strategy
- Consider per-table autovacuum tuning (see section 7)
- Monitor dead tuple ratios closely
