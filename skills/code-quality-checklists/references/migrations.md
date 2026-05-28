# Migration Safety (zero-downtime patterns)

Migrations that pass review and still break prod usually fail one of these patterns. Reviewers should reject changes that violate them.

## Expand → migrate → contract

For any schema change that's not strictly additive, split into 3 deployments:

1. **Expand** — add the new column/table/index. Old code still works. Default values nullable or backfilled later.
2. **Migrate** — backfill data, dual-write from app (write both old and new), read from new only after verified.
3. **Contract** — drop the old column/table/index. Only after all readers and writers are off it.

Single-deployment "rename column" or "drop and recreate" is a guaranteed outage.

## Backfill batching

| Issue | Fix |
|---|---|
| `UPDATE table SET col = ...` on millions of rows | Locks table, WAL bloat, replication lag. Batch in 1k-10k chunks with `LIMIT ... FOR UPDATE SKIP LOCKED`. |
| Backfill inside the migration tool's transaction | Wraps entire backfill in one tx. Use a separate procedure (commits between batches) or app-loop. |
| No throttle between batches | DB load spike. Add `pg_sleep(0.1)` or app-side delay. |

See `postgresql/references/production-ops.md` for the canonical batched-backfill pattern.

## NOT NULL with default on a large table

`ALTER TABLE ... ADD COLUMN x INT NOT NULL DEFAULT 0` rewrites the whole table in older Postgres. PG 11+ handles this fast for constant defaults, but:

- **Volatile defaults** (e.g. `gen_random_uuid()`) still rewrite the table.
- **Add as nullable first**, backfill in batches, then add the NOT NULL constraint.

## Index creation

| Pattern | Issue | Fix |
|---|---|---|
| `CREATE INDEX` on busy table | Locks writes until done | Use `CREATE INDEX CONCURRENTLY` (Postgres). Cannot run in a transaction. |
| Migration tool wraps DDL in tx | Blocks CONCURRENTLY | Use the tool's "no-transaction" / "raw SQL" mode for this migration. |
| `CONCURRENTLY` failed midway | Leaves an INVALID index | Drop and retry. Don't leave half-built indexes. |

## Foreign key additions

`ALTER TABLE ... ADD FOREIGN KEY` validates every existing row (full table scan + share lock) by default.

Two-step alternative:
1. `ALTER TABLE ... ADD CONSTRAINT fk_name FOREIGN KEY (col) REFERENCES other(id) NOT VALID;` — fast, applies to new rows only.
2. `ALTER TABLE ... VALIDATE CONSTRAINT fk_name;` — validates existing rows without blocking writes (only `ShareUpdateExclusiveLock`).

## Dropping columns

`ALTER TABLE ... DROP COLUMN x` is cheap on Postgres (just marks dropped) but:
- Make sure NO code reads it. Search the whole codebase, not just the immediate change.
- For old ORMs, dropping mid-deploy can cause `unknown column` errors during rolling restart.
- Pattern: stop writing → stop reading → drop in the next deploy.

## Rollback plan required

Every migration needs:
- An explicit rollback SQL (or "non-reversible — backup and restore").
- A "how do I know it worked" verification query.
- Where the runbook is for the on-call who has to handle a failed deploy.

## Detection patterns reviewers should grep

- `ALTER TABLE.*ADD COLUMN.*NOT NULL` without a separate backfill step
- `CREATE INDEX` (without `CONCURRENTLY`) on tables larger than a few thousand rows
- `ADD FOREIGN KEY` without `NOT VALID`
- `UPDATE.*SET` across all rows without LIMIT or batching
- Schema change + code change in the same deploy artifact (should be staged)
