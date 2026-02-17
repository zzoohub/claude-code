# Normalization & Denormalization Guide (PostgreSQL)

## Normalization Levels

### 1NF (First Normal Form)
- Every column holds atomic (indivisible) values
- No repeating groups

```sql
-- BAD: violates 1NF
CREATE TABLE order_bad (
    id BIGINT PRIMARY KEY,
    product_names TEXT  -- 'iPhone, MacBook, AirPods' comma-separated
);

-- GOOD: 1NF compliant
CREATE TABLE order_item (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES "order"(id),
    product_id BIGINT NOT NULL REFERENCES product(id),
    quantity INT NOT NULL CHECK (quantity > 0)
);
```

**PostgreSQL exception**: ARRAY and JSONB types intentionally break atomicity,
but are a reasonable choice for tags, metadata, or attributes where
search/join is not required on individual elements.

```sql
-- ARRAY is appropriate here: simple filtering on tags
CREATE TABLE article (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_article_tags ON article USING GIN (tags);

-- Query
SELECT * FROM article WHERE 'postgresql' = ANY(tags);
```

### 2NF (Second Normal Form)
- Satisfies 1NF
- Eliminates partial dependencies (columns dependent on only part of a composite key)

```sql
-- BAD: violates 2NF (student_name depends only on student_id)
CREATE TABLE enrollment_bad (
    student_id BIGINT,
    course_id BIGINT,
    student_name TEXT,      -- depends only on student_id
    grade CHAR(2),
    PRIMARY KEY (student_id, course_id)
);

-- GOOD: 2NF compliant
CREATE TABLE student (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE enrollment (
    student_id BIGINT REFERENCES student(id),
    course_id BIGINT REFERENCES course(id),
    grade CHAR(2),
    PRIMARY KEY (student_id, course_id)
);
```

### 3NF (Third Normal Form)
- Satisfies 2NF
- Eliminates transitive dependencies (non-key column depending on another non-key column)

```sql
-- BAD: violates 3NF (city -> country transitive dependency)
CREATE TABLE customer_bad (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT,
    country TEXT    -- determined by city
);

-- GOOD: 3NF compliant
CREATE TABLE city (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT NOT NULL
);

CREATE TABLE customer (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    city_id BIGINT REFERENCES city(id)
);
```

### BCNF (Boyce-Codd Normal Form)
- Satisfies 3NF
- Every determinant is a candidate key

For most practical applications, 3NF is sufficient. BCNF is only relevant in edge cases with multiple overlapping composite keys.

## Denormalization: When and How

### When Denormalization Is Justified

1. **Read-heavy analytical tables**
   - Dashboards, reports via Materialized Views
   - Data warehouse / OLAP environments

2. **When join cost is measured and confirmed as the bottleneck**
   - Only after EXPLAIN ANALYZE proves joins are the problem
   - Never denormalize based on a guess that "joins might be slow"

3. **Caching computed aggregates**
   - Order totals, average review scores, etc.
   - Must guarantee sync via triggers or application-level logic

```sql
-- Safe denormalization via Materialized View
CREATE MATERIALIZED VIEW mv_product_stats AS
SELECT
    p.id AS product_id,
    p.name,
    COUNT(r.id) AS review_count,
    AVG(r.rating)::NUMERIC(3,2) AS avg_rating,
    SUM(oi.quantity) AS total_sold
FROM product p
LEFT JOIN review r ON r.product_id = p.id
LEFT JOIN order_item oi ON oi.product_id = p.id
GROUP BY p.id, p.name;

CREATE UNIQUE INDEX idx_mv_product_stats_id ON mv_product_stats (product_id);

-- Periodic refresh (non-blocking with CONCURRENTLY)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_product_stats;
```

### When NOT to Denormalize

1. **Core transactional tables** — data integrity is the top priority
2. **"Joins might be slow"** — speculation without measurement is not a reason. PostgreSQL joins are highly efficient
3. **Without a data sync strategy** — if you can't guarantee consistency of duplicated data, don't denormalize

### Optimize Joins Before Denormalizing

```sql
-- 1. Ensure PK/FK type match (no implicit casting)
-- BAD: type mismatch forces casting
SELECT * FROM order_item oi
JOIN product p ON p.id = oi.product_id::BIGINT;  -- casting needed = design mistake

-- 2. Verify FK columns have indexes
-- PostgreSQL does NOT auto-create indexes on FK columns!
CREATE INDEX idx_order_item_product_id ON order_item (product_id);

-- 3. SELECT only needed columns
-- BAD
SELECT * FROM "order" o JOIN order_item oi ON oi.order_id = o.id;
-- GOOD
SELECT o.id, o.status, oi.product_id, oi.quantity
FROM "order" o JOIN order_item oi ON oi.order_id = o.id;

-- 4. For very small lookup tables, consider subquery/IN instead of join
SELECT * FROM product
WHERE category_id IN (SELECT id FROM category WHERE name = 'Electronics');
```
