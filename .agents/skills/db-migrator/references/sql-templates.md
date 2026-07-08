# SQL Templates & Examples

## CREATE TABLE
```sql
CREATE TABLE {table} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  {columns...},
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## ALTER TABLE
```sql
-- Add column
ALTER TABLE {table} ADD COLUMN {col} {type} {constraints};
-- Modify column (⚠️ requires USING for conversion)
ALTER TABLE {table} ALTER COLUMN {col} TYPE {new_type} USING {col}::{new_type};
-- Drop column (⚠️ DESTRUCTIVE — double confirmation)
ALTER TABLE {table} DROP COLUMN IF EXISTS {col};
```

## INDEX / CONSTRAINT
```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_{table}_{col} ON {table} ({col});
ALTER TABLE {table} ADD CONSTRAINT {name} {definition};
```

## DATA Migration
```sql
-- Must be idempotent
UPDATE {table} SET {col} = {val} WHERE {condition} AND {col} IS DISTINCT FROM {val};
```

## Migration Output Format
```sql
-- ============================================================
-- Migration: {NNN}_{description}
-- Date: {YYYY-MM-DD}
-- Author: AI DB Migrator (Power)
-- Description: {what this migration does}
-- Affected Tables: {tables}
-- Destructive: YES | NO
-- ============================================================

-- ==================== UP ====================
{SQL statements}

-- ==================== DOWN ====================
{Rollback SQL statements}

-- ==================== VERIFICATION ====================
-- 1. {verification query}
```

## Example: `001_add_payments_table.sql`
```sql
-- Migration: 001_add_payments_table | Date: 2026-06-28
-- Affected Tables: payments (NEW) | Destructive: NO

-- UP
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','failed','refunded')),
  description VARCHAR(255),
  payment_method VARCHAR(50) NOT NULL,
  external_reference VARCHAR(100),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX CONCURRENTLY idx_payments_user_id ON payments (user_id);
CREATE INDEX CONCURRENTLY idx_payments_status ON payments (status);
CREATE INDEX CONCURRENTLY idx_payments_created_at ON payments (created_at DESC);

-- DOWN
DROP TABLE IF EXISTS payments;
```
