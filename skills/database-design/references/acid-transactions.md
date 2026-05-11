# ACID & Transaction Patterns in PostgreSQL

## Isolation Levels

| Level | Dirty Read | Non-Repeatable Read | Phantom Read | Use Case |
|-------|-----------|-------------------|-------------|----------|
| Read Committed (default) | ❌ | ✅ possible | ✅ possible | General OLTP |
| Repeatable Read | ❌ | ❌ | ❌ (snapshot) | Reports, financial reads |
| Serializable | ❌ | ❌ | ❌ | Strict consistency required |

```sql
-- Set isolation level per transaction
BEGIN ISOLATION LEVEL REPEATABLE READ;
-- ... operations ...
COMMIT;

-- Set default for session
SET default_transaction_isolation = 'repeatable read';
```

### Read Committed (default)
- Each statement sees the latest committed data
- Different statements within the same transaction may see different snapshots
- Best for general OLTP workloads

### Repeatable Read
- Transaction sees a snapshot taken at the start of the first statement
- Consistent reads throughout the transaction
- Will abort with serialization error if a concurrent transaction modifies the same rows
- Application must retry on serialization failure

### Serializable
- Strictest level: transactions behave as if executed sequentially
- Higher chance of serialization errors → requires robust retry logic
- Use only when correctness demands it (e.g., financial transfers, inventory)

## Locking Patterns

### Row-Level Locks

```sql
-- Pessimistic locking: lock rows before updating
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
-- Row is locked until COMMIT/ROLLBACK
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;

-- FOR SHARE: shared lock (allows concurrent reads, blocks writes)
SELECT * FROM products WHERE id = 5 FOR SHARE;

-- NOWAIT: fail immediately if row is locked (don't wait)
SELECT * FROM accounts WHERE id = 1 FOR UPDATE NOWAIT;

-- SKIP LOCKED: skip locked rows (queue processing pattern)
SELECT id, payload FROM task_queues
WHERE status = 'pending'
ORDER BY created_at
LIMIT 10
FOR UPDATE SKIP LOCKED;
```

### Optimistic Locking (version-based)

No database lock held — check version at write time instead.

```sql
-- Add version column
ALTER TABLE products ADD COLUMN version INT NOT NULL DEFAULT 1;

-- Read
SELECT id, name, price, version FROM products WHERE id = 42;
-- Application stores: version = 3

-- Update with version check
UPDATE products
SET price = 29.99, version = version + 1
WHERE id = 42 AND version = 3;

-- If 0 rows updated → someone else modified it → retry or error
```

**When to use which:**
- Pessimistic (FOR UPDATE): high contention, short transactions
- Optimistic (version): low contention, longer user-facing workflows

### Advisory Locks

Application-defined locks not tied to specific rows.

```sql
-- Session-level advisory lock
SELECT pg_advisory_lock(12345);    -- acquire
-- ... critical section ...
SELECT pg_advisory_unlock(12345);  -- release

-- Transaction-level (auto-released at COMMIT/ROLLBACK)
SELECT pg_advisory_xact_lock(12345);

-- Try lock (non-blocking, returns boolean)
SELECT pg_try_advisory_lock(12345);  -- true if acquired, false if already held
```

Use cases: rate limiting, singleton job execution, distributed coordination.

## Deadlock Prevention

Deadlocks occur when two transactions each hold a lock the other needs.

```sql
-- DEADLOCK SCENARIO:
-- Transaction A: locks row 1, then tries to lock row 2
-- Transaction B: locks row 2, then tries to lock row 1
-- → Both wait forever → PostgreSQL detects and kills one

-- PREVENTION: always lock rows in a consistent order
BEGIN;
SELECT * FROM accounts WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
-- Both transactions lock in the same order → no deadlock
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

**Deadlock prevention rules:**
1. Lock rows in consistent order (e.g., ORDER BY id)
2. Keep transactions as short as possible
3. Avoid user interaction within a transaction
4. Use lock timeouts as a safety net:
   ```sql
   SET lock_timeout = '5s';  -- fail after 5 seconds of waiting for a lock
   ```

## SAVEPOINT (Partial Rollback)

```sql
BEGIN;
INSERT INTO orders (user_id, status) VALUES (1, 'pending');

SAVEPOINT before_items;
INSERT INTO order_items (order_id, product_id, quantity) VALUES (1, 999, 1);
-- Error: product_id 999 doesn't exist

ROLLBACK TO SAVEPOINT before_items;
-- Order insert is preserved, only the failed item is rolled back

INSERT INTO order_items (order_id, product_id, quantity) VALUES (1, 100, 1);
COMMIT;
```

## Transaction Design Best Practices

### Keep Transactions Short
```sql
-- BAD: external API call inside transaction (holds locks for seconds)
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- ... call external payment API (2-5 seconds) ...
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- GOOD: external call outside transaction
-- Step 1: call external API first
-- Step 2: only then open transaction for database updates
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

### Retry Logic for Serialization Failures
```python
# Pseudocode for retry pattern
MAX_RETRIES = 3

for attempt in range(MAX_RETRIES):
    try:
        with db.transaction():
            # ... your operations ...
            break  # success
    except SerializationFailure:
        if attempt == MAX_RETRIES - 1:
            raise
        time.sleep(0.1 * (2 ** attempt))  # exponential backoff
```

### Avoid Long-Running Transactions
- They prevent VACUUM from cleaning dead tuples
- They hold snapshots that block tuple removal
- Monitor with:
  ```sql
  SELECT pid, now() - xact_start AS duration, state, query
  FROM pg_stat_activity
  WHERE state != 'idle'
  AND xact_start IS NOT NULL
  ORDER BY duration DESC;
  ```

## Common Anti-Patterns

1. **SELECT ... FOR UPDATE on too many rows** — locks escalation, blocks other transactions
2. **Long transactions with external API calls** — holds locks, prevents VACUUM
3. **Missing retry logic with Repeatable Read / Serializable** — serialization errors are expected
4. **Implicit transactions** — every statement in PostgreSQL auto-commits if not in BEGIN/COMMIT
5. **Forgetting SKIP LOCKED in queue patterns** — causes lock contention instead of parallel processing
