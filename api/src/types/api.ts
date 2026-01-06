export type OutputFormat = 'ascii' | 'boxart' | 'text' | 'graphviz' | 'dot';

export interface ConvertRequest {
  input: string;
  format?: OutputFormat;
  options?: {
    seed?: number;
  };
}

export interface ConvertResponse {
  success: true;
  output: string;
  format: OutputFormat;
  timing_ms: number;
}

export interface ParseRequest {
  input: string;
}

export interface GraphNode {
  id: string;
  label: string;
  attributes?: Record<string, string>;
}

export interface GraphEdge {
  from: string;
  to: string;
  label?: string;
  attributes?: Record<string, string>;
}

export interface ParseResponse {
  success: true;
  graph: {
    nodes: GraphNode[];
    edges: GraphEdge[];
  };
}

export interface HealthResponse {
  status: 'ok';
  version: string;
  engine: string;
}

export interface FormatInfo {
  id: OutputFormat;
  name: string;
  description: string;
}

export interface FormatsResponse {
  formats: FormatInfo[];
}

export interface ErrorResponse {
  success: false;
  error: {
    code: ErrorCode;
    message: string;
    details?: string;
  };
}

export type ErrorCode =
  | 'PARSE_ERROR'
  | 'INVALID_FORMAT'
  | 'INVALID_REQUEST'
  | 'RATE_LIMITED'
  | 'INTERNAL_ERROR';

export type ApiResponse<T> = T | ErrorResponse;
