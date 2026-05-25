---
name: task-status
description: |
  Move a task's status on the board: start (backlog → active), complete
  (active → done), block (active → blocked), unblock (blocked → backlog/active),
  abandon (any → backlog with note). Edits only `tasks/board.md` — one row at
  a time. For block/abandon also appends a note to the feature file's Changes
  section.
  Use when: starting work on a task, marking a task complete, marking a task
  blocked, or moving a task back to backlog. Trigger phrases: "start T-005",
  "complete T-005", "block T-005 — waiting on X", "T-005 is done".
  Do NOT use for: creating tasks (use task-add). Do NOT use for: rewriting the
  board (use task-craft for initial creation).
---

# Task Status — Move One Task

Brownfield skill for status updates. Touches only `tasks/board.md` (one row)
plus an optional note in the feature file for block/abandon.

## Prerequisites

`tasks/board.md` must already exist with the task.

If your project keeps tasks elsewhere, see `AGENTS.md`.

## Status Lifecycle

```
backlog ──start──▶ active ──complete──▶ done
   ▲                  │
   │                  ├──block────▶ blocked ──unblock──▶ backlog or active
   │                  │
   └─abandon──────────┘  (with reason in feature file Changes)
```

| From | To | Action | Side effect |
|---|---|---|---|
| `backlog` | `active` | `start T-NNN [--assignee=X]` | Optionally set assignee |
| `active` | `done` | `complete T-NNN` | None |
| `active` | `blocked` | `block T-NNN — {reason}` | Append note to feature file |
| `blocked` | `active` or `backlog` | `unblock T-NNN [--to=active]` | Default returns to backlog |
| any | `backlog` | `abandon T-NNN — {reason}` | Append reason to feature file Changes |

## What This Skill Does

1. Reads `tasks/board.md`, finds the task row by ID.
2. Edits the `status` cell (and `assignee` cell when starting with an assignee).
3. For `block` or `abandon`: also reads `tasks/features/{feature}.md` for that
   task's feature and appends a dated note to the `Changes` section.

## What This Skill Does NOT Do

- Does not rewrite the board
- Does not create or modify task details (use `task-add`)
- Does not validate completion (use the verifier agent for that)

## Workflow

1. **Find the task** — Grep `T-NNN` in `tasks/board.md`. If not found, ask
   the user (it might be a new task — use `task-add` instead).
2. **Read its current status and feature column** — needed for transition
   validation and (for block/abandon) finding the feature file.
3. **Validate the transition** — see lifecycle table above. Reject invalid
   transitions (e.g., `done` → `active` without explicit user override).
4. **Edit the row in `tasks/board.md`** — change only the `status` (and
   `assignee` if provided).
5. **For block/abandon**: append to `tasks/features/{feature}.md` Changes:
   ```
   - YYYY-MM-DD: T-NNN blocked — {reason}
   ```
   or
   ```
   - YYYY-MM-DD: T-NNN abandoned — {reason}
   ```
6. **Confirm** — report the transition in one line.

## Quality Bar

- [ ] Task ID exists on the board
- [ ] Transition is valid per the lifecycle table
- [ ] Only the relevant row in `tasks/board.md` was edited
- [ ] For block/abandon: feature file `Changes` has a dated entry with reason
- [ ] For complete: the work is actually verified (caller's responsibility —
      this skill trusts the caller)

## Output

- `tasks/board.md` — one row patched
- `tasks/features/{feature}.md` — Changes section appended (block/abandon only)

## Cross-References

- `task-craft` — Creates the initial board
- `task-add` — Appends new tasks to the board
- `verifier` (agent) — Validates that work matches acceptance before complete
