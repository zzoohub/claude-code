---
name: z-ux-design
description: |
  Senior-level UX design principles, diagnostic frameworks, and design process.
  Use when: designing user flows, information architecture, navigation patterns, screen layouts, interaction design, UX copy, diagnosing usability problems, reviewing designs against best practices, or designing for 3D/XR/spatial computing (AR, VR, MR, visionOS, Quest, spatial UI).
  Do not use for: visual styling, color palettes, component implementation, design tokens (use z-design-system skill), or ui code.
  Workflow: User research → this skill (IA, flows, interactions, copy, spatial design) → z-design-system (tokens, components, visual patterns) → platform implementation.
references:
  - references/design-process.md         # 5-step process: Research → Map → Design → Remove → Validate
  - references/cognitive-principles.md   # 12 behavioral principles with diagnosis guide
  - references/information-architecture.md # Navigation patterns, IA principles, sitemap design
  - references/interaction-patterns.md   # State machines, feedback, gestures, loading, undo
  - references/ux-writing.md            # Button labels, error messages, empty states, microcopy
  - references/ergonomics.md            # Sizing, spacing, platform specs, accessibility, motion
  - references/3d-design.md              # 3D viewport UX: camera interaction, object interaction, depth hierarchy, configurator UX, photorealistic scenes, scroll-driven 3D, loading, discoverability, accessibility
  - references/xr-design.md              # XR spatial UX: comfort zones, interaction models, passthrough MR, content persistence, text input, multi-user, cybersickness, onboarding, privacy, platform guidelines (visionOS 26, Quest, Android XR)
---

# UX Design

## Context Check

If `docs/prd.md` or `docs/prd-phase-*.md` exists, read it first. Use as input, not constraint.

---

## First Principles (Every Task)

Before designing anything, answer in order:

1. **What is the user's ONE goal?** (Not features, not business metrics — their actual intent)
2. **What is the minimum needed to achieve it?** (Screens, information, actions)
3. **What can be removed?** (If removing it doesn't block the goal, remove it)

**Rule: If #1 is unclear, stop and clarify before proceeding. Use JTBD framing from `references/design-process.md`.**

---

## Quick Diagnosis

When something "feels wrong" or needs improvement:

| Problem | Primary Principle | Action | Reference |
|---------|------------------|--------|-----------|
| User hesitates | Hick's Law | Reduce choices, progressive disclosure | `cognitive-principles.md` |
| User misses targets | Fitts's Law | Increase size, reduce distance | `cognitive-principles.md` |
| User overwhelmed | Cognitive Load | Show only essentials, chunk into steps | `cognitive-principles.md` |
| User abandons midway | Goal Gradient | Show progress, visible milestones | `cognitive-principles.md` |
| User remembers negatively | Peak-End Rule | Fix worst moment and final state | `cognitive-principles.md` |
| User confused by custom UI | Jakob's Law | Use platform-standard patterns | `cognitive-principles.md` |
| User can't find content | IA failure | Restructure navigation, validate with tree test | `information-architecture.md` |
| User doesn't know what happened | Feedback gap | Add system feedback (toast, inline, state change) | `interaction-patterns.md` |
| User doesn't know what to do | Copy failure | Rewrite labels, add guidance, fix empty states | `ux-writing.md` |
| System feels slow | Doherty Threshold | Optimistic UI, skeleton screens, background processing | `interaction-patterns.md` |
| 3D/XR issue | See dedicated reference | Load the appropriate reference for diagnosis | `3d-design.md` / `xr-design.md` |

---

## Anti-patterns (Never Include)

These fail the "Does this help the user complete their goal?" test:

- Marketing copy, taglines, promotional language inside product flows
- Hero sections with vague value propositions in app screens
- Decorative sections without functional purpose
- Unnecessary onboarding or splash screens (if UI is self-explanatory, skip it)
- Confirmation dialogs for non-destructive or reversible actions (use undo instead)
- Elements that exist "because other apps have it" (violates First Principles)
- Color as the only indicator of state (accessibility failure)
- Placeholder text as labels (disappears on focus)
- "Are you sure?" without specifying what will happen
- Custom patterns for standard tasks (violates Jakob's Law)
- Hover-only interactions on touch devices
- Org-chart navigation (structure matches company, not user mental model)
- 3D/XR anti-patterns: see `3d-design.md` and `xr-design.md` for domain-specific lists

**Rule: If adding something "just in case" — don't. If unsure, mark it for user testing.**

---

## Core Philosophy

> The best UX is one the user doesn't notice. They should remember what they accomplished, not how the interface worked.

- **Efficiency**: Minimum steps, minimum time, minimum cognitive effort
- **Clarity**: One primary action per screen, clear hierarchy, no ambiguity
- **Consistency**: Platform-standard patterns for standard tasks (Jakob's Law)
- **Forgiveness**: Every action is reversible or confirmed before irreversible
- **Accessibility**: Not an afterthought — built into every decision from the start

**Rule: If a design needs explanation, it's not clear enough. If it needs a tutorial, simplify first.**

---

## Design Domains

This skill covers eight interconnected domains. Each has a dedicated reference file:

### 1. Design Process
How to go from problem to validated solution in 5 steps.
→ `references/design-process.md`

### 2. Cognitive Principles
12 behavioral science principles that explain why users struggle and how to fix it.
→ `references/cognitive-principles.md`

### 3. Information Architecture
How to structure navigation, organize content, and design findability.
→ `references/information-architecture.md`

### 4. Interaction Patterns
State machines, system feedback, gestures, loading, undo/redo, transitions.
→ `references/interaction-patterns.md`

### 5. UX Writing
Button labels, error messages, empty states, onboarding copy, microcopy.
→ `references/ux-writing.md`

### 6. Ergonomics & Accessibility
Sizing, spacing, platform-specific specs, responsive design, WCAG compliance.
→ `references/ergonomics.md`

### 7. 3D Interface Design
Camera interaction, object interaction, depth as hierarchy, product configurator UX, photorealistic scene UX (Gaussian splatting), scroll-driven 3D storytelling, loading experience, discoverability, progressive experience levels, accessibility.
→ `references/3d-design.md`

### 8. XR Spatial Design
Comfort zones, interaction models (gaze, hand, voice, controller), text input, passthrough MR design, content persistence, spatial UI patterns, multi-user/social XR, cybersickness prevention, onboarding, privacy, platform design languages (visionOS 26, Quest, Android XR), accessibility.
→ `references/xr-design.md`

---

## Phase Tagging

When the input PRD has companion Phase PRDs (`docs/prd-phase-*.md`):

1. **Design all screens and flows for the complete vision** — do not limit the UX to a single phase
2. **Tag screens and flows inline** — append `[Phase 1]`, `[Phase 2]`, `[Phase 3+]` etc. to screen names, user flows, and IA nodes to indicate when each becomes relevant
3. **Add a Phase Implementation Summary** at the end of the output document:

```
## Phase Implementation Summary

### Phase 1
- Screens: ...
- Key flows: ...

### Phase 2
- New screens: ...
- Flow changes: ...

### Phase 3+
- New screens: ...
- New flows: ...
```

If no Phase PRD exists, omit phase tags entirely.

---

## Quick Checklist

Before finalizing any UX decision:

### Goal & Structure
- [ ] User's ONE goal clearly identified (JTBD statement written)
- [ ] Every element passes "does this help the goal?" test
- [ ] Information architecture validated (≤3 taps to core content)
- [ ] Navigation pattern appropriate for content type

### Screen Design
- [ ] Primary action is ONE and visually dominant per screen
- [ ] Information shown is only what's needed for current decision
- [ ] All 7 screen states designed (empty, loading, loaded, error, partial, refreshing, offline)
- [ ] Content hierarchy: most important first

### Interaction
- [ ] Feedback exists for every user action (visual + optional haptic)
- [ ] Destructive actions require confirmation; reversible actions offer undo
- [ ] Loading pattern matches expected wait time
- [ ] Gestures have visible alternatives

### Copy
- [ ] Button labels are specific verbs (not "OK", "Submit", "Yes")
- [ ] Error messages: what happened + how to fix
- [ ] Empty states: explanation + actionable CTA
- [ ] No jargon, no technical language

### Platform & Ergonomics
- [ ] Mobile: primary actions in thumb zone
- [ ] Safe areas respected (notch, Dynamic Island, home indicator)
- [ ] Platform conventions followed (iOS patterns on iOS, Material on Android)
- [ ] Responsive: tested at 320px minimum

### Accessibility
- [ ] Contrast ratios passing (4.5:1 text, 3:1 UI components)
- [ ] Color not sole indicator of state
- [ ] Focus states visible, keyboard navigation complete
- [ ] Screen reader labels on all interactive elements
- [ ] Dynamic Type / scalable text supported
- [ ] `prefers-reduced-motion` respected

### Anti-patterns
- [ ] Checked against Anti-patterns list above — none present
- [ ] Cognitive principles cited for key design decisions

### 3D / XR (if applicable)
- [ ] Run validation checklist from `3d-design.md` and/or `xr-design.md`

---

## Output

Save to `docs/ux-design.md`.

Start the document with a **Table of Contents** (linked to each section heading) right after the title. UX design docs get long — a TOC makes them navigable.
