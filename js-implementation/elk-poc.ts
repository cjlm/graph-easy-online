/**
 * Proof of Concept: Using ELK for Graph Layout
 *
 * This shows how to use elkjs instead of custom layout algorithms
 */

import ELK from 'elkjs/lib/elk.bundled.js'
import type { Graph } from './core/Graph.ts'

interface ELKNode {
  id: string
  width?: number
  height?: number
  labels?: Array<{ text: string }>
}

interface ELKEdge {
  id: string
  sources: string[]
  targets: string[]
  labels?: Array<{ text: string }>
}

interface ELKGraph {
  id: string
  children: ELKNode[]
  edges: ELKEdge[]
  layoutOptions?: Record<string, string>
}

/**
 * Convert Graph::Easy Graph to ELK format
 */
function graphToELK(graph: Graph): ELKGraph {
  const nodes: ELKNode[] = graph.getNodes().map(node => ({
    id: node.id,
    width: Math.max(node.name.length * 8 + 16, 80), // Estimate width
    height: 40, // Fixed height for boxes
    labels: [{ text: node.name }]
  }))

  const edges: ELKEdge[] = graph.getEdges().map(edge => ({
    id: edge.id,
    sources: [edge.from.id],
    targets: [edge.to.id],
    labels: edge.label ? [{ text: edge.label }] : undefined
  }))

  // Get flow direction from graph attributes
  const flow = graph.getAttribute('flow') || 'east'
  const direction = {
    'east': 'RIGHT',
    'west': 'LEFT',
    'south': 'DOWN',
    'north': 'UP'
  }[flow] || 'RIGHT'

  return {
    id: 'root',
    children: nodes,
    edges: edges,
    layoutOptions: {
      // Use ELK Layered algorithm (Sugiyama-style, similar to Graph::Easy)
      'elk.algorithm': 'layered',

      // Flow direction
      'elk.direction': direction,

      // Spacing
      'elk.spacing.nodeNode': '40',
      'elk.layered.spacing.nodeNodeBetweenLayers': '80',

      // Edge routing (orthogonal = Manhattan-style)
      'elk.edgeRouting': 'ORTHOGONAL',

      // Port constraints
      'elk.portConstraints': 'FIXED_SIDE',

      // Layer assignment strategy
      'elk.layered.layering.strategy': 'NETWORK_SIMPLEX',

      // Node placement
      'elk.layered.nodePlacement.strategy': 'SIMPLE',

      // Cycle breaking
      'elk.layered.cycleBreaking.strategy': 'GREEDY'
    }
  }
}

/**
 * Layout using ELK
 */
async function layoutWithELK(graph: Graph) {
  const elk = new ELK()

  // Convert to ELK format
  const elkGraph = graphToELK(graph)

  // Run layout
  const layouted = await elk.layout(elkGraph)

  return layouted
}

/**
 * Snap ELK continuous coordinates to ASCII grid
 */
function snapToGrid(x: number, y: number, gridSize: number = 8): { x: number, y: number } {
  return {
    x: Math.round(x / gridSize),
    y: Math.round(y / gridSize)
  }
}

/**
 * Convert ELK layout result to Grid Layout for ASCII rendering
 */
function elkToGridLayout(elkResult: any) {
  const gridNodes = elkResult.children.map((node: any) => {
    const gridPos = snapToGrid(node.x, node.y)

    return {
      id: node.id,
      x: gridPos.x,
      y: gridPos.y,
      width: Math.ceil((node.width || 80) / 8),
      height: Math.ceil((node.height || 40) / 8),
      label: node.labels?.[0]?.text || ''
    }
  })

  const gridEdges = elkResult.edges.map((edge: any) => {
    // ELK provides edge routing points
    const points = edge.sections?.[0]?.bendPoints || []

    // Snap all points to grid
    const gridPoints = points.map((p: any) => snapToGrid(p.x, p.y))

    return {
      id: edge.id,
      from: edge.sources[0],
      to: edge.targets[0],
      points: gridPoints,
      label: edge.labels?.[0]?.text
    }
  })

  // Calculate bounds
  const maxX = Math.max(...gridNodes.map((n: any) => n.x + n.width))
  const maxY = Math.max(...gridNodes.map((n: any) => n.y + n.height))

  return {
    nodes: gridNodes,
    edges: gridEdges,
    bounds: { width: maxX, height: maxY }
  }
}

/**
 * Main API: Layout Graph using ELK
 */
export async function layoutGraphWithELK(graph: Graph) {
  // 1. Layout with ELK
  const elkResult = await layoutWithELK(graph)

  // 2. Convert to grid coordinates
  const gridLayout = elkToGridLayout(elkResult)

  // 3. Return in format compatible with existing ASCII renderer
  return gridLayout
}

/**
 * Example usage:
 *
 * import { layoutGraphWithELK } from './elk-poc.ts'
 * import { renderAscii } from './renderers/AsciiRenderer.ts'
 *
 * const graph = parser.parse('[A] -> [B] -> [C]')
 * const layout = await layoutGraphWithELK(graph)
 * const ascii = renderAscii(layout)
 */
