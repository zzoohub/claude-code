# Feature Spec — Batch Generation (prd-craft)

The **`feature-spec` skill** (`feature-spec/SKILL.md`) is the single source of
truth for the feature-spec template, field-by-field guidance, and the Quality
Bar. This file only covers what is *specific to batch generation* from a PRD.
Do not restate or fork the template/quality bar here — they drift.

## When prd-craft calls this

After writing the PRD (`docs/prd/prd.md`), generate one
`docs/prd/features/{feature}.md` per feature in the PRD's Feature Overview table.

**Each feature file must meet the `feature-spec` skill's Quality Bar** (testable
`REQ-NNN` requirements, mapped user journeys, explicit edge cases and
out-of-scope, flagged open questions — no invented answers). In batch mode, add
one cross-reference requirement: each file ties back to the PRD §1 problem
statement.

## Batch generation flow

1. Read the PRD's Feature Overview table for the feature list and dev order.
2. For each feature, **invoke the `feature-spec` skill** (preferred). If
   generating inline instead, use that skill's template verbatim — never a local
   copy.
3. Cross-reference: each feature file links back to the PRD §1 problem statement.
4. After generation, patch `docs/prd/prd.md` Dev Order if any feature was reordered.

## Differences from standalone feature-spec usage

| Standalone (`feature-spec` skill) | Batch (`prd-craft`) |
|---|---|
| One feature at a time | All features at once |
| Reads existing PRD for context | Writes PRD + features together |
| Patches PRD's Feature Overview + Dev Order | Generates PRD's Feature Overview + Dev Order from scratch |
