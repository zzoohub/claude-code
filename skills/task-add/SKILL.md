---
name: task-add
description: |
  Add tasks to an existing task board. Reads the current `tasks/board.md` and
  feature files to learn the project's grouping (phases or iterations) and the
  next available ID, then appends new tasks. Creates or updates a single
  `tasks/features/{feature}.md` with details. Works for feature work, bugfixes,
  hotfixes, refactors, spikes, and chores.
  Use when: the task board already exists and you need to add work — a new
  feature, a bug, a one-off fix, a refactor, a chore. Trigger phrases: "add a
  task for X", "log a bug for X", "create a task to refactor Y", "add this to
  the board".
  Do NOT use for: creating the initial board (use task-craft). Do NOT use for:
  moving task status (use task-status). Do NOT use for: writing the feature
  spec itself (use feature-spec).
---

# Task Add — Append to Existing Board

Adds tasks to a board that already exists, picking the right group and the
next available ID.

## Prerequisites

`tasks/board.md` must already exist. If your project keeps tasks elsewhere,
see `AGENTS.md` at the repo root.

## What This Skill Does

1. Reads `tasks/board.md` to learn the grouping (phases or iterations) and the
   highest existing ID.
2. Reads the relevant feature spec at `docs/prd/features/{feature}.md` if
   the task is feature work.
3. Reads `docs/arch/system.md` for stack and component names, so tasks
   reference the right files.
4. Generates one or more tasks (default: one) with type appropriate for the
   work (feature, bugfix, hotfix, refactor, spike, chore).
5. Picks the right group:
   - **Phases board** — earliest phase that respects dependencies. If all
     phases are done, append `Phase N+1 — {feature}`.
   - **Iterations board** — add to the current open iteration, or the next
     one if the current is closed. Never create a `Phase N` heading on an
     iterations board.
6. Updates or creates `tasks/features/{feature}.md` with task details. For
   one-off bugfixes / chores, skip the feature file unless the user asks for
   `--with-spec` or the change is non-trivial. When you skip it, keep the
   board row self-contained (clear `task` + `touches`) and use a stable
   `feature` bucket (`infra` / `chore` / `bugfix-{slug}`); any later
   block/abandon note for such a task goes to `tasks/features/_misc.md`.
7. Appends a dated entry to the feature file's `Changes` section (skip if no
   feature file was created).
8. Bumps the board's `> Last updated:` header to today's date.

## What This Skill Does NOT Do

- Does not rewrite `tasks/board.md` from scratch
- Does not move task status
- Does not create the initial board
- Does not write feature specs or ADRs

## Task Types

Each task type implies different `context` and `acceptance` shapes. Quick
reference below; the full per-type `context`/`acceptance` shape is the **Task
Type Guide** in `task-craft`.

| Type | Use for |
|---|---|
| `feature` | New behavior tied to a feature spec |
| `bugfix` | Defect with a repro |
| `hotfix` | Production incident; deploy fast |
| `refactor` | Code restructure with no behavior change |
| `spike` | Time-boxed investigation |
| `chore` | Infra / tooling / docs |

## Workflow

1. **Read current board** — `tasks/board.md` for grouping + highest ID
2. **Read context for the task type:**
   - Feature task → `docs/prd/features/{feature}.md`, `docs/arch/system.md`
   - Bugfix → user's repro description (ask for steps to reproduce, observed
     vs expected, severity)
   - Refactor → `docs/arch/system.md` (current shape) + the proposed shape
     (may already be recorded in an ADR)
   - Spike → the question to answer + time-box
3. **Pick the next ID** — highest existing `T-NNN` + 1. ID assignment must be
   serialized: allocate a contiguous block when adding several at once, and
   when agents add in parallel let the orchestrator hand out IDs so two adds
   can't claim the same number.
4. **Choose the group** — see step 5 above (phases vs iterations)
5. **Write the row** — append to `tasks/board.md` in the right group
6. **Write task details** — append to `tasks/features/{feature}.md` (or
   create it if absent). For one-off non-feature work, default to skipping
   the feature file unless the work is non-trivial; keep the board row
   self-contained when you skip it.
7. **Log the change** — append a dated entry to the feature file's `Changes`
   section (skip if no feature file was created).
8. **Bump the header** — set `> Last updated:` to today's date.

## board.md row format

Canonical column set and field semantics: `task-craft/references/board-schema.md`.

```
| T-NNN | {feature} | {one-line description} | {type} | {priority} | backlog | — | {touched files} |
```

## Schema upgrade

When the existing board predates the current schema, upgrade it in place as
part of your update (this is the migration path `board-schema.md` points to):

- Missing `type` column → add it; backfill existing rows by inferring the type
  from each task (default `feature`).
- `P0/P1/P2/P3` priorities → rewrite to lowercase `high | medium | low`.
- Missing `assignee` column → add it, `—` for all existing rows.

Keep upgrades minimal; don't reformat unrelated rows.

## Feature file detail format

```markdown
### T-NNN: {Title}
- **type:** {feature | bugfix | hotfix | refactor | spike | chore}
- **phase:** N            <!-- omit when grouping is iterations -->
- **iteration:** YYYY-Wnn <!-- omit when grouping is phases -->
- **priority:** {low | medium | high}
- **depends_on:** {task IDs or —}
- **touches:** {files to create/modify}
- **context:** {Enough detail that an agent picking this up can start immediately. Cite arch §X, feature R# }
- **acceptance:**
  - {Type-appropriate criteria}
```

## Quality Bar

- [ ] ID is unique and monotonically increasing
- [ ] Type is appropriate for the work
- [ ] `touches` is specific (no "various files")
- [ ] No conflict on the same files with another task in the same group
      (phase/iteration) or any in-flight task (or conflict flagged and
      sequenced)
- [ ] `acceptance` is verifiable
- [ ] For bugfixes: includes a repro test that fails before and passes after
- [ ] For refactors: confirms no behavior change (existing tests still pass)
- [ ] For spikes: time-boxed with a deliverable (decision recorded somewhere)
- [ ] Feature file `Changes` section has a dated entry

## Output

- `tasks/board.md` — patched (rows added in correct group, `> Last updated:` bumped)
- `tasks/features/{feature}.md` — updated (or created if absent and the task
  warrants context)
