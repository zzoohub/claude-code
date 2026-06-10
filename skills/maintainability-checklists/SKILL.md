---
name: maintainability-checklists
description: |
  Maintainability and design-quality checklists for pre-landing review — the
  "will this stay cheap to change" lens that tests, linters, and type-checkers
  are structurally blind to. Covers modularity, cohesion & coupling, abstraction
  fit, extensibility, readability/cognitive load, domain modeling, testability,
  and test quality.
  Use when: reviewing a diff before commit/PR for design smells, high coupling,
  low cohesion, leaky or wrong abstractions, hard-to-extend or hard-to-test code.
  Complements security-checklists (OWASP) and correctness-checklists. Trigger on
  "code review", "maintainability", "refactor smell", "is this extensible".
  Do NOT use for: security vulnerabilities (use security-checklists);
  correctness bugs that survive CI (use correctness-checklists); formatting,
  unused variables, or unreachable code (linters/formatters own
  those); behavioral correctness of deterministic logic (tests own that);
  reuse/simplification micro-cleanups (use /simplify or /code-review); or
  implementing the fixes.
---

# Maintainability Checklists

The review lens nothing else covers. Tests prove *behavior*; linters and type-checkers catch *mechanics*; `security-checklists` catches *exploits*; `correctness-checklists` catches the *survive-CI bugs*. None of them tell you whether the code will be **cheap to change in six months**. That is this skill.

## Scope guard — do NOT flag what tooling already owns

| Owned by | Don't review here |
|---|---|
| Formatter (prettier/black/rustfmt) | formatting, import order |
| Linter (eslint/ruff/clippy/`go vet`) | unused vars/imports, unreachable code, simple dead code |
| Type-checker (tsc strict/mypy/rustc) | within-language type errors, simple nullability |
| Tests | behavioral correctness of deterministic logic |
| `correctness-checklists` | races, idempotency, cache invalidation, partial-failure, boundary defects |
| A dedicated cleanup pass (e.g. `/simplify` in Claude Code), if available | reuse / efficiency / micro-simplification cleanups |

This skill is for **staff-level design judgment** and the **survive-prod bugs** those miss. Pick sections by what the diff changes.

---

## Modularity, Cohesion & Coupling

- **Low cohesion** — a unit does several unrelated things; its responsibility needs an "and" to describe. Split by reason-to-change (SRP).
- **High coupling** — a module reaches into another's internals (fields, private helpers, concrete types) instead of a stable interface. Change one → the other breaks.
- **Feature envy** — a method uses another object's data more than its own; the behavior lives in the wrong place. Move it to the data.
- **Shotgun surgery / change amplification** — one logical change forces edits across many files. The strongest signal a module boundary is drawn wrong.
- **Inappropriate intimacy / circular dependency** — two modules know each other's details; neither can be understood, changed, or tested in isolation.
- **God object / manager class** — one unit accumulates everything and becomes a gravity well for every future change.
- **Dependency direction violation** — domain/policy code imports infrastructure or framework (ORM entities in business logic, HTTP types in the domain). If the project carries an import-boundary CI rule (dependency-cruiser, import-linter, workspace crates), point at it; hand-review this only where no such guard exists.

## Abstraction Fit

- **Leaky abstraction** — callers must know the implementation to use it right (must call `init()` first, must check a flag the abstraction should own).
- **Wrong / premature abstraction** — an interface generalized for cases that don't exist yet; indirection that adds cognitive cost with no payoff. Rule of three: duplicate twice before extracting.
- **Missing abstraction** — the same concept open-coded in many places, or a domain concept that has no name in the code.
- **Wrong altitude** — high-level policy and low-level mechanism mixed in one function (orchestration interleaved with byte-twiddling).

## Extensibility

- **Open/closed violation** — adding a new case means editing a `switch`/`if-else` in N places instead of adding one type/strategy. Every new variant re-touches old code.
- **Hardcoded assumptions** — single tenant/region/currency/limit baked into logic that will obviously need to vary.
- **Boolean/flag parameters that fork behavior** — `doThing(true, false)`; usually two functions crammed into one.

## Readability & Cognitive Load

- **Deep nesting / arrow code** — prefer guard clauses and early returns (suspect nesting ≥3 levels).
- **Long parameter lists** — group into a value object; order-dependent args invite silent mistakes (suspect ≥4 params).
- **Naming that lies or hides** — `data`, `tmp`, `manager`, `process()`; names that no longer match what the code does.
- **Magic values** — unexplained literals; intent buried in a number.
- **Comment/code drift** — comments describing behavior the code no longer has (no tool catches this).

## Domain Modeling

- **Primitive obsession** — raw `string`/`map`/`int` where a domain type belongs (`Email`, `Money`, `UserId`); validation scattered instead of enforced once at the type boundary.
- **Stringly-typed** — branching on or passing magic strings where an enum/union belongs.
- **Anemic model** — data and the rules that govern it drift into separate places, so invariants aren't enforced where the data lives.

## Testability

- **Hidden dependencies** — a unit reaches for globals/singletons or `new`s its own collaborators, so nothing can be substituted in a test.
- **Untestable time / randomness / IO** — `Date.now()`, RNG, direct network calls not injected → tests become flaky or impossible.
- **No seam** — you must stand up the whole world to exercise one rule. If it's hard to test, the design is telling you something.

## Test Quality (meta — do the tests actually protect us?)

Coverage % says lines ran, not that they're guarded. Tests are code too; review them.

- **Asserts status, not side effects** — "401 on bad token" passes even if the handler wrote to the DB before returning.
- **Tests the mock, not the code** — so much mocking that only the mock runs.
- **Missing error/negative-path coverage** — happy path tested; 500 / timeout / partial-failure untested.
- **Hollow assertions** — `expect(result).toBeDefined()` where the real contract goes unchecked.

> For the bugs that survive green CI — races, idempotency, cache invalidation, partial failure, boundary defects — use the **correctness-checklists** skill (Pass 1, blocking). This skill stays on design.

---

## Review Output Contract

```markdown
- **[Smell / Issue Name]** — `file:line`
  - Smell: [name the design smell, one line]
  - Cost: [what future change gets expensive, or which change becomes risky]
  - Fix: [specific — "extract X behind interface Y", not "improve the design"]
```

These are Pass 2 (informational). This is the non-blocking layer within the reviewer gate — security/correctness findings block, these inform (unless project policy escalates them). Don't block a PR on them unless project policy says so — but raise high coupling and missing abstractions early, because they get exponentially more expensive to fix the longer they live.

If you can't fill the **Cost** line with a concrete future change that gets expensive, it isn't a finding — drop it. Design opinions without a named cost are noise.
