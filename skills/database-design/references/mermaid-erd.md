# Mermaid ERD Quick Reference

Use this syntax when producing the ERD output file (`docs/erd.mermaid`).

## Basic Structure

```mermaid
erDiagram
    user_accounts {
        uuid id PK
        text email UK
        text name
        timestamptz created_at
        timestamptz updated_at
    }

    orders {
        uuid id PK
        uuid user_id FK
        order_status status
        timestamptz created_at
        timestamptz updated_at
    }

    order_items {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        int quantity
        numeric unit_price
    }

    products {
        uuid id PK
        text name
        numeric price
        jsonb attributes
        timestamptz created_at
    }

    user_accounts ||--o{ orders : "places"
    orders ||--|{ order_items : "contains"
    products ||--o{ order_items : "referenced by"
```

## Relationship Cardinality

```
||--||   exactly one to exactly one
||--o{   exactly one to zero or more
||--|{   exactly one to one or more
o|--o{   zero or one to zero or more
```

Read left to right: left side of `--` describes left entity, right side describes right entity.

| Symbol | Meaning |
|--------|---------|
| `\|\|` | exactly one |
| `o\|` | zero or one |
| `\|{` | one or more |
| `o{` | zero or more |

## Column Markers

| Marker | Meaning |
|--------|---------|
| `PK` | Primary Key |
| `FK` | Foreign Key |
| `UK` | Unique Key |

## Rules for This Skill

1. Use PostgreSQL type names as column types (uuid, bigint, text, timestamptz, numeric, jsonb) — PK type matches the table's actual PK choice (UUID v7 by default, BIGINT for high-volume internal tables — see SKILL.md "Primary Key Type Decision")
2. Quote table names only if they collide with reserved words (rare with plural names — e.g., `"groups"`)
3. Include PK, FK, UK markers
4. Keep relationship labels short (verb phrases: "places", "contains", "belongs to")
5. Group related tables visually — Mermaid renders top-to-bottom by default
6. For large schemas (15+ tables), split into logical groupings with comments
