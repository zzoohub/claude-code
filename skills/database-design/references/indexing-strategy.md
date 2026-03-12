# PostgreSQL Indexing Strategy Guide

## Core Principle

The goal of indexing: **minimize disk I/O**. An index is metadata pointing to where specific values are stored.

### Selectivity
```
Selectivity = Number of distinct values / Total number of rows
```
- Close to 1 = highly selective (good) → index is very effective
- Close to 0 = low selectivity → index is less effective
- Boolean columns (~0.5 selectivity): use Partial Index instead of a regular index

```sql
-- Check selectivity
SELECT
    attname AS column_name,
    n_distinct,
    CASE
        WHEN n_distinct > 0 THEN n_distinct / reltuples
        WHEN n_distinct < 0 THEN abs(n_distinct)
        ELSE 0
    END AS selectivity
FROM pg_stats
JOIN pg_class ON pg_class.relname = pg_stats.tablename
WHERE tablename = 'your_table'
ORDER BY selectivity DESC;
```

## Index Types

### B-tree (default, most commonly used)
```sql
-- Suitable for equality, range, sorting, LIKE 'prefix%'
CREATE INDEX idx_order_created_at ON "order" (created_at);
CREATE INDEX idx_user_email ON user_account (email);

-- Composite index: matches left-to-right (leftmost prefix rule)
CREATE INDEX idx_order_user_status ON "order" (user_id, status);
-- ✅ WHERE user_id = 1
-- ✅ WHERE user_id = 1 AND status = 'pending'
-- ❌ WHERE status = 'pending' (without user_id, index is not used)
```

### Hash (equality-only)
```sql
-- Slightly faster than B-tree for pure = comparisons
CREATE INDEX idx_session_token ON session USING HASH (token);
-- ❌ Cannot do range searches or sorting
```

### GIN (Generalized Inverted Index)
```sql
-- Essential for ARRAY, JSONB, full-text search
CREATE INDEX idx_product_tags ON product USING GIN (tags);
CREATE INDEX idx_product_attrs ON product USING GIN (attributes);

-- Full-text search
CREATE INDEX idx_article_fts ON article USING GIN (to_tsvector('english', title || ' ' || body));
```

### GiST (Generalized Search Tree)
```sql
-- Geographic data, range types, proximity searches
CREATE INDEX idx_store_location ON store USING GIST (location);

-- Range types (overlap searches)
CREATE INDEX idx_reservation_period ON reservation USING GIST (
    tstzrange(check_in, check_out)
);
```

### BRIN (Block Range Index)
```sql
-- Physically sorted large datasets (time-series, logs)
-- Much smaller than B-tree
CREATE INDEX idx_log_created_at ON access_log USING BRIN (created_at);
-- Requirement: data must be physically ordered by the indexed column
```

## Advanced Index Patterns

### Partial Index
Index only rows that match a condition. Saves space and improves performance.

```sql
-- Only index active orders (if 5% of total, saves 95% space)
CREATE INDEX idx_order_active ON "order" (created_at)
WHERE status NOT IN ('delivered', 'cancelled');

-- Unread notifications only
CREATE INDEX idx_notification_unread ON notification (user_id, created_at)
WHERE is_read = false;

-- Soft delete pattern
CREATE INDEX idx_user_active ON user_account (email)
WHERE deleted_at IS NULL;
```

### Expression Index
```sql
-- Case-insensitive search
CREATE INDEX idx_user_email_lower ON user_account (lower(email));
-- Query: WHERE lower(email) = 'user@example.com'

-- Date extraction
CREATE INDEX idx_order_year_month ON "order" (
    date_trunc('month', created_at)
);

-- JSONB specific key
CREATE INDEX idx_product_brand ON product ((attributes->>'brand'));
```

### Covering Index (INCLUDE)
Enables Index-Only Scan by including all needed columns in the index.

```sql
-- Frequent lookup by id returning email and name
CREATE INDEX idx_user_lookup ON user_account (id) INCLUDE (email, name);

-- Order listing optimization
CREATE INDEX idx_order_user_list ON "order" (user_id, created_at DESC)
INCLUDE (status, total_amount);
```

### Composite Index Design Rules

Column order matters:
1. **Equality conditions** first
2. **Range conditions** next
3. **Sort columns** last

```sql
-- Query: WHERE user_id = ? AND status = ? ORDER BY created_at DESC
CREATE INDEX idx_order_user_status_date ON "order" (user_id, status, created_at DESC);

-- Query: WHERE user_id = ? AND created_at > ?
CREATE INDEX idx_order_user_date ON "order" (user_id, created_at);
```

## Index Maintenance

### Check index usage
```sql
-- Find unused indexes
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

### Rebuild bloated indexes
```sql
-- CONCURRENTLY (zero-downtime, recommended)
REINDEX INDEX CONCURRENTLY idx_order_created_at;

-- Or create new + swap
CREATE INDEX CONCURRENTLY idx_order_created_at_new ON "order" (created_at);
DROP INDEX idx_order_created_at;
ALTER INDEX idx_order_created_at_new RENAME TO idx_order_created_at;
```

### Check index sizes
```sql
SELECT
    tablename, indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

## Index Anti-Patterns

1. **Indexing every column** → degrades INSERT/UPDATE/DELETE, wastes storage
2. **Regular index on low-selectivity columns** → use Partial Index for Boolean/status
3. **Leaving unused indexes** → check `pg_stat_user_indexes` regularly
4. **Ignoring composite index column order** → leftmost prefix rule violation
5. **Function in WHERE without Expression Index**
   ```sql
   -- Index is ignored
   WHERE UPPER(email) = 'USER@EXAMPLE.COM'
   -- Needs Expression Index
   CREATE INDEX idx_user_email_upper ON user_account (UPPER(email));
   ```

## Reading EXPLAIN ANALYZE

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM "order" WHERE user_id = 123 AND status = 'pending';
```

Key indicators:
- **Seq Scan**: Full table scan (bad for large tables, fine for small ones)
- **Index Scan**: Finds rows via index, reads data from table (good)
- **Index Only Scan**: Completes entirely from index (best)
- **Bitmap Index Scan**: Combines multiple index conditions (acceptable)
- **actual time**: Real execution time (ms)
- **Buffers: shared hit**: Pages read from cache (more = better)
- **Buffers: shared read**: Pages read from disk (less = better)
