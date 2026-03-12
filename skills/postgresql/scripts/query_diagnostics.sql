-- ============================================
-- PostgreSQL Query Performance Diagnostic Script
-- Run against your database to identify query-level issues
-- ============================================

-- 1. Queries with high Filter (rows removed after index fetch)
-- Indicates index is not selective enough — needs composite index
-- Requires pg_stat_statements extension
SELECT
    queryid,
    calls,
    ROUND(mean_exec_time::NUMERIC, 2) AS avg_ms,
    rows AS avg_rows_returned,
    LEFT(query, 150) AS query_preview
FROM pg_stat_statements
WHERE calls > 50
AND mean_exec_time > 100  -- over 100ms average
ORDER BY mean_exec_time DESC
LIMIT 20;

-- 2. Tables with poor HOT update ratio (overindexed on updated columns)
SELECT
    schemaname, relname,
    n_tup_upd AS total_updates,
    n_tup_hot_upd AS hot_updates,
    ROUND(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd, 0), 2) AS hot_pct
FROM pg_stat_user_tables
WHERE n_tup_upd > 1000
ORDER BY hot_pct ASC
LIMIT 20;

-- 3. FK columns without indexes (causes slow CASCADE and JOIN)
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

-- 4. Unused indexes (wasting storage and slowing writes)
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

-- 5. Tables needing VACUUM (high dead tuple ratio)
SELECT
    schemaname, relname,
    n_live_tup, n_dead_tup,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
    last_vacuum, last_autovacuum,
    last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC
LIMIT 20;

-- 6. Invalid indexes (from failed CONCURRENTLY operations)
SELECT
    n.nspname AS schema_name,
    c.relname AS index_name,
    i.indisvalid AS is_valid
FROM pg_index i
JOIN pg_class c ON c.oid = i.indexrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT i.indisvalid;

-- 7. Table and index sizes (find bloat candidates)
SELECT
    t.schemaname, t.tablename,
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

-- 8. Cache hit ratio per table (identify cold tables)
SELECT
    schemaname, relname,
    heap_blks_hit, heap_blks_read,
    ROUND(
        100.0 * heap_blks_hit / NULLIF(heap_blks_hit + heap_blks_read, 0), 2
    ) AS cache_hit_pct
FROM pg_statio_user_tables
WHERE heap_blks_hit + heap_blks_read > 100
ORDER BY cache_hit_pct ASC
LIMIT 20;

-- 9. Index selectivity check
SELECT
    tablename, attname AS column_name,
    n_distinct,
    CASE
        WHEN n_distinct > 0 THEN ROUND((n_distinct / c.reltuples)::NUMERIC, 6)
        WHEN n_distinct < 0 THEN ROUND(abs(n_distinct)::NUMERIC, 6)
        ELSE 0
    END AS selectivity
FROM pg_stats s
JOIN pg_class c ON c.relname = s.tablename
WHERE s.schemaname NOT IN ('pg_catalog', 'information_schema')
AND c.reltuples > 0
ORDER BY tablename, selectivity DESC;

-- 10. Long-running active queries
SELECT
    pid,
    now() - query_start AS duration,
    state,
    wait_event_type,
    wait_event,
    LEFT(query, 120) AS query
FROM pg_stat_activity
WHERE state = 'active'
AND query_start < now() - interval '30 seconds'
ORDER BY duration DESC;
