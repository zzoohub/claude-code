-- ============================================
-- PostgreSQL Schema Review Diagnostic Queries
-- Run against your database to identify common issues
-- ============================================

-- 1. Foreign Key columns without indexes
-- PostgreSQL does NOT auto-create indexes on FK columns
SELECT
    c.conrelid::regclass AS table_name,
    a.attname AS fk_column,
    c.conname AS constraint_name
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid
    -- leading-column coverage per FK column; composite FKs may need ordered-prefix checks
    AND i.indkey[0] = a.attnum
)
ORDER BY table_name, fk_column;

-- 2. Tables without a primary key
SELECT n.nspname AS schemaname, c.relname AS tablename
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
AND n.nspname NOT IN ('pg_catalog', 'information_schema')
AND NOT EXISTS (
    SELECT 1 FROM pg_constraint k
    WHERE k.conrelid = c.oid AND k.contype = 'p'
)
ORDER BY n.nspname, c.relname;

-- 3. Unused indexes (idx_scan = 0 since last stats reset)
SELECT
    s.schemaname, s.relname AS tablename, s.indexrelname AS indexname,
    s.idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size
FROM pg_stat_user_indexes s
JOIN pg_index ix ON ix.indexrelid = s.indexrelid
-- idx_scan is cumulative since the last stats reset (pg_upgrade/pg_stat_reset zero it); check SELECT stats_reset FROM pg_stat_database and trust 0 only over a representative window. PG16+ has last_idx_scan for recency.
WHERE s.idx_scan = 0
-- verify uniqueness/replica-identity before dropping any flagged index (standalone UNIQUE indexes have no pg_constraint row)
AND NOT ix.indisunique
AND NOT ix.indisprimary
AND NOT ix.indisreplident
AND s.indexrelid NOT IN (
    SELECT conindid FROM pg_constraint WHERE contype IN ('p', 'u')
)
ORDER BY pg_relation_size(s.indexrelid) DESC
LIMIT 20;

-- 4. Table and index sizes
SELECT
    t.schemaname,
    t.tablename,
    pg_size_pretty(pg_total_relation_size(format('%I.%I', t.schemaname, t.tablename))) AS total_size,
    pg_size_pretty(pg_relation_size(format('%I.%I', t.schemaname, t.tablename))) AS table_size,
    pg_size_pretty(
        pg_total_relation_size(format('%I.%I', t.schemaname, t.tablename)) -
        pg_relation_size(format('%I.%I', t.schemaname, t.tablename))
    ) AS index_size
FROM pg_tables t
WHERE t.schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(format('%I.%I', t.schemaname, t.tablename)) DESC
LIMIT 20;

-- 5. Dead tuples (tables needing VACUUM)
SELECT
    schemaname, relname,
    n_live_tup,
    n_dead_tup,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC
LIMIT 20;

-- 6. Slow queries (requires pg_stat_statements extension)
-- Enable: CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- counts are cumulative since the last pg_stat_statements_reset()/stats reset; interpret over a known window.
SELECT
    queryid,
    calls,
    ROUND(total_exec_time::NUMERIC, 2) AS total_ms,
    ROUND(mean_exec_time::NUMERIC, 2) AS avg_ms,
    ROUND(max_exec_time::NUMERIC, 2) AS max_ms,
    rows,
    LEFT(query, 100) AS query_preview
FROM pg_stat_statements
WHERE calls > 10
ORDER BY mean_exec_time DESC
LIMIT 20;

-- 7. Current locks and blocking
SELECT a.pid AS blocked_pid,
       a.query AS blocked_query,
       b.pid AS blocking_pid,
       b.query AS blocking_query,
       now() - a.query_start AS blocked_duration
FROM pg_stat_activity a
JOIN LATERAL unnest(pg_blocking_pids(a.pid)) AS bp(pid) ON true
JOIN pg_stat_activity b ON b.pid = bp.pid
ORDER BY blocked_duration DESC;

-- 8. Columns with high null ratio (potential design issues)
SELECT
    s.schemaname, s.tablename, s.attname,
    s.null_frac AS null_ratio,
    s.n_distinct
FROM pg_stats s
WHERE s.schemaname NOT IN ('pg_catalog', 'information_schema')
AND s.null_frac > 0.5
ORDER BY s.null_frac DESC
LIMIT 20;

-- 9. Column alignment check (identify potential padding waste)
-- Shows column order with type sizes for manual review
SELECT
    c.table_schema, c.table_name, c.column_name, c.ordinal_position,
    c.data_type,
    CASE
        WHEN c.data_type IN ('bigint', 'double precision', 'timestamp with time zone', 'timestamp without time zone') THEN 8
        WHEN c.data_type IN ('integer', 'real', 'date') THEN 4
        WHEN c.data_type = 'uuid' THEN 16
        WHEN c.data_type = 'smallint' THEN 2
        WHEN c.data_type = 'boolean' THEN 1
        ELSE -1  -- variable length
    END AS type_storage_bytes
-- storage size, not alignment (uuid is 1-byte/char aligned despite 16-byte storage); ordinal_position omits dropped columns, so this is a heuristic — inspect pg_attribute for true on-disk layout.
FROM information_schema.columns c
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY c.table_schema, c.table_name, c.ordinal_position;
