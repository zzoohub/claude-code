# Feature Spec — Reference

The canonical feature-spec template and writing guidance live in the **`feature-spec` skill** (`feature-spec/SKILL.md`). Use it as the single source of truth.

## When prd-craft calls this

After writing the PRD (`docs/prd/prd.md`), generate one `docs/prd/features/{feature}.md` per feature in the PRD's Feature Overview table. Each file follows the template in `feature-spec/SKILL.md`.

Quality bar (must hold for every feature file):
- Requirements are independently testable (`REQ-NNN` IDs)
- User journeys cover the happy path + 1-2 edge cases
- Out-of-scope is explicit
- Open questions are flagged (don't invent answers)
- Line limit: 200 lines per feature file

## Batch generation flow (prd-craft specific)

1. Read PRD's Feature Overview table for the feature list and dev order.
2. For each feature, invoke the `feature-spec` skill OR generate inline using its template.
3. Cross-reference: each feature file links back to the PRD problem statement.
4. After generation, patch `docs/prd/prd.md` Dev Order section if any feature was reordered.

## Differences from standalone feature-spec usage

| Standalone (`feature-spec` skill) | Batch (`prd-craft`) |
|---|---|
| One feature at a time | All features at once |
| Reads existing PRD for context | Writes PRD + features together |
| Patches PRD's Feature Overview + Dev Order | Generates PRD's Feature Overview + Dev Order from scratch |

For the actual template, field-by-field guidance, and writing examples, **read `feature-spec/SKILL.md`**.
