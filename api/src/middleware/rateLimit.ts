interface RateLimitInfo {
  count: number;
  resetTime: number;
}

// In-memory rate limit store (per isolate)
// For production with multiple workers, use Cloudflare KV or Durable Objects
const rateLimitStore = new Map<string, RateLimitInfo>();

const RATE_LIMIT = 100; // requests per window
const WINDOW_MS = 60 * 1000; // 1 minute

export interface RateLimitResult {
  allowed: boolean;
  limit: number;
  remaining: number;
  resetTime: number;
}

export function checkRateLimit(clientIP: string): RateLimitResult {
  const now = Date.now();
  const key = clientIP;

  let info = rateLimitStore.get(key);

  // Clean up expired entries periodically
  if (rateLimitStore.size > 10000) {
    for (const [k, v] of rateLimitStore) {
      if (v.resetTime < now) {
        rateLimitStore.delete(k);
      }
    }
  }

  if (!info || info.resetTime < now) {
    info = {
      count: 1,
      resetTime: now + WINDOW_MS,
    };
    rateLimitStore.set(key, info);
    return {
      allowed: true,
      limit: RATE_LIMIT,
      remaining: RATE_LIMIT - 1,
      resetTime: info.resetTime,
    };
  }

  info.count++;
  const allowed = info.count <= RATE_LIMIT;

  return {
    allowed,
    limit: RATE_LIMIT,
    remaining: Math.max(0, RATE_LIMIT - info.count),
    resetTime: info.resetTime,
  };
}

export function rateLimitHeaders(result: RateLimitResult): HeadersInit {
  return {
    'X-RateLimit-Limit': String(result.limit),
    'X-RateLimit-Remaining': String(result.remaining),
    'X-RateLimit-Reset': String(Math.ceil(result.resetTime / 1000)),
  };
}
