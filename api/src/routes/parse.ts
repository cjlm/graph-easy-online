import type { ParseRequest, ParseResponse } from '../types/api';
import { parse } from '../services/graphService';
import { jsonResponse, invalidRequestError, parseError, internalError } from '../utils/response';

const MAX_INPUT_SIZE = 100 * 1024; // 100KB max input

export async function handleParse(request: Request): Promise<Response> {
  let body: ParseRequest;

  try {
    const text = await request.text();
    if (text.length > MAX_INPUT_SIZE) {
      return invalidRequestError(`Input too large. Maximum size is ${MAX_INPUT_SIZE / 1024}KB`);
    }
    body = JSON.parse(text);
  } catch {
    return invalidRequestError('Invalid JSON body');
  }

  if (!body.input || typeof body.input !== 'string') {
    return invalidRequestError('Missing required field: input');
  }

  if (body.input.trim().length === 0) {
    return invalidRequestError('Input cannot be empty');
  }

  try {
    const result = parse(body.input);

    const response: ParseResponse = {
      success: true,
      graph: result,
    };

    return jsonResponse(response);
  } catch (error) {
    if (error instanceof Error) {
      return parseError('Failed to parse graph notation', error.message);
    }
    return internalError();
  }
}
