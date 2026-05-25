---
name: task-craft
description: |
  Create the initial task board from a complete PRD + architecture + UX. Generates
  the full `tasks/board.md` (phase-grouped) plus per-feature task files for every
  feature in the PRD. Used once per project to bootstrap the task system.
  Use when: a new project's design docs are ready and you need the initial task
  breakdown. Single source of truth for `tasks/board.md` format and task quality bar.
  Do NOT use for: adding a task to an existing board (use task-add instead). Do
  NOT use for: moving task status (use task-status). Do NOT use for: product
  planning (use prd-craft), architecture (use software-architecture), UX design
  (use ux-design), or implementing tasks (developer agents' job).
---

# Task Craft — Initial Board from Design Docs

Turn a complete set of design documents into a phased, parallel-safe task board.
Use this once when starting a new project. After the board exists, use
**`task-add`** to append tasks and **`task-status`** to move task state.

## Inputs

Read before generating tasks:

- `docs/prd/prd.md` — dev order, feature overview, scope
- `docs/prd/features/*.md` — detailed requirements per feature
- `docs/arch/` — architecture decisions (stack, component boundaries, patterns)
- `docs/arch/database.md` — data model (if exists)
- `docs/ux/` — user flows, wireframes, screen specs (if exists)
- `docs/api/` — OpenAPI specs, API contracts (if exists)

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
- `board.md`: **600 lines** — split into phase sub-files only if it grows past 1000
- `features/{feature}.md`: **400 lines** per feature

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

### Format

```markdown
# Task Board

> Last updated: YYYY-MM-DD

## Phase 1 — Foundation (all parallel)

| id | feature | task | type | priority | status | assignee | touches |
|----|---------|------|------|----------|--------|----------|---------|
| T-001 | infra | Project scaffolding and CI setup | chore | high | done | — | package.json, tsconfig.json |
| T-002 | file-parser | Input schema type definitions | feature | high | backlog | — | src/types/input.ts |

## Phase 2 — Core (all parallel, after Phase 1)

| id | feature | task | type | priority | status | assignee | touches |
|----|---------|------|------|----------|--------|----------|---------|
| T-003 | file-parser | CSV streaming reader | feature | high | backlog | — | src/parsers/csv.ts |
```

### Task fields

- `id` — globally unique, monotonically increasing (`T-001`, `T-002`, ...). Survives across batches.
- `feature` — feature name; maps to `features/{feature}.md`.
- `task` — one-line description.
- `type` — `feature` | `bugfix` | `hotfix` | `refactor` | `spike` | `chore`. Drives the acceptance shape (see below).
- `priority` — `low` | `medium` | `high`.
- `status` — `backlog` | `active` | `done` | `blocked`.
- `assignee` — agent or person; set by orchestrator, not on creation. `—` initially.
- `touches` — primary files the task creates or modifies. Avoids agent conflicts.

### Status Values

- `backlog` — not started
- `active` — assigned, in progress
- `done` — completed and verified
- `blocked` — waiting on external input or unresolved dependency

### Board Rules

- IDs are globally unique and monotonic.
- `touches` helps avoid agent conflicts.
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
- **context:** Define TypeScript types for all supported input formats. See arch §1 for type conventions.
- **acceptance:**
  - Types cover CSV, JSON, XML input formats
  - Exported from src/types/index.ts
  - No runtime validation here (that's T-003)
```

### Feature File Rules

- `context` must include enough information for an agent to start without reading the entire PRD. Reference specific sections (e.g., "arch §2") rather than vague pointers.
- `acceptance` defines done. Tasks without clear acceptance criteria should be sent back for revision.
- `depends_on` lists task IDs within or across features. This is the precise dependency — phases are the coarse grouping.
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

- **Session-sized** — Completable in one agent session. If it needs multiple sessions, split it.
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
- [ ] Every task has `type`, `phase`, `priority`, `touches`, `context`, `acceptance`
- [ ] No two tasks in the same phase touch the same file (or the conflict is flagged and sequenced)
- [ ] Every feature in `docs/prd/features/` has a corresponding `tasks/features/` file
- [ ] `board.md` phases correctly reflect dependency ordering (Phase N depends_on items must be in Phase < N)
- [ ] Task descriptions are specific enough that a worker agent can start without reading the PRD

Fail a gate → revise before saving.

---

## Cross-References

- **prd-craft** — Produces PRD + feature specs this skill consumes
- **software-architecture** — Produces `docs/arch/` which this skill relies on
- **ux-design** — Produces `docs/ux/` which this skill uses for frontend task specificity
- **task-add** — Append new tasks to an existing board (brownfield)
- **task-status** — Move task status (start/complete/block)
- **task-manager** — Orchestrator agent that invokes these task skills
