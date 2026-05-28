# `tasks/board.md` — Canonical Row Schema

Single source of truth for the task board format. Any skill that writes to `tasks/board.md` must follow this schema.

## Row Format

```markdown
| id | feature | task | type | priority | status | assignee | touches |
|----|---------|------|------|----------|--------|----------|---------|
| T-001 | infra | Project scaffolding | chore | high | backlog | — | package.json, tsconfig.json |
```

## Fields

| Field | Values | Notes |
|---|---|---|
| `id` | `T-NNN`, monotonically increasing | Survives across batches and phases. Never reused. |
| `feature` | feature name | Maps to `tasks/features/{feature}.md`. Use `infra`, `chore`, `bugfix-{slug}` for non-feature work. |
| `task` | one-line description | Imperative voice. Avoid duplicating info from feature file. |
| `type` | `feature \| bugfix \| refactor \| chore \| spike \| hotfix` | Required column. |
| `priority` | `high \| medium \| low` | **Lowercase. Not `P0/P1/P2/P3`.** |
| `status` | `backlog \| active \| blocked \| done` | Lifecycle managed by `task-status` skill. |
| `assignee` | username or `—` | `—` for unassigned. |
| `touches` | comma-separated file/dir paths | What this task modifies. Used for conflict detection. |

## Grouping

- **Phases** (default for new projects): `## Phase 1 — Foundation`, `## Phase 2 — Core`, etc. All tasks in a phase can run in parallel.
- **Iterations** (alternative for brownfield/Shape-Up shops): `## Iteration 5 (2026-W22)`. Drop the implicit "parallel-safe" assumption; iterations are time-boxed.

Pick one grouping per project. Don't mix.

## Forbidden variants

- ❌ `P0 / P1 / P2 / P3 / P4` priority — not aligned with this schema. (`plan-eng-review` previously used this; reconciled to lowercase.)
- ❌ Dropping the `type` column — required for filtering and reporting.
- ❌ Dropping the `assignee` column — leave as `—` for unassigned, but the column must exist.

## Who writes here

- `task-craft` — generates initial board from PRD + arch + UX
- `task-add` — appends one or more rows
- `task-status` — patches `status` field only
- `plan-ceo-review` / `plan-eng-review` — append new rows for issues found during review (using this schema)

All writers honor the same schema. Migration of older boards: see `task-add` schema-upgrade rules.
