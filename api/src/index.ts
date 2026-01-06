import { Router, error } from 'itty-router';
import { handleConvert } from './routes/convert';
import { handleParse } from './routes/parse';
import { handleHealth } from './routes/health';
import { handleFormats } from './routes/formats';
import { handleCors, addCorsHeaders } from './middleware/cors';
import { checkRateLimit, rateLimitHeaders } from './middleware/rateLimit';
import { rateLimitedError, jsonResponse } from './utils/response';

const router = Router();

// API v1 routes
router.get('/v1/health', handleHealth);
router.get('/v1/formats', handleFormats);
router.post('/v1/convert', handleConvert);
router.post('/v1/parse', handleParse);

// Also support routes without /v1 prefix for simplicity
router.get('/health', handleHealth);
router.get('/formats', handleFormats);
router.post('/convert', handleConvert);
router.post('/parse', handleParse);

// Root endpoint with API info
router.get('/', () => {
  return jsonResponse({
    name: 'Graph Easy API',
    version: '1.0.0',
    engine: 'graph-easy-ts',
    endpoints: {
      convert: 'POST /v1/convert',
      parse: 'POST /v1/parse',
      health: 'GET /v1/health',
      formats: 'GET /v1/formats',
    },
    documentation: 'https://github.com/cjlm/graph-easy-online',
  });
});

// 404 for unmatched routes
router.all('*', () => {
  return jsonResponse(
    {
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: 'Endpoint not found',
      },
    },
    404
  );
});

export default {
  async fetch(request: Request, _env: unknown, _ctx: ExecutionContext): Promise<Response> {
    // Handle CORS preflight
    const corsResponse = handleCors(request);
    if (corsResponse) {
      return corsResponse;
    }

    // Rate limiting
    const clientIP = request.headers.get('CF-Connecting-IP') ||
                     request.headers.get('X-Forwarded-For')?.split(',')[0] ||
                     'unknown';
    const rateLimit = checkRateLimit(clientIP);

    if (!rateLimit.allowed) {
      const response = rateLimitedError();
      return addCorsHeaders(
        new Response(response.body, {
          status: response.status,
          headers: {
            ...Object.fromEntries(response.headers),
            ...rateLimitHeaders(rateLimit),
          },
        })
      );
    }

    try {
      const response = await router.fetch(request);

      // Add CORS and rate limit headers to response
      const headers = new Headers(response.headers);
      for (const [key, value] of Object.entries(rateLimitHeaders(rateLimit))) {
        headers.set(key, value);
      }

      return addCorsHeaders(
        new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers,
        })
      );
    } catch (err) {
      console.error('Unhandled error:', err);
      return addCorsHeaders(
        error(500, 'Internal Server Error')
      );
    }
  },
};
