---
name: frontend-clean-code
description: >
  Frontend code quality reviewer based on Toss Frontend Fundamentals.
  Evaluates and improves TypeScript/React code against 4 pillars: Readability, Predictability, Cohesion, and Coupling.
  Use this skill whenever the user asks to review frontend code quality, refactor React/TypeScript components,
  improve code readability, reduce coupling, increase cohesion, or asks about clean code practices for frontend.
  Also triggers when editing TSX/TS files and the user mentions "code smell", "clean code", "refactor for readability",
  "too coupled", "not cohesive", or "hard to read". Use even for partial reviews like "is this naming good?" or
  "should I split this component?".
---

# Frontend Clean Code

Based on [Toss Frontend Fundamentals](https://frontend-fundamentals.com/code-quality/code/).

Good frontend code is **code that is easy to change**. When new requirements arrive, good code lets you modify and deploy with confidence. This skill evaluates code against 4 pillars and surfaces concrete improvements.

## The 4 Pillars

### 1. Readability

Code must be understood before it can be changed. Readable code minimizes the context a reader must hold in their head and flows naturally top-to-bottom.

**Strategies:**

#### A. Separate code that doesn't execute together

When a single component or function handles mutually exclusive branches (e.g., viewer vs admin), split each branch into its own component. This reduces the number of conditional paths a reader must trace.

```tsx
// Before: interleaved branches
function SubmitButton() {
  const role = useRole();
  // ... viewer logic and admin logic mixed together
}

// After: each role gets its own component
function SubmitButton() {
  return useRole() === "viewer" ? <ViewerSubmitButton /> : <AdminSubmitButton />;
}
```

#### B. Abstract implementation details

A person can hold about 6-7 pieces of context at once. When a component mixes authentication checks, redirects, and UI rendering, extract the cross-cutting concern into a wrapper or HOC so the main component focuses only on its primary job.

```tsx
// Before: auth logic embedded in LoginStartPage
// After: auth logic extracted to AuthGuard wrapper
function App() {
  return (
    <AuthGuard>
      <LoginStartPage />
    </AuthGuard>
  );
}
```

Similarly, if a confirm dialog and its trigger button live far apart in the tree, co-locate them into a single `InviteButton` component to reduce distance between related logic.

#### C. Split functions merged by logic type

When a Hook or function handles multiple unrelated concerns (e.g., all query params for a page), each concern should become its own Hook. A monolithic `usePageState()` that manages `cardId`, `filter`, `sort` all at once forces readers to understand everything when they only care about one param — and causes unnecessary re-renders.

```tsx
// Before: one hook for everything
function usePageState() { /* cardId, filter, sort, ... */ }

// After: one hook per concern
function useCardIdQueryParam() { /* only cardId */ }
function useFilterQueryParam() { /* only filter */ }
```

#### D. Name complex conditions

When a conditional expression spans multiple lines or combines several checks, extract it into a named variable that describes the *intent*, not the mechanics.

```tsx
// Before
product.categories.some(cat => cat.id === targetCategory.id && product.prices.some(p => p >= min && p <= max))

// After
const isSameCategory = category.id === targetCategory.id;
const isPriceInRange = product.prices.some(p => p >= minPrice && p <= maxPrice);
return isSameCategory && isPriceInRange;
```

Name conditions when: logic spans multiple lines, is reused, or needs unit testing.
Skip naming when: logic is simple and single-use.

#### E. Name magic numbers

A bare `300` in `delay(300)` could mean animation duration, server wait, or leftover test code. Name it:

```tsx
const ANIMATION_DELAY_MS = 300;
await delay(ANIMATION_DELAY_MS);
```

This also improves cohesion — if the animation duration changes, the constant name makes it obvious what else needs updating.

#### F. Minimize eye movement (context switching)

When understanding a piece of logic requires jumping between files, functions, or distant lines, consider inlining or co-locating. For simple permission checks, an inline object literal or switch may be clearer than an abstracted `getPolicyByRole()` defined elsewhere.

```tsx
// Inline policy — no jumping required
const policy = {
  admin: { canInvite: true, canView: true },
  viewer: { canInvite: false, canView: true },
}[user.role];
```

#### G. Simplify ternary operators

Nested ternaries are notoriously hard to read. Replace them with an IIFE using early returns:

```tsx
// Before
const status = A && B ? "BOTH" : A || B ? (A ? "A" : "B") : "NONE";

// After
const status = (() => {
  if (A && B) return "BOTH";
  if (A) return "A";
  if (B) return "B";
  return "NONE";
})();
```

#### H. Order comparisons left-to-right

Range checks are easier to read when they mirror mathematical notation (min <= value <= max):

```tsx
// Before
if (score >= 80 && score <= 100)

// After — reads like 80 ≤ score ≤ 100
if (80 <= score && score <= 100)
```

---

### 2. Predictability

Teammates should predict behavior from a function's name, parameters, and return type — without reading the implementation.

**Strategies:**

#### A. Don't reuse names for different behavior

If you wrap a library's `http.get` with auth token logic, don't call it `http.get` — call it `httpService.getWithAuth()`. Reusing the name creates false expectations.

```tsx
// Before: http.get secretly adds auth
export const http = {
  async get(url: string) {
    const token = await fetchToken();
    return httpLibrary.get(url, { headers: { Authorization: `Bearer ${token}` } });
  }
};

// After: name reveals the behavior
export const httpService = {
  async getWithAuth(url: string) { /* ... */ }
};
```

#### B. Unify return types for similar functions

If `useUser()` returns a full Query object but `useServerTime()` returns just the data, consumers must check each time. Pick one pattern and stick with it. Similarly, if validation functions mix `boolean` and `{ ok, reason }` return types, the boolean one will always be truthy when used in an `if` check on the object-returning one.

```tsx
// Consistent: all validation functions return { ok: boolean; reason?: string }
function checkIsNameValid(name: string): { ok: boolean; reason?: string } { /* ... */ }
function checkIsAgeValid(age: number): { ok: boolean; reason?: string } { /* ... */ }
```

#### C. Surface hidden logic

If `fetchBalance()` secretly logs analytics, that's unpredictable. The caller can't know logging happens, and a logging error could break balance fetching. Keep functions honest — move side effects to the call site.

```tsx
// Before: hidden logging inside fetchBalance
async function fetchBalance() {
  const balance = await http.get("...");
  logging.log("balance_fetched"); // hidden!
  return balance;
}

// After: logging at the call site where it's visible
const balance = await fetchBalance();
logging.log("balance_fetched");
```

---

### 3. Cohesion

Code that must change together should live together. High cohesion means modifying one part doesn't accidentally leave another part stale.

**Strategies:**

#### A. Co-locate files that change together

Organize by domain/feature, not by type. A `domains/Invite/` folder containing its components, hooks, and utils makes dependencies visible and deletion clean. Type-based folders (`components/`, `hooks/`, `utils/`) scatter related code and hide dependencies.

```
// Before: type-based
src/components/InviteButton.tsx
src/hooks/useInvite.ts
src/utils/inviteHelper.ts

// After: domain-based
src/domains/Invite/InviteButton.tsx
src/domains/Invite/useInvite.ts
src/domains/Invite/inviteHelper.ts
```

#### B. Eliminate magic numbers (cohesion angle)

A bare `300` in `delay(300)` is a cohesion risk: if the animation duration changes from 300ms to 500ms but the delay stays at 300, the code breaks silently. A named constant `ANIMATION_DELAY_MS` ties the two together so they get updated in lockstep.

#### C. Choose form cohesion strategy deliberately

- **Field-level cohesion** (independent validation per field): best when fields have complex async validation or are reused across forms.
- **Form-level cohesion** (unified Zod schema): best when fields interact (password confirmation, calculated totals) or the form represents a single business action.

Pick based on how fields change together, not on which pattern looks cleaner.

---

### 4. Coupling

Lower coupling means a smaller blast radius when code changes.

**Strategies:**

#### A. Manage one responsibility per unit

A `usePageState()` that manages all query params for an entire page is highly coupled — changing one param affects everything that uses the hook. Split into `useCardIdQueryParam()`, `useFilterQueryParam()`, etc.

#### B. Allow duplication when it reduces coupling

If a `useOpenMaintenanceBottomSheet` hook is shared across pages but each page starts needing different logging, different close behavior, or different text — the shared abstraction becomes a liability. Each page needs testing when the hook changes. Sometimes duplication is the right trade-off: each page owns its own version, and changes are local.

Allow duplication when: pages are likely to diverge in behavior.
Consolidate when: behavior is truly identical and unlikely to diverge.

#### C. Reduce props drilling

When the same prop passes through 3+ component layers untouched, it creates coupling between all those layers.

1. **Composition first**: use `children` to skip intermediate layers.
2. **Context as last resort**: use Context API when composition isn't enough and the data is deeply needed.

```tsx
// Composition: ItemEditModal renders ItemEditList directly, skipping ItemEditBody
<ItemEditBody keyword={keyword} onClose={onClose}>
  <ItemEditList items={items} onConfirm={onConfirm} />
</ItemEditBody>
```

---

## Trade-offs Between Pillars

These 4 pillars sometimes conflict. This is normal and expected — the skill of a frontend developer is knowing which to prioritize in each situation.

| Tension | What happens | Guidance |
|---------|-------------|----------|
| **Cohesion vs Readability** | Abstracting shared logic increases cohesion but adds indirection | If modification errors cause bugs → prioritize cohesion. If risk is low → prioritize readability, tolerate duplication |
| **Coupling vs Cohesion** | Allowing duplication lowers coupling but risks one copy getting stale | If behavior will diverge → allow duplication. If behavior is identical → consolidate |

There is no universal answer. Evaluate based on: how likely the code is to change, how dangerous a stale copy would be, and how many people touch this area.

---

## How to Apply This Skill

When reviewing or writing frontend code, check each pillar in order:

1. **Readability**: Can a teammate understand this without asking questions? Are there unnamed conditions, magic numbers, nested ternaries, or mixed branches?
2. **Predictability**: Does every function do exactly what its name suggests? Are return types consistent? Are there hidden side effects?
3. **Cohesion**: If requirement X changes, will all affected code get updated together? Are related files co-located?
4. **Coupling**: If I change this function/component, how many other files break? Can I reduce the blast radius?

When pillars conflict, state the trade-off explicitly and recommend based on the specific context (change likelihood, bug risk, team size).
