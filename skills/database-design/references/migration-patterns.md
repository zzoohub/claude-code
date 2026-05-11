# PostgreSQL Migration Patterns

## Core Principles

1. **Every migration has a rollback** — no exceptions
2. **Version-controlled** — migrations are numbered sequentially
3. **Tested on production-scale data** — a migration that works on 1000 rows may break on 10 million
4. **Backup before migration** — always

```bash
# Logical backup before migration
pg_dump -Fc -d mydb -f backup_before_migration.dump

# Restore if needed
pg_restore -d mydb backup_before_migration.dump
```

## Migration File Convention

```
migrations/
├── 001_create_user_accounts.sql
├── 001_create_user_accounts.rollback.sql
├── 002_create_orders.sql
├── 002_create_orders.rollback.sql
├── 003_add_phone_to_users.sql
└── 003_add_phone_to_users.rollback.sql
```

## Zero-Downtime Migration Patterns

### Adding a Column (safe)
```sql
-- Forward: Adding a nullable column does NOT lock the table
ALTER TABLE user_accounts ADD COLUMN phone TEXT;

-- PostgreSQL 11+: Adding with DEFAULT is also safe (no table rewrite)
ALTER TABLE user_accounts ADD COLUMN is_verified BOOLEAN NOT NULL DEFAULT false;

-- Rollback
ALTER TABLE user_accounts DROP COLUMN phone;
ALTER TABLE user_accounts DROP COLUMN is_verified;
```

### Creating an Index (safe with CONCURRENTLY)
```sql
-- Forward: CONCURRENTLY does not block reads or writes
CREATE INDEX CONCURRENTLY idx_user_email ON user_accounts (email);

-- Rollback
DROP INDEX idx_user_email;
```

⚠️ `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block.
If it fails partway through, clean up the invalid index:
```sql
DROP INDEX IF EXISTS idx_user_email;
```

### Adding a NOT NULL Constraint (careful)
```sql
-- Step 1: Add column as nullable
ALTER TABLE user_accounts ADD COLUMN phone TEXT;

-- Step 2: Backfill existing rows (in batches)
UPDATE user_accounts SET phone = 'unknown' WHERE phone IS NULL;

-- Step 3: Add NOT NULL constraint with NOT VALID (no table scan)
ALTER TABLE user_accounts ADD CONSTRAINT chk_phone_not_null CHECK (phone IS NOT NULL) NOT VALID;

-- Step 4: Validate (scans table but does NOT hold ACCESS EXCLUSIVE lock for the full duration)
ALTER TABLE user_accounts VALIDATE CONSTRAINT chk_phone_not_null;

-- Rollback
ALTER TABLE user_accounts DROP CONSTRAINT chk_phone_not_null;
```

### Renaming a Column (Expand-Contract Pattern)

Never rename directly in production — it breaks running application code.

```sql
-- Phase 1: EXPAND — add new column
ALTER TABLE user_accounts ADD COLUMN full_name TEXT;

-- Phase 2: Dual-write — application writes to both columns
UPDATE user_accounts SET full_name = name WHERE full_name IS NULL;

-- Phase 3: Deploy code that reads from full_name

-- Phase 4: CONTRACT — drop old column (after all code is migrated)
ALTER TABLE user_accounts DROP COLUMN name;

-- Rollback (Phase 1)
ALTER TABLE user_accounts DROP COLUMN full_name;
```

### Changing a Column Type

```sql
-- Phase 1: Add new column with target type
ALTER TABLE products ADD COLUMN price_new NUMERIC(15, 2);

-- Phase 2: Batch-copy data
UPDATE products SET price_new = price::NUMERIC(15, 2) WHERE price_new IS NULL;

-- Phase 3: Deploy dual-write code (writes to both columns)

-- Phase 4: Switch reads to new column

-- Phase 5: Drop old column
ALTER TABLE products DROP COLUMN price;
ALTER TABLE products RENAME COLUMN price_new TO price;

-- Rollback (Phase 1)
ALTER TABLE products DROP COLUMN price_new;
```

### Dropping a Column (Expand-Contract)

```sql
-- Phase 1: Deprecate — stop writing to the column in application code
-- Phase 2: Deploy code that no longer reads the column
-- Phase 3: Wait for all old code versions to be replaced
-- Phase 4: Drop
ALTER TABLE user_accounts DROP COLUMN legacy_field;

-- Rollback: Cannot easily undo a DROP COLUMN
-- This is why you wait and verify before dropping
```

### Dropping a Table

```sql
-- Phase 1: Rename (soft-deprecate)
ALTER TABLE old_feature RENAME TO _deprecated_old_feature;

-- Phase 2: Monitor for errors (1-2 weeks)

-- Phase 3: Drop
DROP TABLE _deprecated_old_feature;

-- Rollback (Phase 1)
ALTER TABLE _deprecated_old_feature RENAME TO old_feature;
```

## Strangler Fig Pattern (Table Migration)

Replace an old table with a new one without downtime.

```
Phase 1: Create new table alongside old
Phase 2: Dual-write to both tables
Phase 3: Batch-migrate historical data from old → new
Phase 4: Switch reads to new table
Phase 5: Stop writing to old table
Phase 6: Drop old table (after verification period)
```

```sql
-- Phase 1
CREATE TABLE user_accounts_v2 (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Phase 3: Batch migrate (preserve original ids if cross-table FKs reference them;
-- otherwise let DEFAULT uuidv7() generate new ones).
INSERT INTO user_accounts_v2 (id, email, name, created_at, updated_at)
SELECT id, email, name, created_at, updated_at
FROM user_accounts_v1
WHERE id > $last_migrated_id
ORDER BY id
LIMIT 10000;

-- Phase 6
DROP TABLE user_accounts_v1;
```

## Large Table Migrations

For tables with millions+ rows, batch all data modifications:

```sql
-- Batch update pattern
DO $$
DECLARE
    batch_size INT := 5000;
    rows_updated INT;
BEGIN
    LOOP
        UPDATE user_accounts
        SET phone = 'unknown'
        WHERE phone IS NULL
        AND id IN (
            SELECT id FROM user_accounts
            WHERE phone IS NULL
            LIMIT batch_size
            FOR UPDATE SKIP LOCKED
        );

        GET DIAGNOSTICS rows_updated = ROW_COUNT;
        EXIT WHEN rows_updated = 0;

        RAISE NOTICE 'Updated % rows', rows_updated;
        COMMIT;
        PERFORM pg_sleep(0.1);  -- brief pause to reduce load
    END LOOP;
END $$;
```

## Post-Migration Checklist

1. ✅ Run `ANALYZE` on affected tables (refresh planner statistics)
2. ✅ Verify index usage with `EXPLAIN ANALYZE` on key queries
3. ✅ Check for invalid indexes: `SELECT * FROM pg_index WHERE NOT indisvalid;`
4. ✅ Monitor application error rates for 24-48 hours
5. ✅ Verify constraint validity
6. ✅ Update COMMENT ON TABLE / COLUMN if schema changed
