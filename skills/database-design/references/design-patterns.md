# PostgreSQL Design Patterns

## 1. Table Inheritance

Model multiple entity types that share common attributes.

### Single Table Inheritance (STI)
All types in one table. Simple but may accumulate many NULL columns.

```sql
CREATE TABLE payments (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
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
ALTER TABLE payments ADD CONSTRAINT chk_credit_card
    CHECK (type != 'credit_card' OR (card_last_four IS NOT NULL AND card_brand IS NOT NULL));
```

**When to use**: 3-5 types with few type-specific columns each.

### Class Table Inheritance (CTI)
Shared table + type-specific tables. Normalized but requires joins.

```sql
CREATE TABLE payments (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    type TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payment_credit_cards (
    payment_id UUID PRIMARY KEY REFERENCES payments(id) ON DELETE CASCADE,
    card_last_four CHAR(4) NOT NULL,
    card_brand TEXT NOT NULL,
    expiry_month SMALLINT NOT NULL,
    expiry_year SMALLINT NOT NULL
);

CREATE TABLE payment_bank_transfers (
    payment_id UUID PRIMARY KEY REFERENCES payments(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    routing_number TEXT
);
```

**When to use**: Many type-specific columns, or types are added frequently.

### PostgreSQL Native Inheritance (reference only)
```sql
CREATE TABLE payment_credit_cards () INHERITS (payment);
```
⚠️ **Not recommended in production**: FK constraints don't apply to child tables, UNIQUE is per-table only.

## 2. Soft Delete

```sql
CREATE TABLE user_accounts (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    deleted_at TIMESTAMPTZ,  -- NULL = active
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- View for active users only
CREATE VIEW active_user AS
SELECT * FROM user_accounts WHERE deleted_at IS NULL;

-- Partial unique index (active users only)
CREATE UNIQUE INDEX uq_user_email_active ON user_accounts (email) WHERE deleted_at IS NULL;

-- Delete operation
UPDATE user_accounts SET deleted_at = now() WHERE id = '...';
```

**Caveats**:
- Every query needs `WHERE deleted_at IS NULL` → solve with views or Row-Level Security
- Deleted data accumulates → schedule periodic archiving

## 3. Audit Trail

### Trigger-based automatic audit logging

```sql
-- BIGINT IDENTITY here per SKILL.md mixed strategy: high-volume internal append-only
-- table where 8-byte savings cascade through every audit row. record_id is TEXT to
-- accommodate any PK type (UUID, BIGINT, composite).
CREATE TABLE audit_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    changed_by TEXT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_table_record ON audit_logs (table_name, record_id);

-- For triggers below: NEW.id and OLD.id are typed per the source table (UUID, BIGINT, etc.).
-- Cast to TEXT when inserting into audit_logs.record_id.
CREATE INDEX idx_audit_logs_changed_at ON audit_logs USING BRIN (changed_at);

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (table_name, record_id, action, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id::TEXT, 'INSERT', to_jsonb(NEW), current_user);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id::TEXT, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), current_user);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_data, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id::TEXT, 'DELETE', to_jsonb(OLD), current_user);
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to a table
CREATE TRIGGER trg_orders_audit
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();
```

## 4. Event Sourcing

Store every state change as an event. Derive current state by replaying events.

```sql
-- BIGINT IDENTITY here per SKILL.md mixed strategy: append-only event store can
-- accumulate billions of rows; 8-byte PKs save measurable space cumulatively.
CREATE TABLE event_stores (
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

CREATE INDEX idx_events_stores_aggregate ON event_stores (aggregate_id, version);
CREATE INDEX idx_events_stores_type ON event_stores (aggregate_type, created_at);

-- Current state via projection table
CREATE TABLE order_projections (
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
CREATE TABLE orders (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    user_id UUID NOT NULL REFERENCES user_accounts(id),
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
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
FROM orders o
JOIN user_accounts u ON u.id = o.user_id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.user_id, u.name, u.email, o.status, o.created_at;

CREATE UNIQUE INDEX idx_mv_order_summary_id ON mv_order_summary (order_id);
CREATE INDEX idx_mv_order_summary_user ON mv_order_summary (user_id);
```

## 6. Multi-Tenant Patterns

### Schema-per-Tenant (strong isolation)
```sql
CREATE SCHEMA tenant_acme;
CREATE TABLE tenant_acme.user_accounts ( ... );
CREATE TABLE tenant_acme.orders ( ... );
```

### Row-Level Security (flexible isolation)
```sql
CREATE TABLE orders (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    tenant_id UUID NOT NULL,
    -- ... other columns
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.current_tenant')::UUID);
```

## 7. Polymorphic Association

One table needs to reference multiple different parent tables.

```sql
-- Approach 1: Separate FK columns (recommended — FK constraints enforced)
CREATE TABLE comments (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    body TEXT NOT NULL,
    article_id UUID REFERENCES articles(id),
    product_id UUID REFERENCES products(id),
    CONSTRAINT chk_one_parent CHECK (
        (article_id IS NOT NULL)::INT + (product_id IS NOT NULL)::INT = 1
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Approach 2: Intermediate table (more extensible)
CREATE TABLE commentables (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    commentable_type TEXT NOT NULL,
    commentable_id UUID NOT NULL,
    UNIQUE (commentable_type, commentable_id)
);

CREATE TABLE comments (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    commentable_id UUID NOT NULL REFERENCES commentables(id),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 8. Temporal Data

```sql
-- Data with validity periods (prices, policies, etc.)
CREATE TABLE product_prices (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    product_id UUID NOT NULL REFERENCES products(id),
    price NUMERIC(12, 2) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ,
    CONSTRAINT chk_valid_range CHECK (valid_until IS NULL OR valid_until > valid_from)
);

-- Current price view
CREATE VIEW current_product_price AS
SELECT DISTINCT ON (product_id)
    product_id, price, valid_from
FROM product_prices
WHERE valid_from <= now() AND (valid_until IS NULL OR valid_until > now())
ORDER BY product_id, valid_from DESC;

-- Range type with exclusion constraint (prevent overlapping reservations)
CREATE TABLE room_reservations (
    id UUID NOT NULL PRIMARY KEY DEFAULT uuidv7(),
    room_id UUID NOT NULL REFERENCES room(id),
    reserved_period TSTZRANGE NOT NULL,
    EXCLUDE USING GIST (room_id WITH =, reserved_period WITH &&)
);
```

## 9. Auto-Updated Timestamps

The `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` column from the SKILL.md DDL skeleton only fires the default on INSERT. To keep `updated_at` accurate on every UPDATE, attach a trigger.

```sql
-- Reusable trigger function (define once per database)
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach per entity table
CREATE TRIGGER trg_user_accounts_updated_at
    BEFORE UPDATE ON user_accounts
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
```

**Alternative**: Manage `updated_at` at the application/ORM layer. Either is valid — pick one and apply consistently. Mixed strategies cause inconsistent `updated_at` values when one path forgets.

**Skip-update optimization**: The trigger above runs on every UPDATE even when the row didn't actually change. To skip no-op updates:

```sql
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW IS DISTINCT FROM OLD THEN
        NEW.updated_at = now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
