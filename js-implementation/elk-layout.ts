/**
 * ELK (Eclipse Layout Kernel) Integration
 *
 * Provides high-quality graph layout using elkjs library
 */

import ELK from 'elkjs'
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
 * Analyze graph structure to determine optimal layout strategy
 */
interface GraphStructure {
  isTree: boolean
  hasCycles: boolean
  isDense: boolean
  maxFanout: number
  averageDegree: number
}

function analyzeGraphStructure(graph: Graph): GraphStructure {
  const nodes = graph.getNodes()
  const edges = graph.getEdges()

  if (nodes.length === 0) {
    return { isTree: true, hasCycles: false, isDense: false, maxFanout: 0, averageDegree: 0 }
  }

  // Build adjacency info
  const outDegree = new Map<string, number>()
  const inDegree = new Map<string, number>()

  nodes.forEach(node => {
    outDegree.set(node.id, 0)
    inDegree.set(node.id, 0)
  })

  edges.forEach(edge => {
    outDegree.set(edge.from.id, (outDegree.get(edge.from.id) || 0) + 1)
    inDegree.set(edge.to.id, (inDegree.get(edge.to.id) || 0) + 1)
  })

  // Calculate metrics
  const maxFanout = Math.max(...Array.from(outDegree.values()))
  const totalDegree = edges.length * 2 // Each edge contributes to 2 nodes
  const averageDegree = totalDegree / nodes.length

  // Check if it's a tree: n-1 edges and no cycles
  const isTree = edges.length === nodes.length - 1 && edges.length > 0

  // Simple cycle detection: back edges indicate cycles
  const hasCycles = !isTree && edges.length >= nodes.length

  // Consider dense if average degree > 3
  const isDense = averageDegree > 3

  return { isTree, hasCycles, isDense, maxFanout, averageDegree }
}

/**
 * Convert Graph to ELK format with structure-aware options
 */
function graphToELK(graph: Graph): ELKGraph {
  const nodes: ELKNode[] = graph.getNodes().map(node => {
    // Calculate minimum width to fit label with padding (4 chars = 2 on each side)
    const labelLength = (node.name || '').length
    const minWidth = (labelLength + 4) * 8 // 8 pixels per character in grid

    return {
      id: node.id,
      width: Math.max(minWidth, 80), // At least 10 grid cells (80px)
      height: 24, // 3 grid cells
      labels: node.name ? [{ text: node.name }] : undefined
    }
  })

  const edges: ELKEdge[] = graph.getEdges().map(edge => ({
    id: edge.id,
    sources: [edge.from.id],
    targets: [edge.to.id],
    labels: edge.label ? [{ text: edge.label }] : undefined
  }))

  // Analyze graph structure
  const structure = analyzeGraphStructure(graph)

  // Get flow direction
  const flow = graph.getAttribute('flow') || 'east'
  const directionMap: Record<string, string> = {
    'east': 'RIGHT',
    'west': 'LEFT',
    'south': 'DOWN',
    'north': 'UP'
  }
  const direction = directionMap[flow] || 'RIGHT'

  // Base layout options
  const layoutOptions: Record<string, string> = {
    'elk.algorithm': 'layered',
    'elk.direction': direction,
    'elk.edgeRouting': 'ORTHOGONAL',
    'elk.portConstraints': 'FREE',
  }

  // Apply heuristics based on graph structure
  if (structure.isTree) {
    // Tree structure: prioritize compactness and straight edges
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '20',
      'elk.layered.spacing.nodeNodeBetweenLayers': '35',
      'elk.spacing.edgeNode': '15',
      'elk.spacing.edgeEdge': '10',
      'elk.layered.layering.strategy': 'LONGEST_PATH',
      'elk.layered.nodePlacement.strategy': 'SIMPLE',
      'elk.layered.nodePlacement.favorStraightEdges': 'true',
      'elk.layered.nodePlacement.bk.fixedAlignment': 'BALANCED',
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
      'elk.layered.thoroughness': '5',
      'elk.layered.compaction.postCompaction.strategy': 'EDGE_LENGTH',
    })
  } else if (structure.hasCycles) {
    // Cyclic graph: prioritize stability and avoid hitbox issues
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '25',
      'elk.layered.spacing.nodeNodeBetweenLayers': '45',
      'elk.spacing.edgeNode': '20',
      'elk.spacing.edgeEdge': '15',
      'elk.layered.layering.strategy': 'LONGEST_PATH',
      'elk.layered.nodePlacement.strategy': 'SIMPLE',
      'elk.layered.cycleBreaking.strategy': 'GREEDY',
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
      'elk.layered.thoroughness': '7',
      'elk.layered.compaction.postCompaction.strategy': 'EDGE_LENGTH',
      'elk.layered.compaction.postCompaction.constraints': 'NONE',
    })
  } else if (structure.isDense) {
    // Dense graph: prioritize crossing minimization and readability
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '30',
      'elk.layered.spacing.nodeNodeBetweenLayers': '50',
      'elk.spacing.edgeNode': '20',
      'elk.spacing.edgeEdge': '15',
      'elk.layered.layering.strategy': 'NETWORK_SIMPLEX',
      'elk.layered.nodePlacement.strategy': 'BRANDES_KOEPF',
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
      'elk.layered.crossingMinimization.greedySwitch': 'TWO_SIDED',
      'elk.layered.thoroughness': '10',
      'elk.layered.compaction.postCompaction.strategy': 'NONE',
    })
  } else {
    // Default: balanced settings for general graphs
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '20',
      'elk.layered.spacing.nodeNodeBetweenLayers': '40',
      'elk.spacing.edgeNode': '15',
      'elk.spacing.edgeEdge': '10',
      'elk.layered.layering.strategy': 'LONGEST_PATH',
      'elk.layered.nodePlacement.strategy': 'SIMPLE',
      'elk.layered.nodePlacement.favorStraightEdges': 'true',
      'elk.layered.nodePlacement.bk.fixedAlignment': 'BALANCED',
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
      'elk.layered.thoroughness': '7',
      'elk.layered.compaction.postCompaction.strategy': 'EDGE_LENGTH',
    })
  }

  return {
    id: 'root',
    children: nodes,
    edges: edges,
    layoutOptions
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
    let points = [
      snapToGrid(startPoint.x, startPoint.y),
      ...bendPoints.map((p: any) => snapToGrid(p.x, p.y)),
      snapToGrid(endPoint.x, endPoint.y)
    ]

    // Pull back the arrow endpoint by 1 cell to avoid overlap with node box
    if (points.length >= 2) {
      const lastPoint = points[points.length - 1]
      const prevPoint = points[points.length - 2]

      const dx = Math.sign(lastPoint.x - prevPoint.x)
      const dy = Math.sign(lastPoint.y - prevPoint.y)

      // Move arrow back one cell in the direction it came from
      points[points.length - 1] = {
        x: lastPoint.x - dx,
        y: lastPoint.y - dy
      }
    }

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
    // ELK is a regular dependency, so it's always available
    return true
  } catch {
    return false
  }
}
