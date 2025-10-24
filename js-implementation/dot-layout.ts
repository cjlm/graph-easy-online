/**
 * DOT/Graphviz Layout Integration
 *
 * Uses viz.js (Graphviz compiled to WebAssembly) for high-quality graph layout,
 * then renders to ASCII
 */

import * as Viz from '@viz-js/viz'
import type { Graph } from './core/Graph'
import type { LayoutResult } from './core/Graph'

/**
 * Convert Graph to DOT format
 */
function graphToDOT(graph: Graph): string {
  const nodes = graph.getNodes()
  const edges = graph.getEdges()

  // Check if graph is directed (has any edges with arrows)
  const hasDirectedEdges = edges.some(e => !e.isUndirected())
  const graphType = hasDirectedEdges ? 'digraph' : 'graph'
  const edgeOp = hasDirectedEdges ? '->' : '--'

  // Get flow direction
  const flow = graph.getAttribute('flow') || 'east'
  const rankdirMap: Record<string, string> = {
    'east': 'LR',
    'west': 'RL',
    'south': 'TB',
    'north': 'BT'
  }
  const rankdir = rankdirMap[flow] || 'LR'

  let dot = `${graphType} G {\n`
  dot += `  rankdir="${rankdir}";\n`
  dot += `  node [shape=box];\n`
  dot += `\n`

  // Add nodes
  nodes.forEach(node => {
    const id = node.id.replace(/[^a-zA-Z0-9_]/g, '_')
    const label = node.name || ''
    dot += `  ${id} [label="${label}"];\n`
  })

  dot += `\n`

  // Add edges
  edges.forEach(edge => {
    const fromId = edge.from.id.replace(/[^a-zA-Z0-9_]/g, '_')
    const toId = edge.to.id.replace(/[^a-zA-Z0-9_]/g, '_')
    const attrs = []

    if (edge.label) {
      attrs.push(`label="${edge.label}"`)
    }

    const attrStr = attrs.length > 0 ? ` [${attrs.join(', ')}]` : ''
    dot += `  ${fromId} ${edgeOp} ${toId}${attrStr};\n`
  })

  dot += `}\n`

  return dot
}

/**
 * Parse DOT output to extract layout information
 */
function parseDOTLayout(dotOutput: string, graph: Graph): LayoutResult {
  const nodes = graph.getNodes()
  const edges = graph.getEdges()

  // Parse the DOT output (with layout info)
  const nodePositions = new Map<string, { x: number, y: number, width: number, height: number }>()
  const edgePaths = new Map<string, Array<{ x: number, y: number }>>()

  // Extract node positions from DOT  (format: id_12 [height=0.5, label="...", pos="40.864,138", width=1.134];)
  // Note: Node definitions can span multiple lines, so use [\s\S] to match including newlines
  const nodeRegex = /(\w+)\s+\[([\s\S]+?)\];/g
  let match

  while ((match = nodeRegex.exec(dotOutput)) !== null) {
    const [, id, attrs] = match

    // Extract pos attribute
    const posMatch = attrs.match(/pos="([\d.]+),([\d.]+)"/)
    const widthMatch = attrs.match(/width=([\d.]+)/)
    const heightMatch = attrs.match(/height=([\d.]+)/)

    if (posMatch && widthMatch && heightMatch) {
      const x = parseFloat(posMatch[1])
      const y = parseFloat(posMatch[2])
      const width = parseFloat(widthMatch[1]) * 72 // Convert inches to points
      const height = parseFloat(heightMatch[1]) * 72

      nodePositions.set(id, { x, y, width, height })
    }
  }

  // Extract edge paths (format: id_12 -- id_14 [label="Bridge 1", pos="e,195.91,138 81.89,138 ...");)
  // Note: Edge definitions can span multiple lines
  const edgeRegex = /(\w+)\s+--\s+(\w+)\s+\[([\s\S]+?)\];/g

  while ((match = edgeRegex.exec(dotOutput)) !== null) {
    const [, from, to, attrs] = match
    const posMatch = attrs.match(/pos="([^"]+)"/)

    if (posMatch) {
      const posStr = posMatch[1]
      // Parse position string - format is "e,x,y x1,y1 x2,y2 ..." where e,x,y is the end point
      const parts = posStr.split(' ')
      const points = parts.map(p => {
        const coords = p.replace(/^[es],/, '').split(',')
        return { x: parseFloat(coords[0]), y: parseFloat(coords[1]) }
      }).filter(p => !isNaN(p.x) && !isNaN(p.y))

      if (points.length > 0) {
        edgePaths.set(`${from}-${to}`, points)
      }
    }
  }

  // Convert to grid layout
  const gridSize = 8
  const gridNodes = nodes.map(node => {
    const id = node.id.replace(/[^a-zA-Z0-9_]/g, '_')
    const pos = nodePositions.get(id)

    if (!pos) {
      // Fallback position
      const labelLength = (node.name || '').length
      return {
        id: node.id,
        x: 0,
        y: 0,
        width: Math.max(labelLength + 4, 10),
        height: 3,
        label: node.name || ''
      }
    }

    // Calculate width based on label length (in characters)
    const labelLength = (node.name || '').length
    const width = Math.max(labelLength + 4, 10)  // Label + padding, min 10 chars

    return {
      id: node.id,
      x: Math.round(pos.x / gridSize),
      y: Math.round(pos.y / gridSize),
      width: width,
      height: 3,  // Fixed height like other engines
      label: node.name || ''
    }
  })

  const gridEdges = edges.map(edge => {
    const fromId = edge.from.id.replace(/[^a-zA-Z0-9_]/g, '_')
    const toId = edge.to.id.replace(/[^a-zA-Z0-9_]/g, '_')
    const path = edgePaths.get(`${fromId}-${toId}`)

    let points: Array<{ x: number; y: number }> = []
    if (path && path.length > 0) {
      points = path.map(p => ({
        x: Math.round(p.x / gridSize),
        y: Math.round(p.y / gridSize)
      }))
    } else {
      // Fallback: direct line
      const fromNode = gridNodes.find(n => n.id === edge.from.id)
      const toNode = gridNodes.find(n => n.id === edge.to.id)

      if (fromNode && toNode) {
        points = [
          { x: fromNode.x + Math.floor(fromNode.width / 2), y: fromNode.y + Math.floor(fromNode.height / 2) },
          { x: toNode.x + Math.floor(toNode.width / 2), y: toNode.y + Math.floor(toNode.height / 2) }
        ]
      }
    }

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

    return {
      id: edge.id,
      from: edge.from.id,
      to: edge.to.id,
      points: points,
      label: edge.label
    }
  })

  // Calculate bounds
  const maxX = Math.max(...gridNodes.map(n => n.x + n.width), 0)
  const maxY = Math.max(...gridNodes.map(n => n.y + n.height), 0)

  return {
    nodes: gridNodes,
    edges: gridEdges,
    bounds: { width: maxX, height: maxY }
  }
}

/**
 * Layout Graph using DOT/Graphviz
 */
export async function layoutWithDOT(graph: Graph): Promise<LayoutResult> {
  const viz = await Viz.instance()

  // Convert to DOT format
  const dot = graphToDOT(graph)

  console.log('📊 DOT input:', dot)

  // Run layout with position info
  const layoutedDOT = viz.renderString(dot, {
    format: 'dot',
    engine: 'dot'
  })

  console.log('📊 DOT output:', layoutedDOT)

  // Parse layout and convert to grid coordinates
  const gridLayout = parseDOTLayout(layoutedDOT, graph)

  return gridLayout
}

/**
 * Check if DOT/viz.js is available
 */
export function isDOTAvailable(): boolean {
  try {
    return true // viz.js is a regular dependency
  } catch {
    return false
  }
}
