import type { ErrorCode, ErrorResponse } from '../types/api';

export function jsonResponse<T>(data: T, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

export function errorResponse(
  code: ErrorCode,
  message: string,
  details?: string,
  status = 400
): Response {
  const body: ErrorResponse = {
    success: false,
    error: {
      code,
      message,
      ...(details && { details }),
    },
  };
  return jsonResponse(body, status);
}

export function parseError(message: string, details?: string): Response {
  return errorResponse('PARSE_ERROR', message, details, 400);
}

export function invalidFormatError(format: string): Response {
  return errorResponse(
    'INVALID_FORMAT',
    `Unsupported output format: ${format}`,
    'Supported formats: ascii, boxart, text, graphviz, dot',
    400
  );
}

export function invalidRequestError(message: string): Response {
  return errorResponse('INVALID_REQUEST', message, undefined, 400);
}

export function rateLimitedError(): Response {
  return errorResponse(
    'RATE_LIMITED',
    'Rate limit exceeded. Please try again later.',
    undefined,
    429
  );
}

export function internalError(message = 'An unexpected error occurred'): Response {
  return errorResponse('INTERNAL_ERROR', message, undefined, 500);
}
