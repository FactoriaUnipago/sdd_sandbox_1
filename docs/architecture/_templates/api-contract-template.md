<!-- ⚠️ TEMPLATE — Este archivo fue generado por sdd-sync.sh. Llénalo con la información de tu proyecto. -->
<!-- Los powers (solution-designer, project-scanner, db-migrator) lo actualizan automáticamente. -->
# API Contract

> 📋 **TEMPLATE** — Reemplaza los placeholders con la información real de tu proyecto. Los powers lo actualizan automáticamente cuando features modifican la arquitectura.

## Base URL
| Environment | URL |
|-------------|-----|
| DEV | `https://dev-api.example.com` |
| CERT | `https://cert-api.example.com` |
| PROD | `https://api.example.com` |

## Endpoints
| Method | Path | Auth | Description | Feature |
|--------|------|------|-------------|---------|
| POST | `/api/v1/auth/login` | Public | Autenticación de usuario | auth |
| POST | `/api/v1/auth/refresh` | Refresh token | Renovar access token | auth |
| GET | `/api/v1/orders` | Bearer JWT | Listar órdenes del usuario | orders |
| POST | `/api/v1/orders` | Bearer JWT (role: user) | Crear nueva orden | orders |
| GET | `/api/v1/products` | Bearer JWT | Listar productos activos | catalog |

### POST /api/v1/orders
- **Auth**: Bearer JWT (role: `user`)
- **Rate limit**: 100 req/min
- **Request**:
  ```json
  {
    "product_id": "uuid",
    "quantity": 2
  }
  ```
- **Response 201**:
  ```json
  {
    "id": "uuid",
    "status": "pending",
    "total": 49.98,
    "created_at": "2026-01-01T00:00:00Z"
  }
  ```
- **Errors**: `400` (validation), `401` (unauthorized), `429` (rate limit)

## Authentication
<!-- Estrategia de autenticación -->
- **Método**: JWT (JSON Web Tokens)
- **Header**: `Authorization: Bearer {access_token}`
- **Expiración**: Access token 15 min, Refresh token 7 días
- **Algoritmo**: RS256

## Error Format
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": {}
  }
}
```

Códigos de error estándar:
| HTTP Status | Code | Descripción |
|-------------|------|-------------|
| 400 | `VALIDATION_ERROR` | Datos de entrada inválidos |
| 401 | `UNAUTHORIZED` | Token ausente o expirado |
| 403 | `FORBIDDEN` | Sin permisos para el recurso |
| 404 | `NOT_FOUND` | Recurso no encontrado |
| 429 | `RATE_LIMITED` | Límite de requests excedido |
| 500 | `INTERNAL_ERROR` | Error interno del servidor |

## Versionamiento
- **Estrategia**: URL prefix → `/api/v1/`, `/api/v2/`
- **Header adicional**: `X-API-Version: 1` (informativo, no routing)
- **Deprecación**: Mínimo 6 meses de aviso antes de retirar una versión. Header `Deprecation: true` + `Sunset: <date>` en respuestas de versiones deprecadas.
- **Compatibilidad**: Cambios backward-compatible dentro de la misma versión (agregar campos opcionales, nuevos endpoints). Breaking changes requieren nueva versión.

## Rate Limiting
| Tipo de endpoint | Límite | Ventana | Header de respuesta |
|------------------|--------|---------|---------------------|
| Autenticación (`/auth/*`) | 10 req | 1 min | `X-RateLimit-Remaining` |
| Lectura (GET) | 200 req | 1 min | `X-RateLimit-Remaining` |
| Escritura (POST/PUT/DELETE) | 100 req | 1 min | `X-RateLimit-Remaining` |
| Uploads | 10 req | 10 min | `X-RateLimit-Remaining` |

Respuesta cuando se excede: `429 Too Many Requests` con header `Retry-After: <seconds>`.

## Paginación
Estrategia: **cursor-based pagination** para listas ordenadas.

**Request**:
```
GET /api/v1/orders?cursor=eyJpZCI6MTAwfQ&limit=20
```

**Response**:
```json
{
  "data": [ ... ],
  "pagination": {
    "cursor": "eyJpZCI6MTIwfQ",
    "limit": 20,
    "has_more": true
  }
}
```

- `cursor`: opaco, codificado en base64. Omitir para la primera página.
- `limit`: máximo 100, default 20.
- `has_more`: `true` si existen más registros.

## Ejemplo curl
```bash
# Login
curl -X POST https://dev-api.example.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secret123"}'

# Crear orden (con token obtenido del login)
curl -X POST https://dev-api.example.com/api/v1/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIs..." \
  -d '{"product_id": "550e8400-e29b-41d4-a716-446655440000", "quantity": 2}'
```

## Changelog
| Date | Feature | Change |
|------|---------|--------|

---
_Last updated: [date] by [feature]_
