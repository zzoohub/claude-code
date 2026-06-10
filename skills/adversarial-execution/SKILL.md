---
name: adversarial-execution
description: |
  Runtime adversarial verification (DAST) — EXECUTE, against a running app in an isolated
  environment, the abuse and exploitation attempts a static diff review can only name. Use when:
  a high-risk change (auth/session, payments, credential/VC issuance, irreversible data, DB
  schema/migration) needs proof that a named risk can or cannot be reproduced live — concurrency/
  race, token/nonce replay, cross-tenant IDOR, illegal state-machine transitions, numeric/limit
  abuse, migration dry-runs under prod-shaped data. Trigger on "adversarial test", "exploit the
  running app", "DAST", "abuse testing", "red-team this change", "prove the race", "reproduce the
  exploit".
  Do NOT use for: the threat taxonomy itself — what to look for and why (use security-checklists for
  OWASP/business-logic and correctness-checklists for races/idempotency; this skill EXECUTES their
  findings, it does not restate them); static diff review with no running app (use those two
  checklists); functional or happy-path browser/E2E verification and single-request negative checks
  (use the qa capability); or implementing the fixes (developer's job).
---

# Adversarial Execution

The **runtime arm of the static review.** The `security-checklists` and `correctness-checklists`
capabilities *name* the ways a change breaks — and their own discipline stops at naming ("if you
can't name the trigger, it isn't confirmed yet"). The attacker-view file `business-logic.md` even
ends checks with a runtime instruction — *"send 10 identical requests simultaneously"* — that a
static, read-only reviewer cannot run, and a black-box functional verifier is forbidden to form
(it may not read the diff to build the hypothesis). This skill is where those stranded instructions
get **executed**: you take a named risk and reproduce it against a running app, or prove you couldn't.

**A reproduction is the only currency.** You never argue "exploitable when X" — you demonstrate the
request sequence that broke the invariant.

## 1. Reuse the catalog — never reinvent the taxonomy

You carry no list of your own. The catalog already exists; read the section that matches the change
(via these capabilities, if available) and supply the verb it can't — **fire it**:

- **Business-logic abuse** — race/double-spend, numeric manipulation, state-machine violations,
  discount/refund/limit abuse, privilege boundaries → `security-checklists/references/business-logic.md`
  (the *attacker* view, written to be executed).
- **Auth / session / identity** — IDOR, session fixation, JWT alg/`none` confusion, OAuth
  state+nonce+PKCE, SAML XSW/replay, WebAuthn → `security-checklists/references/auth.md`.
- **Correctness under load** — idempotency, retries, partial failure, caching, boundaries →
  `correctness-checklists`.

## 2. Safe target environment — NON-NEGOTIABLE

You send mutating, abusive, sometimes destructive traffic. Before any attack, confirm the target is
safe to break:

- **Never production. Never a shared dev/staging others rely on.** Only a disposable, isolated
  instance you may corrupt and reset.
- **Seed from prod-*shape*, anonymized** — realistic volume/distribution/edge cases; never real PII
  or real credentials.
- **Stub every irreversible side effect** — outbound email/SMS, payment capture, webhooks, and
  especially **credential/VC issuance to a ledger, registry, or chain** (testnet/stub only — an
  issuance-abuse test fired at mainnet is itself the incident).
- **Allow-list the target host.** A misconfigured base URL must fail closed, not hit prod or a third
  party.
- **Reset between runs** so a destructive attack doesn't poison the next.
- **Read-only on the codebase.** You attack the running system; you never edit code. Report — the
  developer fixes.

If no such environment exists, **that is the blocker to report** — building it precedes any attack.

## 3. The techniques static review can't run

This is the whole value — setups a single-request, single-actor, code-blind verifier structurally
cannot create:

- **Concurrency / race.** Fire N simultaneous identical requests at one state change and check the
  invariant held exactly once — `seq 20 | xargs -P 20 -I _ curl -s -X POST …`, or parallel browser
  contexts. Targets: double-spend, oversell, double-issue, single-use coupon/credential redeemed
  twice, limit bypass.
- **Replay.** Capture a token / nonce / one-time link / idempotency key and resend it — after use,
  after expiry, after revoke. Targets: nonce/OTP replay, idempotency duplication, revoked-credential
  acceptance.
- **Multi-session / cross-tenant IDOR.** Hold two real sessions (attacker + victim, or tenant A + B).
  With A's session, read or mutate B's object by ID swap, parameter tamper, forced browsing. The
  highest-yield runtime check — and impossible single-actor.
- **Illegal state-machine transitions.** Craft requests that skip or revisit steps — POST straight to
  the final step, present-after-revoke, re-claim a consumed benefit, transition without the guard.
- **Numeric / limit abuse.** Negative / zero / overflow quantities, client-tampered
  price/discount/currency, `limit=999999`, unbounded export.
- **Migration dry-run** (schema changes). Run the migration against a prod-*census* clone and verify
  the named zero-downtime patterns actually hold — lock duration, the app working in the
  **intermediate state** (old code + new schema, *and* new code + old schema), backfill
  idempotency/resumability, rollback. Don't invent the method — execute the patterns
  `correctness-checklists` points to (the `database-design` / `postgresql` migration references),
  against a disposable DB.

## 4. Confirm, but never acquit

- A finding is real **only with a reproduction** — the exact request sequence that violated the
  invariant. No repro → not a finding (and no false positives: a reproduction is proof).
- **Failure to reproduce ≠ safe.** You could not build the right conditions; that is not proof the
  flaw is absent. A risk the static review named and you couldn't trigger stays **OPEN** (documented),
  never closed. You confirm; you do not clear.
- Keep an attempt log — invariant → attack → result — so a clean pass is *evidenced coverage*, not a
  shrug.

## 5. Output + promote to CI

```markdown
## Adversarial Execution Report

**Target**: [isolated env URL] · **Change**: [high-risk flag(s) fired] · **Catalog**: [sections executed]

### Confirmed Exploits (BLOCKING)
- **[Name]** — invariant violated: [what must never happen]
  - Repro: [exact request sequence / concurrency setup / replayed token]
  - Impact: [what an attacker achieves]
  - Promote: [the CI security-regression test this becomes — red now, green after fix]

### Attempted, Not Reproduced (risks stay OPEN — not cleared)
- **[Name from reviewer/catalog]** — attack tried: […] — result: not reproduced under [conditions].
  Static risk remains open.

### Coverage
- Invariants targeted: […] · Techniques run: [concurrency / replay / IDOR / state / numeric / migration]

### Verdict
- [ ] No exploit reproduced → adversary gate PASSES
- Any confirmed exploit → BLOCKS merge; route to developer; re-run after fix
```

Every confirmed exploit becomes a **CI security-regression test** (red now, green after the fix) —
the same way a permanent external contract is promoted to a CI-resident wire-guard spec.

## Trigger → battery

Run only the rows whose high-risk flag fired.

| High-risk flag | Catalog section | Runtime techniques to fire |
|---|---|---|
| auth / session | `auth.md` | cross-tenant IDOR, session fixation, JWT alg/`none`, token+nonce replay, OAuth state/PKCE, rate-limit & enumeration |
| payments | `business-logic.md` (Race, Numeric, Refund) + `correctness` (idempotency) | concurrent double-charge, idempotency-key replay, negative/overflow amount, client price tamper, over-refund |
| credential / VC issuance | `auth.md` (nonce/replay/alg, WebAuthn/SAML) + `business-logic.md` (State Machine, single-use) | present-after-revoke, re-issue-then-use-old, signature/alg downgrade, nonce replay, holder ≠ subject |
| irreversible data | `correctness` (idempotency, partial failure) + `business-logic.md` (limit/refund) | retry/replay for duplicate effect, race to bypass once-only, partial-failure double-write |
| DB schema / migration | `correctness` (Schema & Migration Safety) → `database-design` / `postgresql` refs | migration dry-run on prod-census: lock time, intermediate-state app, backfill idempotency, rollback |
