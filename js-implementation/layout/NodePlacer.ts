/**
 * NodePlacer - Places nodes on the grid using various strategies
 *
 * Based on Graph::Easy::Layout::Path::_find_node_place
 *
 * Placement strategies (in priority order):
 * 1. Rank-based: Use user-defined rank position
 * 2. Parent-based: Place near parent node (for chained nodes)
 * 3. Predecessor-based: Place near predecessor nodes
 * 4. Successor-based: Place near already-placed successors
 * 5. Fallback: Find first free position in grid
 */

import { Graph } from '../core/Graph'
import { Node } from '../core/Node'
import { Edge } from '../core/Edge'
import { Cell, gridKey } from '../core/Cell'

/**
 * Extend Graph to store cells grid
 */
declare module '../core/Graph' {
  interface Graph {
    cells: Map<string, Cell>
    _rankPos?: Map<number, { x: number; y: number }>
    _rankCoord?: 'x' | 'y'
  }
}

/**
 * Extend Node to store position
 */
declare module '../core/Node' {
  interface Node {
    x?: number
    y?: number
    cx?: number  // Column span
    cy?: number  // Row span
  }
}

interface Position {
  x: number
  y: number
}

export class NodePlacer {
  private graph: Graph
  private flowDir: 'east' | 'west' | 'north' | 'south'

  constructor(graph: Graph) {
    this.graph = graph

    // Initialize cells map if not exists
    if (!this.graph.cells) {
      this.graph.cells = new Map()
    }

    // Get flow direction from graph attributes
    const flow = this.graph.getAttribute('flow') as string | undefined
    this.flowDir = (flow as any) || 'east'

    // Initialize rank tracking
    if (!this.graph._rankPos) {
      this.graph._rankPos = new Map()
    }

    // Determine rank coordinate based on flow
    // east/west: ranks are columns (x)
    // north/south: ranks are rows (y)
    this.graph._rankCoord = this.flowDir === 'east' || this.flowDir === 'west' ? 'x' : 'y'
  }

  /**
   * Place a node on the grid
   *
   * @returns true if placement succeeded, false otherwise
   */
  placeNode(node: Node, tryCount: number, parent?: Node, parentEdge?: Edge): boolean {
    // Calculate node dimensions if not already set
    if (node.cx === undefined || node.cy === undefined) {
      this.calculateNodeDimensions(node)
    }

    // Strategy 1: Rank-based placement (for all ranked nodes)
    if (node.rank !== undefined) {
      if (this.tryRankBasedPlacement(node, tryCount)) {
        return true
      }
    }

    // Strategy 2: Parent-based placement (for chained nodes)
    if (parent && parent.x !== undefined && parent.y !== undefined) {
      if (this.tryParentBasedPlacement(node, parent, parentEdge, tryCount)) {
        return true
      }
    }

    // Strategy 3: Predecessor-based placement
    const predecessors = this.getPlacedPredecessors(node)
    if (predecessors.length > 0) {
      if (this.tryPredecessorBasedPlacement(node, predecessors, tryCount)) {
        return true
      }
    }

    // Strategy 4: Successor-based placement
    const successors = this.getPlacedSuccessors(node)
    if (successors.length > 0) {
      if (this.trySuccessorBasedPlacement(node, successors, tryCount)) {
        return true
      }
    }

    // Strategy 5: Fallback - find first free position
    return this.tryFallbackPlacement(node, tryCount)
  }

  /**
   * Strategy 1: Place based on user-defined rank
   */
  private tryRankBasedPlacement(node: Node, tryCount: number): boolean {
    const rank = Math.abs(node.rank!)
    const rankPos = this.graph._rankPos!

    // Get or create position for this rank
    if (!rankPos.has(rank)) {
      rankPos.set(rank, { x: rank * 4, y: 0 })
    }

    const pos = rankPos.get(rank)!
    const coord = this.graph._rankCoord!

    // Try to place at rank position with increasing offsets
    for (let offset = 0; offset <= tryCount; offset++) {
      let x = pos.x
      let y = pos.y

      if (coord === 'x') {
        y += offset * 2
      } else {
        x += offset * 2
      }

      if (this.tryPlaceAt(node, x, y)) {
        // Update rank position for next node
        // Use node height/width + gap to avoid overlap
        const gap = 1  // Minimum gap between nodes at same rank
        if (coord === 'x') {
          pos.y += (node.cy || 1) + gap
        } else {
          pos.x += (node.cx || 1) + gap
        }
        return true
      }
    }

    return false
  }

  /**
   * Strategy 2: Place near parent node
   */
  private tryParentBasedPlacement(
    node: Node,
    parent: Node,
    parentEdge: Edge | undefined,
    tryCount: number
  ): boolean {
    // Get minimum distance from edge attribute (default 5)
    // This is the gap between nodes, not including node width
    const minDist = (parentEdge?.getAttribute('minlen') as number) || 5

    // Get candidate positions around parent
    const candidates = this.getNearPlaces(parent, minDist)

    // Try each candidate
    for (let i = 0; i < Math.min(candidates.length, tryCount + 1); i++) {
      const pos = candidates[i]
      if (this.tryPlaceAt(node, pos.x, pos.y)) {
        return true
      }
    }

    return false
  }

  /**
   * Strategy 3: Place near predecessors
   */
  private tryPredecessorBasedPlacement(node: Node, predecessors: Node[], tryCount: number): boolean {
    if (predecessors.length === 1) {
      // Single predecessor: place near it
      const pred = predecessors[0]
      const candidates = this.getNearPlaces(pred, 5)

      for (let i = 0; i < Math.min(candidates.length, tryCount + 1); i++) {
        if (this.tryPlaceAt(node, candidates[i].x, candidates[i].y)) {
          return true
        }
      }
    } else if (predecessors.length === 2) {
      // Two predecessors: try middle position
      const pred1 = predecessors[0]
      const pred2 = predecessors[1]

      // Try middle point
      const midX = Math.floor((pred1.x! + pred2.x!) / 2)
      const midY = Math.floor((pred1.y! + pred2.y!) / 2)

      if (this.tryPlaceAt(node, midX, midY)) {
        return true
      }

      // Try near each predecessor
      for (const pred of predecessors) {
        const candidates = this.getNearPlaces(pred, 5)
        for (const pos of candidates) {
          if (this.tryPlaceAt(node, pos.x, pos.y)) {
            return true
          }
        }
      }
    }

    return false
  }

  /**
   * Strategy 4: Place near successors
   */
  private trySuccessorBasedPlacement(node: Node, successors: Node[], tryCount: number): boolean {
    for (const succ of successors) {
      const candidates = this.getNearPlaces(succ, 5)

      for (let i = 0; i < Math.min(candidates.length, tryCount + 1); i++) {
        if (this.tryPlaceAt(node, candidates[i].x, candidates[i].y)) {
          return true
        }
      }
    }

    return false
  }

  /**
   * Strategy 5: Fallback - find first free position
   */
  private tryFallbackPlacement(node: Node, tryCount: number): boolean {
    // Start at origin or near first predecessor
    let startX = 0
    let startY = 0

    const preds = this.getPlacedPredecessors(node)
    if (preds.length > 0) {
      startX = preds[0].x!
      startY = preds[0].y!
    }

    // Try positions in a grid pattern
    for (let offset = 0; offset <= tryCount + 10; offset++) {
      const positions = [
        { x: startX + offset * 2, y: startY },
        { x: startX, y: startY + offset * 2 },
        { x: startX - offset * 2, y: startY },
        { x: startX, y: startY - offset * 2 },
      ]

      for (const pos of positions) {
        if (this.tryPlaceAt(node, pos.x, pos.y)) {
          return true
        }
      }
    }

    return false
  }

  /**
   * Get candidate positions around a node
   *
   * Returns positions at given distance in order based on flow direction
   */
  private getNearPlaces(node: Node, distance: number): Position[] {
    const x = node.x!
    const y = node.y!
    const cx = node.cx || 1
    const cy = node.cy || 1

    // For single-cell nodes: 4 positions (right, down, left, up)
    if (cx === 1 && cy === 1) {
      const positions = [
        { x: x + distance, y }, // right (east)
        { x, y: y + distance }, // down (south)
        { x: x - distance, y }, // left (west)
        { x, y: y - distance }, // up (north)
      ]

      // Reorder based on flow direction
      return this.shuffleByFlow(positions)
    }

    // For multi-cell nodes: positions along all sides
    const positions: Position[] = []

    // Right side (east)
    for (let dy = 0; dy < cy; dy++) {
      positions.push({ x: x + cx + distance, y: y + dy })
    }

    // Bottom side (south)
    for (let dx = 0; dx < cx; dx++) {
      positions.push({ x: x + dx, y: y + cy + distance })
    }

    // Left side (west)
    for (let dy = 0; dy < cy; dy++) {
      positions.push({ x: x - distance, y: y + dy })
    }

    // Top side
    for (let dx = 0; dx < cx; dx++) {
      positions.push({ x: x + dx, y: y - distance })
    }

    return this.shuffleByFlow(positions)
  }

  /**
   * Reorder positions based on flow direction
   */
  private shuffleByFlow(positions: Position[]): Position[] {
    // For east flow: prefer right, then down, then left, then up (already in order)
    // For south flow: prefer down, then right, then left, then up
    // etc.

    const flowOrder: { [key: string]: number[] } = {
      east: [0, 1, 2, 3], // right, down, left, up
      south: [1, 0, 2, 3], // down, right, left, up
      west: [2, 1, 0, 3], // left, down, right, up
      north: [3, 0, 2, 1], // up, right, left, down
    }

    const order = flowOrder[this.flowDir]
    return order.map(i => positions[i]).filter(p => p !== undefined)
  }

  /**
   * Try to place node at specific position
   *
   * @returns true if successful, false if position occupied
   */
  private tryPlaceAt(node: Node, x: number, y: number): boolean {
    const cx = node.cx || 1
    const cy = node.cy || 1

    // Check if all required cells are free
    for (let dx = 0; dx < cx; dx++) {
      for (let dy = 0; dy < cy; dy++) {
        const key = gridKey(x + dx, y + dy)
        if (this.graph.cells.has(key)) {
          return false // Position occupied
        }
      }
    }

    // Place node
    node.x = x
    node.y = y

    // Create cells for this node
    for (let dx = 0; dx < cx; dx++) {
      for (let dy = 0; dy < cy; dy++) {
        const cell = Cell.createNodeCell(x + dx, y + dy, node)
        this.graph.cells.set(gridKey(x + dx, y + dy), cell)
      }
    }

    return true
  }

  /**
   * Get predecessors that have been placed
   */
  private getPlacedPredecessors(node: Node): Node[] {
    const preds: Node[] = []
    const edges = node.edges()

    for (const edge of edges) {
      if (edge.to === node && edge.from !== node) {
        if (edge.from.x !== undefined && edge.from.y !== undefined) {
          preds.push(edge.from)
        }
      }
    }

    // Sort by rank (highest rank first)
    return preds.sort((a, b) => {
      const rankA = Math.abs(a.rank || 0)
      const rankB = Math.abs(b.rank || 0)
      return rankB - rankA
    })
  }

  /**
   * Get successors that have been placed
   */
  private getPlacedSuccessors(node: Node): Node[] {
    const succs: Node[] = []
    const edges = node.edges()

    for (const edge of edges) {
      if (edge.from === node && edge.to !== node) {
        if (edge.to.x !== undefined && edge.to.y !== undefined) {
          succs.push(edge.to)
        }
      }
    }

    return succs
  }

  /**
   * Remove node from grid (for backtracking)
   */
  removeNode(node: Node): void {
    if (node.x === undefined || node.y === undefined) return

    const cx = node.cx || 1
    const cy = node.cy || 1

    for (let dx = 0; dx < cx; dx++) {
      for (let dy = 0; dy < cy; dy++) {
        const key = gridKey(node.x + dx, node.y + dy)
        this.graph.cells.delete(key)
      }
    }

    node.x = undefined
    node.y = undefined
  }

  /**
   * Calculate node dimensions based on label and attributes
   */
  private calculateNodeDimensions(node: Node): void {
    const label = node.label || node.name

    // Width: label length + 4 (2 for borders, 2 for padding)
    const labelWidth = label.length
    node.cx = labelWidth + 4

    // Height: always 3 (top border, label, bottom border)
    node.cy = 3

    // Apply minimum dimensions from attributes if specified
    const minWidth = node.getAttribute('minwidth') as number | undefined
    const minHeight = node.getAttribute('minheight') as number | undefined

    if (minWidth !== undefined && minWidth > node.cx) {
      node.cx = minWidth
    }

    if (minHeight !== undefined && minHeight > node.cy) {
      node.cy = minHeight
    }
  }
}
