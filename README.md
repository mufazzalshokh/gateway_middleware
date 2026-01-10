# Gateway/Provider Middleware - Ruby on Rails

A middleware application that sits between a Gateway system and a Provider system, handling transaction initialization and authorization.

## Overview

This application acts as an intermediary:
1. **Gateway → Our System**: Receives transaction initialization requests
2. **Our System → Provider**: Forwards requests to provider's API
3. **Our System → Gateway**: Returns redirect URLs for user authorization
4. **User → Our System → Provider**: Handles authorization flow

## Architecture

```
Gateway → POST /gateway/transactions → Our System → Provider (init)
                                           ↓
                                    Generate redirect_url
                                           ↓
User → GET /transactions/auth/:id → Our System → Provider (auth)
                                           ↓
                                    Display result
```

## Prerequisites

- Ruby 2.7+
- Rails 6.0+
- SQLite3
- Bundler

## Installation

1. Clone the repository and navigate to the project directory

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:create
rails db:migrate
```

4. (Optional) Set environment variables:
```bash
export PROVIDER_BASE_URL=https://provider.example.com
export PROVIDER_API_KEY=your_api_key
```

## Running the Application

Start the Rails server:
```bash
rails server
```

The application will be available at `http://localhost:3000`

## Running Tests

Run the full test suite:
```bash
bundle exec rspec
```

Run specific test files:
```bash
bundle exec rspec spec/controllers/gateway/transactions_controller_spec.rb
bundle exec rspec spec/services/provider_service_spec.rb
```

With coverage:
```bash
COVERAGE=true bundle exec rspec
```

## API Endpoints

### 1. Initialize Transaction (Gateway → System)

**Endpoint:** `POST /gateway/transactions`

**Request Body:**
```json
{
  "amount": 1000,
  "currency": "EUR",
  "id": "unique_id_123"
}
```

**Success Response (201):**
```json
{
  "redirect_url": "https://our-app.test/transactions/auth/123"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid parameters
- `503 Service Unavailable`: Provider unavailable
- `422 Unprocessable Entity`: Duplicate transaction

### 2. Authorize Transaction (User → System)

**Endpoint:** `GET /transactions/auth/:id`

**Success Response (200):**
```
success
```

**Failure Response (200):**
```
failed
```

**Error Responses:**
- `404 Not Found`: Transaction doesn't exist
- `400 Bad Request`: Invalid transaction ID format
- `503 Service Unavailable`: Provider unavailable

## Testing Strategy

All tests use **WebMock** to stub HTTP requests - no real external calls are made.

### Test Coverage:

1. **Service Layer** (`spec/services/provider_service_spec.rb`)
   - Successful API calls
   - Error handling
   - Timeout scenarios
   - Invalid JSON responses

2. **Gateway Controller** (`spec/controllers/gateway/transactions_controller_spec.rb`)
   - Valid transaction creation
   - Input validation
   - Provider unavailability
   - Duplicate transaction prevention

3. **Transactions Controller** (`spec/controllers/transactions_controller_spec.rb`)
   - Successful authorization
   - Failed authorization
   - Transaction not found
   - Security (injection attacks)
   - Provider errors

4. **Model** (`spec/models/transaction_spec.rb`)
   - Validations
   - Scopes
   - Data integrity

## Security Features

See `SECURITY_ANALYSIS.md` for detailed security analysis.

**Key Security Features:**
- ✅ Input validation (prevents SQL injection, path traversal)
- ✅ Request timeouts (10 seconds)
- ✅ Secure error handling (no information leakage)
- ✅ Duplicate transaction prevention
- ✅ HTTPS enforcement for provider communication
- ✅ Transaction ID format validation

**Recommended for Production:**
- Rate limiting (rack-attack)
- API authentication (HMAC signatures)
- Enhanced logging and monitoring
- WAF integration

## Project Structure

```
app/
├── controllers/
│   ├── gateway/
│   │   └── transactions_controller.rb    # Gateway endpoint
│   └── transactions_controller.rb        # User-facing endpoint
├── models/
│   └── transaction.rb                    # Transaction model
└── services/
    └── provider_service.rb               # Provider API client

spec/
├── controllers/
│   ├── gateway/
│   │   └── transactions_controller_spec.rb
│   └── transactions_controller_spec.rb
├── models/
│   └── transaction_spec.rb
└── services/
    └── provider_service_spec.rb

config/
└── routes.rb                             # API routes
```

## Database Schema

**transactions table:**
- `id`: Primary key
- `external_id`: Unique ID from Gateway (unique index)
- `provider_transaction_id`: Transaction ID from Provider
- `amount`: Transaction amount (integer, cents)
- `currency`: Currency code (3 letters, e.g., EUR)
- `status`: Transaction status (pending/success/failed/error)
- `created_at`: Timestamp
- `updated_at`: Timestamp

## Development Notes

### Key Design Decisions:

1. **Service Object Pattern**: `ProviderService` encapsulates all provider communication
2. **Error Handling**: Custom `ProviderError` exception for all provider-related errors
3. **Input Validation**: Both controller-level and model-level validations
4. **Test Isolation**: All external HTTP calls stubbed using WebMock
5. **Security First**: Input sanitization, timeout protection, secure error messages

### Future Enhancements:

- [ ] Add authentication/authorization
- [ ] Implement rate limiting
- [ ] Add request/response logging
- [ ] Implement retry logic for provider calls
- [ ] Add monitoring and alerting
- [ ] Support multiple providers
- [ ] Add admin dashboard

## Contributing

1. Write tests first (TDD approach)
2. Ensure all tests pass: `bundle exec rspec`
3. Follow Ruby style guide
4. Update documentation as needed

## License

This project is for evaluation purposes.
