/**
 * ELK (Eclipse Layout Kernel) Integration
 *
 * Provides high-quality graph layout using elkjs library
 */

import ELK from 'elkjs/lib/elk.bundled.js'
import type { Graph } from './core/Graph'
import type { LayoutResult } from './core/Graph'

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
 * Convert Graph to ELK format
 */
function graphToELK(graph: Graph): ELKGraph {
  const nodes: ELKNode[] = graph.getNodes().map(node => ({
    id: node.id,
    width: Math.max((node.name || '').length * 8 + 16, 80), // Estimate width based on text
    height: 40, // Fixed height
    labels: node.name ? [{ text: node.name }] : undefined
  }))

  const edges: ELKEdge[] = graph.getEdges().map(edge => ({
    id: edge.id,
    sources: [edge.from.id],
    targets: [edge.to.id],
    labels: edge.label ? [{ text: edge.label }] : undefined
  }))

  // Get flow direction
  const flow = graph.getAttribute('flow') || 'east'
  const directionMap: Record<string, string> = {
    'east': 'RIGHT',
    'west': 'LEFT',
    'south': 'DOWN',
    'north': 'UP'
  }
  const direction = directionMap[flow] || 'RIGHT'

  return {
    id: 'root',
    children: nodes,
    edges: edges,
    layoutOptions: {
      // Use ELK Layered algorithm (Sugiyama-style, similar to Graph::Easy)
      'elk.algorithm': 'layered',

      // Flow direction
      'elk.direction': direction,

      // Spacing (tuned for ASCII grid)
      'elk.spacing.nodeNode': '40',
      'elk.layered.spacing.nodeNodeBetweenLayers': '80',
      'elk.spacing.edgeNode': '20',
      'elk.spacing.edgeEdge': '20',

      // Edge routing (orthogonal = Manhattan-style, perfect for ASCII!)
      'elk.edgeRouting': 'ORTHOGONAL',

      // Port constraints (where edges connect)
      'elk.portConstraints': 'FIXED_SIDE',

      // Layer assignment strategy (network simplex gives best quality)
      'elk.layered.layering.strategy': 'NETWORK_SIMPLEX',

      // Node placement
      'elk.layered.nodePlacement.strategy': 'SIMPLE',
      'elk.layered.nodePlacement.favorStraightEdges': 'true',

      // Cycle breaking (for graphs with cycles)
      'elk.layered.cycleBreaking.strategy': 'GREEDY',

      // Crossing minimization
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',

      // Self-loops
      'elk.layered.selfLoopPlacement': 'NORTH_STACKED',

      // Thoroughness (higher = better quality, slower)
      'elk.layered.thoroughness': '10',

      // Edge straightening
      'elk.layered.edgeRouting.splines.mode': 'CONSERVATIVE',

      // Compaction
      'elk.layered.compaction.postCompaction.strategy': 'EDGE_LENGTH'
    }
  }
}

/**
 * Snap continuous coordinates to ASCII grid
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
function elkToGridLayout(elkResult: any): LayoutResult {
  const gridNodes = elkResult.children.map((node: any) => {
    const gridPos = snapToGrid(node.x || 0, node.y || 0)

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
    // Get edge routing points from ELK
    const section = edge.sections?.[0]
    const bendPoints = section?.bendPoints || []

    // Start and end points
    const startPoint = section?.startPoint || { x: 0, y: 0 }
    const endPoint = section?.endPoint || { x: 0, y: 0 }

    // Snap all points to grid
    const points = [
      snapToGrid(startPoint.x, startPoint.y),
      ...bendPoints.map((p: any) => snapToGrid(p.x, p.y)),
      snapToGrid(endPoint.x, endPoint.y)
    ]

    return {
      id: edge.id,
      from: edge.sources[0],
      to: edge.targets[0],
      points: points,
      label: edge.labels?.[0]?.text
    }
  })

  // Calculate bounds
  const maxX = Math.max(...gridNodes.map((n: any) => n.x + n.width), 0)
  const maxY = Math.max(...gridNodes.map((n: any) => n.y + n.height), 0)

  return {
    nodes: gridNodes,
    edges: gridEdges,
    bounds: { width: maxX, height: maxY }
  }
}

/**
 * Layout Graph using ELK
 */
export async function layoutWithELK(graph: Graph): Promise<LayoutResult> {
  const elk = new ELK()

  // Convert to ELK format
  const elkGraph = graphToELK(graph)

  // Run layout
  const layouted = await elk.layout(elkGraph)

  // Convert to grid coordinates
  const gridLayout = elkToGridLayout(layouted)

  return gridLayout
}

/**
 * Check if ELK is available
 */
export function isELKAvailable(): boolean {
  try {
    // Try to import ELK
    require('elkjs/lib/elk.bundled.js')
    return true
  } catch {
    return false
  }
}
