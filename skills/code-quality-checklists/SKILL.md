---
name: code-quality-checklists
description: |
  Structural code quality checklists for pre-landing review. Covers the bugs that
  tests don't catch: race conditions, N+1 queries, TOCTOU, dead code, test gaps,
  type coercion at boundaries, LLM output trust boundaries, and conditional
  side-effect leaks.
  Use when: reviewing a diff before commit/PR, or reviewing for race conditions,
  data corruption risks, silent failures, trust boundary violations, or
  maintenance smells. Complements security-checklists (OWASP) — this skill covers
  non-security structural bugs.
  Do NOT use for: security vulnerabilities (use security-checklists), style
  nitpicks, formatting, or implementing fixes.
---

# Code Quality Checklists

Structural issues that pass tests and lint but still blow up in production. This is the **Pass 2 (Informational)** layer of code review. Security issues (Pass 1) live in `security-checklists`.

Pick sections by what the diff actually changes — most reviews need 3-5.

---

## Race Conditions & Concurrency

- **Read-check-write without uniqueness constraint or retry-on-conflict** — Two concurrent callers both pass the check, both write. Fix: DB unique index + `ON CONFLICT` or advisory lock.
- **Upsert without a unique DB index** — `findOrCreate` / `upsert` relying only on application-level checks creates duplicates under load.
- **Status transitions without atomic guard** — `UPDATE ... SET status='paid' WHERE id=?` without `AND status='pending'` lets two workers mark the same row paid.
- **TOCTOU races** — Any check-then-act that should be atomic (balance ≥ amount → debit; slot available → reserve).

## Data Safety

- **ORM bypassing validations** — `update_column` / raw writes on fields with business constraints. Bypass requires justification.
- **Mass assignment** — Passing `req.body` straight to `model.update()` lets attackers set `is_admin`. Whitelist permitted fields.
- **N+1 queries in loops or views** — Missing eager-loading. Caught by framework logs or EXPLAIN in dev.
- **Nullable FK without ON DELETE behavior** — Orphan rows after parent deletion.

## LLM Output Trust Boundary

- **LLM-generated values written to DB without format validation** — Schema crash downstream.
- **Structured tool output accepted without shape check** — Missing required fields break callers silently.
- **Prompt-injection trusting user content as instructions** — User strings interpolated into the system prompt. (See also `security-checklists/references/llm-security.md`.)
- **Free-form LLM output used as a flag** — `"yes" in response.lower()` is not authoritative. Use structured output + schema.

## Conditional Side Effects

- **Branch forgets side effects on one path** — e.g. publish flow generates a URL, edit flow doesn't, leaving stale URLs.
- **Log claims action that was conditionally skipped** — `logger.info("Email sent")` outside the if-block that actually sends.
- **Error path missing cleanup** — Transaction + file write, DB fails, file orphaned. Use `try/finally` / `defer`.

## Dead Code & Consistency

- **Variables assigned but never read** — Especially dangerous when the assignment had a side effect that's now gone.
- **Comments describing old behavior** — Drift between comment and code.
- **Unreachable branches** — Dead or shadowed by earlier returns.

## Test Gaps

- **Negative-path tests assert status but not side effects** — "401 on bad token" passes even if the handler wrote to DB before returning 401.
- **Security enforcement without integration test** — Auth middleware claimed in code, no test exercising the enforcement path.
- **Missing assertions on error conditions** — Happy path well-tested; 500/timeout behavior untested.
- **Tests that exercise mocks, not code** — Mocking so much that only the mock runs.

## Type Coercion at Boundaries

- **Values crossing language / serialization boundaries** — Numeric IDs becoming strings in JSON, then compared `===` with numeric IDs; always fails.
- **Hash / digest inputs without normalization** — Field ordering or numeric type differs; non-deterministic hashes across runs.
- **Date / timezone drift** — Parsing a date string without timezone, passing it to code that assumes UTC.

## LLM Prompt Drift

- **Prompt lists tools that aren't wired up** — Model hallucinates tools.
- **Token / word limits stated in multiple places** — Prompt says 500, UI copy says 300, `max_tokens` says 1000. They drift.
- **Prompt changes without eval** — Any prompt change should be paired with a benchmark run (see `llm-app-design`).

---

## Review Output Contract

```markdown
- **[Issue Name]** — `file:line`
  - Problem: [one line]
  - Impact: [what breaks, how often]
  - Fix: [specific — not "add validation"]
```

These are Pass 2 (informational). Do not block a PR on them unless project policy says otherwise.

---

## Cross-References

- **security-checklists** (skill) — Pass 1 (blocking) OWASP Top 10:2025
- **postgresql** (skill) — N+1 diagnosis via EXPLAIN
- **llm-app-design** (skill) — Upstream design for LLM output handling and eval-driven prompt changes
- **reviewer** (agent) — Invokes this skill during pre-landing review
