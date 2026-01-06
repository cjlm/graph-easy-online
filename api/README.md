# Graph Easy API

REST API for converting graph notation to various output formats using [graph-easy-ts](https://github.com/fairfieldt/graph-easy-ts).

## Quick Start

```bash
# Install dependencies
npm install

# Run locally
npm run dev

# Deploy to Cloudflare Workers
npm run deploy
```

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/convert` | POST | Convert graph notation |
| `/api/v1/parse` | POST | Parse graph to structured data |
| `/api/v1/health` | GET | Health check |
| `/api/v1/formats` | GET | List supported formats |

## Examples

### Convert to ASCII

```bash
curl -X POST http://localhost:8787/api/v1/convert \
  -H "Content-Type: application/json" \
  -d '{"input": "[A] -> [B] -> [C]", "format": "ascii"}'
```

### Parse Graph

```bash
curl -X POST http://localhost:8787/api/v1/parse \
  -H "Content-Type: application/json" \
  -d '{"input": "[A] -> [B] -> [C]"}'
```

## Supported Formats

- `ascii` - ASCII art representation
- `boxart` - Unicode box drawing characters
- `text` - Plain text representation
- `graphviz` / `dot` - Graphviz DOT format

## Rate Limiting

- 100 requests per minute per IP
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## License

Same as the main project.
