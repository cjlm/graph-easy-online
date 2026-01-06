# Plan: Graph Easy API using TypeScript Implementation

## Overview

Create a REST API for Graph Easy that uses the `graph-easy-ts` TypeScript library, enabling programmatic access to graph conversion functionality.

## Current State

- **Application Type**: Frontend-only SPA (React + Vite)
- **Rendering Engines**:
  - `graph-easy-ts` (TypeScript) - supports ASCII, Box Art, Text, Graphviz/DOT
  - WebPerl (WASM) - supports all formats including HTML, SVG, GraphML, VCG
- **Deployment**: Cloudflare Pages (based on `CF_PAGES` env variable in vite.config.ts)
- **No existing API endpoints**

## Proposed Solution

### Option A: Cloudflare Workers API (Recommended)

**Rationale**:
- Seamless integration with existing Cloudflare Pages deployment
- Serverless, auto-scaling, low latency at edge
- No additional infrastructure needed
- Free tier generous for API usage

**Implementation**:
- Create a Cloudflare Worker that exposes REST endpoints
- Use the `graph-easy-ts` library directly in the Worker
- Deploy alongside the existing Pages site

### Option B: Express.js API Server

**Rationale**:
- Traditional Node.js approach
- Easy to develop and test locally
- Can be deployed anywhere (Docker, VPS, etc.)

**Implementation**:
- Create new `/api` directory with Express server
- Use `graph-easy-ts` library for conversions
- Add scripts for running API locally and in production

### Option C: Vercel Serverless Functions

**Rationale**:
- Easy deployment if migrating to Vercel
- Auto-scaling serverless architecture

---

## Recommended Approach: Option A (Cloudflare Workers)

### API Design

#### Base URL
```
https://api.graph-easy.online/v1  (or subdomain of main site)
```

#### Endpoints

##### 1. Convert Graph (POST /convert)
Convert graph notation to various output formats.

**Request**:
```http
POST /v1/convert
Content-Type: application/json

{
  "input": "[A] -> [B] -> [C]",
  "format": "ascii",
  "options": {
    "seed": 12345
  }
}
```

**Response**:
```json
{
  "success": true,
  "output": "+---+     +---+     +---+\n| A | --> | B | --> | C |\n+---+     +---+     +---+",
  "format": "ascii",
  "timing_ms": 5
}
```

**Supported Formats**:
- `ascii` - ASCII art representation
- `boxart` - Unicode box drawing art
- `text` - Plain text representation
- `graphviz` / `dot` - Graphviz DOT format

##### 2. Parse Graph (POST /parse)
Parse graph notation and return structured graph data.

**Request**:
```http
POST /v1/parse
Content-Type: application/json

{
  "input": "[A] -> [B] -> [C]"
}
```

**Response**:
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
      {"from": "A", "to": "B", "label": ""},
      {"from": "B", "to": "C", "label": ""}
    ]
  }
}
```

##### 3. Health Check (GET /health)
```http
GET /v1/health

Response:
{
  "status": "ok",
  "version": "1.0.0",
  "engine": "graph-easy-ts"
}
```

##### 4. Formats Info (GET /formats)
```http
GET /v1/formats

Response:
{
  "formats": [
    {"id": "ascii", "name": "ASCII Art", "description": "Classic ASCII representation"},
    {"id": "boxart", "name": "Box Art", "description": "Unicode box drawing characters"},
    {"id": "text", "name": "Text", "description": "Plain text representation"},
    {"id": "graphviz", "name": "Graphviz/DOT", "description": "DOT format for Graphviz"}
  ]
}
```

### Error Handling

```json
{
  "success": false,
  "error": {
    "code": "PARSE_ERROR",
    "message": "Invalid graph syntax at line 2",
    "details": "Unexpected token ']' at position 15"
  }
}
```

**Error Codes**:
- `PARSE_ERROR` - Invalid graph notation syntax
- `INVALID_FORMAT` - Unsupported output format
- `INVALID_REQUEST` - Malformed request body
- `RATE_LIMITED` - Too many requests
- `INTERNAL_ERROR` - Server-side error

### Rate Limiting

- **Free Tier**: 100 requests/minute per IP
- **Headers**: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

---

## Implementation Steps

### Phase 1: Project Setup
1. Create `/api` directory for Cloudflare Worker code
2. Set up `wrangler.toml` configuration
3. Configure TypeScript for Worker environment
4. Add build scripts to `package.json`

### Phase 2: Core API Implementation
5. Create Worker entry point (`api/src/index.ts`)
6. Implement request routing
7. Integrate `graph-easy-ts` library
8. Implement `/convert` endpoint
9. Implement `/parse` endpoint
10. Implement `/health` and `/formats` endpoints

### Phase 3: Error Handling & Validation
11. Add input validation with helpful error messages
12. Implement error response formatting
13. Add request size limits (prevent abuse)

### Phase 4: Rate Limiting & Security
14. Implement rate limiting using Cloudflare's built-in capabilities or KV storage
15. Add CORS headers for browser usage
16. Add request logging

### Phase 5: Documentation & Testing
17. Create API documentation (OpenAPI/Swagger spec)
18. Write unit tests for conversion logic
19. Write integration tests for endpoints
20. Add example code snippets (curl, JavaScript, Python)

### Phase 6: Deployment
21. Configure Cloudflare Worker deployment
22. Set up CI/CD for automatic deployments
23. Configure custom domain (optional)

---

## File Structure

```
/api/
├── src/
│   ├── index.ts           # Worker entry point & router
│   ├── routes/
│   │   ├── convert.ts     # /convert endpoint
│   │   ├── parse.ts       # /parse endpoint
│   │   ├── health.ts      # /health endpoint
│   │   └── formats.ts     # /formats endpoint
│   ├── services/
│   │   └── graphService.ts # graph-easy-ts integration
│   ├── middleware/
│   │   ├── cors.ts        # CORS handling
│   │   ├── rateLimit.ts   # Rate limiting
│   │   └── validation.ts  # Request validation
│   ├── types/
│   │   └── api.ts         # API types & interfaces
│   └── utils/
│       └── response.ts    # Response helpers
├── wrangler.toml          # Cloudflare Worker config
├── tsconfig.json          # TypeScript config
├── package.json           # Dependencies
└── README.md              # API documentation
```

---

## Dependencies

```json
{
  "dependencies": {
    "graph-easy-ts": "github:fairfieldt/graph-easy-ts",
    "itty-router": "^5.0.0"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20240000",
    "wrangler": "^3.0.0",
    "typescript": "^5.0.0",
    "vitest": "^4.0.0"
  }
}
```

---

## Questions for Clarification

1. **Deployment preference**: Should we use Cloudflare Workers (recommended for your current setup) or a different platform (Express.js, Vercel)?

2. **API authentication**: Should the API be:
   - Fully public (with rate limiting)
   - Require API keys for higher limits
   - Both (free tier + authenticated tier)

3. **Custom domain**: Do you want the API on a subdomain like `api.graph-easy.online` or a path like `graph-easy.online/api`?

4. **WebPerl fallback**: Should the API also support WebPerl backend for formats not supported by graph-easy-ts (HTML, SVG, GraphML, VCG)?

5. **Additional features**: Any specific features needed beyond basic conversion?
   - Batch conversion (multiple graphs in one request)
   - Graph validation without rendering
   - Image output (SVG rendered to PNG)
