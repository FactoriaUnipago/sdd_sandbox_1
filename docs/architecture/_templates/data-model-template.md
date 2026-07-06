<!-- ⚠️ TEMPLATE — Este archivo fue generado por sdd-sync.sh. Llénalo con la información de tu proyecto. -->
<!-- Los powers (solution-designer, project-scanner, db-migrator) lo actualizan automáticamente. -->
# Data Model

> 📋 **TEMPLATE** — Reemplaza los placeholders con la información real de tu proyecto. Los powers lo actualizan automáticamente cuando features modifican la arquitectura.

## Entity Relationship Diagram
```mermaid
erDiagram
    USERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : "included in"
    USERS {
        uuid id PK
        string email UK
        string name
        timestamp created_at
    }
    ORDERS {
        uuid id PK
        uuid user_id FK
        decimal total
        string status
        timestamp created_at
    }
    PRODUCTS {
        uuid id PK
        string name
        decimal price
        boolean active
    }
    ORDER_ITEMS {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        int quantity
        decimal unit_price
    }
```

## Entities
<!-- Una sección por tabla/entidad -->

### USERS
| Column | Type | Nullable | Default | Index | Description |
|--------|------|----------|---------|-------|-------------|
| id | `uuid` | NO | `gen_random_uuid()` | PK | Identificador único del usuario |
| email | `varchar(255)` | NO | — | UNIQUE | Email del usuario, usado para login |
| name | `varchar(150)` | NO | — | — | Nombre completo |
| password_hash | `varchar(255)` | NO | — | — | Hash bcrypt del password |
| role | `varchar(20)` | NO | `'user'` | IDX | Rol: `admin`, `user`, `guest` |
| active | `boolean` | NO | `true` | — | Soft delete flag |
| created_at | `timestamptz` | NO | `now()` | IDX | Fecha de creación |
| updated_at | `timestamptz` | NO | `now()` | — | Última actualización (trigger) |

### [Entity Name]
| Column | Type | Nullable | Default | Index | Description |
|--------|------|----------|---------|-------|-------------|
<!-- Agrega las columnas de la entidad -->

## Relationships
| From | To | Type | FK | ON DELETE |
|------|-----|------|------|-----------|
| ORDERS | USERS | Many-to-One | `orders.user_id → users.id` | CASCADE |
| ORDER_ITEMS | ORDERS | Many-to-One | `order_items.order_id → orders.id` | CASCADE |
| ORDER_ITEMS | PRODUCTS | Many-to-One | `order_items.product_id → products.id` | RESTRICT |

## Migraciones
- **Convención de nombres**: `YYYYMMDDHHMMSS_description.sql` (ejemplo: `20260101120000_create_users_table.sql`)
- **Herramienta**: Prisma Migrate / Knex / TypeORM (seleccionar según el proyecto)
- **Reglas**:
  - Cada migración debe ser idempotente y reversible (`up` / `down`).
  - No modificar migraciones ya aplicadas en `cert` o `prod`.
  - Incluir índices y constraints en la misma migración que crea la tabla.
  - Migraciones de datos separadas de migraciones de esquema.
- **Ejecución**:
  - DEV: `npm run migrate:dev` (auto-apply)
  - CERT/PROD: `npm run migrate:deploy` (requiere aprobación)

## Seeds
- Utilizar el power `test-data-generator` para generar datos de prueba consistentes.
- Archivo de seeds: `prisma/seed.ts` o `seeds/` directory.
- **Entornos**:
  - DEV: seeds completos con datos de prueba variados.
  - CERT: subset representativo con datos anonimizados.
  - PROD: solo datos de referencia (catálogos, roles, configuración).

## Changelog
| Date | Feature | Change |
|------|---------|--------|

---
_Last updated: [date] by [feature]_
