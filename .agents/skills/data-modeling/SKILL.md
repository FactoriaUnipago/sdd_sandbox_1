---
name: Data Modeling Standards
description: Every data model MUST satisfy Third Normal Form before presenting to user for approval. Denormalization is allowed ONLY with documented justification.
---

# Data Modeling Standards

## Normalization Rules (up to 3NF)

Every data model MUST satisfy Third Normal Form before presenting to user for approval. Denormalization is allowed ONLY with documented justification.

### 1NF — Atomic Values

| Rule | Violation example | Fix |
|------|------------------|-----|
| Every column holds ONE value | `tags: "api,auth,db"` | Separate `tags` table with FK |
| No repeating groups | `phone1, phone2, phone3` | Separate `phones` table with FK |
| Every row has a unique PK | Table without PK | Add `id` (UUID or serial) |
| Column names describe ONE attribute | `name_and_email` | Split into `name`, `email` |

```
-- ❌ BAD: repeating groups
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  phone1 VARCHAR(20),
  phone2 VARCHAR(20),
  phone3 VARCHAR(20)
);

-- ✅ GOOD: separate table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);
CREATE TABLE user_phones (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  phone VARCHAR(20) NOT NULL,
  type VARCHAR(10) DEFAULT 'mobile'
);
```

### 2NF — No Partial Dependencies

Applies to tables with **composite primary keys**. Every non-key column must depend on the ENTIRE key.

| Rule | Violation example | Fix |
|------|------------------|-----|
| Non-key depends on full PK | `order_items(order_id, product_id, product_name)` — `product_name` depends only on `product_id` | Move `product_name` to `products` table |
| No subset dependency | Attribute determined by part of composite key | Extract to its own table |

```
-- ❌ BAD: product_name depends only on product_id (partial dependency)
CREATE TABLE order_items (
  order_id INT,
  product_id INT,
  product_name VARCHAR(100),  -- depends on product_id only
  quantity INT,
  PRIMARY KEY (order_id, product_id)
);

-- ✅ GOOD: product_name in products table
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);
CREATE TABLE order_items (
  order_id INT REFERENCES orders(id),
  product_id INT REFERENCES products(id),
  quantity INT NOT NULL,
  PRIMARY KEY (order_id, product_id)
);
```

### 3NF — No Transitive Dependencies

Every non-key column depends ONLY on the primary key, not on another non-key column.

| Rule | Violation example | Fix |
|------|------------------|-----|
| No column depends on non-key | `employees(id, dept_id, dept_name)` — `dept_name` depends on `dept_id`, not on `id` | Move `dept_name` to `departments` table |
| No derived/calculated storage | `price, quantity, total` — `total` is derived | Compute at query time or use generated column |
| No lookup values inline | `status: "active"` repeated 10K times | `status_id` FK → `statuses` table (if >5 values) |

```
-- ❌ BAD: dept_name depends on dept_id (transitive dependency)
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  dept_id INT,
  dept_name VARCHAR(50)  -- depends on dept_id, not on id
);

-- ✅ GOOD: department in its own table
CREATE TABLE departments (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  dept_id INT REFERENCES departments(id)
);
```

---

## Denormalization — When Allowed

Denormalization is acceptable ONLY when:

| Condition | Example | Document as |
|-----------|---------|-------------|
| Read-heavy query optimization | Dashboard aggregation table | ADR: "Denormalized for read performance" |
| Avoiding expensive JOINs in hot paths | Caching user display_name on comments | Comment in migration + design.md |
| Reporting/analytics tables | Materialized view or summary table | Separate schema (e.g., `analytics.`) |
| NoSQL constraints | DynamoDB single-table design | Follow `dynamodb.md` steering |

**Rule**: ALWAYS document denormalization decisions in `design.md § Data Model` with:
- Which normal form it violates
- Why (measured performance need, not premature optimization)
- How consistency is maintained (triggers, application logic, eventual sync)

---

## Validation Checklist

Before presenting a data model in `design.md`, verify:

```
1NF:
- [ ] Every column is atomic (no CSV, no JSON arrays for structured data)
- [ ] No repeating column groups (phone1/phone2/phone3)
- [ ] Every table has a primary key
- [ ] No multi-value columns

2NF:
- [ ] No partial dependencies on composite keys
- [ ] If composite PK exists → every non-key depends on FULL key

3NF:
- [ ] No transitive dependencies (non-key → non-key)
- [ ] No derived/calculated columns stored (unless generated column)
- [ ] Lookup values with >5 distinct values use FK to reference table
- [ ] No repeated string values that should be a separate entity

General:
- [ ] FKs have ON DELETE policy (CASCADE / SET NULL / RESTRICT)
- [ ] Indexes on FK columns and frequent WHERE/ORDER BY columns
- [ ] Timestamps: created_at (NOT NULL DEFAULT NOW), updated_at
- [ ] Soft delete: deleted_at nullable (if applicable per project conventions)
- [ ] Table names: snake_case, plural (users, order_items)
- [ ] Column names: snake_case, singular (user_id, created_at)
```

---

## Common Anti-Patterns

| Anti-Pattern | NF Violation | Fix |
|-------------|-------------|-----|
| God table (20+ columns) | Usually 2NF/3NF | Split into related tables |
| CSV in column | 1NF | Junction table |
| JSON column for structured data | 1NF | Separate table with proper columns |
| Storing age instead of birth_date | 3NF (derived) | Store birth_date, compute age |
| Country name + country code in same table | 3NF (transitive) | `countries` reference table |
| `status VARCHAR` with 3 values | Not a violation but smell | ENUM type or check constraint |
| `is_active, is_deleted, is_archived` | Redundant states | Single `status` column |
| EAV (Entity-Attribute-Value) | Breaks all NFs | Proper schema or JSONB (document) |

## JSON/JSONB Exception

JSONB columns are acceptable for:
- **Unstructured metadata** (user preferences, external API responses)
- **Flexible schemas** where structure varies per row
- **Audit logs** (storing snapshots)

JSONB is NOT acceptable for:
- Data you query with WHERE/JOIN regularly → normalize it
- Data with known, fixed structure → use proper columns
- Relationships between entities → use FKs

