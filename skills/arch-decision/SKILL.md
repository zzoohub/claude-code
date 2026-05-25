---
name: arch-decision
description: |
  Record a single Architecture Decision Record (ADR) for an existing system.
  Appends one ADR to `docs/arch/decisions.md` (or creates one file under
  `docs/arch/decisions/ADR-NNN-{slug}.md` if the project uses that layout).
  Patches `docs/arch/system.md` only when the decision changes the architecture
  surface (new component, swapped pattern).
  Use when: you need to record one architectural choice on an existing system —
  swapping a pattern, adding a component, choosing a library, migrating a piece
  of infrastructure. Trigger phrases: "record an ADR", "we decided to X",
  "make an architecture decision about X", "let's switch from X to Y".
  Do NOT use for: a new system from scratch (use software-architecture — it
  produces the full design doc plus initial ADRs). Do NOT use for: schema
  decisions (use database-design). Do NOT use for: pure code refactors that
  don't shift architecture (just open a task).
---

# Arch Decision — Single ADR

Brownfield counterpart to `software-architecture`. Record one decision, tied
to the existing system's ASRs, without rewriting `context.md` or `system.md`.

## Prerequisites

`docs/arch/context.md` and `docs/arch/system.md` should exist. If they don't,
the project is greenfield — use `software-architecture` instead. (You can
still record an ADR against a missing context, but flag the gap.)

If your project keeps architecture docs elsewhere, see `AGENTS.md`.

## What This Skill Does

1. Reads existing `docs/arch/context.md` (problem, ASRs, domain) and
   `docs/arch/system.md` (current patterns, components) for context.
2. Frames the decision — one decision per ADR. If 3+ unrelated decisions
   surface, split into 3 ADRs.
3. Captures 2-4 realistic options including "do nothing / keep current."
4. States the choice with reasoning tied to an ASR or constraint from
   `context.md` §3.
5. Records consequences — enables, costs, risks, affected components.
6. Appends the ADR. Default location: `docs/arch/decisions.md` (append at top —
   newest first). Alternative location: `docs/arch/decisions/ADR-NNN-{slug}.md`
   if the project uses split files (check existing layout).
7. Patches the affected section of `system.md` ONLY if the decision changes
   the surface (new component, new pattern). Otherwise leaves `system.md` alone.

## What This Skill Does NOT Do

- Does not rewrite `context.md` (the problem and ASRs don't change)
- Does not rewrite `system.md` from scratch
- Does not produce diagrams unless the decision adds a new container
- Does not produce database schema changes (use `database-design`)

## ADR Template

```markdown
## ADR-{NNN}: {Title}

**Date:** YYYY-MM-DD
**Status:** Accepted | Proposed | Superseded by ADR-NNN

### Context

What is the issue motivating this decision? Cite the ASRs from
`docs/arch/context.md` §3 that drive it. Cite the feature spec at
`docs/prd/features/{feature}.md` if the decision is feature-driven.

### Options Considered

1. **{Option A}** — pros / cons.
2. **{Option B}** — pros / cons.
3. **Do nothing / keep current** — pros / cons (always include this option).

### Decision

We chose Option {X} because {reason tied to ASR or constraint}.

### Consequences

- **Enables:** ...
- **Costs:** ...
- **Risks / mitigations:** ...
- **Affected components:** {list from system.md §2, or "none"}
```

## Workflow

1. **Read context** — `docs/arch/context.md` and `docs/arch/system.md`. If
   either is missing, flag it: "Architecture context is incomplete. Want me to
   do a full design pass with `software-architecture` instead?"
2. **Get the next ADR number** — Find the highest existing ADR-NNN in
   `decisions.md` or under `decisions/` and add 1.
3. **Frame one decision** — If multiple decisions surface, ask the user which
   to record first; defer the others to follow-up ADRs.
4. **Draft 2-4 options** — Include "keep current" as one option.
5. **Tie the choice to an ASR** — If you can't, the decision probably isn't
   ready, or the ASR list is incomplete (raise that).
6. **Write the ADR** — Append to `decisions.md` (newest first) or create a new
   `decisions/ADR-NNN-{slug}.md` file.
7. **Patch system.md if needed** — Only when surface changes (new component,
   new pattern, etc.).

## Quality Bar

- [ ] One decision, clearly named
- [ ] 2-4 realistic options considered, including "keep current"
- [ ] Decision tied to a specific ASR or constraint from `context.md`
- [ ] Consequences spelled out (enables / costs / risks / affected components)
- [ ] ADR number is unique and monotonically increasing
- [ ] If the decision changes architecture surface, `system.md` is patched in
      the affected section
- [ ] Status is `Accepted` (or `Proposed` if pending review)

## Output

- `docs/arch/decisions.md` — appended (newest first)
- `docs/arch/system.md` — patched if architecture surface changed

**Line limit:** `decisions.md` — 400 lines. When exceeded, summarize superseded
ADRs to one line and mark them `[superseded by ADR-NNN]` rather than deleting.

## Cross-References

- `software-architecture` — Creates the initial design; this skill extends it
- `database-design` — Schema-level decisions go through that skill instead
- `task-add` — Generates implementation tasks for the decided change
