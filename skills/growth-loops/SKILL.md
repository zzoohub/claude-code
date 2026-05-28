---
name: growth-loops
description: |
  Growth loop design — referral programs, viral loops, content loops, paid loops.
  Use when: designing a referral program, modeling viral coefficients (K factor),
  identifying acquisition loops, choosing loop type for a product, debugging a stalled loop,
  or when user mentions "viral loop", "referral program", "K factor", "growth loop",
  "viral coefficient", "amplification", "compounding growth".
  Do NOT use for: page-level conversion optimization (use cro), pricing of referrals
  (use pricing), or analytics of loop performance (use product-analytics).
---

# Growth Loops

A growth loop is a self-reinforcing system: action → output → reinvestment that drives more of the same action. Loops *compound* (network effects, viral spread, content moats); funnels *deplete* (one-time visitors). Most durable growth comes from loops, not funnels.

For loop types, K factor math, the 5-stage design framework, amplification techniques, cycle time, anti-patterns, and output format, read `references/loops.md`.

## When to invoke

| Situation | Action |
|---|---|
| "Design a referral program" | Read `references/loops.md` → Loop type selection → 5-stage design |
| "Why isn't our viral loop working?" | Read `references/loops.md` → anti-patterns + cycle time diagnosis |
| "Calculate our K factor" | `references/loops.md` § K Factor |
| "Identify acquisition loops in our product" | `references/loops.md` § Loop Types |

## Boundary

- **Not CRO**: signup form conversion goes to `cro`. Loop design is about what triggers acquisition, not how an individual page converts.
- **Not pricing**: incentive economics for referrals go through `pricing`. Loop design picks the structure (double-sided, single-sided, milestone-based); pricing decides the dollar amount.
- **Not analytics**: K factor measurement methodology is in `product-analytics`. Loop design uses K factor; analytics computes it.

## Output

When this skill produces a referral or loop design, write it to `biz/growth/referral-program.md` (default) or the path defined in `AGENTS.md`.
