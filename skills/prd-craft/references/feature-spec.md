# Feature Spec — Template & Writing Guide

After writing the PRD (`docs/prd/prd.md`), create a separate spec file for each
feature in `docs/prd/features/`. Each file is a self-contained reference for
implementing that feature.

---

## Why Separate Feature Files?

- The PRD captures the full vision and serves as the long-term source of truth
- Feature specs answer: "What exactly does this feature do, and how should it work?"
- Separation keeps each file small enough for one Claude Code session to consume
- **Every file is a single source of truth (SSOT).** If a file already exists, update it in place — never create duplicates. The file should always reflect the latest state.

---

## Feature Spec Template

```markdown
# [Feature Name]

## Overview

What this feature does and why it matters. 2-3 sentences connecting back to
the product vision. Reference the PRD problem statement if relevant.

---

## Requirements

Functional requirements specific to this feature. Each requirement should be
independently testable.

- REQ-001: Tool reads CSV files and validates against a user-defined schema
- REQ-002: Malformed rows are reported with line and column numbers
- REQ-003: Files over 100MB are processed via streaming (not loaded into memory)
- REQ-004: Exit code is non-zero when any validation error is found

---

## User Journeys

Step-by-step flows showing how users interact with this feature.

### First run
1. User runs the tool with an input file
2. Tool reads the file and applies default validation
3. Output shows a summary: rows processed, errors found
4. If errors exist, each is listed with file, line, and description

### With custom schema
1. User creates a schema config file
2. Runs the tool with --schema flag pointing to config
3. Tool validates each row against the schema
4. Errors include which schema rule was violated

### Error states
- File not found → clear message with the path that was tried
- Permission denied → suggest checking file permissions
- Malformed input (not valid CSV) → report the line where parsing failed
- Schema config invalid → report which field in the config is wrong

---

## Edge Cases

- Empty file → report "0 rows processed" (not an error)
- File with only headers → report "0 data rows" with a note
- Mixed line endings (CRLF/LF) → handle transparently
- Very long lines (>1MB per row) → process normally up to a configurable limit

---

## Dependencies

- None (this is the first feature in dev order)

## Depends On This

- transform-engine (needs parsed and validated data as input)
- output-formatter (needs parsed data to format)
```

---

## Writing Guide

### Requirements — Good vs Bad

**Good granularity (independently testable):**

> ```
> REQ-001 Tool reads CSV files up to 1GB within 512MB memory using streaming.
> REQ-002 Each row is validated against a user-defined schema (field types,
>         required fields, value constraints).
> REQ-003 Validation errors include row number, column name, expected type,
>         and actual value.
> REQ-004 Tool supports --quiet flag that outputs only error count and exit code.
> REQ-005 When no errors are found, tool outputs summary and exits with code 0.
> ```

**Too coarse:**

> "REQ-001 Tool processes files."
>
> (Not testable. Which files? What processing? What output?)

**Too fine:**

> "REQ-001 CSV parser uses RFC 4180 strict mode with LF line terminator."
>
> (Implementation detail. This belongs in a technical spec, not a PRD.)

**Right level:** "Tool processes CSV files and reports malformed rows with line numbers."

### User Journeys — Good vs Bad

**Good:**

> **Journey: First use**
> 1. User installs the tool
> 2. Runs `tool check data.csv` with no config
> 3. Tool applies default rules (type detection, required fields from header)
> 4. Output shows: 1,247 rows checked, 3 errors found
>    - If errors → each listed with line number and description
>    - If clean → "All rows valid" and exit code 0
> 5. User sees a hint: "Add --schema config.yaml for custom validation rules"
>
> **Drop-off risk:** Step 3 (default rules). If defaults produce too many
> false positives, users won't trust the tool. Consider conservative defaults
> with an opt-in strict mode.

**Bad:**

> "User runs the tool, it processes the file, shows results."
>
> (No decision points. No error states. No drop-off analysis.)

### Granularity

Each requirement should be independently testable — a QA engineer could
verify it passes or fails.

- Too coarse: "Tool processes files"
- Too fine: "CSV parser allocates a 64KB read buffer"
- Right level: "Tool processes CSV files up to 1GB within 512MB memory"

### What Belongs Here vs Elsewhere

| Content | Feature spec | PRD |
|---------|-------------|-----|
| Requirements | Yes | Feature overview only |
| User journeys | Yes | No |
| Success metrics | No | Yes |
| Dev order | No | Yes |

### Length

Target **100-200 lines** per feature. If a feature spec exceeds 200 lines,
consider splitting the feature into sub-features with their own specs.

### Naming Convention

- `docs/prd/features/file-parser.md`
- `docs/prd/features/transform-engine.md`
- `docs/prd/features/output-formatter.md`

Use short, descriptive names matching the feature name in the PRD's feature
overview table. Filenames should be kebab-case for multi-word features.
