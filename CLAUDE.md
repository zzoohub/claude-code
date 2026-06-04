# CLAUDE.md — human reference map (not auto-loaded)

**What this file is:** a human-readable reference map of this agent + skill library — a
maintainer's guide to **which agent to call for a given intent**, **how the agents chain end to
end**, **where each agent reads and writes files by convention**, and **what external tools the
system depends on**.

> The plan agents are the domain owners of their doc trees: `product-manager` owns `docs/prd/`,
> `architect` owns `docs/arch/`, `ux-designer` owns `docs/ux/`, `task-manager` owns `tasks/`.

---

## How the system works

- **Two kinds of agents.** *Routers* (the plan layer) own no skills themselves — they read your
  intent and invoke the right skill. *Doers* (dev + biz) do the work, calling skills as needed.
- **Agents never call other agents.** Each agent invokes *skills* only. Sequencing across agents
  is orchestrated by the main conversation (you, or the top-level assistant). The **workflow
  chains** below are the intended sequences — run them step by step, checking each output before
  the next agent consumes it.
- **Skills load on demand.** An agent pulls a skill into context only when the task needs it.
  Skills hold the method, the format, and the quality bar; agents hold the routing and judgment.
- **Files are the handoff medium.** product-manager writes `docs/prd/`, architect reads it and
  writes `docs/arch/`, and so on. The **Default doc locations** table records the conventional
  layout these agents follow, so a later agent can find where an earlier one left off. It is a
  reference of where things live by default, not a contract this file enforces.

---

## Design philosophy & conventions

The split below is the load-bearing idea; the rest follows from it.

**Orchestrator ⊥ capability.** A **skill** is a portable, framework-agnostic
*capability* (the method, format, and quality bar). An **agent** is a
Claude-Code-only *orchestrator* (routing, judgment, file I/O, sequencing). This is
separation of mechanism (skill) from policy (agent) — ports & adapters: the skill is
the dependency-free core, each runtime is an adapter. **The portable unit is the
skill, not the agent.** A `SKILL.md` runs on any Agent-Skills-compatible runtime
(Claude Code, Hermes, OpenClaw, Codex, …); a `.claude/agents/*.md` runs only in
Claude Code, by design.

### Skill conventions (keep skills portable)

- **Framework-agnostic.** No `$ARGUMENTS`, no harness-only tools, no `AskUserQuestion`
  as a requirement. Only `name` + `description` are load-bearing frontmatter; the body
  is plain instructions any runtime reads.
- **Paths are defaults, not contracts.** Write "the X (default `docs/…`; caller may
  redirect)" — never a hardcoded destination. The default preserves current behavior;
  the caller (an agent) may override.
- **Prerequisites degrade gracefully.** "If absent, ask the caller" — never a
  framework-specific hard-stop.
- **No `## Contract` / Inputs-Outputs / YAML block.** Decouple by editing existing
  lines in place ("Lean-inline"). A blind A/B (6-0) showed a dedicated section adds
  body surface that competes for the model's attention and *lowers craft-output
  quality* — quality, not token cost, is the reason.
- **Body cross-references are soft** ("via the X capability, if available"). The
  `description` block's "use the Y skill" routing text is harmless metadata other
  runtimes ignore — leave it.
- **Host-coupled skills declare it** via the standard `compatibility:` frontmatter
  (e.g. `browse`/`qa` ship a binary; resolve it via `${BROWSE_BIN}`, not a fixed path).

### Agent conventions (own the orchestration the skills don't)

- **Agents never call other agents.** Cross-agent sequencing is the main session's
  job; sequencing an agent's *own* skills in dependency order is fine.
- **The agent owns the three things a decoupled skill hands back:**
  1. **Input provisioning.** Read `CLAUDE.md` first (it may redirect roots), resolve
     and pass the doc paths the skill needs, so the skill's "ask the caller" never
     dead-ends in a subagent that cannot prompt. A genuinely missing input becomes a
     *text question in the return summary*, never an interactive prompt. Each plan
     agent lists these in a **Required Inputs** section.
  2. **Output paths.** The agent owns where artifacts land (the skill's path is a
     caller-overridable default). See the Default doc locations table.
  3. **Sequencing / build.** The agent drives the skill to produce + place the
     artifact and reports back. Chains removed from skill bodies (e.g.
     `software-architecture` → `arch-decision` per decision) live in the owning agent.
- **Task lifecycle has one owner per transition.** `task-manager` writes the **left
  edge** (`backlog`→`active` + assignee, on dispatch) and the **close**
  (`active`→`done`) — the close only after the main session confirms reviewer *and*
  verifier passed. Builder agents never self-certify `done` (they leave the task
  `active`, or mark `blocked` if they couldn't finish); the verifier *proves* behavior
  but writes no status. The main session sequences the chain and triggers the close.
- **Model policy is intentionally uniform `opus`** (reviewer/verifier = `sonnet`).
  Not a cost oversight — leave it.

### Why this lives here

`AGENTS.md` is a non-auto-loaded human reference map. Conventions belong here (and
runtime overrides in the consuming project's `CLAUDE.md`) — never baked into a skill,
which must stay portable. Several conventions above were chosen by blind A/B
experiment, not assertion.

---

## Intent → agent decision table

Find the row that matches what you want, call that agent.

| You want to… | Agent | Layer |
|---|---|---|
| Validate a new product idea / write a one-pager (the *why*) | `product-manager` | plan |
| Write a full PRD, or spec a single feature on an existing PRD | `product-manager` | plan |
| Design the system architecture, an ADR, a DB schema, or an LLM/AI app | `architect` | plan |
| Design app-wide UX/IA, a single screen, or audit existing UX | `ux-designer` | plan |
| Generate the task board, add/revise a task, move task status, audit the board | `task-manager` | plan |
| Build/modify backend: APIs, domain logic, DB queries, workers (`apps/api`, `apps/worker`, `db/`) | `backend-developer` | dev |
| Build/modify web frontend: pages, components, state, styling (`apps/web`) | `frontend-developer` | dev |
| Build/modify a mobile app: Expo / React Native screens (`apps/mobile`) | `mobile-developer` | dev |
| Build/modify a desktop app: Tauri core + web UI (`apps/desktop`) | `desktop-developer` | dev |
| Pre-landing code review: security + correctness + maintainability | `reviewer` | dev |
| Verify behavior in a real browser / smoke-test endpoints before merge | `verifier` | dev |
| **Ship to production: deploy, env/secrets, migrations, CI/CD, rollback** | **`release-engineer`** | dev |
| Marketing strategy, launch, positioning, competitor angle, pricing strategy, ad creative | `marketer` | biz |
| Ongoing content: social, email sequences, blog/SEO, changelog, build-in-public | `content-marketer` | biz |
| Conversion (CRO), referral/viral loops, churn/retention, paywall/upgrade | `growth-optimizer` | biz |
| Analytics: tracking plan, funnels, retention/PMF, weekly reports, A/B analysis | `data-analyst` | biz |

For a plan review *before* writing code, the main agent can invoke the `plan-ceo-review`
(scope/vision) or `plan-eng-review` (locked-scope execution rigor) skills directly — these are
not owned by an agent. The review skill **proposes** task rows but does not place them: after the
review, the main session renders the structured issue list interactively (it is the runtime that
supplies the question UI) and carries any approved tasks to `task-manager`, which appends them via
`task-add`.

---

## Agent roster

**Plan layer (routers — no skills of their own):**
- `product-manager` → product-brief · prd-craft · feature-spec
- `architect` → software-architecture · arch-decision · database-design · llm-app-design
- `ux-designer` → ux-design (incl. 3D/XR UX) · screen-design · cro (when conversion-driven)
- `task-manager` → task-craft · task-add · task-status

**Dev layer (doers):**
- `backend-developer` → postgresql + one of axum / fastapi / hono / nestjs-hexagonal (by stack) · database-design · correctness-checklists
- `frontend-developer` → frontend-design + tanstack-start / vercel-composition-patterns / vercel-react-best-practices (by stack) · design-system · motion · i18n · web3d
- `mobile-developer` → vercel-react-native-skills · expo-app-design (Expo/Vercel-managed) · design-system · motion · i18n
- `desktop-developer` → same web UI skill as frontend + Tauri-specific work
- `reviewer` → security-checklists · correctness-checklists · maintainability-checklists
- `verifier` → qa (browse) + playwright (preferred) / claude-in-chrome fallbacks
- `release-engineer` → vercel:deploy · vercel:env · vercel:deployments-cicd · vercel:status · cloudflare:wrangler · cloudflare:workers-best-practices · Supabase MCP (by target)

**Biz layer (doers):**
- `marketer` → copywriting · competitor-pages · pricing · ad-creative · marketing-psychology
- `content-marketer` → copywriting · social-content · email-marketing · search-visibility
- `growth-optimizer` → cro · growth-loops · churn-prevention · pricing · marketing-psychology · copywriting
- `data-analyst` → product-analytics + PostHog MCP

---

## Workflow chains

Suggested sequences for the human or main session to run step by step. Each arrow is a handoff:
the next agent reads the file the prior one wrote (see **Default doc locations**). Check each
output before continuing.

### 1. Full product launch (idea → production)
```
product-manager   → docs/prd/prd.md (+ feature specs)
architect         → docs/arch/system.md (+ ADRs, schema)
ux-designer       → docs/ux/ux-design.md (+ screen specs)
task-manager      → tasks/board.md (+ feature task files)
backend-developer ┐
frontend-developer├ implement tasks (mobile/desktop as the product needs)
                  ┘
reviewer          → security + correctness + maintainability (blocking gate)
verifier          → real-browser / API verification (behavior gate)
release-engineer   → ship to production + post-deploy health check
```

**Who writes task status, and when.** No builder self-certifies its own task `done`.
The main session owns the status edges and drives them through `task-manager` (agents
never call each other):
- *Before* a builder runs, the main session has `task-manager` move the task
  `backlog` → `active` and set the assignee (`task-manager` owns this left edge; the
  board ships assignees as `—`).
- A builder leaves its task `active` and returns a verdict; it only ever moves the task
  to `blocked` itself, when it couldn't finish.
- The main session marks the task `done` (via `task-manager`) **only after both reviewer
  and verifier pass** — `verifier` proves behavior but writes no status by design.

This keeps the closer unambiguous and matches `task-status`'s rule that completion is
verified before `done` is written.
Optionally insert a plan review (`plan-ceo-review` for scope, `plan-eng-review` for rigor)
between architect and task-manager.

### 2. Feature on an existing product
```
product-manager (feature-spec) → architect (arch-decision, if it shifts architecture)
→ ux-designer (screen-design) → task-manager (task-add)
→ developer(s) → reviewer → verifier → release-engineer
```

### 3. Growth optimization cycle
```
data-analyst (find the drop-off / Aha / retention gap)
→ growth-optimizer (design the CRO / loop / churn fix)
→ ux-designer (screen-design) + frontend-developer (implement)
→ reviewer → verifier → release-engineer
→ data-analyst (measure the result)
```

### 4. Go-to-market / launch
```
marketer (positioning, launch strategy, pricing)
→ content-marketer (social, email, blog, launch content)
→ data-analyst (instrument + track launch)
```

### 5. Architecture / UX review (no new build)
```
architect (software-architecture in review mode)  — or —  ux-designer (ux-design in review mode)
→ reviewer (if code is implicated)
```

**Connecting build ↔ GTM ↔ product:** when `data-analyst` or `growth-optimizer` surface a
product-level insight (new persona, requested feature, retention driver), route it back through
`product-manager` (feature-spec) → `architect` → dev, closing the loop instead of patching
marketing around a product gap.

---

## Default doc locations

The conventional file locations the agents follow by default — a reference map of where each
artifact lives, not a runtime override point. Agents do **not** read this table at boot; to
change paths for a real project, set the conventions in that project's `CLAUDE.md`. Every file
an agent reads or writes has a row here. A trailing `/` denotes a directory family authored by
one agent.

| Artifact | Path | Written by | Read by |
|---|---|---|---|
| Product brief | `docs/prd/product-brief.md` | product-manager | architect, ux-designer, biz agents |
| PRD | `docs/prd/prd.md` | product-manager | architect, ux-designer, task-manager, biz agents |
| Feature spec | `docs/prd/features/{feature}.md` | product-manager | architect, task-manager, developers |
| Arch context (greenfield sentinel) | `docs/arch/context.md` | architect (software-architecture) | architect (brownfield detection), developers |
| Architecture | `docs/arch/system.md` | architect (software-architecture) | developers, release-engineer, reviewer |
| Architecture decisions (ADRs) | `docs/arch/adr/ADR-NNN-{slug}.md` | architect (software-architecture, arch-decision) | developers |
| Risks & open questions | `docs/arch/risks.md` | architect (software-architecture) | developers, reviewer |
| Database design | `docs/arch/database.md` | architect (database-design) | backend-developer, reviewer, task-manager |
| App UX | `docs/ux/ux-design.md` | ux-designer | frontend/mobile/desktop developers |
| Screen specs | `docs/ux/screens/{screen}.md` | ux-designer | frontend/mobile/desktop developers |
| Task board | `tasks/board.md` | task-manager | developers, release-engineer |
| Task details | `tasks/features/{feature}.md` | task-manager | developers |
| Project checklist (optional) | `checklist.md` (repo root or `docs/`) | *(project-defined)* | reviewer |
| Deploy runbook | `docs/ops/runbook.md` | release-engineer | release-engineer (next release) |
| Marketing strategy | `biz/marketing/strategy.md` | marketer | content-marketer, growth-optimizer, data-analyst |
| Launch materials | `biz/marketing/launch/` | marketer | content-marketer |
| Pricing (public tiers) | `biz/marketing/pricing.md` | marketer | growth-optimizer |
| Competitor analysis | `biz/marketing/competitors.md` | marketer | content-marketer |
| Marketing assets | `biz/marketing/assets/` | marketer, content-marketer | — |
| Content strategy | `biz/marketing/content/strategy.md` | content-marketer | — |
| Content (social/email/blog/changelog) | `biz/marketing/content/{social,email,blog,changelog}/` | content-marketer | — |
| Tracking plan + Aha moment | `biz/analytics/tracking-plan.md` | data-analyst | marketer, content-marketer, growth-optimizer |
| Funnels + retention | `biz/analytics/funnels.md` | data-analyst | ux-designer, growth-optimizer |
| Dashboards | `biz/analytics/dashboards.md` | data-analyst | — |
| Kill/Keep/Scale + CC | `biz/analytics/kill-criteria.md` | data-analyst | marketer |
| Customer health score | `biz/analytics/health-score.md` | data-analyst | growth-optimizer |
| Analytics reports | `biz/analytics/reports/` | data-analyst | all biz agents |
| Growth experiments log | `biz/growth/experiments.md` | growth-optimizer | data-analyst, content-marketer |
| Referral / viral loop | `biz/growth/referral-program.md` | growth-optimizer | — |
| Churn prevention strategy | `biz/growth/churn-prevention.md` | growth-optimizer | — |
| Dunning / payment recovery | `biz/growth/dunning.md` | growth-optimizer | — |
| Paywall / upgrade pricing | `biz/growth/paywall-pricing.md` | growth-optimizer | — |
| CRO analyses | `biz/growth/cro/{page-or-flow}-analysis.md` | growth-optimizer | — |
| Customer feedback log | `biz/ops/feedback-log.md` | *(currently unowned — see Known gaps)* | all biz agents |

**Source layout (monorepo convention):** `apps/web` · `apps/api` · `apps/worker` ·
`apps/mobile` · `apps/desktop` · `db/`. Each developer agent owns its `apps/*` directory.

---

## External dependencies (MCP servers & plugins)

These power specific agents. If one is unavailable, the agent falls back as noted.

| Dependency | Used by | Purpose | Fallback if missing |
|---|---|---|---|
| `frontend-design` plugin | frontend-developer, desktop-developer | Production-grade UI design | `design-system` + general best practice |
| `vercel-*` skills (Vercel-managed) | frontend/mobile/desktop developers | React / Next / TanStack / RN patterns. Vercel-managed upstream, always installed — fall back briefly only if absent | `design-system` + general best practice |
| `expo-app-design` plugin (Expo-managed) | mobile-developer | Native Expo/RN UI patterns. Expo-managed upstream, always installed — fall back briefly only if absent | `vercel-react-native-skills` + `design-system` |
| Vercel MCP | release-engineer | Auth session for `vercel:*` skills + CLI (MCP exposes auth only; deploy/env/state run through the skills) | `vercel` CLI via Bash |
| Cloudflare MCPs (bindings/builds/observability) | release-engineer | Workers/Pages deploy, build logs, runtime logs | `wrangler` CLI via Bash |
| Supabase MCP | release-engineer | Migrations, edge functions, advisors, logs | `supabase` CLI via Bash |
| PostHog MCP | data-analyst | Live funnels, insights, cohorts, experiments | methodology only (no live data) |
| `@hypothesi/tauri-mcp-server` | desktop-developer | Tauri dev/inspection | `design-system` + general Tauri practice |
| claude-in-chrome / playwright MCP | verifier | Real-browser verification, E2E | the other of the two |

---

## Solo founder critical path

You don't need every agent on day one. The minimum spine from idea to live product:

```
product-manager → architect → ux-designer → task-manager
→ (one) developer → reviewer → verifier → release-engineer
```

Defer until you actually need them: `mobile-developer` / `desktop-developer` (web-only start),
the full biz layer until you have something to launch, `plan-*-review` skills until scope feels
risky. Add the GTM chain (#4) once the product is verifiable, then the growth cycle (#3) once
you have users and tracking.

---

## Known gaps (not yet covered)

Be honest about what this library does **not** do yet, so you don't assume an owner exists:

- **Run-the-business operations** — finance (runway, P&L, unit economics, tax), legal/compliance
  (ToS, privacy policy, GDPR/CCPA, entity), and founder operations (weekly cadence, OKRs,
  prioritization, decision log) have **no agent or skill**. Handle these outside the system.
- **Customer support / success** — ticket triage, help-center/FAQ ownership, NPS/CSAT, and the
  customer-feedback loop are unowned. `biz/ops/feedback-log.md` is read by biz agents but nothing
  creates or curates it.
- **Launch execution & GTM gate** — `marketer` owns launch *strategy*, but there is no day-of
  launch playbook or pre-launch go/no-go readiness checklist.
- **Native release depth** — mobile (Expo EAS, deep links, push) and desktop (Tauri signing,
  notarization, auto-update) lean on the developer agents + `release-engineer` without a dedicated
  in-house skill; expect more hands-on steps.
- **Security/compliance ops** — code-level security is covered (`reviewer` + `security-checklists`),
  but SOC2/ISO, secrets-rotation policy, and vendor risk are not.
- **Validation/PMF method** — `product-brief` captures the problem; it does not prescribe how to
  validate it (interviews, landing-page smoke tests, Sean Ellis survey).
- **Orphan reference** — `skills/web-design-guidelines` is not routed by any agent;
  `design-system` is the primary UI guidance for frontend/desktop developers. Either
  deprecate `web-design-guidelines` or give it an explicit role if you keep it.
