---
name: task-status
description: |
  Move a task's status on the board: start (backlog → active), complete
  (active → done), block (active → blocked), unblock (blocked → backlog/active),
  abandon (any → backlog with note). Also makes light single-row field edits —
  reprioritize, reassign, move a task to another phase — and removes a row
  created in error. Edits `tasks/board.md` one row at a time; block/abandon
  (and phase moves) also touch the feature file.
  Use when: starting work on a task, marking a task complete, marking a task
  blocked, moving a task back to backlog, changing a single task's priority,
  assignee, or phase, or removing a mistaken row. Trigger phrases: "start
  T-005", "complete T-005", "block T-005 — waiting on X", "T-005 is done",
  "reprioritize T-005 to high", "reassign T-005 to Alice", "move T-005 to phase
  3", "remove T-009 — created by mistake".
  Do NOT use for: creating tasks (use task-add). Do NOT use for: revising a
  task's definition — context, acceptance, touches, deps (use task-add). Do NOT
  use for: rewriting the board (use task-craft for initial creation).
---

# Task Status — Move One Task

Brownfield skill for status and light single-field updates. Touches one row of
`tasks/board.md`, plus a note in the feature file for block/abandon and a
`phase:` sync for phase moves.

## Prerequisites

`tasks/board.md` must already exist with the task.

If your project keeps tasks elsewhere, see `AGENTS.md`.

## Status Lifecycle

```
backlog ──start──▶ active ──complete──▶ done
   ▲                 │
   │                 └──block──▶ blocked ──unblock──▶ active or backlog
   │
   └── abandon ◀── any state (active / blocked / done), → backlog with reason logged to the feature file
```

| From | To | Action | Side effect |
|---|---|---|---|
| `backlog` | `active` | `start T-NNN [--assignee=X]` | Optionally set assignee |
| `active` | `done` | `complete T-NNN` | None (assignee kept as the record of who did it) |
| `active` | `blocked` | `block T-NNN — {reason}` | Append note to feature file |
| `blocked` | `active` or `backlog` | `unblock T-NNN [--to=active]` | Default returns to backlog; clear `assignee` to `—` when landing in backlog |
| any | `backlog` | `abandon T-NNN — {reason}` | Append reason to feature file Changes; clear `assignee` to `—` |

> `start` / `complete` / `block` / … are shorthand for the transition, not
> shell commands — invoke this skill in natural language ("mark T-005 blocked,
> waiting on the API key").

### Field edits (no status change)

Same one-row discipline, for single-field corrections:

| Field | Action | Notes |
|---|---|---|
| `priority` | `reprioritize T-NNN --to={high\|medium\|low}` | Lowercase only. |
| `assignee` | `reassign T-NNN --to={user\|—}` | Doesn't change status. |
| phase | `move T-NNN --to-phase=N` | Relocate the row to the `## Phase N` section **and** update `phase:` in the feature file so the two stay in sync. Verify the new phase doesn't break dependency ordering or create a same-file conflict. |

### Removing a task

Prefer **abandon** (status → backlog with a logged reason) for any task that was
ever real — it keeps the audit trail. **Hard-remove** — delete the board row and
its `### T-NNN` detail block — only for a row created in error (a duplicate or a
typo-task). On hard-remove, append a dated `Changes` note recording the deletion
and why (to `tasks/features/_misc.md` if the task had no feature file). IDs are
never reused, even after a hard-remove.

## What This Skill Does

1. Reads `tasks/board.md`, finds the task row by its leading `| T-NNN |` cell.
2. Edits the `status` cell — and the `assignee` cell when starting with an
   assignee, or clearing it to `—` on unblock-to-backlog / abandon. Handles
   light field edits (priority, assignee, phase) the same way.
3. For `block` or `abandon`: appends a dated note to the `Changes` section of
   `tasks/features/{feature}.md` — or to `tasks/features/_misc.md` if the task
   has no feature file (one-off work that skipped it).
4. Bumps the board's `> Last updated:` header to today's date.

## What This Skill Does NOT Do

- Does not rewrite the board or re-order unrelated rows
- Does not edit a task's definition in the feature file — only board fields, the
  `phase:` mirror, `Changes` notes, and (on hard-remove) deletion of the row's
  detail block. To change context/acceptance/touches, use `task-add` (revise).
- Does not create tasks
- Does not validate completion

## Workflow

1. **Find the task** — Grep the row by its leading cell `| T-NNN |` in
   `tasks/board.md` (anchoring on the cell avoids matching the ID where it
   appears inside another row's text). If not found, ask the user (it might
   be a new task).
2. **Read its current status, feature, and phase** — needed for transition
   validation and (for block/abandon) finding the feature file.
3. **Validate the transition** — see lifecycle table above. Reject invalid
   transitions (e.g., `done` → `active` without explicit user override).
4. **Edit the row in `tasks/board.md`** — change only the target cell(s):
   `status`, and `assignee` (set on start, cleared to `—` on
   unblock-to-backlog / abandon). For a phase move, relocate the row to the
   new `## Phase N` section and update `phase:` in the feature file.
5. **For block/abandon**: append a dated entry (use today's actual date, not
   the literal `YYYY-MM-DD`) to the `Changes` section of
   `tasks/features/{feature}.md` — or `tasks/features/_misc.md` if the task
   has no feature file:
   ```
   - <today, YYYY-MM-DD>: T-NNN blocked — {reason}
   ```
   or
   ```
   - <today, YYYY-MM-DD>: T-NNN abandoned — {reason}
   ```
6. **Bump** the board's `> Last updated:` header to today's date.
7. **Confirm** — report the transition in one line.

## Quality Bar

- [ ] Task ID exists on the board (matched on the `| T-NNN |` cell)
- [ ] Transition is valid per the lifecycle table
- [ ] Only the relevant row in `tasks/board.md` was edited
- [ ] On unblock-to-backlog / abandon: `assignee` reset to `—`
- [ ] On a phase move: board section and feature-file `phase:` both updated
- [ ] For block/abandon: feature file (or `_misc.md`) `Changes` has a dated
      entry with reason
- [ ] For hard-remove: row and `### T-NNN` detail block both deleted, deletion
      logged to `Changes`, and the ID is never reused
- [ ] `> Last updated:` header bumped
- [ ] For complete: the work is actually verified (caller's responsibility —
      this skill trusts the caller)

## Output

- `tasks/board.md` — one row patched (status/field), `> Last updated:` bumped
- `tasks/features/{feature}.md` (or `tasks/features/_misc.md`) — Changes
  appended (block/abandon) and `phase:` synced (phase move)
