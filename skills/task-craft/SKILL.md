---
name: task-craft
description: |
  Create the initial task board from a complete PRD + architecture + UX. Generates
  the full `tasks/board.md` (phase-grouped) plus per-feature task files for every
  feature in the PRD. Used once per project to bootstrap the task system.
  Use when: a new project's design docs are ready and you need the initial task
  breakdown. Owns the task generation process and the task quality bar; the
  canonical row format lives in `references/board-schema.md`.
  Also use to review / audit an existing task board (read-only — produces a
  prioritized findings list, does not overwrite the board).
  Do NOT use for: adding a task to an existing board (use task-add instead). Do
  NOT use for: moving task status (use task-status). Do NOT use for: product
  planning (use prd-craft), architecture (use software-architecture), UX design
  (use ux-design), or implementing tasks (developer agents' job).
---

# Task Craft — Initial Board from Design Docs

Turn a complete set of design documents into a phased, parallel-safe task board.
Use this once when starting a new project.

## Inputs

Read before generating tasks:

- `docs/prd/prd.md` — dev order, feature overview, scope
- `docs/prd/features/*.md` — detailed requirements per feature
- `docs/arch/` — architecture decisions (stack, component boundaries, patterns)
- `docs/arch/database.md` — data model (if exists)
- `docs/ux/` — user flows, wireframes, screen specs (if exists)

If architecture docs don't exist, flag it. Tasks without architecture decisions
tend to need rework.

If your project keeps these elsewhere, see `AGENTS.md` at the repo root.

---

## Output Structure

```
tasks/
├── board.md              # Phase-based status table (mutable; orchestrator reads this)
└── features/
    └── {feature}.md      # Full task details per feature
```

**Separation principle**: `board.md` tracks state (changes often). Feature files
hold context (change rarely). Minimizes merge conflicts when multiple agents
work in parallel.

---

## Publication Standard

You produce publication-ready task systems, not drafts for the user to fix.

**Line limits** (check before each update; consolidate first if exceeded):
- `board.md`: **target 600 lines** (tighten wording when exceeded); only **split** into phase sub-files past **1000**. The 600 target keeps the status table scannable; the 1000 split point is where one file starts causing merge conflicts across parallel agents.
- `features/{feature}.md`: **400 lines** per feature — sized to fit in one worker agent's session context alongside the task it's executing.

When a file hits the limit: tighten wording, merge redundant context, remove
resolved open notes. Trust git for history.

---

## board.md — Status Registry

The board is the single source of truth for task state.

### Phase Rules

- **Within a phase**: All tasks can run in parallel.
- **Between phases**: Phase N+1 starts only after all Phase N tasks are done.
- Tasks with no cross-feature dependencies go in the earliest possible phase.
- Infrastructure / setup tasks go in Phase 1.
- `task-craft` always groups by **phases**. The iterations grouping (see `references/board-schema.md`) is a brownfield alternative that `task-add` maintains — don't produce it here.

### Format

Canonical row schema: `references/board-schema.md`. All writers follow it: `task-craft`, `task-add`, and `task-status` write directly; `plan-ceo-review` / `plan-eng-review` route through `task-add`.

```markdown
# Task Board

> Last updated: YYYY-MM-DD

## Phase 1 — Foundation (all parallel)

| id | feature | task | type | priority | status | assignee | touches |
|----|---------|------|------|----------|--------|----------|---------|
| T-001 | infra | Project scaffolding and CI setup | chore | high | backlog | — | package.json, tsconfig.json |
| T-002 | file-parser | Input schema type definitions | feature | high | backlog | — | src/types/input.ts |

## Phase 2 — Core (all parallel, after Phase 1)

| id | feature | task | type | priority | status | assignee | touches |
|----|---------|------|------|----------|--------|----------|---------|
| T-003 | file-parser | CSV streaming reader | feature | high | backlog | — | src/parsers/csv.ts |
```

### Task fields

Column set, allowed values, and field semantics are canonical in
`references/board-schema.md`. Generation-specific notes:

- `id` — globally unique, monotonically increasing (`T-001`, `T-002`, ...). Survives across batches; never reused.
- `assignee` — `—` initially; the orchestrator sets it, not creation.
- `touches` — primary files the task creates or modifies. Used to keep two tasks in the same phase off the same file.
- All tasks start at `status: backlog`.

### Board Rules

- **Phase is not a column.** A task's phase is the `## Phase N` heading it sits under — that heading is the single source of truth, mirrored by the `phase:` field in the feature file. The two must always match.
- IDs are globally unique and monotonic.
- `assignee` is set by the orchestrator, not on creation.

---

## features/{feature}.md — Task Detail Files

One file per feature. Contains full context so a worker agent can start
immediately without reading the entire project.

### Format

```markdown
# {feature}

> Sources: docs/prd/features/{feature}.md, docs/arch/{relevant}.md, docs/ux/{screen}.md

## Changes
<!-- Append-only. Record when tasks are added, modified, or removed due to plan changes. -->
- YYYY-MM-DD: Initial task breakdown from PRD v1.

## Tasks

### T-002: Input schema type definitions
- **type:** feature
- **phase:** 1
- **priority:** high
- **depends_on:** —
- **touches:** src/types/input.ts
- **context:** Define TypeScript types for all supported input formats. Satisfies REQ-001/REQ-002 in `docs/prd/features/file-parser.md`. See arch §1 for type conventions.
- **acceptance:**
  - Types cover CSV, JSON, XML input formats (REQ-001)
  - Exported from src/types/index.ts
  - No runtime validation here (that's T-003)
```

### Feature File Rules

- `context` must include enough information for an agent to start without reading the entire PRD. Reference specific sections (e.g., "arch §2") rather than vague pointers.
- `acceptance` defines done. Tasks without clear acceptance criteria should be sent back for revision. Cite the requirement(s) the task satisfies by their `REQ-NNN` IDs from `docs/prd/features/{feature}.md`, so work traces back to a requirement.
- `depends_on` lists task IDs within or across features. This is the precise dependency — phases are the coarse grouping.
- `phase:` mirrors the board's `## Phase N` heading (the board is authoritative). If a task ever moves between phases, update both.
- `Changes` section is append-only. When the plan changes, record what changed and why. Worker agents check this to see if their task was recently modified.

---

## Task Type Guide

Each task type implies a different shape for `context` and `acceptance`.

| Type | `context` should include | `acceptance` should include |
|---|---|---|
| `feature` | Feature spec ref, arch section, UX screen ref | New behavior verifiable end-to-end, tests added |
| `bugfix` | Bug repro, observed vs expected, root cause hypothesis | Test that fails before fix and passes after, no regression in adjacent code |
| `hotfix` | Production impact, severity, affected users | Fix deployed, post-mortem task created |
| `refactor` | Current shape, target shape, ASR or pain motivating change | No behavior change (existing tests still pass), affected files listed |
| `spike` | Question to answer, time-box | Decision recorded (ADR or note), follow-up tasks if needed |
| `chore` | What and why | Done criteria (e.g., "CI green", "docs published") |

---

## Workflow

1. Read all input documents.
2. Build a dependency graph: identify which tasks can run in parallel vs. must be sequential.
3. Assign tasks to phases (earliest possible phase respecting dependencies).
4. Create `tasks/board.md` with phase-grouped tables.
5. Create `tasks/features/{feature}.md` for each feature with full task details.

---

## Task Quality Bar

Every task must satisfy:

- **Session-sized** — Completable in one agent session. If it needs multiple sessions, split it. Heuristic: consider splitting when a task `touches` more than 3–5 files or has more than 5 independent acceptance items.
- **Phased** — Belongs to exactly one phase. Tasks in the same phase have no mutual dependencies.
- **Architecture-aware** — Reflects chosen stack, patterns, and component names from `docs/arch/`.
- **Conflict-aware** — `touches` lists files the task will create or modify. Two tasks in the same phase should not touch the same file. If they must, note it and sequence them into different phases.
- **Specific and actionable**:
  - ❌ Bad: "Set up parsing"
  - ✅ Good: "Implement CSV streaming reader with backpressure for files over 100MB"
- **Feature-grouped** — One feature file per feature, matching `docs/prd/features/` filenames.
- **Type-appropriate acceptance** — See Task Type Guide above.

---

## Quality Gates (apply before saving)

- [ ] Every task has a unique ID in format `T-NNN`
- [ ] Every task has `type`, `phase`, `priority`, `depends_on` (or `—`), `touches`, `context`, `acceptance`
- [ ] Each task's feature-file `phase:` matches the `## Phase N` board section it sits under
- [ ] No two tasks in the same phase touch the same file (or the conflict is flagged and sequenced)
- [ ] Every feature in `docs/prd/features/` has a corresponding `tasks/features/` file
- [ ] `board.md` phases correctly reflect dependency ordering (Phase N depends_on items must be in Phase < N)
- [ ] Task descriptions are specific enough that a worker agent can start without reading the PRD

Fail a gate → revise before saving.

---

## Review / Audit Mode

When the user asks to **review / audit** an existing task board (not generate a
new one), do **not** run the generation workflow and do **not** overwrite
`tasks/board.md`. This mode is read-only.

1. Read `tasks/board.md` and `tasks/features/*.md`.
2. Audit against the **Task Quality Bar** and **Quality Gates** above, plus:
   - **Phase integrity** — no same-phase file conflicts; every `depends_on`
     item sits in an earlier phase.
   - **Coverage** — every feature in `docs/prd/features/` has tasks; no orphan
     tasks pointing at non-existent features.
   - **Acceptance quality** — each task is specific, session-sized, and
     type-appropriate.
3. Output a prioritized findings list (🔴 blocker / 🟠 should-fix / 🟡 nit),
   each citing the offending `T-NNN` and a concrete fix. Do **not** rewrite the
   board — propose changes and let the user apply them via `task-add` /
   `task-status`.

---
