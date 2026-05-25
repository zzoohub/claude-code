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

Brownfield counterpart to `task-craft`. Adds tasks to a board that already
exists, picking the right group and the next available ID.

## Prerequisites

`tasks/board.md` must already exist. If it doesn't, the project is greenfield —
use `task-craft` to create the initial board.

If your project keeps tasks elsewhere, see `AGENTS.md` at the repo root.

## What This Skill Does

1. Reads `tasks/board.md` to learn the grouping (phases or iterations or
   simple Backlog/Active/Done) and the highest existing ID.
2. Reads the relevant feature spec at `docs/prd/features/{feature}.md` if
   the task is feature work.
3. Reads `docs/arch/system.md` for stack and component names, so tasks
   reference the right files.
4. Generates one or more tasks (default: one) with type appropriate for the
   work (feature, bugfix, hotfix, refactor, spike, chore).
5. Picks the right group:
   - Phase grouping: earliest phase that respects dependencies. If all
     phases are done, append `Phase N+1 — {feature}` or switch to a
     Backlog group.
   - Iteration grouping: current iteration if in scope; otherwise `Backlog`.
   - Simple Backlog/Active/Done: append to Backlog.
6. Updates or creates `tasks/features/{feature}.md` with task details. For
   one-off bugfixes / chores, skip the feature file unless the user asks for
   `--with-spec` or the change is non-trivial.
7. Appends a dated entry to the feature file's `Changes` section.

## What This Skill Does NOT Do

- Does not rewrite `tasks/board.md` from scratch
- Does not move task status (that's `task-status`)
- Does not create the initial board (that's `task-craft`)
- Does not write feature specs or ADRs (use `feature-spec` / `arch-decision`)

## Task Types

Each task type implies different `context` and `acceptance` shapes. See
`task-craft/SKILL.md` for the full guide. Quick reference:

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
     (may already be in an ADR via `arch-decision`)
   - Spike → the question to answer + time-box
3. **Pick the next ID** — highest existing `T-NNN` + 1
4. **Choose the group** — see step 5 above
5. **Write the row** — append to `tasks/board.md` in the right group
6. **Write task details** — append to `tasks/features/{feature}.md` (or
   create it if absent). For one-off non-feature work, default to skipping
   the feature file unless the work is non-trivial.
7. **Log the change** — append a dated entry to the feature file's `Changes`
   section.

## board.md row format

```
| T-NNN | {feature} | {one-line description} | {type} | {priority} | backlog | — | {touched files} |
```

The `type` column is required. If the existing board lacks the `type` column,
add it as part of this update (one-time schema upgrade).

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
  - {Type-appropriate criteria — see task-craft Task Type Guide}
```

## Quality Bar

- [ ] ID is unique and monotonically increasing
- [ ] Type is appropriate for the work
- [ ] `touches` is specific (no "various files")
- [ ] No conflict with another in-flight task on the same files (or conflict
      flagged and sequenced)
- [ ] `acceptance` is verifiable
- [ ] For bugfixes: includes a repro test that fails before and passes after
- [ ] For refactors: confirms no behavior change (existing tests still pass)
- [ ] For spikes: time-boxed with a deliverable (decision recorded somewhere)
- [ ] Feature file `Changes` section has a dated entry

## Output

- `tasks/board.md` — patched (rows added in correct group)
- `tasks/features/{feature}.md` — updated (or created if absent and the task
  warrants context)

## Cross-References

- `task-craft` — Creates the initial board; this skill extends it
- `task-status` — Moves task status (start, complete, block)
- `feature-spec` — Writes the feature spec a feature task implements
- `arch-decision` — Records the architectural decision a refactor implements
