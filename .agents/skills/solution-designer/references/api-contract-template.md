# API Contract Template — Reference

Generate ONE section per endpoint in this format. Include ALL fields shown below.

## Example: POST /api/payments

### POST `/api/payments` — Create a new payment

**Auth**: Bearer JWT (roles: `user`, `admin`)

**Request body**:
```typescript
interface CreatePaymentRequest {
  amount: number;          // required, decimal, min 0.01, max 999999.99
  currency: "USD" | "PAB"; // required, ISO 4217
  card_token: string;      // required, from payment provider tokenization
  description?: string;    // optional, max 255 chars, sanitized
  metadata?: Record<string, string>; // optional, max 5 keys
}
```

**Response 201** (Created):
```typescript
interface PaymentResponse {
  id: string;              // UUID v4
  amount: number;
  currency: string;
  status: "pending" | "completed" | "failed";
  card_last_four: string;  // "4242"
  card_brand: string;      // "visa" | "mastercard"
  description: string | null;
  created_at: string;      // ISO 8601
  updated_at: string;      // ISO 8601
}
```

**Error responses**:
| Status | When | Body |
|--------|------|------|
| 400 | Validation failed (missing field, invalid amount) | `{ error: "VALIDATION_ERROR", message: "amount must be > 0", field: "amount" }` |
| 401 | Missing or invalid JWT | `{ error: "UNAUTHORIZED", message: "Invalid or expired token" }` |
| 402 | Payment declined by provider | `{ error: "PAYMENT_FAILED", message: "Card declined", decline_code: "insufficient_funds" }` |
| 404 | Resource not found | `{ error: "NOT_FOUND", message: "Resource not found" }` |
| 429 | Rate limit exceeded | `{ error: "RATE_LIMITED", message: "Too many requests", retry_after: 60 }` |

**Rate limit**: 10 requests/minute per user

**Example**:
```bash
curl -X POST https://api.example.com/api/payments \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 150.00,
    "currency": "USD",
    "card_token": "tok_visa_4242",
    "description": "Monthly subscription"
  }'
```

**Notes**:
- `card_token` is single-use, expires in 15 minutes
- `amount` is stored as integer cents internally (15000 = $150.00)
- Idempotency: include `Idempotency-Key` header for safe retries

---

## Rules for generating API contracts

1. ALWAYS include TypeScript interfaces for request AND response
2. ALWAYS include validation rules as inline comments
3. ALWAYS list ALL error status codes with example body
4. ALWAYS include at least one curl example
5. ALWAYS specify auth requirements (none, JWT, API key, roles)
6. ALWAYS specify rate limits if applicable
7. For GET endpoints with query params, use `interface` for params too
8. For paginated endpoints, include pagination response format:
   ```typescript
   interface PaginatedResponse<T> {
     data: T[];
     pagination: {
       page: number;
       per_page: number;
       total: number;
       total_pages: number;
     };
   }
   ```
9. Group endpoints by resource (e.g., all /payments/* together)
10. Include relationship to DB schema (which table/columns each field maps to)
