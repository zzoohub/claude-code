# Mermaid ERD Quick Reference

Use this syntax when producing the ERD output file (`docs/erd.mermaid`).

## Basic Structure

```mermaid
erDiagram
    user_account {
        bigint id PK
        text email UK
        text name
        timestamptz created_at
        timestamptz updated_at
    }

    "order" {
        bigint id PK
        bigint user_id FK
        order_status status
        timestamptz created_at
        timestamptz updated_at
    }

    order_item {
        bigint id PK
        bigint order_id FK
        bigint product_id FK
        int quantity
        numeric unit_price
    }

    product {
        bigint id PK
        text name
        numeric price
        jsonb attributes
        timestamptz created_at
    }

    user_account ||--o{ "order" : "places"
    "order" ||--|{ order_item : "contains"
    product ||--o{ order_item : "referenced by"
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

1. Use PostgreSQL type names as column types (bigint, text, timestamptz, numeric, jsonb)
2. Quote table names that are reserved words (`"order"`, `"user"`)
3. Include PK, FK, UK markers
4. Keep relationship labels short (verb phrases: "places", "contains", "belongs to")
5. Group related tables visually — Mermaid renders top-to-bottom by default
6. For large schemas (15+ tables), split into logical groupings with comments
