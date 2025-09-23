API Reference

No public HTTP API endpoints are currently implemented in this repository.

Use this template when adding endpoints:

Endpoint: METHOD /path
Description: One-line description
Auth: e.g., Bearer token (if applicable)
Request
Headers:
- Content-Type: application/json
Body:
{
  "example": true
}

Response 200
{
  "ok": true
}

Errors
- 400: ValidationError — reason
- 401: Unauthorized — reason
- 500: InternalError — reason

Curl example
curl -X POST "https://api.example.com/path" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"example": true}'

