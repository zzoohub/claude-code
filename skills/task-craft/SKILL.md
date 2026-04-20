---
name: task-craft
description: |
  Task breakdown methodology and templates. Converts a PRD + architecture + UX into
  phase-based, parallel-safe, session-sized implementation tasks. Single source of
  truth for the board.md and features/*.md formats, phase rules, status lifecycle,
  and task quality bar used by the task-manager agent.
  Use when: generating implementation tasks from design docs, updating a task
  board, reorganizing tasks after plan changes, validating task quality, or
  setting up a new task system in a project.
  Do NOT use for: product planning (use prd-craft), architecture (use
  software-architecture), UX design (use ux-design), or implementing tasks
  themselves (that's the developer agents' job).
---

# Task Craft

Turn design documents into actionable, session-sized tasks organized by execution phase. This skill is the format authority for `tasks/board.md` and `tasks/features/*.md` so the task-manager agent and any worker agents share one contract.

---

## Inputs

Before generating tasks, read:

- `docs/prd/prd.md` — dev order, feature overview, scope
- `docs/prd/features/*.md` — detailed requirements per feature
- `docs/arch/` — architecture decisions (stack, component boundaries, patterns)
- `docs/arch/database.md` — data model (if exists)
- `docs/ux/` — user flows, wireframes, screen specs (if exists)
- `docs/api/` — OpenAPI specs, API contracts (if exists)

If architecture docs don't exist yet, flag it. Tasks without architecture decisions tend to need rework.

---

## Output Structure

```
tasks/
├── board.md              # Phase-based status table (mutable; orchestrator reads this)
└── features/
    ├── {feature}.md      # Full task details per feature
    └── ...
```

**Separation principle**: `board.md` tracks state (changes often). Feature files hold context (change rarely). Minimizes merge conflicts when multiple agents work in parallel.

---

## Publication Standard

You produce publication-ready task systems, not drafts for the user to fix.

**Line limits** (check before each update; consolidate first if exceeded):
- `board.md`: **600 lines** — split into phase sub-files only if it grows past 1000
- `features/{feature}.md`: **400 lines** per feature

When a file hits the limit: tighten wording, merge redundant context, remove resolved open notes. Trust git for history.

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

| id | feature | task | priority | status | assignee | touches |
|----|---------|------|----------|--------|----------|---------|
| T-001 | infra | Project scaffolding and CI setup | high | done | — | package.json, tsconfig.json |
| T-002 | file-parser | Input schema type definitions | high | backlog | — | src/types/input.ts |

## Phase 2 — Core (all parallel, after Phase 1)

| id | feature | task | priority | status | assignee | touches |
|----|---------|------|----------|--------|----------|---------|
| T-003 | file-parser | CSV streaming reader | high | backlog | — | src/parsers/csv.ts |
```

### Status Values

- `backlog` — not started
- `active` — assigned, in progress
- `done` — completed and verified
- `blocked` — waiting on external input or unresolved dependency

### Board Rules

- IDs are globally unique, monotonically increasing (`T-001`, `T-002`, ...)
- `touches` lists primary files the task will create or modify (helps avoid agent conflicts)
- `assignee` is set by the orchestrator, not when generating. Leave as `—` initially
- When updating status, edit only the relevant row — do not rewrite the entire table

---

## features/{feature}.md — Task Detail Files

One file per feature. Contains full context so a worker agent can start immediately without reading the entire project.

### Format

```markdown
# {feature}

> Sources: docs/prd/features/{feature}.md, docs/arch/{relevant}.md, docs/ux/{screen}.md

## Changes
<!-- Append-only. Record when tasks are added, modified, or removed due to plan changes. -->
- YYYY-MM-DD: Initial task breakdown from PRD v1.

## Tasks

### T-002: Input schema type definitions
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

---

## Workflow

### Generate (initial breakdown)

1. Read all input documents.
2. Build a dependency graph: identify which tasks can run in parallel vs. must be sequential.
3. Assign tasks to phases (earliest possible phase respecting dependencies).
4. Create `tasks/board.md` with phase-grouped tables.
5. Create `tasks/features/{feature}.md` for each feature with full task details.

### Update (plan change)

1. Read current `tasks/` files and relevant source documents.
2. Apply requested changes to both `board.md` and affected feature files.
3. If new tasks are added, assign the next available ID (check highest existing ID).
4. If dependencies change, re-evaluate phase assignments.
5. Append a dated entry to the `Changes` section of affected feature files.

### Progress (status moves)

- **Start**: Set status to `active` in `board.md`
- **Complete**: Set status to `done` in `board.md`
- **Block**: Set status to `blocked` in `board.md`, add a note in the feature file
- **Abandon**: Set status back to `backlog` in `board.md`, append reason to feature file Changes

Progress updates only touch `board.md` (one row edit). Feature files are not modified for status changes.

---

## Quality Gates (apply before saving)

- [ ] Every task has a unique ID in format `T-NNN`
- [ ] Every task has `phase`, `priority`, `touches`, `context`, `acceptance`
- [ ] No two tasks in the same phase touch the same file (or the conflict is flagged and sequenced)
- [ ] Every feature in `docs/prd/features/` has a corresponding `tasks/features/` file
- [ ] `board.md` phases correctly reflect dependency ordering (Phase N depends_on items must be in Phase < N)
- [ ] Task descriptions are specific enough that a worker agent can start without reading the PRD

Fail a gate → revise before saving.

---

## Cross-References

- **prd-craft** (skill) — Produces the PRD this skill consumes
- **software-architecture** (skill) — Produces `docs/arch/` which this skill relies on for stack decisions
- **ux-design** (skill) — Produces `docs/ux/` which this skill uses for frontend task specificity
- **task-manager** (agent) — Orchestrator that invokes this skill
