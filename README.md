# 💳 Gateway Middleware — Payment Transaction Middleware (Ruby on Rails)

A Rails middleware application that sits between a Gateway system and a Payment
Provider, handling transaction initialization, authorization, and state management.
Built with service-object architecture, full RSpec coverage, and a security analysis
document covering 12 attack vectors.

![Ruby](https://img.shields.io/badge/ruby-2.7+-red)
![Rails](https://img.shields.io/badge/rails-6.0+-red)
![RuboCop](https://img.shields.io/badge/code%20style-rubocop-blue)

## Overview

```
Gateway ──POST /gateway/transactions──► Our System ──► Provider (init)
                                             │
                                      Save transaction
                                      Generate redirect_url
                                             │
                                             ▼
User ──GET /transactions/auth/:id──► Our System ──► Provider (authorize)
                                             │
                                      Update status
                                             │
                                             ▼
                                      Display result
```

**Three-party flow:**
1. Gateway sends a transaction initialization request to our system
2. We forward it to the Provider, get back a `transaction_id`
3. We return a `redirect_url` to the Gateway for user authorization
4. User hits the auth URL → we call Provider to complete authorization

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1 |
| Database | SQLite3 (dev) → PostgreSQL-ready |
| HTTP Client | HTTParty |
| Testing | RSpec + WebMock (all external calls stubbed) |
| Linting | RuboCop |
| Security Scan | Brakeman + bundler-audit |
| CI | GitHub Actions (4 jobs: security scan, lint, test, system test) |

## API Reference

### POST /gateway/transactions
Receives a transaction from the Gateway, initializes it with the Provider.

**Request:**
```json
{ "amount": 1000, "currency": "EUR", "id": "unique_id_123" }
```

**Responses:**

| Status | Meaning |
|---|---|
| `201 Created` | `{ "redirect_url": "https://our-app/transactions/auth/123" }` |
| `400 Bad Request` | Invalid or missing parameters |
| `422 Unprocessable Entity` | Duplicate `external_id` |
| `503 Service Unavailable` | Provider timeout or error |

### GET /transactions/auth/:id
User-facing authorization endpoint.

| Status | Response |
|---|---|
| `200` | `success` or `failed` |
| `400` | Invalid transaction ID format |
| `404` | Transaction not found |
| `503` | Provider unavailable |

## Project Structure

```
gateway_middleware/
├── app/
│   ├── controllers/
│   │   ├── gateway/
│   │   │   └── transactions_controller.rb  # Gateway-facing endpoint
│   │   └── transactions_controller.rb      # User-facing auth endpoint
│   ├── models/
│   │   └── transaction.rb                  # Validations + scopes
│   └── services/
│       └── provider_service.rb             # Provider API client (HTTParty)
├── spec/
│   ├── controllers/gateway/
│   │   └── transactions_controller_spec.rb
│   ├── models/
│   │   └── transaction_spec.rb
│   └── services/
│       └── provider_service_spec.rb
├── .github/workflows/ci.yml                # 4-job CI pipeline
├── SECURITY_ANALYSISA.md                   # 12-vector security analysis
└── db/schema.rb
```

## Database Schema

```
transactions
├── id                      integer   PK
├── external_id             string    UNIQUE — Gateway's transaction ID
├── provider_transaction_id string    — Provider's transaction ID
├── amount                  integer   — Amount in cents
├── currency                string    — ISO 4217 (e.g. EUR, USD)
├── status                  string    — pending | success | failed | error
├── created_at              datetime
└── updated_at              datetime
```

## Security

Full analysis documented in [`SECURITY_ANALYSISA.md`](./SECURITY_ANALYSISA.md).
**12 attack vectors analysed** — 4 mitigated in code, 8 documented with
production recommendations.

**Implemented:**

| Protection | Implementation |
|---|---|
| Input validation | Regex `/\A[a-zA-Z0-9_-]+\z/` blocks SQL injection + path traversal |
| Duplicate prevention | `external_id` unique index — idempotent by design |
| Timeout protection | 10s hard timeout on all provider HTTP calls |
| Error isolation | Generic messages returned; detail only logged server-side |
| HTTPS enforcement | HTTParty base_uri uses `https://` with TLS verification |

**Recommended for production:** rate limiting (rack-attack), HMAC signature
verification on gateway requests, WAF integration.

## CI Pipeline

```yaml
CI on push/PR:
  ├── scan_ruby   → Brakeman (Rails security scan) + bundler-audit (gem CVEs)
  ├── lint        → RuboCop with cache
  ├── test        → RSpec full suite
  └── system-test → Rails system tests + screenshot upload on failure
```

## Testing Strategy

All external HTTP calls stubbed via **WebMock** — no real provider calls in tests.

| Spec | Coverage |
|---|---|
| `provider_service_spec.rb` | Success, 500 error, invalid JSON, timeout |
| `transactions_controller_spec.rb` | Valid create, missing params, zero amount, provider down, duplicate ID |
| `transactions_spec.rb` (model) | Validations, scopes, data integrity |

## Getting Started

```bash
git clone https://github.com/mufazzalshokh/gateway_middleware.git
cd gateway_middleware
bundle install
rails db:create db:migrate

# Optional: set provider credentials
export PROVIDER_BASE_URL=https://provider.example.com
export PROVIDER_API_KEY=your_api_key

rails server
```

**Run tests:**
```bash
bundle exec rspec                                         # full suite
bundle exec rspec spec/services/provider_service_spec.rb  # service only
COVERAGE=true bundle exec rspec                           # with coverage
```

## Key Design Decisions

- **Service Object pattern** — `ProviderService` encapsulates all provider
  communication. Controllers stay thin; business logic stays testable.
- **Custom `ProviderError` exception** — all provider failure modes (timeout,
  5xx, invalid JSON) surface as one exception type, simplifying controller
  rescue blocks.
- **Regex input sanitisation at controller level** — transaction IDs validated
  before they touch the DB or the provider, blocking injection at the entry point.
- **WebMock for all tests** — tests are deterministic, fast, and never make
  real HTTP calls. Timeout scenarios are explicitly tested.
- **`external_id` unique index** — replay protection at the DB level, not just
  application level.
