/**
 * ELK (Eclipse Layout Kernel) Integration
 *
 * Provides high-quality graph layout using elkjs library
 */

import ELK from 'elkjs'
import type { Graph } from './core/Graph'
import type { Group } from './core/Group'
import type { LayoutResult } from './core/Graph'

interface ELKNode {
  id: string
  width?: number
  height?: number
  labels?: Array<{ text: string }>
  children?: ELKNode[] // For hierarchical layout (groups)
  edges?: ELKEdge[] // For edges within a group
  layoutOptions?: Record<string, string>
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
  hasMultiEdges: boolean
  maxFanout: number
  averageDegree: number
}

function analyzeGraphStructure(graph: Graph): GraphStructure {
  const nodes = graph.getNodes()
  const edges = graph.getEdges()

  if (nodes.length === 0) {
    return { isTree: true, hasCycles: false, isDense: false, hasMultiEdges: false, maxFanout: 0, averageDegree: 0 }
  }

  // Build adjacency info
  const outDegree = new Map<string, number>()
  const inDegree = new Map<string, number>()
  const edgePairs = new Map<string, number>()

  nodes.forEach(node => {
    outDegree.set(node.id, 0)
    inDegree.set(node.id, 0)
  })

  edges.forEach(edge => {
    outDegree.set(edge.from.id, (outDegree.get(edge.from.id) || 0) + 1)
    inDegree.set(edge.to.id, (inDegree.get(edge.to.id) || 0) + 1)

    // Track multi-edges (multiple edges between same node pairs)
    const pairKey = [edge.from.id, edge.to.id].sort().join('-')
    edgePairs.set(pairKey, (edgePairs.get(pairKey) || 0) + 1)
  })

  // Calculate metrics
  const maxFanout = Math.max(...Array.from(outDegree.values()))
  const totalDegree = edges.length * 2 // Each edge contributes to 2 nodes
  const averageDegree = totalDegree / nodes.length

  // Check for multi-edges (more than one edge between same pair of nodes)
  const hasMultiEdges = Array.from(edgePairs.values()).some(count => count > 1)

  // Check if it's a tree: n-1 edges and no cycles
  const isTree = edges.length === nodes.length - 1 && edges.length > 0

  // Simple cycle detection: back edges indicate cycles
  const hasCycles = !isTree && edges.length >= nodes.length

  // Consider dense if average degree > 3
  const isDense = averageDegree > 3

  return { isTree, hasCycles, isDense, hasMultiEdges, maxFanout, averageDegree }
}

/**
 * Convert a Node to an ELKNode
 */
function nodeToELKNode(node: any): ELKNode {
  // Calculate width: label + 2 chars padding (1 on each side) for compact nodes
  const labelLength = (node.name || '').length
  const width = (labelLength + 2) * 6 // 6 pixels per character for compact display

  return {
    id: node.id,
    width: width,
    height: 10, // Exactly 3 lines high (with scale 0.3: 10*0.3=3)
    labels: node.name ? [{ text: node.name }] : undefined
  }
}

/**
 * Convert a Group to an ELKNode with children
 */
function groupToELKNode(group: Group): ELKNode {
  const members = group.getMembers()
  const children = members.map(nodeToELKNode)
  const internalEdges = group.getInternalEdges()

  return {
    id: group.id,
    labels: group.label ? [{ text: group.label }] : undefined,
    children: children,
    edges: internalEdges.map(edge => ({
      id: edge.id,
      sources: [edge.from.id],
      targets: [edge.to.id],
      labels: edge.label ? [{ text: edge.label }] : undefined
    })),
    layoutOptions: {
      'elk.padding': '[top=20,left=10,bottom=10,right=10]', // Space for label and borders
      'elk.algorithm': 'layered',
      'elk.hierarchyHandling': 'INCLUDE_CHILDREN'
    }
  }
}

/**
 * Convert Graph to ELK format with structure-aware options
 */
function graphToELK(graph: Graph): ELKGraph {
  const groups = graph.getGroups()
  const allNodes = graph.getNodes()
  const allEdges = graph.getEdges()

  // Track which nodes are in groups
  const groupedNodeIds = new Set<string>()
  for (const group of groups) {
    for (const member of group.getMembers()) {
      groupedNodeIds.add(member.id)
    }
  }

  // Create ELK nodes for groups
  const groupNodes: ELKNode[] = groups.map(groupToELKNode)

  // Create ELK nodes for ungrouped nodes
  const ungroupedNodes: ELKNode[] = allNodes
    .filter(node => !groupedNodeIds.has(node.id))
    .map(nodeToELKNode)

  // Combine all top-level children (groups + ungrouped nodes)
  const children = [...groupNodes, ...ungroupedNodes]

  // Collect all internal edge IDs (edges within groups)
  const internalEdgeIds = new Set<string>()
  for (const group of groups) {
    for (const edge of group.getInternalEdges()) {
      internalEdgeIds.add(edge.id)
    }
  }

  // Create ELK edges for external edges (not within any group)
  const edges: ELKEdge[] = allEdges
    .filter(edge => !internalEdgeIds.has(edge.id))
    .map(edge => ({
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
  if (structure.hasMultiEdges) {
    // Graphs with multi-edges (like Seven Bridges): prevent vertical stacking
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '25',
      'elk.layered.spacing.nodeNodeBetweenLayers': '40',
      'elk.spacing.edgeNode': '20',
      'elk.spacing.edgeEdge': '15',
      'elk.layered.layering.strategy': 'NETWORK_SIMPLEX',
      'elk.layered.nodePlacement.strategy': 'LINEAR_SEGMENTS',
      'elk.layered.considerModelOrder.strategy': 'NODES_AND_EDGES',
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
      'elk.layered.thoroughness': '10',
      'elk.layered.compaction.postCompaction.strategy': 'NONE',
    })
  } else if (structure.isTree) {
    // Tree structure: prioritize compactness and straight edges
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '10',
      'elk.layered.spacing.nodeNodeBetweenLayers': '20',
      'elk.spacing.edgeNode': '8',
      'elk.spacing.edgeEdge': '6',
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
    // Disable post-compaction to prevent constraint conflicts
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '20',
      'elk.layered.spacing.nodeNodeBetweenLayers': '35',
      'elk.spacing.edgeNode': '15',
      'elk.spacing.edgeEdge': '12',
      'elk.layered.layering.strategy': 'NETWORK_SIMPLEX',
      'elk.layered.nodePlacement.strategy': 'NETWORK_SIMPLEX',
      'elk.layered.cycleBreaking.strategy': 'GREEDY',
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
      'elk.layered.thoroughness': '5',
      'elk.layered.compaction.postCompaction.strategy': 'NONE',
    })
  } else if (structure.isDense) {
    // Dense graph: prioritize crossing minimization and readability
    Object.assign(layoutOptions, {
      'elk.spacing.nodeNode': '20',
      'elk.layered.spacing.nodeNodeBetweenLayers': '35',
      'elk.spacing.edgeNode': '15',
      'elk.spacing.edgeEdge': '12',
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
      'elk.spacing.nodeNode': '15',
      'elk.layered.spacing.nodeNodeBetweenLayers': '25',
      'elk.spacing.edgeNode': '12',
      'elk.spacing.edgeEdge': '8',
      'elk.layered.layering.strategy': 'LONGEST_PATH',
      'elk.layered.nodePlacement.strategy': 'SIMPLE',
      'elk.layered.nodePlacement.favorStraightEdges': 'true',
      'elk.layered.nodePlacement.bk.fixedAlignment': 'BALANCED',
      'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
      'elk.layered.thoroughness': '7',
      'elk.layered.compaction.postCompaction.strategy': 'EDGE_LENGTH',
    })
  }

  // Enable hierarchical layout if there are groups
  if (groups.length > 0) {
    layoutOptions['elk.hierarchyHandling'] = 'INCLUDE_CHILDREN'
  }

  return {
    id: 'root',
    children: children,
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
 * Recursively collect all nodes from ELK result (including nodes in groups)
 */
function collectNodesFromELK(elkNode: any, offsetX: number = 0, offsetY: number = 0): any[] {
  const nodes: any[] = []

  for (const child of elkNode.children || []) {
    const absoluteX = (child.x || 0) + offsetX
    const absoluteY = (child.y || 0) + offsetY

    if (child.children && child.children.length > 0) {
      // This is a group - recurse into it
      nodes.push(...collectNodesFromELK(child, absoluteX, absoluteY))
    } else {
      // This is a regular node
      const gridPos = snapToGrid(absoluteX, absoluteY)
      nodes.push({
        id: child.id,
        x: gridPos.x,
        y: gridPos.y,
        width: Math.ceil((child.width || 80) / 8),
        height: Math.ceil((child.height || 40) / 8),
        label: child.labels?.[0]?.text || ''
      })
    }
  }

  return nodes
}

/**
 * Recursively collect all edges from ELK result (including edges in groups)
 */
function collectEdgesFromELK(elkNode: any, offsetX: number = 0, offsetY: number = 0): any[] {
  const edges: any[] = []

  // Process edges at this level
  for (const edge of elkNode.edges || []) {
    const section = edge.sections?.[0]
    const bendPoints = section?.bendPoints || []
    const startPoint = section?.startPoint || { x: 0, y: 0 }
    const endPoint = section?.endPoint || { x: 0, y: 0 }

    // Apply offset and snap to grid
    let points = [
      snapToGrid(startPoint.x + offsetX, startPoint.y + offsetY),
      ...bendPoints.map((p: any) => snapToGrid(p.x + offsetX, p.y + offsetY)),
      snapToGrid(endPoint.x + offsetX, endPoint.y + offsetY)
    ]

    // Pull back the arrow endpoint by 1 cell to avoid overlap with node box
    if (points.length >= 2) {
      const lastPoint = points[points.length - 1]
      const prevPoint = points[points.length - 2]

      const dx = Math.sign(lastPoint.x - prevPoint.x)
      const dy = Math.sign(lastPoint.y - prevPoint.y)

      points[points.length - 1] = {
        x: lastPoint.x - dx,
        y: lastPoint.y - dy
      }
    }

    edges.push({
      id: edge.id,
      from: edge.sources[0],
      to: edge.targets[0],
      points: points,
      label: edge.labels?.[0]?.text
    })
  }

  // Recurse into children (groups)
  for (const child of elkNode.children || []) {
    if (child.children && child.children.length > 0) {
      const absoluteX = (child.x || 0) + offsetX
      const absoluteY = (child.y || 0) + offsetY
      edges.push(...collectEdgesFromELK(child, absoluteX, absoluteY))
    }
  }

  return edges
}

/**
 * Collect group boundaries for rendering
 */
function collectGroupBoundaries(elkNode: any, offsetX: number = 0, offsetY: number = 0): any[] {
  const groups: any[] = []

  for (const child of elkNode.children || []) {
    if (child.children && child.children.length > 0) {
      // This is a group
      const absoluteX = (child.x || 0) + offsetX
      const absoluteY = (child.y || 0) + offsetY
      const gridPos = snapToGrid(absoluteX, absoluteY)
      const gridSize = {
        width: Math.ceil((child.width || 80) / 8),
        height: Math.ceil((child.height || 40) / 8)
      }

      groups.push({
        id: child.id,
        x: gridPos.x,
        y: gridPos.y,
        width: gridSize.width,
        height: gridSize.height,
        label: child.labels?.[0]?.text || ''
      })

      // Recurse into nested groups
      groups.push(...collectGroupBoundaries(child, absoluteX, absoluteY))
    }
  }

  return groups
}

/**
 * Convert ELK layout result to Grid Layout for ASCII rendering
 */
function elkToGridLayout(elkResult: any): LayoutResult {
  // Collect all nodes (including those in groups)
  const gridNodes = collectNodesFromELK(elkResult)

  // Collect all edges (including those in groups)
  const gridEdges = collectEdgesFromELK(elkResult)

  // Collect group boundaries for rendering
  const groups = collectGroupBoundaries(elkResult)

  // Calculate bounds (include both nodes and groups)
  const nodeBounds = gridNodes.length > 0
    ? Math.max(...gridNodes.map((n: any) => n.x + n.width))
    : 0
  const groupBounds = groups.length > 0
    ? Math.max(...groups.map((g: any) => g.x + g.width))
    : 0
  const maxX = Math.max(nodeBounds, groupBounds, 0)

  const nodeHeight = gridNodes.length > 0
    ? Math.max(...gridNodes.map((n: any) => n.y + n.height))
    : 0
  const groupHeight = groups.length > 0
    ? Math.max(...groups.map((g: any) => g.y + g.height))
    : 0
  const maxY = Math.max(nodeHeight, groupHeight, 0)

  return {
    nodes: gridNodes,
    edges: gridEdges,
    bounds: { width: maxX, height: maxY },
    // @ts-expect-error - groups is not in the base LayoutResult type yet, but the renderer may use it
    groups: groups
  }
}

/**
 * Layout Graph using ELK (returns simplified LayoutResult)
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
 * Layout and render Graph using ELK with the new orthogonal ASCII renderer
 *
 * This uses the elk-ascii-renderer which produces higher quality output
 * with proper orthogonal routing, smart junctions, and better edge rendering.
 */
export async function layoutAndRenderWithELK(graph: Graph, boxart: boolean = false): Promise<string> {
  const elk = new ELK()

  // Convert to ELK format
  const elkGraph = graphToELK(graph)

  // Run layout
  const layouted = await elk.layout(elkGraph)

  // Use the new elk-ascii-renderer for better quality output
  const { renderASCII } = await import('./renderers/elk-ascii-renderer')
  // Cast to any to avoid type mismatch between elkjs types and our simplified types
  // The renderer handles the conversion internally
  const { ascii, metadata } = renderASCII(layouted as any, {
    scale: 0.3,
    unicode: boxart,
    arrows: true,
    renderLabels: true,
    renderPorts: false,
    margin: 5,
  })

  if (!ascii) {
    throw new Error(metadata.error || 'Failed to render ASCII')
  }

  // Log metadata for debugging
  if (metadata.warnings && metadata.warnings.length > 0) {
    console.warn('ELK ASCII Renderer warnings:', metadata.warnings)
  }

  return ascii
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
