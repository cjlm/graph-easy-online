import type { HealthResponse } from '../types/api';
import { jsonResponse } from '../utils/response';

const VERSION = '1.0.0';

export function handleHealth(): Response {
  const response: HealthResponse = {
    status: 'ok',
    version: VERSION,
    engine: 'graph-easy-ts',
  };

  return jsonResponse(response);
}
