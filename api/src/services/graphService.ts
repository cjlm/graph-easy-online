import { Parser } from 'graph-easy-ts';
import type { OutputFormat, GraphNode, GraphEdge } from '../types/api';

export interface ConvertOptions {
  seed?: number;
}

export interface ConvertResult {
  output: string;
  timing_ms: number;
}

export interface ParseResult {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export function convert(
  input: string,
  format: OutputFormat,
  options: ConvertOptions = {}
): ConvertResult {
  const startTime = performance.now();

  const graph = Parser.fromText(input);

  if (options.seed !== undefined) {
    graph.seed = options.seed;
  }

  graph.layout();

  let output: string;
  switch (format) {
    case 'ascii':
      output = graph.asAscii();
      break;
    case 'boxart':
      output = graph.asBoxart();
      break;
    case 'text':
      output = graph.asTxt();
      break;
    case 'graphviz':
    case 'dot':
      output = graph.asGraphviz();
      break;
    default:
      throw new Error(`Unsupported format: ${format}`);
  }

  const timing_ms = Math.round((performance.now() - startTime) * 1000) / 1000;

  return { output, timing_ms };
}

export function parse(input: string): ParseResult {
  const graph = Parser.fromText(input);

  const nodes: GraphNode[] = [];
  const edges: GraphEdge[] = [];

  // Extract nodes
  for (const node of graph.nodes()) {
    nodes.push({
      id: node.name,
      label: node.label || node.name,
      ...(Object.keys(node.attributes || {}).length > 0 && {
        attributes: node.attributes,
      }),
    });
  }

  // Extract edges
  for (const edge of graph.edges()) {
    edges.push({
      from: edge.from.name,
      to: edge.to.name,
      ...(edge.label && { label: edge.label }),
      ...(Object.keys(edge.attributes || {}).length > 0 && {
        attributes: edge.attributes,
      }),
    });
  }

  return { nodes, edges };
}

export function isValidFormat(format: string): format is OutputFormat {
  return ['ascii', 'boxart', 'text', 'graphviz', 'dot'].includes(format);
}
