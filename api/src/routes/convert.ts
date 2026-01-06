import type { ConvertRequest, ConvertResponse, OutputFormat } from '../types/api';
import { convert, isValidFormat } from '../services/graphService';
import { jsonResponse, invalidRequestError, invalidFormatError, parseError, internalError } from '../utils/response';

const MAX_INPUT_SIZE = 100 * 1024; // 100KB max input

export async function handleConvert(request: Request): Promise<Response> {
  let body: ConvertRequest;

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

  const format: OutputFormat = body.format || 'ascii';

  if (!isValidFormat(format)) {
    return invalidFormatError(format);
  }

  try {
    const result = convert(body.input, format, body.options);

    const response: ConvertResponse = {
      success: true,
      output: result.output,
      format,
      timing_ms: result.timing_ms,
    };

    return jsonResponse(response);
  } catch (error) {
    if (error instanceof Error) {
      // Check if it's a parsing error from graph-easy-ts
      if (error.message.includes('parse') || error.message.includes('syntax') || error.message.includes('unexpected')) {
        return parseError('Failed to parse graph notation', error.message);
      }
      return internalError(error.message);
    }
    return internalError();
  }
}
