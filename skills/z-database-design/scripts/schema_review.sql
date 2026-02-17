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
    AND a.attnum = ANY(i.indkey)
)
ORDER BY table_name, fk_column;

-- 2. Tables without a primary key
SELECT
    schemaname, tablename
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
AND tablename NOT IN (
    SELECT tc.table_name
    FROM information_schema.table_constraints tc
    WHERE tc.constraint_type = 'PRIMARY KEY'
)
ORDER BY schemaname, tablename;

-- 3. Unused indexes (idx_scan = 0 since last stats reset)
SELECT
    schemaname, tablename, indexname,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexrelid NOT IN (
    SELECT conindid FROM pg_constraint WHERE contype IN ('p', 'u')
)
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 20;

-- 4. Table and index sizes
SELECT
    t.schemaname,
    t.tablename,
    pg_size_pretty(pg_total_relation_size(t.schemaname || '.' || t.tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(t.schemaname || '.' || t.tablename)) AS table_size,
    pg_size_pretty(
        pg_total_relation_size(t.schemaname || '.' || t.tablename) -
        pg_relation_size(t.schemaname || '.' || t.tablename)
    ) AS index_size
FROM pg_tables t
WHERE t.schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(t.schemaname || '.' || t.tablename) DESC
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
SELECT
    blocked.pid AS blocked_pid,
    blocked.query AS blocked_query,
    blocking.pid AS blocking_pid,
    blocking.query AS blocking_query,
    now() - blocked.query_start AS blocked_duration
FROM pg_stat_activity blocked
JOIN pg_locks bl ON bl.pid = blocked.pid
JOIN pg_locks kl ON kl.locktype = bl.locktype
    AND kl.database IS NOT DISTINCT FROM bl.database
    AND kl.relation IS NOT DISTINCT FROM bl.relation
    AND kl.page IS NOT DISTINCT FROM bl.page
    AND kl.tuple IS NOT DISTINCT FROM bl.tuple
    AND kl.virtualxid IS NOT DISTINCT FROM bl.virtualxid
    AND kl.transactionid IS NOT DISTINCT FROM bl.transactionid
    AND kl.pid != bl.pid
JOIN pg_stat_activity blocking ON blocking.pid = kl.pid
WHERE NOT bl.granted
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
        WHEN c.data_type = 'smallint' THEN 2
        WHEN c.data_type = 'boolean' THEN 1
        ELSE -1  -- variable length
    END AS type_alignment_bytes
FROM information_schema.columns c
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY c.table_schema, c.table_name, c.ordinal_position;
