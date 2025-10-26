/**
 * NodePlacer - Places nodes on the grid using Graph::Easy's algorithm
 *
 * Based on Graph::Easy::Layout::Path::_find_node_place
 *
 * Placement strategies (tried in order):
 * 1. User-defined rank constraints
 * 2. Shared port alignment
 * 3. Parent-relative placement (for chained nodes)
 * 4. First node at (0,0)
 * 5. Predecessor-based placement
 * 6. Successor-based placement
 * 7. Generic column scanning fallback
 *
 * This is NOT Sugiyama layering - it's flexible grid placement!
 */

import { Graph } from '../core/Graph.ts'
import { Node } from '../core/Node.ts'
import { Edge } from '../core/Edge.ts'
import { Cell, gridKey } from '../core/Cell.ts'

/**
 * Extend Graph to store cells grid
 */
declare module '../core/Graph.ts' {
  interface Graph {
    cells: Map<string, Cell>
  }
}

/**
 * Extend Node to store position
 */
declare module '../core/Node.ts' {
  interface Node {
    x?: number
    y?: number
    cx?: number  // Column span
    cy?: number  // Row span
  }
}

interface PlacementPosition {
  x: number
  y: number
}

export class NodePlacer {
  private graph: Graph
  private debug: boolean = false

  constructor(graph: Graph) {
    this.graph = graph

    // Initialize cells map if not exists
    if (!this.graph.cells) {
      this.graph.cells = new Map()
    }
  }

  /**
   * Place a node on the grid
   *
   * Returns: true if placement succeeded, false if need to backtrack
   */
  placeNode(node: Node, tryCount: number, parent?: Node, parentEdge?: Edge): boolean {
    // Calculate node dimensions if not already set
    if (node.cx === undefined || node.cy === undefined) {
      this.calculateNodeDimensions(node)
    }

    if (this.debug) {
      console.log(`# Finding place for ${node.name}, try #${tryCount}`)
      if (parent) console.log(`# Parent node is '${parent.name}'`)
    }

    // Strategy 1: Try parent-relative placement first (for chained nodes)
    if (parent && parent.x !== undefined && parent.y !== undefined && parentEdge) {
      const minDist = this.getMinDistance(parentEdge)
      const positions = this.getNearPositions(parent, minDist)

      if (this.debug) {
        console.log(`# Trying chained placement with min distance ${minDist} from parent ${parent.name}`)
      }

      const filtered = this.filterPositions(node, positions)

      // Skip first N tries if retrying
      const toTry = tryCount > 0 ? filtered.slice(tryCount) : filtered

      for (const pos of toTry) {
        if (this.tryPlace(node, pos.x, pos.y)) {
          return true
        }
      }
    }

    // Strategy 2: First node at (0,0)
    if (tryCount === 0) {
      if (this.debug) console.log(`# Trying to place ${node.name} at 0,0`)
      if (this.tryPlace(node, 0, 0)) {
        return true
      }
    }

    // Strategy 3: Predecessor-based placement
    const predecessors = this.getPlacedPredecessors(node)

    if (this.debug) {
      console.log(`# Number of placed predecessors of ${node.name}: ${predecessors.length}`)
    }

    let tries: PlacementPosition[] = []

    if (predecessors.length === 1) {
      // Place near single predecessor
      const pred = predecessors[0]
      const minDist = parentEdge ? this.getMinDistance(parentEdge) : 2

      if (this.debug) console.log(`# Placing ${node.name} near predecessor`)

      tries.push(...this.getNearPositions(pred, minDist))
      tries.push(...this.getNearPositions(pred, minDist + 2))
    } else if (predecessors.length === 2) {
      // Place at crossing point or midpoint
      const p0 = predecessors[0]
      const p1 = predecessors[1]
      const dx = (p0.x! - p1.x!)
      const dy = (p0.y! - p1.y!)

      if (dx !== 0 && dy !== 0) {
        // Not on straight line - try crossing points
        tries.push({ x: p0.x!, y: p1.y! })
        tries.push({ x: p1.x!, y: p0.y! })
      } else {
        // On straight line - try midpoint
        if (dx === 0) {
          tries.push({ x: p1.x!, y: p1.y! + Math.floor(dy / 2) })
        } else {
          tries.push({ x: p1.x! + Math.floor(dx / 2), y: p1.y! })
        }
      }

      // Also try around each predecessor
      for (const pred of predecessors) {
        const minDist = parentEdge ? this.getMinDistance(parentEdge) : 2
        tries.push(...this.getNearPositions(pred, minDist))
      }
    } else if (predecessors.length >= 3) {
      // Multiple predecessors: try to find optimal position
      // For 3+ predecessors, try all pairwise crossing points
      // This handles cases like: A-B-C arranged in L or U shape, where D should be at the fourth corner

      if (this.debug) console.log(`# Placing ${node.name} with ${predecessors.length} predecessors`)

      // Try crossing points for all pairs of predecessors
      for (let i = 0; i < predecessors.length; i++) {
        for (let j = i + 1; j < predecessors.length; j++) {
          const p0 = predecessors[i]
          const p1 = predecessors[j]
          const dx = p0.x! - p1.x!
          const dy = p0.y! - p1.y!

          if (dx !== 0 && dy !== 0) {
            // Try the two crossing points
            tries.push({ x: p0.x!, y: p1.y! })
            tries.push({ x: p1.x!, y: p0.y! })
          }
        }
      }

      // Also try positions near each predecessor
      for (const pred of predecessors) {
        const minDist = 2
        tries.push(...this.getNearPositions(pred, minDist))
      }
    }

    // Strategy 4: Successor-based placement
    const successors = this.getPlacedSuccessors(node)

    if (this.debug) {
      console.log(`# Number of placed successors of ${node.name}: ${successors.length}`)
    }

    for (const suc of successors) {
      const minDist = 2
      tries.push(...this.getNearPositions(suc, minDist))
      tries.push(...this.getNearPositions(suc, minDist + 2))
    }

    // Filter and try positions
    const filtered = this.filterPositions(node, tries)

    if (this.debug) {
      console.log(`# Left with ${filtered.length} tries for node ${node.name}`)
    }

    const toTry = tryCount > 0 ? filtered.slice(tryCount) : filtered

    for (const pos of toTry) {
      if (this.debug) console.log(`# Trying to place ${node.name} at ${pos.x},${pos.y}`)
      if (this.tryPlace(node, pos.x, pos.y)) {
        return true
      }
    }

    // Strategy 5: Generic column scanning fallback
    if (this.debug) {
      console.log(`# No more simple possibilities for node ${node.name}`)
    }

    // Find column based on predecessors or use column 0
    let col = 0
    if (predecessors.length > 0) {
      col = predecessors[0].x!
    }

    // Find first free row in this column
    let y = 0
    while (this.graph.cells.has(gridKey(col, y))) {
      y += 2
    }
    // Leave one cell spacing if previous cell exists
    if (this.graph.cells.has(gridKey(col, y - 1))) {
      y += 1
    }

    // Try to place, incrementing Y until success
    while (true) {
      if (this.isPositionClear(node, col, y)) {
        if (this.tryPlace(node, col, y)) {
          return true
        }
      }
      y += 2

      // Safety limit
      if (y > 100) {
        console.warn(`Could not place ${node.name} after 100 tries`)
        return false
      }
    }
  }

  /**
   * Remove a node from the grid (for backtracking)
   */
  removeNode(node: Node): void {
    if (node.x === undefined || node.y === undefined) return

    const cx = node.cx || 1
    const cy = node.cy || 1

    for (let dy = 0; dy < cy; dy++) {
      for (let dx = 0; dx < cx; dx++) {
        const key = gridKey(node.x + dx, node.y + dy)
        this.graph.cells.delete(key)
      }
    }

    node.x = undefined
    node.y = undefined
  }

  /**
   * Try to place node at specific position
   */
  private tryPlace(node: Node, x: number, y: number): boolean {
    const cx = node.cx || 1
    const cy = node.cy || 1

    // Check if all cells are free
    for (let dy = 0; dy < cy; dy++) {
      for (let dx = 0; dx < cx; dx++) {
        const key = gridKey(x + dx, y + dy)
        if (this.graph.cells.has(key)) {
          return false
        }
      }
    }

    // Place the node
    node.x = x
    node.y = y

    for (let dy = 0; dy < cy; dy++) {
      for (let dx = 0; dx < cx; dx++) {
        const cell = new Cell(x + dx, y + dy)
        cell.node = node
        cell.cx = cx
        cell.cy = cy
        this.graph.cells.set(gridKey(x + dx, y + dy), cell)
      }
    }

    return true
  }

  /**
   * Get minimum distance based on edge attributes
   */
  private getMinDistance(edge: Edge): number {
    // minlen = 0 => min_dist = 2
    // minlen = 1 => min_dist = 2
    // minlen = 2 => min_dist = 3, etc
    const minlen = edge.getAttribute('minlen') as number | undefined
    return minlen !== undefined ? minlen + 1 : 2
  }

  /**
   * Get positions near a node at given distance
   */
  private getNearPositions(node: Node, distance: number): PlacementPosition[] {
    const positions: PlacementPosition[] = []
    const cx = node.cx || 1
    const cy = node.cy || 1

    if (node.x === undefined || node.y === undefined) return positions

    // Single-celled node
    if (cx === 1 && cy === 1) {
      // Four cardinal directions at specified distance
      positions.push(
        { x: node.x + distance, y: node.y },      // East
        { x: node.x, y: node.y + distance },      // South
        { x: node.x - distance, y: node.y },      // West
        { x: node.x, y: node.y - distance }       // North
      )
    } else {
      // Multi-celled node - positions around all sides
      const px = node.x
      const py = node.y

      // Right side: node occupies [px, px+cx-1], so next position is px+cx+distance
      for (let dy = 0; dy < cy; dy++) {
        positions.push({ x: px + cx + distance, y: py + dy })
      }
      // Bottom side: node occupies [py, py+cy-1], so next position is py+cy+distance
      for (let dx = 0; dx < cx; dx++) {
        positions.push({ x: px + dx, y: py + cy + distance })
      }
      // Left side
      for (let dy = 0; dy < cy; dy++) {
        positions.push({ x: px - distance, y: py + dy })
      }
      // Top side
      for (let dx = 0; dx < cx; dx++) {
        positions.push({ x: px + dx, y: py - distance })
      }
    }

    return positions
  }

  /**
   * Filter out blocked positions
   */
  private filterPositions(node: Node, positions: PlacementPosition[]): PlacementPosition[] {
    return positions.filter(pos => this.isPositionClear(node, pos.x, pos.y))
  }

  /**
   * Check if position is clear for node
   */
  private isPositionClear(node: Node, x: number, y: number): boolean {
    const cx = node.cx || 1
    const cy = node.cy || 1

    for (let dy = 0; dy < cy; dy++) {
      for (let dx = 0; dx < cx; dx++) {
        if (this.graph.cells.has(gridKey(x + dx, y + dy))) {
          return false
        }
      }
    }

    return true
  }

  /**
   * Get all placed predecessors of a node
   */
  private getPlacedPredecessors(node: Node): Node[] {
    const predecessors: Node[] = []

    for (const edge of this.graph.getEdges()) {
      if (edge.to === node && edge.from.x !== undefined) {
        predecessors.push(edge.from)
      }
    }

    // Sort by rank (higher rank first)
    return predecessors.sort((a, b) => (b.rank || 0) - (a.rank || 0))
  }

  /**
   * Get all placed successors of a node
   */
  private getPlacedSuccessors(node: Node): Node[] {
    const successors: Node[] = []

    for (const edge of this.graph.getEdges()) {
      if (edge.from === node && edge.to.x !== undefined) {
        successors.push(edge.to)
      }
    }

    return successors
  }

  /**
   * Calculate node dimensions based on label
   *
   * Each grid cell renders as 5 characters wide.
   * Node box width = label.length + 2 (for padding/borders)
   * Grid cells needed = ceil(box_width / 5)
   */
  private calculateNodeDimensions(node: Node): void {
    const label = node.label || node.name

    // Calculate character width needed (label + 2 for borders, min 5)
    const charWidth = Math.max(label.length + 2, 5)

    // Calculate grid cells needed (each cell is 5 chars wide)
    node.cx = Math.ceil(charWidth / 5)
    node.cy = 1  // Height is always 1 grid cell (3 char rows)
  }
}
