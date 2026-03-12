# PostgreSQL Design Patterns

## 1. Table Inheritance

Model multiple entity types that share common attributes.

### Single Table Inheritance (STI)
All types in one table. Simple but may accumulate many NULL columns.

```sql
CREATE TABLE payment (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('credit_card', 'bank_transfer', 'paypal')),
    amount NUMERIC(15, 2) NOT NULL,
    -- credit_card only
    card_last_four CHAR(4),
    card_brand TEXT,
    -- bank_transfer only
    bank_name TEXT,
    account_number TEXT,
    -- paypal only
    paypal_email TEXT,
    -- common
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Per-type constraints
ALTER TABLE payment ADD CONSTRAINT chk_credit_card
    CHECK (type != 'credit_card' OR (card_last_four IS NOT NULL AND card_brand IS NOT NULL));
```

**When to use**: 3-5 types with few type-specific columns each.

### Class Table Inheritance (CTI)
Shared table + type-specific tables. Normalized but requires joins.

```sql
CREATE TABLE payment (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payment_credit_card (
    payment_id BIGINT PRIMARY KEY REFERENCES payment(id) ON DELETE CASCADE,
    card_last_four CHAR(4) NOT NULL,
    card_brand TEXT NOT NULL,
    expiry_month SMALLINT NOT NULL,
    expiry_year SMALLINT NOT NULL
);

CREATE TABLE payment_bank_transfer (
    payment_id BIGINT PRIMARY KEY REFERENCES payment(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    routing_number TEXT
);
```

**When to use**: Many type-specific columns, or types are added frequently.

### PostgreSQL Native Inheritance (reference only)
```sql
CREATE TABLE payment_credit_card () INHERITS (payment);
```
⚠️ **Not recommended in production**: FK constraints don't apply to child tables, UNIQUE is per-table only.

## 2. Soft Delete

```sql
CREATE TABLE user_account (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    deleted_at TIMESTAMPTZ,  -- NULL = active
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- View for active users only
CREATE VIEW active_user AS
SELECT * FROM user_account WHERE deleted_at IS NULL;

-- Partial unique index (active users only)
CREATE UNIQUE INDEX uq_user_email_active ON user_account (email) WHERE deleted_at IS NULL;

-- Delete operation
UPDATE user_account SET deleted_at = now() WHERE id = 123;
```

**Caveats**:
- Every query needs `WHERE deleted_at IS NULL` → solve with views or Row-Level Security
- Deleted data accumulates → schedule periodic archiving

## 3. Audit Trail

### Trigger-based automatic audit logging

```sql
CREATE TABLE audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id BIGINT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    changed_by TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_table_record ON audit_log (table_name, record_id);
CREATE INDEX idx_audit_log_changed_at ON audit_log USING BRIN (changed_at);

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), current_user);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), current_user);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_data, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), current_user);
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to a table
CREATE TRIGGER trg_order_audit
    AFTER INSERT OR UPDATE OR DELETE ON "order"
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();
```

## 4. Event Sourcing

Store every state change as an event. Derive current state by replaying events.

```sql
CREATE TABLE event_store (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    aggregate_type TEXT NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    version INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (aggregate_id, version)  -- optimistic concurrency control
);

CREATE INDEX idx_event_store_aggregate ON event_store (aggregate_id, version);
CREATE INDEX idx_event_store_type ON event_store (aggregate_type, created_at);

-- Current state via projection table
CREATE TABLE order_projection (
    id UUID PRIMARY KEY,
    status TEXT NOT NULL,
    total_amount NUMERIC(15, 2) NOT NULL DEFAULT 0,
    item_count INT NOT NULL DEFAULT 0,
    last_event_version INT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**When to use**: Finance, inventory, or any domain requiring complete change history for legal/business reasons.

## 5. CQRS (Command Query Responsibility Segregation)

```sql
-- Write Model (normalized, integrity-focused)
CREATE TABLE "order" (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_account(id),
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_item (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES "order"(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES product(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL
);

-- Read Model (denormalized, query performance-focused)
CREATE MATERIALIZED VIEW mv_order_summary AS
SELECT
    o.id AS order_id,
    o.user_id,
    u.name AS user_name,
    u.email AS user_email,
    o.status,
    COUNT(oi.id) AS item_count,
    SUM(oi.quantity * oi.unit_price) AS total_amount,
    o.created_at
FROM "order" o
JOIN user_account u ON u.id = o.user_id
JOIN order_item oi ON oi.order_id = o.id
GROUP BY o.id, o.user_id, u.name, u.email, o.status, o.created_at;

CREATE UNIQUE INDEX idx_mv_order_summary_id ON mv_order_summary (order_id);
CREATE INDEX idx_mv_order_summary_user ON mv_order_summary (user_id);
```

## 6. Multi-Tenant Patterns

### Schema-per-Tenant (strong isolation)
```sql
CREATE SCHEMA tenant_acme;
CREATE TABLE tenant_acme.user_account ( ... );
CREATE TABLE tenant_acme."order" ( ... );
```

### Row-Level Security (flexible isolation)
```sql
CREATE TABLE "order" (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    -- ... other columns
);

ALTER TABLE "order" ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON "order"
    USING (tenant_id = current_setting('app.current_tenant')::BIGINT);
```

## 7. Polymorphic Association

One table needs to reference multiple different parent tables.

```sql
-- Approach 1: Separate FK columns (recommended — FK constraints enforced)
CREATE TABLE comment (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    body TEXT NOT NULL,
    article_id BIGINT REFERENCES article(id),
    product_id BIGINT REFERENCES product(id),
    CONSTRAINT chk_one_parent CHECK (
        (article_id IS NOT NULL)::INT + (product_id IS NOT NULL)::INT = 1
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Approach 2: Intermediate table (more extensible)
CREATE TABLE commentable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    commentable_type TEXT NOT NULL,
    commentable_id BIGINT NOT NULL,
    UNIQUE (commentable_type, commentable_id)
);

CREATE TABLE comment (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    commentable_id BIGINT NOT NULL REFERENCES commentable(id),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 8. Temporal Data

```sql
-- Data with validity periods (prices, policies, etc.)
CREATE TABLE product_price (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES product(id),
    price NUMERIC(12, 2) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ,
    CONSTRAINT chk_valid_range CHECK (valid_until IS NULL OR valid_until > valid_from)
);

-- Current price view
CREATE VIEW current_product_price AS
SELECT DISTINCT ON (product_id)
    product_id, price, valid_from
FROM product_price
WHERE valid_from <= now() AND (valid_until IS NULL OR valid_until > now())
ORDER BY product_id, valid_from DESC;

-- Range type with exclusion constraint (prevent overlapping reservations)
CREATE TABLE room_reservation (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES room(id),
    reserved_period TSTZRANGE NOT NULL,
    EXCLUDE USING GIST (room_id WITH =, reserved_period WITH &&)
);
```
