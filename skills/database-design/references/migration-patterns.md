# PostgreSQL Migration Patterns

> Examples use the skill's PK default `UUID DEFAULT uuidv7()` (PG18+); on PG ≤17 generate v7 at the application layer — see SKILL.md → 'Primary Key Type Decision'.

These patterns are the **agility engine**, not just outage-avoidance: they are what let you keep a hard, fully-constrained schema *and* change it routinely (see SKILL.md → "Modeling for Change"). The right answer to fast-changing requirements is a cheap, safe, reversible change *process* — these patterns — not a soft, under-constrained schema *shape*.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Migration File Convention](#migration-file-convention)
3. [Zero-Downtime Migration Patterns](#zero-downtime-migration-patterns)
4. [Strangler Fig Pattern (Table Migration)](#strangler-fig-pattern-table-migration)
5. [Large Table Migrations](#large-table-migrations)
6. [Post-Migration Checklist](#post-migration-checklist)

## Core Principles

1. **Every migration has a rollback** — no exceptions — and the rollback is **tested, not just written**: run forward → rollback → forward in CI against a production-scale snapshot, and assert the schema returns to its prior state. An untested rollback fails at 3am, which is the only time you reach for it
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
db/migrations/
├── 001_create_user_accounts.sql
├── 001_create_user_accounts.rollback.sql
├── 002_create_orders.sql
├── 002_create_orders.rollback.sql
├── 003_add_phone_to_users.sql
└── 003_add_phone_to_users.rollback.sql
```

## Zero-Downtime Migration Patterns

### Schema is a contract — inventory consumers first

Expand-contract protects the *deploying application* during a rolling deploy. But the schema is a contract with consumers that do **not** redeploy in lockstep, and a literal "now drop the old column" breaks them silently:

- **CDC / ETL pipelines** (Debezium, Fivetran) — a column rename is usually a *drop + add* to these tools, so the downstream stream/warehouse column vanishes mid-stream.
- **Read replicas feeding a BI/analytics warehouse**, **sibling services** reading the same DB, **materialized views** (a renamed/dropped column makes `REFRESH` fail), and **API serializers** that shape responses directly from columns.

So before any **rename / retype / drop**: *inventory who else reads this table*, apply expand-contract across that whole consumer set (not just the app), and treat the change as breaking until every consumer — including the nightly job nobody owns — has migrated. The phases below are the mechanism; the consumer inventory is what decides when each phase is actually safe.

### Fail Fast on Locks
Even 'safe' DDL (e.g. ADD COLUMN) briefly takes an ACCESS EXCLUSIVE lock; if it can't acquire it because of a long-running transaction, it waits AND every subsequent query on that table queues behind it (a leading cause of migration outages). Set a short lock_timeout so the migration fails fast and you retry, instead of stalling all traffic:
```sql
SET lock_timeout = '2s';  -- optionally also a bounded statement_timeout
```
(CREATE/DROP INDEX CONCURRENTLY can't run inside a transaction block, so set such timeouts at the session level rather than bundling them into one BEGIN...COMMIT with the concurrent build.)

### Adding a Column (safe)
```sql
-- Forward: Adding a nullable column does NOT lock the table
ALTER TABLE user_accounts ADD COLUMN phone TEXT;

-- PostgreSQL 11+: adding with a CONSTANT/non-volatile DEFAULT is also safe (no table rewrite)
ALTER TABLE user_accounts ADD COLUMN is_verified BOOLEAN NOT NULL DEFAULT false;
-- ⚠️ A VOLATILE default forces a FULL table rewrite under ACCESS EXCLUSIVE for the whole rewrite —
-- e.g. ADD COLUMN ... uuid NOT NULL DEFAULT uuidv7() (or gen_random_uuid()/now() evaluated per row).
-- For those, add the column nullable, backfill in batches, then SET NOT NULL (see below).

-- Rollback
ALTER TABLE user_accounts DROP COLUMN phone;
ALTER TABLE user_accounts DROP COLUMN is_verified;
```

### Creating an Index (safe with CONCURRENTLY)
```sql
-- Forward: CONCURRENTLY does not block reads or writes
CREATE INDEX CONCURRENTLY idx_user_email ON user_accounts (email);

-- Rollback
DROP INDEX CONCURRENTLY idx_user_email;
-- like CREATE INDEX CONCURRENTLY, this cannot run inside a transaction block
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

-- Step 4: Validate — takes only SHARE UPDATE EXCLUSIVE (reads and writes continue during the scan; never ACCESS EXCLUSIVE)
ALTER TABLE user_accounts VALIDATE CONSTRAINT chk_phone_not_null;

-- Step 5: now make the column itself NOT NULL — PG12+ uses the already-validated CHECK to skip a second full scan
ALTER TABLE user_accounts ALTER COLUMN phone SET NOT NULL;
-- Step 6 (optional): drop the helper CHECK so the catalog shows only NOT NULL
ALTER TABLE user_accounts DROP CONSTRAINT chk_phone_not_null;

-- Rollback
ALTER TABLE user_accounts ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE user_accounts DROP CONSTRAINT IF EXISTS chk_phone_not_null;
```

### Adding a Foreign Key (large table)
```sql
-- Step 0: index the child FK column first (PostgreSQL does not auto-index FK columns)
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);

-- Step 1: add the constraint NOT VALID (brief lock, skips the full validation scan)
ALTER TABLE orders ADD CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES user_accounts (id) NOT VALID;

-- Step 2: validate separately (scans under SHARE UPDATE EXCLUSIVE; does not block DML)
ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_user;
```
Pair Step 1 with `SET lock_timeout` (above): the NOT VALID add still takes a brief exclusive lock on both tables.

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
FROM user_accounts
WHERE id > $last_migrated_id
ORDER BY id
LIMIT 10000;

-- Phase 6
DROP TABLE user_accounts;
-- (optionally then: ALTER TABLE user_accounts_v2 RENAME TO user_accounts;)
```

## Large Table Migrations

For tables with millions+ rows, batch all data modifications:

⚠️ **A `DO` block cannot `COMMIT`.** An anonymous `DO` block always runs in an atomic context, so a `COMMIT`/`ROLLBACK` inside one raises `ERROR: invalid transaction termination` (SQLSTATE 2D000) on **every** PostgreSQL version — unconditionally, whether or not a wrapping transaction exists. To commit per batch *inside the database* you must use a **`PROCEDURE` invoked via `CALL`** (and the `CALL` must not itself be inside an outer transaction — run it via `psql` **without** `-1`, not bundled into a `BEGIN…COMMIT`). Backfills should live in a separate idempotent script, not the transactional migration file.

```sql
-- Batch update pattern (keyset walk by primary key) — a PROCEDURE, because it COMMITs per batch.
-- (A DO block here would fail: COMMIT inside DO raises ERROR: invalid transaction termination.)
CREATE PROCEDURE backfill_user_phone()
LANGUAGE plpgsql AS $$
DECLARE
    batch_size INT := 5000;
    rows_scanned INT;
    last_id UUID := '00000000-0000-0000-0000-000000000000';
BEGIN
    LOOP
        -- Walk forward by primary key with a stable ORDER BY cursor.
        -- (Do NOT use FOR UPDATE SKIP LOCKED here — that is only for concurrent
        -- queue consumers; a single-writer backfill would silently skip rows.)
        WITH batch AS (
            SELECT id FROM user_accounts
            WHERE id > last_id
            ORDER BY id
            LIMIT batch_size
        ), updated AS (
            UPDATE user_accounts u
            SET phone = 'unknown'
            FROM batch
            WHERE u.id = batch.id AND u.phone IS NULL
            RETURNING u.id
        )
        -- Carry the cursor forward from the ordered batch. Do NOT use max(id): PostgreSQL has no
        -- max(uuid)/min(uuid) aggregate (UUID has btree comparison operators, so id > last_id and
        -- ORDER BY id work, but the aggregate does not exist — max(uuid) raises an error).
        SELECT count(*), (SELECT id FROM batch ORDER BY id DESC LIMIT 1)
        INTO rows_scanned, last_id FROM batch;

        EXIT WHEN last_id IS NULL;  -- no more rows past the cursor

        RAISE NOTICE 'Scanned % rows', rows_scanned;
        COMMIT;                 -- legal here: a PROCEDURE run via CALL, not inside an outer transaction
        PERFORM pg_sleep(0.1);  -- brief pause to reduce load
    END LOOP;
END $$;

-- Run it with the CALL un-wrapped (psql without -1), then drop it:
CALL backfill_user_phone();
DROP PROCEDURE backfill_user_phone();
```

## Post-Migration Checklist

1. ✅ Run `ANALYZE` on affected tables (refresh planner statistics)
2. ✅ Verify index usage with `EXPLAIN ANALYZE` on key queries
3. ✅ Check for invalid indexes: `SELECT * FROM pg_index WHERE NOT indisvalid;`
4. ✅ Monitor application error rates for 24-48 hours
5. ✅ Verify constraint validity
6. ✅ Update COMMENT ON TABLE / COLUMN if schema changed
