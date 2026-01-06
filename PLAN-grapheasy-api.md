# Plan: Graph Easy API using TypeScript Implementation

## Status: IMPLEMENTED

## Decisions Made

| Question | Decision |
|----------|----------|
| Deployment platform | Cloudflare Workers |
| Authentication | Fully public with rate limiting (100 req/min per IP) |
| API location | `/api` path (portable, others can deploy) |
| WebPerl fallback | No - TS implementation only |
| Additional features | None for v1 |

---

## Overview

REST API for Graph Easy that uses the `graph-easy-ts` TypeScript library, enabling programmatic access to graph conversion functionality.

## API Endpoints

### Base Path: `/api`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/convert` | POST | Convert graph notation to ASCII, Box Art, Text, or DOT |
| `/api/v1/parse` | POST | Parse graph and return structured node/edge data |
| `/api/v1/health` | GET | Health check |
| `/api/v1/formats` | GET | List supported formats |
| `/api/` | GET | API info and available endpoints |

Routes are also available without the `/v1` prefix for convenience.

---

## Usage Examples

### Convert Graph (POST /api/v1/convert)

```bash
curl -X POST https://your-domain.com/api/v1/convert \
  -H "Content-Type: application/json" \
  -d '{"input": "[A] -> [B] -> [C]", "format": "ascii"}'
```

**Response:**
```json
{
  "success": true,
  "output": "+---+     +---+     +---+\n| A | --> | B | --> | C |\n+---+     +---+     +---+",
  "format": "ascii",
  "timing_ms": 5
}
```

**Supported Formats:** `ascii`, `boxart`, `text`, `graphviz`, `dot`

### Parse Graph (POST /api/v1/parse)

```bash
curl -X POST https://your-domain.com/api/v1/parse \
  -H "Content-Type: application/json" \
  -d '{"input": "[A] -> [B] -> [C]"}'
```

**Response:**
```json
{
  "success": true,
  "graph": {
    "nodes": [
      {"id": "A", "label": "A"},
      {"id": "B", "label": "B"},
      {"id": "C", "label": "C"}
    ],
    "edges": [
      {"from": "A", "to": "B"},
      {"from": "B", "to": "C"}
    ]
  }
}
```

### Health Check (GET /api/v1/health)

```bash
curl https://your-domain.com/api/v1/health
```

**Response:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "engine": "graph-easy-ts"
}
```

---

## Error Handling

```json
{
  "success": false,
  "error": {
    "code": "PARSE_ERROR",
    "message": "Failed to parse graph notation",
    "details": "Unexpected token at position 15"
  }
}
```

**Error Codes:**
- `PARSE_ERROR` - Invalid graph notation syntax
- `INVALID_FORMAT` - Unsupported output format
- `INVALID_REQUEST` - Malformed request body
- `RATE_LIMITED` - Too many requests (100/min exceeded)
- `NOT_FOUND` - Endpoint not found
- `INTERNAL_ERROR` - Server-side error

---

## Rate Limiting

- **Limit:** 100 requests per minute per IP
- **Headers included in responses:**
  - `X-RateLimit-Limit` - Maximum requests allowed
  - `X-RateLimit-Remaining` - Requests remaining in window
  - `X-RateLimit-Reset` - Unix timestamp when limit resets

---

## File Structure

```
/api/
├── src/
│   ├── index.ts              # Worker entry point & router
│   ├── routes/
│   │   ├── convert.ts        # /convert endpoint
│   │   ├── parse.ts          # /parse endpoint
│   │   ├── health.ts         # /health endpoint
│   │   └── formats.ts        # /formats endpoint
│   ├── services/
│   │   └── graphService.ts   # graph-easy-ts integration
│   ├── middleware/
│   │   ├── cors.ts           # CORS handling
│   │   └── rateLimit.ts      # Rate limiting
│   ├── types/
│   │   └── api.ts            # API types & interfaces
│   └── utils/
│       └── response.ts       # Response helpers
├── wrangler.toml             # Cloudflare Worker config
├── tsconfig.json             # TypeScript config
└── package.json              # Dependencies
```

---

## Development

```bash
cd api

# Install dependencies
npm install

# Run locally
npm run dev

# Deploy to Cloudflare
npm run deploy
```

---

## Deployment Notes

The API is designed to be deployed as a Cloudflare Worker. The `/api` path makes it portable - others can deploy their own instance.

For production deployment alongside the main site, configure the Worker route in `wrangler.toml` to handle `/api/*` requests.
