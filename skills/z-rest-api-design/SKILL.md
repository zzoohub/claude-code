---
name: z-rest-api-design
description: |
  Generate OpenAPI 3.1 specification files from user requirements.
  Use when: user wants to design an API, define endpoints, create API contracts,
  generate openapi.yaml, plan REST resources, or says things like
  "design the API", "what endpoints do I need", "create the API spec",
  "add a new endpoint", "define the API contract", "API for this feature".
  Also use when user provides a PRD, database schema, or ERD and wants API endpoints derived from it.
  Use this skill even for partial API work — adding a single endpoint counts.
  Do NOT use for: framework-specific implementation (use z-fastapi-hexagonal or z-axum-hexagonal after this).
  Workflow: requirements → this skill (OpenAPI spec) → z-fastapi-hexagonal | z-axum-hexagonal (implementation).
  Output: openapi/openapi.yaml at project root.
---

# z-rest-api-design — OpenAPI Spec Generator

Generate production-ready OpenAPI 3.1 specs. Output: `openapi/openapi.yaml`.

> **References** (read the relevant one on demand — not all upfront):
> - `references/design-decisions.md` — Decision frameworks for resource modeling, endpoint design, response format
> - `references/openapi-template.yaml` — Base template to copy when starting a new spec
> - `references/examples-core.md` — CRUD, errors, pagination, filtering examples
> - `references/examples-advanced.md` — File upload, state transitions, search, real-time, bulk ops

---

## Workflow

### Step 1: Identify Resources

Extract API resources from user input (direct description, PRD, database schema, or existing spec).

**Resource identification process:**

1. List all nouns from the requirements (users, orders, invoices, comments)
2. For each noun, decide: **first-class resource or property?**
   - First-class resource: has its own lifecycle (created, read, updated, deleted independently)
   - Property: only exists as part of another resource (e.g., `address` inside `user`)
3. For each resource, list the operations users actually need — think beyond CRUD to real workflows
4. Map relationships between resources

**Decision: Sub-resource or flat route?**

| Signal | Sub-resource `/parents/{id}/children` | Flat `/children?parentId=X` |
|--------|--------------------------------------|-----------------------------|
| Child cannot exist without parent | Yes | — |
| Child belongs to exactly one parent | Either works | Either works |
| Child can belong to multiple parents | — | Yes |
| Need to list children across parents | — | Yes |
| Nesting would exceed 2 levels | — | Yes (flatten) |

Default to flat routes with query filters. Use sub-resources only when parent-child ownership is fundamental to the domain.

**Decision: PATCH vs custom action?**

| Signal | PATCH | Custom action `POST /resources/{id}/{action}` |
|--------|-------|-----------------------------------------------|
| Changing a data field | Yes | — |
| Triggering a side effect (send email, charge) | — | Yes |
| State machine transition (draft → published) | — | Yes |
| Partial field update | Yes | — |

**Extracting from different source types:**

| Source | What to extract |
|--------|-----------------|
| PRD / brief | User stories → resources + operations |
| DB schema / ERD | Tables → resources, FKs → relationships, NOT NULL → required, enums → schema enums, unique → 409 conflicts |
| Existing spec | Read first, add/modify, preserve existing content |

### Step 2: Design Endpoints

Read `references/design-decisions.md` for conventions, then design each endpoint.

**Naming rules:**
- Plural nouns, lowercase, kebab-case (`line-items`, not `lineItems`)
- No verbs in paths — HTTP methods express actions, custom actions for non-CRUD
- `/v1/` prefix on all paths

**Schema naming:**

| Purpose | Pattern | Example |
|---------|---------|---------|
| Create request body | `Create{Resource}` | `CreateUser` |
| Update request body | `Update{Resource}` | `UpdateUser` |
| Full resource object | `{Resource}` | `User` |
| List wrapper | `{Resource}List` | `UserList` |
| Error | `ProblemDetail` | (shared) |

**OperationId naming:**

| Method | Pattern | Example |
|--------|---------|---------|
| GET collection | `list{Resources}` | `listUsers` |
| GET single | `get{Resource}` | `getUser` |
| POST create | `create{Resource}` | `createUser` |
| PATCH update | `update{Resource}` | `updateUser` |
| DELETE | `delete{Resource}` | `deleteUser` |
| Custom action | `{verb}{Resource}` | `cancelOrder`, `publishPost` |

### Step 3: Generate OpenAPI Spec

Read `references/openapi-template.yaml` as base, then:

1. **Tags** — one per resource, with description
2. **Paths** — each endpoint:
   - `operationId` (unique, camelCase)
   - `summary` — one line
   - `description` — only when behavior isn't obvious from summary
   - `parameters` — path params, query filters, pagination
   - `requestBody` — `$ref` to schema
   - `responses` — all applicable status codes
   - `security` — per-operation if different from global
3. **Schemas** — reusable data models:
   - `required` fields explicit
   - `format` for dates (`date-time`), emails (`email`), UUIDs (`uuid`)
   - `readOnly: true` for server-generated fields (`id`, `createdAt`, `updatedAt`)
   - Create/Update schemas must NOT include readOnly fields
4. **Reusable components** — error responses (400, 401, 403, 404, 409, 422, 429), pagination params

**For advanced patterns**, read the relevant section of `references/examples-advanced.md`:
- File uploads → § File Upload
- State transitions → § State Transitions
- Search → § Search
- Relationship expansion → § Relationship Expansion
- Real-time streaming → § Server-Sent Events
- Async jobs → § Async Operations
- Batch operations → § Bulk Operations

### Step 4: Validate

Before writing the file:

- [ ] Plural nouns, no verbs in paths
- [ ] POST → 201, DELETE → 204, async → 202
- [ ] All collections have pagination params (`CursorParam`, `LimitParam`)
- [ ] Errors use RFC 9457 `ProblemDetail` schema with `application/problem+json`
- [ ] `operationId` unique across all endpoints
- [ ] Create/Update schemas exclude `readOnly` fields
- [ ] All `$ref` pointers resolve to defined components
- [ ] Security scheme defined and applied
- [ ] Custom actions use `POST /resources/{id}/{verb}` (not PATCH with magic values)
- [ ] No endpoint nesting beyond 2 levels

Write output to `openapi/openapi.yaml`. Create `openapi/` directory if needed.

---

## Modifying an Existing Spec

When `openapi/openapi.yaml` already exists:

1. Read the existing spec first
2. Add new paths, schemas, parameters
3. Preserve existing content — do not remove or reorder unless explicitly asked
4. Match the style of existing definitions

---

## File Layout

```
project-root/
├── openapi/
│   └── openapi.yaml    # Generated by this skill (source of truth)
└── services/
    └── api/             # Implementation consumes the spec
```

For specs with 50+ endpoints, split with `$ref` to external files under `openapi/`. The main `openapi.yaml` stays as entry point.

---

## Troubleshooting

**Circular `$ref`**: Break with inline objects or separate the recursive part. OpenAPI 3.1 allows them but many tools choke.

**Versioning**: `/v1/` prefix. Bump only for breaking changes (removing fields, changing types). Additive changes (new optional fields, new endpoints) don't need a bump. Use `Sunset` header for deprecation.
