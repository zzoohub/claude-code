# claude-code skills & agents

Skills and agents for Claude Code (and any [AGENTS.md](https://agents.md)–compatible
tool — Cursor, Cline, Codex, Gemini CLI, Goose, OpenHands, etc.).

## Layout

```
skills/         # Atomic skills, one purpose each
agents/         # Orchestrator agents that route user intent to skills
conventions/    # Reference doc for default file paths
AGENTS.md       # Override defaults per-project (see template inside)
```

## Architecture

This repo follows the [Agent Skills](https://agentskills.io) open standard
with two extensions:

1. **Skills are single-purpose.** Greenfield work uses one skill; brownfield
   work uses another. No multi-mode bodies. Examples:
   - `prd-craft` (full new PRD) vs `feature-spec` (one feature on existing PRD)
   - `software-architecture` (full design doc) vs `arch-decision` (one ADR)
   - `ux-design` (full app UX) vs `screen-design` (one screen)
   - `task-craft` (initial board) vs `task-add` (one task) vs `task-status` (status move)

2. **Agents are thin routers.** Each planning agent (product-manager,
   architect, ux-designer, task-manager) is a description-based routing table
   that maps user intent to the right skill. No workflow logic in the agent;
   no skill-internal dispatch.

### Why this shape

Industry research (Anthropic Skills, Cursor rules, Cline, CrewAI, DSPy,
LangGraph) shows the dominant pattern is **one skill = one purpose**, with
**description-based routing** at the host LLM. Multi-mode skill bodies and
explicit workflow files don't appear in production systems. See
`docs/research.md` for the survey (not yet written; planned).

## Path conventions

Skills hardcode default paths in their bodies (e.g. "writes to `docs/prd/prd.md`").
Projects override via `AGENTS.md` at the project root. The full reference
lives in `conventions/README.md`.

## Skill list (planning pipeline)

### Greenfield (new product)

| Skill | Produces |
|---|---|
| `product-brief` | `docs/prd/product-brief.md` |
| `prd-craft` | `docs/prd/prd.md` + `docs/prd/features/*.md` |
| `software-architecture` | `docs/arch/context.md`, `system.md`, `decisions.md` |
| `database-design` | `docs/arch/database.md` + `db/migrations/` |
| `ux-design` | `docs/ux/ux-design.md` + `docs/ux/screens/*.md` |
| `task-craft` | `tasks/board.md` + `tasks/features/*.md` |

### Brownfield (existing product)

| Skill | Produces |
|---|---|
| `feature-spec` | One `docs/prd/features/{feature}.md`; patches `prd.md` overview + dev order |
| `arch-decision` | One ADR appended to `decisions.md`; patches `system.md` only if surface changes |
| `screen-design` | One `docs/ux/screens/{screen}.md`; patches `ux-design.md` only if IA changes |
| `task-add` | New rows on `tasks/board.md`; new/updated `tasks/features/{feature}.md` |
| `task-status` | One row patched on `tasks/board.md` |

### Planning agents (thin routers)

| Agent | Routes between |
|---|---|
| `product-manager` | product-brief, prd-craft, feature-spec |
| `architect` | software-architecture, arch-decision, database-design, llm-app-design |
| `ux-designer` | ux-design, screen-design |
| `task-manager` | task-craft, task-add, task-status |

## Implementation skills & agents

Implementation skills (`axum-hexagonal`, `fastapi-hexagonal`, `hono-hexagonal`,
`nestjs-hexagonal`, `postgresql`, `design-system`, `motion`, `i18n`,
`tanstack-start`, `web3d`) are self-contained — they produce code, not docs.
They don't reference path conventions.

Developer agents (`backend-developer`, `frontend-developer`, `mobile-developer`,
`desktop-developer`) read `docs/arch/system.md` to pick the right framework
skill, then implement. They handle missing docs gracefully (ask the user or
infer from existing code).

Review agents (`reviewer`, `verifier`) are self-contained.

## Marketing / analytics skills & agents

Marketing skills (`copywriting`, `social-content`, `email-marketing`,
`ad-creative`, `search-visibility`, `competitor-pages`, `marketing-psychology`,
`pricing`, `cro`, `churn-prevention`, `product-analytics`) are pure knowledge
modules — they don't write to specific paths.

Biz agents (`marketer`, `content-marketer`, `data-analyst`, `growth-optimizer`)
read product context if it exists and write outputs under `biz/marketing/`,
`biz/analytics/`, `biz/growth/`, etc. See `conventions/README.md` for the
full layout.

## Getting started

1. Install in your project (clone or symlink into `.claude/skills/` and
   `.claude/agents/`).
2. Read `AGENTS.md` (the template) and create one at your project root if you
   want non-default paths.
3. Invoke a skill via `/skill-name` or let the host LLM pick based on
   description.
