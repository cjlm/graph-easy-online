import type { FormatsResponse, FormatInfo } from '../types/api';
import { jsonResponse } from '../utils/response';

const FORMATS: FormatInfo[] = [
  {
    id: 'ascii',
    name: 'ASCII Art',
    description: 'Classic ASCII representation using +, -, |, and other characters',
  },
  {
    id: 'boxart',
    name: 'Box Art',
    description: 'Unicode box drawing characters for cleaner appearance',
  },
  {
    id: 'text',
    name: 'Text',
    description: 'Plain text representation of the graph structure',
  },
  {
    id: 'graphviz',
    name: 'Graphviz/DOT',
    description: 'DOT format for use with Graphviz tools',
  },
  {
    id: 'dot',
    name: 'DOT',
    description: 'Alias for Graphviz DOT format',
  },
];

export function handleFormats(): Response {
  const response: FormatsResponse = {
    formats: FORMATS,
  };

  return jsonResponse(response);
}
