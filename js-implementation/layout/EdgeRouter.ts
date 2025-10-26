/**
 * EdgeRouter - Routes edges using A* pathfinding
 *
 * Based on Graph::Easy::Layout::Scout
 *
 * Implements:
 * - Fast paths for straight lines and single bends
 * - A* pathfinding for complex routes
 * - Manhattan distance heuristic
 * - Crossing and direction change penalties
 */

import { MinPriorityQueue } from '@datastructures-js/priority-queue'
import { Graph } from '../core/Graph'
import { Node } from '../core/Node'
import { Edge } from '../core/Edge'
import {
  gridKey,
  EDGE_HOR,
  EDGE_VER,
  EDGE_CROSS,
  EDGE_N_E,
  EDGE_N_W,
  EDGE_S_E,
  EDGE_S_W,
} from '../core/Cell'

interface PathCell {
  x: number
  y: number
  type: number
}

interface AStarNode {
  x: number
  y: number
  g: number // Cost from start
  h: number // Heuristic to goal
  f: number // g + h
  parentX?: number
  parentY?: number
}

export class EdgeRouter {
  private graph: Graph

  constructor(graph: Graph) {
    this.graph = graph
  }

  /**
   * Find path for an edge
   *
   * Returns array of cells representing the path
   */
  findPath(edge: Edge): PathCell[] {
    const src = edge.from
    const dst = edge.to

    // Check if nodes are placed
    if (src.x === undefined || src.y === undefined) {
      throw new Error(`Source node ${src.name} not placed`)
    }
    if (dst.x === undefined || dst.y === undefined) {
      throw new Error(`Destination node ${dst.name} not placed`)
    }

    // Handle self-loops specially
    if (src === dst) {
      return this.findPathLoop(src, edge)
    }

    // Try fast paths first
    const fastPath = this.tryFastPath(src, dst, edge)
    if (fastPath.length > 0) {
      return fastPath
    }

    // Fall back to A*
    return this.findPathAStar(src, dst, edge)
  }

  /**
   * Try fast path (straight line or single bend)
   */
  private tryFastPath(src: Node, dst: Node, edge: Edge): PathCell[] {
    const dx = dst.x! - src.x!
    const dy = dst.y! - src.y!

    // Straight horizontal or vertical
    if (dx === 0 || dy === 0) {
      const path = this.tryStraightPath(src, dst, edge)
      if (path.length > 0) return path
    }

    // Single bend (L-shape)
    if (dx !== 0 && dy !== 0) {
      // Try horizontal then vertical
      const path1 = this.trySingleBend(src, dst, edge, true)
      if (path1.length > 0) return path1

      // Try vertical then horizontal
      const path2 = this.trySingleBend(src, dst, edge, false)
      if (path2.length > 0) return path2
    }

    return []
  }

  /**
   * Try straight path
   */
  private tryStraightPath(src: Node, dst: Node, _edge: Edge): PathCell[] {
    const path: PathCell[] = []
    const dx = dst.x! - src.x!
    const dy = dst.y! - src.y!

    if (dx === 0) {
      // Vertical path
      const step = dy > 0 ? 1 : -1
      const startY = src.y! + step
      const endY = dst.y!

      // Check if path is clear
      for (let y = startY; step > 0 ? y < endY : y > endY; y += step) {
        const key = gridKey(src.x!, y)
        const cell = this.graph.cells.get(key)
        if (cell && cell.node) {
          return [] // Blocked by node
        }
      }

      // Build path
      for (let y = startY; step > 0 ? y < endY : y > endY; y += step) {
        path.push({
          x: src.x!,
          y,
          type: EDGE_VER,
        })
      }
    } else if (dy === 0) {
      // Horizontal path
      const step = dx > 0 ? 1 : -1
      const startX = src.x! + step
      const endX = dst.x!

      // Check if path is clear
      for (let x = startX; step > 0 ? x < endX : x > endX; x += step) {
        const key = gridKey(x, src.y!)
        const cell = this.graph.cells.get(key)
        if (cell && cell.node) {
          return [] // Blocked by node
        }
      }

      // Build path
      for (let x = startX; step > 0 ? x < endX : x > endX; x += step) {
        path.push({
          x,
          y: src.y!,
          type: EDGE_HOR,
        })
      }
    }

    return path
  }

  /**
   * Try single bend path (L-shape)
   */
  private trySingleBend(src: Node, dst: Node, _edge: Edge, horizontalFirst: boolean): PathCell[] {
    const path: PathCell[] = []

    if (horizontalFirst) {
      // Horizontal then vertical
      const bendX = dst.x!
      const bendY = src.y!

      // Check bend point
      const bendKey = gridKey(bendX, bendY)
      const bendCell = this.graph.cells.get(bendKey)
      if (bendCell && bendCell.node) {
        return [] // Bend point blocked
      }

      // Horizontal segment
      const hStep = dst.x! > src.x! ? 1 : -1
      for (let x = src.x! + hStep; hStep > 0 ? x < bendX : x > bendX; x += hStep) {
        const key = gridKey(x, src.y!)
        const cell = this.graph.cells.get(key)
        if (cell && cell.node) return []

        path.push({ x, y: src.y!, type: EDGE_HOR })
      }

      // Bend
      const bendType = this.getBendType(hStep, dst.y! > src.y! ? 1 : -1)
      path.push({ x: bendX, y: bendY, type: bendType })

      // Vertical segment
      const vStep = dst.y! > src.y! ? 1 : -1
      for (let y = src.y! + vStep; vStep > 0 ? y < dst.y! : y > dst.y!; y += vStep) {
        const key = gridKey(bendX, y)
        const cell = this.graph.cells.get(key)
        if (cell && cell.node) return []

        path.push({ x: bendX, y, type: EDGE_VER })
      }
    } else {
      // Vertical then horizontal
      const bendX = src.x!
      const bendY = dst.y!

      // Check bend point
      const bendKey = gridKey(bendX, bendY)
      const bendCell = this.graph.cells.get(bendKey)
      if (bendCell && bendCell.node) {
        return [] // Bend point blocked
      }

      // Vertical segment
      const vStep = dst.y! > src.y! ? 1 : -1
      for (let y = src.y! + vStep; vStep > 0 ? y < bendY : y > bendY; y += vStep) {
        const key = gridKey(src.x!, y)
        const cell = this.graph.cells.get(key)
        if (cell && cell.node) return []

        path.push({ x: src.x!, y, type: EDGE_VER })
      }

      // Bend
      const bendType = this.getBendType(dst.x! > src.x! ? 1 : -1, vStep)
      path.push({ x: bendX, y: bendY, type: bendType })

      // Horizontal segment
      const hStep = dst.x! > src.x! ? 1 : -1
      for (let x = src.x! + hStep; hStep > 0 ? x < dst.x! : x > dst.x!; x += hStep) {
        const key = gridKey(x, bendY)
        const cell = this.graph.cells.get(key)
        if (cell && cell.node) return []

        path.push({ x, y: bendY, type: EDGE_HOR })
      }
    }

    return path
  }

  /**
   * Get bend type based on direction
   */
  private getBendType(dx: number, dy: number): number {
    // dx, dy are direction vectors (-1, 0, 1)
    if (dx > 0 && dy > 0) return EDGE_S_E // Going east then south
    if (dx > 0 && dy < 0) return EDGE_N_E // Going east then north
    if (dx < 0 && dy > 0) return EDGE_S_W // Going west then south
    if (dx < 0 && dy < 0) return EDGE_N_W // Going west then north
    return EDGE_CROSS
  }

  /**
   * A* pathfinding
   */
  private findPathAStar(src: Node, dst: Node, edge: Edge): PathCell[] {
    // Initialize open list (priority queue)
    const open = new MinPriorityQueue<AStarNode>((node: AStarNode) => node.f)

    // Track best g scores
    const gScores = new Map<string, number>()

    // Track parent pointers
    const parents = new Map<string, { x: number; y: number }>()

    // Start position (just outside source node)
    const startPositions = this.getStartPositions(src, dst)

    for (const pos of startPositions) {
      const h = this.manhattanDistance(pos.x, pos.y, dst.x!, dst.y!)
      open.enqueue({
        x: pos.x,
        y: pos.y,
        g: 0,
        h,
        f: h,
      })
      gScores.set(gridKey(pos.x, pos.y), 0)
    }

    // Goal positions (just outside destination node)
    const goalPositions = this.getGoalPositions(src, dst)
    const goalSet = new Set(goalPositions.map(p => gridKey(p.x, p.y)))

    // A* main loop
    while (!open.isEmpty()) {
      const current = open.dequeue()
      if (!current) break

      const currentKey = gridKey(current.x, current.y)

      // Check if we reached goal
      if (goalSet.has(currentKey)) {
        return this.reconstructPath(parents, current, src, dst)
      }

      // Get neighbors (4-way: up, down, left, right)
      const neighbors = [
        { x: current.x + 1, y: current.y },
        { x: current.x - 1, y: current.y },
        { x: current.x, y: current.y + 1 },
        { x: current.x, y: current.y - 1 },
      ]

      for (const neighbor of neighbors) {
        const neighborKey = gridKey(neighbor.x, neighbor.y)

        // Check if neighbor is blocked by a node
        const cell = this.graph.cells.get(neighborKey)
        if (cell && cell.node && cell.node !== src && cell.node !== dst) {
          continue // Blocked
        }

        // Calculate cost
        const moveCost = 1
        const crossingPenalty = cell && cell.edge && cell.edge !== edge ? 30 : 0
        const directionChangePenalty = this.getDirectionChangePenalty(
          current.x,
          current.y,
          neighbor.x,
          neighbor.y,
          current.parentX,
          current.parentY
        )

        const tentativeG = current.g + moveCost + crossingPenalty + directionChangePenalty

        // Check if this path is better
        const currentG = gScores.get(neighborKey) ?? Infinity
        if (tentativeG < currentG) {
          gScores.set(neighborKey, tentativeG)
          parents.set(neighborKey, { x: current.x, y: current.y })

          const h = this.manhattanDistance(neighbor.x, neighbor.y, dst.x!, dst.y!)
          open.enqueue({
            x: neighbor.x,
            y: neighbor.y,
            g: tentativeG,
            h,
            f: tentativeG + h,
            parentX: current.x,
            parentY: current.y,
          })
        }
      }
    }

    // No path found
    return []
  }

  /**
   * Get start positions (positions just outside source node)
   */
  private getStartPositions(src: Node, _dst: Node): Array<{ x: number; y: number }> {
    const positions: Array<{ x: number; y: number }> = []
    const x = src.x!
    const y = src.y!
    const cx = src.cx || 1
    const cy = src.cy || 1

    // Calculate center of node
    const centerY = y + Math.floor(cy / 2)

    // Add positions in all 4 directions from center
    positions.push({ x: x + cx, y: centerY })  // right (east)
    positions.push({ x: x - 1, y: centerY })    // left (west)
    positions.push({ x, y: y + cy })            // bottom (south)
    positions.push({ x, y: y - 1 })             // top (north)

    return positions
  }

  /**
   * Get goal positions (positions just outside destination node)
   */
  private getGoalPositions(_src: Node, dst: Node): Array<{ x: number; y: number }> {
    const positions: Array<{ x: number; y: number }> = []
    const x = dst.x!
    const y = dst.y!
    const cx = dst.cx || 1
    const cy = dst.cy || 1

    // Calculate center of node
    const centerY = y + Math.floor(cy / 2)

    // Add positions in all 4 directions from center
    positions.push({ x: x + cx, y: centerY })  // right (east)
    positions.push({ x: x - 1, y: centerY })    // left (west)
    positions.push({ x, y: y + cy })            // bottom (south)
    positions.push({ x, y: y - 1 })             // top (north)

    return positions
  }

  /**
   * Manhattan distance heuristic
   */
  private manhattanDistance(x1: number, y1: number, x2: number, y2: number): number {
    const dx = Math.abs(x2 - x1)
    const dy = Math.abs(y2 - y1)

    // Add 1 if both dx and dy are non-zero (need to make a turn)
    return dx + dy + (dx > 0 && dy > 0 ? 1 : 0)
  }

  /**
   * Get direction change penalty
   */
  private getDirectionChangePenalty(
    x: number,
    y: number,
    nextX: number,
    nextY: number,
    parentX?: number,
    parentY?: number
  ): number {
    if (parentX === undefined || parentY === undefined) {
      return 0 // First move, no penalty
    }

    // Check if direction changed
    const prevDx = x - parentX
    const prevDy = y - parentY
    const nextDx = nextX - x
    const nextDy = nextY - y

    if (prevDx !== nextDx || prevDy !== nextDy) {
      return 6 // Direction change penalty
    }

    return 0
  }

  /**
   * Reconstruct path from parent pointers
   */
  private reconstructPath(
    parents: Map<string, { x: number; y: number }>,
    goal: AStarNode,
    _src: Node,
    _dst: Node
  ): PathCell[] {
    const path: PathCell[] = []

    let current = { x: goal.x, y: goal.y }

    while (true) {
      const key = gridKey(current.x, current.y)
      const parent = parents.get(key)

      if (!parent) break

      // Determine edge type based on direction
      const dx = current.x - parent.x
      const dy = current.y - parent.y

      let type: number
      if (dx === 0) {
        type = EDGE_VER
      } else if (dy === 0) {
        type = EDGE_HOR
      } else {
        type = EDGE_CROSS
      }

      path.unshift({ x: current.x, y: current.y, type })

      current = parent
    }

    return path
  }

  /**
   * Find path for self-loop
   */
  private findPathLoop(node: Node, _edge: Edge): PathCell[] {
    // Simple self-loop going to the right
    const x = node.x!
    const y = node.y!

    return [
      { x: x + 1, y, type: EDGE_HOR },
      { x: x + 2, y, type: EDGE_N_E },
      { x: x + 2, y: y - 1, type: EDGE_VER },
      { x: x + 2, y: y - 2, type: EDGE_N_W },
      { x: x + 1, y: y - 2, type: EDGE_HOR },
    ]
  }
}
