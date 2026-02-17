# PostgreSQL Indexing Pitfalls

Real-world scenarios where indexes are ignored or used inefficiently, and how to fix them.

## Pitfall 1: Partial Index Not Used — Query Doesn't Match Exactly

```sql
-- Index
CREATE INDEX idx_file_zero ON file (size) WHERE size = 0 AND file_hash IS NULL;

-- ❌ NOT USED: query doesn't include file_hash IS NULL
SELECT * FROM file WHERE size = 0;

-- ✅ USED: query matches index WHERE clause exactly
SELECT * FROM file WHERE size = 0 AND file_hash IS NULL;
```

**Rule**: Partial index WHERE clause must appear verbatim in the query. PostgreSQL will not infer that `file_hash IS NULL` is always true when `size = 0`, even if your data guarantees it.

## Pitfall 2: Composite Index Column Order Mismatch

```sql
-- Index (wrong order for this query)
CREATE INDEX idx_log_time_user ON log (created_at, user_id);

-- Query
SELECT * FROM log WHERE user_id = 42 AND created_at > now() - interval '1 day';
```

PostgreSQL uses composite indexes left-to-right. Once it hits a range condition, subsequent columns are less effective.

**Rule**: Equality conditions first → Range conditions next → Sort columns last.

```sql
-- ✅ Correct order
CREATE INDEX idx_log_user_time ON log (user_id, created_at);
```

## Pitfall 3: Index Not Selective Enough — Filter Instead of Index Cond

```sql
-- Index on only one column
CREATE INDEX idx_download_user ON download (user_id);

-- Query filters on two columns
SELECT * FROM download WHERE user_id = 42 AND download_status = 'complete';
```

EXPLAIN shows:
```
Index Scan using idx_download_user
  Index Cond: (user_id = 42)
  Filter: (download_status = 'complete')    -- ← wasteful
  Rows Removed by Filter: 3847             -- ← wasted I/O
```

**Fix**: Composite index covering both filter columns:
```sql
CREATE INDEX idx_download_user_status ON download (user_id, download_status);
```

**Rule**: If EXPLAIN shows `Filter` + `Rows Removed by Filter`, the index is incomplete. All WHERE conditions should appear in `Index Cond`.

## Pitfall 4: LIKE Query Ignored Due to Collation

```sql
-- B-tree index on text column with en_US.UTF-8 collation
CREATE INDEX idx_file_path ON file (path);

-- ❌ NOT USED with locale-aware collation
SELECT * FROM file WHERE path LIKE '/media/photos/2023/%';
```

PostgreSQL converts `LIKE 'prefix%'` to range comparison (`>= AND <`), but locale-aware collation (en_US.UTF-8) doesn't guarantee binary-consistent ordering.

**Fix options**:
```sql
-- Option 1: Specify C collation on the index
CREATE INDEX idx_file_path_c ON file (path COLLATE "C");
-- Query must also use: WHERE path COLLATE "C" LIKE '/media/photos/2023/%'

-- Option 2: Use text_pattern_ops operator class
CREATE INDEX idx_file_path_pattern ON file (path text_pattern_ops);

-- Option 3: Set database default collation to "C" (if appropriate for your use case)
```

**Rule**: For LIKE 'prefix%' with B-tree, ensure collation allows binary-consistent comparison.

## Pitfall 5: Index Direction Doesn't Match ORDER BY

```sql
-- Index (default ASC)
CREATE INDEX idx_item_cat_pub ON item (category, published_at);

-- Query needs DESC
SELECT * FROM item WHERE category = 'books' ORDER BY published_at DESC LIMIT 10;
```

PostgreSQL can scan B-tree indexes backwards, but only for the entire index. Mixed directions in composite indexes require explicit direction specification.

**Fix**:
```sql
CREATE INDEX idx_item_cat_pub_desc ON item (category, published_at DESC);
```

## Pitfall 6: FK DELETE Slow — Missing Index on Referenced Column

```sql
DELETE FROM region WHERE id = 1;
```

Looks simple, but EXPLAIN ANALYZE reveals:
```
Trigger: RI_ConstraintTrigger  Time: 10244ms  Calls: 126
```

On DELETE, PostgreSQL validates referential integrity:
```sql
-- Internally executes:
SELECT 1 FROM file WHERE region_id = 1;
```

If `file.region_id` has no index → sequential scan for every DELETE.

**Fix**:
```sql
CREATE INDEX idx_file_region_id ON file (region_id);
```

**Rule**: Always index FK columns. PostgreSQL does NOT auto-index foreign keys. This affects both JOIN performance and CASCADE DELETE/UPDATE speed.

## Pitfall 7: Overindexing Kills HOT Updates

HOT (Heap-Only Tuple) updates skip index maintenance when:
- Updated columns are NOT part of any index
- New row version fits on the same page

If a frequently-updated column is indexed, every update must also update the index → slower writes, more bloat.

```sql
-- Check HOT update ratio
SELECT n_tup_upd, n_tup_hot_upd,
    ROUND(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd, 0), 2) AS hot_pct
FROM pg_stat_all_tables
WHERE relname = 'your_table';
```

**Example**: Index on `modified_at` which is updated on every write:
```sql
-- Drop if only used for occasional admin queries
DROP INDEX idx_document_modified_at;
```

**Rule**: Don't index columns that are updated frequently unless critical queries depend on it. Check HOT ratio for high-write tables.

## Pitfall 8: Index Ignored After Bulk DELETE — Stale Statistics

After large batch DELETE, PostgreSQL statistics become stale. The planner overestimates row count and chooses Seq Scan instead of Index Scan.

```sql
-- Check when last analyzed
SELECT relname, last_autoanalyze, last_analyze
FROM pg_stat_all_tables
WHERE relname = 'your_table';

-- Fix: refresh statistics
ANALYZE your_table;
```

**Rule**: Always run `ANALYZE` after bulk INSERT, UPDATE, or DELETE operations. Don't rely on autovacuum timing for immediate query plan correctness.

## Pitfall 9: Index-Only Scan Slow — Index Bloat

Index-only scan avoids table access but can be slow if the index itself is bloated (dead entries from deleted/updated rows).

```sql
-- Check index size
SELECT pg_size_pretty(pg_relation_size('your_index'));

-- Fix: clean up index
VACUUM (INDEX_CLEANUP ON) your_table;

-- Or rebuild (zero-downtime)
REINDEX INDEX CONCURRENTLY your_index;
```

## Pitfall 10: Function in WHERE Without Expression Index

```sql
-- ❌ Index on email is NOT used
SELECT * FROM user_account WHERE lower(email) = 'user@example.com';

-- ✅ Create expression index
CREATE INDEX idx_user_email_lower ON user_account (lower(email));
```

**Rule**: If WHERE clause applies a function to a column, you need an expression index on that same function call. The bare column index won't be used.

## Index Selection Cheat Sheet

| Query Pattern | Index Type | Example |
|---------------|-----------|---------|
| `WHERE col = value` | B-tree | `CREATE INDEX ON t (col)` |
| `WHERE col1 = ? AND col2 > ?` | B-tree composite | `CREATE INDEX ON t (col1, col2)` |
| `WHERE col LIKE 'prefix%'` | B-tree + text_pattern_ops | `CREATE INDEX ON t (col text_pattern_ops)` |
| `WHERE jsonb_col @> '{}'` | GIN | `CREATE INDEX ON t USING GIN (col)` |
| `WHERE col = ANY(array)` | GIN | `CREATE INDEX ON t USING GIN (col)` |
| `WHERE func(col) = value` | Expression index | `CREATE INDEX ON t (func(col))` |
| `WHERE status = 'active'` | Partial index | `CREATE INDEX ON t (col) WHERE status = 'active'` |
| `WHERE ts > now() - '1 day'` (time-series) | BRIN | `CREATE INDEX ON t USING BRIN (ts)` |
| Covering for index-only scan | INCLUDE | `CREATE INDEX ON t (filter_col) INCLUDE (select_col)` |
