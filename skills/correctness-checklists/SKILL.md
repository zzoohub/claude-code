---
name: correctness-checklists
description: |
  Correctness checklists for the bugs that survive green CI — defects that pass
  tests, lint, and type-checks but corrupt data, double-charge, lose writes, or
  page you at 3am. Tests run single-threaded on happy paths, so they miss
  concurrency, retry, partial-failure, caching, and boundary defects. This is
  the Pass 1 (blocking) review layer for runtime correctness, alongside
  security-checklists.
  Use when: reviewing a diff that touches concurrency, locks, transactions,
  retries, webhooks, event/queue handlers, caching, background jobs,
  money/inventory state machines, or data crossing serialization/network/DB
  boundaries. Trigger on "race condition", "idempotency", "TOCTOU", "cache
  invalidation", "double charge", "lost update", "concurrent", "retry safety",
  "exactly once", "deadlock".
  Do NOT use for: security vulnerabilities (use security-checklists);
  design/maintainability smells (use maintainability-checklists); deterministic
  logic bugs (tests own those); style/formatting (linters own those); or
  implementing the fixes.
---

# Correctness Checklists

The bugs that pass tests + lint + types and still break in production. Tests run single-threaded on a happy path, so the entire class of **concurrency / retry / partial-failure / boundary** defects slips through a green pipeline. This is **Pass 1 (blocking)** — these corrupt data, double-charge, or lose writes. Treat a confirmed finding as a commit blocker, not an FYI.

Flag these when the diff touches the trigger areas. Pick sections by what changed.

---

## Concurrency & Races

- **Read-check-write without a uniqueness constraint or atomic guard** — two callers both pass the check, both write. Fix: DB unique index + `ON CONFLICT`, `SELECT ... FOR UPDATE`, or an advisory lock.
- **Lost update** — load row → mutate in app → save, with no version column / optimistic lock; concurrent edits silently clobber each other.
- **Status transition without a guard** — `UPDATE ... SET status='paid' WHERE id=?` missing `AND status='pending'`; two workers both transition the same row.
- **Upsert relying on an app-level existence check** — `findOrCreate` / `upsert` without a unique index creates duplicates under load.
- **TOCTOU** — any check-then-act that must be atomic (balance ≥ amount → debit; slot free → reserve; quota left → consume).
- **Non-atomic counter / aggregate** — read-modify-write of a count/total instead of an atomic increment or a DB-side aggregate.

## Idempotency & Retries

- **Mutating endpoint without an idempotency key** — a client retry or double-submit charges/creates twice.
- **At-least-once treated as exactly-once** — a webhook / queue / event handler that isn't safe to run twice on the same message.
- **Retry around a non-idempotent side effect** — a retry wrapper over send-email / charge-card / external POST that isn't safe to repeat.
- **No dedup on event consumers** — the same event id can be processed more than once with no guard.

## Partial Failure & Side-Effect Ordering

- **Conditional side-effect leak** — one branch performs a side effect another path forgets (publish generates a URL, edit doesn't → stale URL).
- **Log claims an action a guard skipped** — `logger.info("email sent")` sits outside the `if` that actually sends.
- **Error path leaves state half-done** — DB write + external call; one fails, the other isn't compensated or rolled back. Use `try/finally`, `defer`, or an outbox/saga.
- **Multi-resource write without a transaction or compensation** — two writes that must both land or both not.
- **Resource leak on the error path** — connection/file/lock acquired, then an early return or throw skips the release.

## Caching

- **Stale read after write** — the write path doesn't invalidate or update the cache.
- **Missing invalidation on related keys** — updating one entity leaves derived/aggregate cache entries stale.
- **Cache key collision / missing dimension** — key omits tenant/locale/version, so users see each other's data.
- **Stampede** — no single-flight / negative caching; a hot-key miss floods the origin.

## Trust & Serialization Boundaries

- **LLM output used without validation** — model output used as a flag or written to a store without a shape/enum check. (See `security-checklists/references/llm-security.md`.)
- **Cross-boundary type coercion** — JSON number↔string IDs compared with `===`; numeric precision lost; non-normalized hash/digest inputs producing nondeterministic results.
- **Naive datetime across a UTC boundary** — parsing/storing without a timezone, then comparing or ordering against UTC.
- **Money as float** — currency in floating point; rounding, truncation, or `==` comparison errors. Use integer minor units or a decimal type.

## Schema & Migration Safety

For any schema change, apply the zero-downtime rules in `database-design/references/migration-patterns.md` and `postgresql/references/production-ops.md` (expand→migrate→contract, `CREATE INDEX CONCURRENTLY`, FK `NOT VALID` + `VALIDATE CONSTRAINT`, batched backfills, rollback SQL). A single-deploy rename/drop, or an unbatched full-table `UPDATE`, is an outage. That's their single source of truth — don't restate the patterns here.

---

## Review Output Contract

```markdown
- **[Issue Name]** (blocking) — `file:line`
  - Failure mode: [how it breaks under concurrency / retry / partial failure — one line]
  - Trigger: [the real-world condition that exposes it — load, retry, crash mid-op]
  - Fix: [specific mechanism — unique index, idempotency key, FOR UPDATE, try/finally]
```

These are Pass 1 (blocking). A confirmed finding should stop the commit until it's fixed or explicitly accepted with written justification.
