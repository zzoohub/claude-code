# AGENTS.md

The map for this agent + skill library. Read this first. It tells you **which agent to call
for a given intent**, **how the agents chain end to end**, **where each agent reads and writes
files**, and **what external tools the system depends on**.

This file is also the override point: agents read `AGENTS.md` at boot, so anything you change in
the **Path configuration** or **Project conventions** sections below overrides their defaults
for this repo.

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
- **Files are the handoff contract.** product-manager writes `docs/prd/`, architect reads it and
  writes `docs/arch/`, and so on. The **Path configuration** table is the shared filesystem
  contract that lets a later agent pick up where an earlier one left off.

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
not owned by an agent.

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

Run these as ordered sequences. Each arrow is a handoff: the next agent reads the file the prior
one wrote (see **Path configuration**). Check each output before continuing.

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

## Path configuration

Default file locations. Override here to change them for this repo — agents read this section.

This is the single override point for paths — every file an agent reads or writes
has a row here. A trailing `/` denotes a directory family authored by one agent.

| Artifact | Path | Written by | Read by |
|---|---|---|---|
| Product brief | `docs/prd/product-brief.md` | product-manager | architect, ux-designer, biz agents |
| PRD | `docs/prd/prd.md` | product-manager | architect, ux-designer, task-manager, biz agents |
| Feature spec | `docs/prd/features/{feature}.md` | product-manager | architect, task-manager, developers |
| Arch context (greenfield sentinel) | `docs/arch/context.md` | architect (software-architecture) | architect (brownfield detection), developers |
| Architecture | `docs/arch/system.md` | architect (software-architecture) | developers, release-engineer, reviewer |
| Architecture decisions | `docs/arch/decisions.md` (or `docs/arch/decisions/ADR-NNN-*.md`) | architect (arch-decision) | developers |
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
