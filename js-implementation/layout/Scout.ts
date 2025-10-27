/**
 * Scout - A* pathfinding for edge routing
 *
 * Based on Graph::Easy::Layout::Scout
 *
 * This implements 3-tier pathfinding:
 * 1. Try straight path (horizontal or vertical)
 * 2. Try single-bend path (L-shape)
 * 3. Full A* with Manhattan heuristic
 *
 * Key features:
 * - Can cross existing edges (with 30-point penalty)
 * - Penalizes direction changes (6 points)
 * - Creates joints/T-junctions for shared ports
 * - Path straightening to remove unnecessary bends
 */

import { Graph } from '../core/Graph.ts'
import { Node } from '../core/Node.ts'
import { Edge } from '../core/Edge.ts'
import {
  gridKey,
  EDGE_HOR,
  EDGE_VER,
  EDGE_N_E,
  EDGE_N_W,
  EDGE_S_E,
  EDGE_S_W,
  EDGE_SHORT_E,
  EDGE_SHORT_W,
  EDGE_SHORT_N,
  EDGE_SHORT_S,
  EDGE_LABEL_CELL,
} from '../core/Cell.ts'

interface PathCell {
  x: number
  y: number
  type: number
}

interface AStarNode {
  f: number  // total cost (g + h)
  g: number  // cost from start
  h: number  // heuristic to goal
  x: number
  y: number
  px?: number  // parent x
  py?: number  // parent y
  type?: number
}

/**
 * Scout class - handles pathfinding for edges
 */
export class Scout {
  private graph: Graph
  private debug: boolean = false

  constructor(graph: Graph, debug: boolean = false) {
    this.graph = graph
    this.debug = debug
  }

  /**
   * Find path from source to destination node
   *
   * Uses 3-tier strategy:
   * 1. Try straight path
   * 2. Try L-shaped path (one bend)
   * 3. Full A* algorithm
   */
  findPath(edge: Edge): PathCell[] {
    const src = edge.from
    const dst = edge.to

    if (src.x === undefined || src.y === undefined || dst.x === undefined || dst.y === undefined) {
      throw new Error(`Nodes not placed: ${src.name} or ${dst.name}`)
    }

    if (this.debug) console.log(`🔍 Scout.findPath: ${src.name}(${src.x},${src.y}) -> ${dst.name}(${dst.x},${dst.y})`)

    // Tier 1: Try straight path
    const straight = this.tryStraightPath(src, dst, edge)
    if (straight.length > 0) {
      if (this.debug) console.log(`# Found straight path with ${straight.length} cells`)
      return straight
    }

    // Tier 2: Try single-bend path
    const bend = this.tryBendPath(src, dst, edge)
    if (bend.length > 0) {
      if (this.debug) console.log(`# Found bend path with ${bend.length} cells`)
      return bend
    }

    // Tier 3: Full A*
    if (this.debug) console.log(`# Trying A* pathfinding`)
    const astar = this.findPathAStar(src, dst, edge)
    return astar
  }

  /**
   * Tier 1: Try straight horizontal or vertical path
   */
  private tryStraightPath(src: Node, dst: Node, edge: Edge): PathCell[] {
    const x0 = src.x!
    const y0 = src.y!
    const x1 = dst.x!
    const y1 = dst.y!

    const dx = Math.sign(x1 - x0)
    const dy = Math.sign(y1 - y0)

    // Not straight
    if (dx !== 0 && dy !== 0) return []

    const srcCx = src.cx || 1
    const srcCy = src.cy || 1
    const dstCy = dst.cy || 1

    // Apply offset perpendicular to the direction of travel
    const offset = edge.offset || 0

    // Exit from source, enter to destination
    // For horizontal edges: exit right of source, enter left of dest
    // For vertical edges: exit below/above source, enter above/below dest
    const exitX = x0 + srcCx  // Cell to the right of source
    const exitY_horiz = y0 + Math.floor(srcCy / 2) + offset  // Middle row for horizontal + offset
    const exitY_vert = dy > 0 ? y0 + srcCy : y0 - 1  // Below/above for vertical

    const enterX = x1 - 1  // Cell to the left of dest
    const enterY_vert = dy > 0 ? y1 - 1 : y1 + dstCy  // Above/below for vertical
    const exitX_vert = x0 + offset  // Apply offset for vertical edges

    const path: PathCell[] = []

    // Check if nodes are 2 cells apart (short edge)
    const distance = dx !== 0 ? Math.abs(x1 - x0) : Math.abs(y1 - y0)
    if (distance === 2) {
      const x = dx !== 0 ? x0 + dx : x0 + offset
      const y = dy !== 0 ? y0 + dy : y0 + offset

      if (!this.isBlocked(x, y, src, dst)) {
        let type = EDGE_LABEL_CELL
        if (dx === 1) type += EDGE_SHORT_E
        if (dx === -1) type += EDGE_SHORT_W
        if (dy === 1) type += EDGE_SHORT_S
        if (dy === -1) type += EDGE_SHORT_N
        return [{ x, y, type }]
      }
    }

    // Try longer straight path
    if (dx !== 0) {
      // Horizontal - apply offset to Y
      let blocked = false
      for (let x = exitX; x <= enterX; x++) {
        if (this.isBlocked(x, exitY_horiz, src, dst)) {
          blocked = true
          break
        }
      }

      if (!blocked) {
        for (let x = exitX; x <= enterX; x++) {
          const type = path.length === 0 ? EDGE_HOR + EDGE_LABEL_CELL : EDGE_HOR
          path.push({ x, y: exitY_horiz, type })
        }
        return path
      }
    } else if (dy !== 0) {
      // Vertical - apply offset to X
      let blocked = false
      const startY = exitY_vert
      const endY = enterY_vert

      for (let y = startY; dy > 0 ? y <= endY : y >= endY; y += dy) {
        if (this.isBlocked(exitX_vert, y, src, dst)) {
          blocked = true
          break
        }
      }

      if (!blocked) {
        for (let y = startY; dy > 0 ? y <= endY : y >= endY; y += dy) {
          const type = path.length === 0 ? EDGE_VER + EDGE_LABEL_CELL : EDGE_VER
          path.push({ x: exitX_vert, y, type })
        }
        return path
      }
    }

    return []
  }

  /**
   * Tier 2: Try L-shaped path with one bend
   */
  private tryBendPath(src: Node, dst: Node, _edge: Edge): PathCell[] {
    const x0 = src.x!
    const y0 = src.y!
    const x1 = dst.x!
    const y1 = dst.y!

    const srcCx = src.cx || 1
    const srcCy = src.cy || 1
    const dstCy = dst.cy || 1

    // Calculate exit and enter points
    const exitX = x0 + srcCx  // Right of source
    const exitY = y0 + Math.floor(srcCy / 2)  // Middle row
    const enterX = x1 - 1  // Left of dest
    const enterY = y1 + Math.floor(dstCy / 2)  // Middle row

    // Calculate direction based on exit/enter points, not node positions
    const dx = Math.sign(enterX - exitX)
    const dy = Math.sign(enterY - exitY)

    // Need both dx and dy for a bend
    if (dx === 0 || dy === 0) return []

    // Try horizontal then vertical
    let path: PathCell[] = []
    let blocked = false

    // Horizontal segment
    let x = exitX
    let safetyCounter = 0
    const maxSteps = 100
    while (x !== enterX && safetyCounter++ < maxSteps) {
      if (this.isBlocked(x, exitY, src, dst)) {
        blocked = true
        break
      }
      const type = path.length === 0 ? EDGE_HOR + EDGE_LABEL_CELL : EDGE_HOR
      path.push({ x, y: exitY, type })
      x += dx
    }

    if (safetyCounter >= maxSteps) {
      console.warn(`tryBendPath: horizontal loop exceeded ${maxSteps} steps`)
      return []
    }

    if (!blocked) {
      // Check bend cell
      if (this.isBlocked(x, exitY, src, dst)) {
        blocked = true
      }

      if (!blocked) {
        // Add bend
        const bendType = this.getEdgeType(x - dx, exitY, x, exitY, x, exitY + dy)
        path.push({ x, y: exitY, type: bendType })

        // Vertical segment
        let y = exitY + dy
        safetyCounter = 0
        while (y !== enterY && safetyCounter++ < maxSteps) {
          if (this.isBlocked(x, y, src, dst)) {
            blocked = true
            break
          }
          path.push({ x, y, type: EDGE_VER })
          y += dy
        }

        if (safetyCounter >= maxSteps) {
          console.warn(`tryBendPath: vertical loop (try 1) exceeded ${maxSteps} steps`)
          blocked = true
        }
      }
    }

    if (!blocked) return path

    // Try vertical then horizontal
    path = []
    blocked = false

    let y = exitY + dy
    safetyCounter = 0
    while (y !== enterY && safetyCounter++ < maxSteps) {
      if (this.isBlocked(exitX, y, src, dst)) {
        blocked = true
        break
      }
      path.push({ x: exitX, y, type: EDGE_VER })
      y += dy
    }

    if (safetyCounter >= maxSteps) {
      console.warn(`tryBendPath: vertical loop (try 2) exceeded ${maxSteps} steps`)
      return []
    }

    if (!blocked) {
      if (this.isBlocked(exitX, y, src, dst)) {
        blocked = true
      }

      if (!blocked) {
        const bendType = this.getEdgeType(exitX, y - dy, exitX, y, exitX + dx, y)
        path.push({ x: exitX, y, type: bendType })

        x = exitX + dx
        safetyCounter = 0
        while (x !== enterX && safetyCounter++ < maxSteps) {
          if (this.isBlocked(x, y, src, dst)) {
            blocked = true
            break
          }
          const type = path.length === 0 ? EDGE_HOR + EDGE_LABEL_CELL : EDGE_HOR
          path.push({ x, y, type })
          x += dx
        }

        if (safetyCounter >= maxSteps) {
          console.warn(`tryBendPath: horizontal loop (try 2) exceeded ${maxSteps} steps`)
          blocked = true
        }
      }
    }

    return blocked ? [] : path
  }

  /**
   * Tier 3: Full A* pathfinding with Manhattan heuristic
   */
  private findPathAStar(src: Node, dst: Node, _edge: Edge): PathCell[] {
    if (this.debug) console.log(`# A* from ${src.x},${src.y} to ${dst.x},${dst.y}`)

    const srcCx = src.cx || 1
    const srcCy = src.cy || 1
    const dstCy = dst.cy || 1

    // Start positions (all cells around source node)
    const start: AStarNode[] = []
    const exitX = src.x! + srcCx
    const exitY = src.y! + Math.floor(srcCy / 2)

    start.push({
      f: this.manhattanDistance(exitX, exitY, dst.x!, dst.y!),
      g: 0,
      h: this.manhattanDistance(exitX, exitY, dst.x!, dst.y!),
      x: exitX,
      y: exitY,
      px: src.x! + srcCx - 1,  // inside source node
      py: exitY,
    })

    // Goal position
    const goalX = dst.x! - 1
    const goalY = dst.y! + Math.floor(dstCy / 2)

    // A* data structures
    const openList: AStarNode[] = [...start]
    const closedSet = new Set<string>()
    const cameFrom = new Map<string, { x: number; y: number; px: number; py: number; type: number }>()

    let maxTries = 500  // Reduced from 2000
    let tries = 0
    const maxOpenListSize = 1000  // Reduced from 5000 - prevent unbounded memory growth

    while (openList.length > 0 && tries++ < maxTries) {
      // Safety check: prevent open list from growing too large
      if (openList.length > maxOpenListSize) {
        if (this.debug) console.log(`# A* open list too large (${openList.length}), aborting`)
        return []
      }
      // Find node with lowest f score
      openList.sort((a, b) => a.f - b.f)
      const current = openList.shift()!

      const key = gridKey(current.x, current.y)

      // Reached goal?
      if (current.x === goalX && current.y === goalY) {
        return this.reconstructPath(cameFrom, current, src, dst)
      }

      closedSet.add(key)

      // Explore neighbors
      const neighbors = this.getNeighbors(current.x, current.y, src, dst)

      for (const [nx, ny] of neighbors) {
        const nKey = gridKey(nx, ny)
        if (closedSet.has(nKey)) continue

        // Calculate cost
        const moveCost = this.getMoveCost(current.px || current.x, current.py || current.y, current.x, current.y, nx, ny)
        const g = current.g + moveCost
        const h = this.manhattanDistance(nx, ny, goalX, goalY)
        const f = g + h

        // Check if already in open list with lower cost
        const existing = openList.find(n => n.x === nx && n.y === ny)
        if (existing && existing.g <= g) continue

        if (existing) {
          // Update existing node
          existing.g = g
          existing.f = f
          existing.px = current.x
          existing.py = current.y
        } else {
          // Add new node
          openList.push({ f, g, h, x: nx, y: ny, px: current.x, py: current.y })
        }

        // Store path info (without edge type - determined later in reconstructPath)
        if (!cameFrom.has(nKey)) {
          cameFrom.set(nKey, { x: current.x, y: current.y, px: current.px || current.x, py: current.py || current.y, type: 0 })
        } else if (g < (cameFrom.get(nKey)!.type || Infinity)) {
          // Update with better path
          cameFrom.set(nKey, { x: current.x, y: current.y, px: current.px || current.x, py: current.py || current.y, type: g })
        }
      }
    }

    if (this.debug) console.log(`# A* failed to find path after ${tries} tries`)
    return []
  }

  /**
   * Reconstruct path from A* came-from map
   *
   * Edge types are determined AFTER path is complete, matching Perl's algorithm
   */
  private reconstructPath(
    cameFrom: Map<string, { x: number; y: number; px: number; py: number; type: number }>,
    goal: AStarNode,
    _src: Node,
    _dst: Node
  ): PathCell[] {
    // First, build the path positions
    const positions: { x: number; y: number }[] = []
    let current = { x: goal.x, y: goal.y }

    positions.unshift(current)
    while (cameFrom.has(gridKey(current.x, current.y))) {
      const prev = cameFrom.get(gridKey(current.x, current.y))!
      current = { x: prev.x, y: prev.y }
      positions.unshift(current)
    }

    // Remove the first position (it's inside the source node)
    if (positions.length > 0) {
      positions.shift()
    }

    // Now determine edge types for each position using prev->current->next
    const path: PathCell[] = []
    for (let i = 0; i < positions.length; i++) {
      const curr = positions[i]
      const prev = i > 0 ? positions[i - 1] : positions[i]  // Use curr if no prev
      const next = i < positions.length - 1 ? positions[i + 1] : positions[i]  // Use curr if no next

      const type = this.getEdgeType(prev.x, prev.y, curr.x, curr.y, next.x, next.y)
      path.push({ x: curr.x, y: curr.y, type })
    }

    // Add label to first cell
    if (path.length > 0) {
      path[0].type |= EDGE_LABEL_CELL
    }

    return path
  }

  /**
   * Get neighbors of a cell for A* expansion
   */
  private getNeighbors(x: number, y: number, _src: Node, _dst: Node): [number, number][] {
    return [
      [x + 1, y],  // East
      [x, y + 1],  // South
      [x - 1, y],  // West
      [x, y - 1],  // North
    ]
  }

  /**
   * Calculate movement cost (A* modifier)
   *
   * Based on Perl's _astar_modifier:
   * - Base cost: 1
   * - Crossing edge: +30
   * - Direction change: +6
   */
  private getMoveCost(px: number, py: number, x: number, y: number, nx: number, ny: number): number {
    let cost = 1

    // Penalty for crossing existing edge
    const cell = this.graph.cells.get(gridKey(nx, ny))
    if (cell && cell.edge) {
      cost += 30  // harsh penalty
    }

    // Penalty for direction change (encourages straight paths)
    const dx1 = Math.sign(x - px)
    const dy1 = Math.sign(y - py)
    const dx2 = Math.sign(nx - x)
    const dy2 = Math.sign(ny - y)

    if (dx1 !== dx2 && dy1 !== dy2) {
      cost += 6
    }

    return cost
  }

  /**
   * Manhattan distance heuristic
   */
  private manhattanDistance(x1: number, y1: number, x2: number, y2: number): number {
    const dx = Math.abs(x2 - x1)
    const dy = Math.abs(y2 - y1)

    // Add 1 if we need to go around a corner
    const cornerPenalty = (dx !== 0 && dy !== 0) ? 1 : 0

    return dx + dy + cornerPenalty
  }

  /**
   * Determine edge type based on direction - EXACT match to Perl's _astar_edge_type
   *
   * Given three consecutive positions: (px,py) → (x,y) → (nx,ny)
   * Returns the edge type for cell at (x,y)
   */
  private getEdgeType(px: number, py: number, x: number, y: number, nx: number, ny: number): number {
    // Direction from previous to current
    let dx1 = Math.sign(x - px)
    let dy1 = Math.sign(y - py)

    // Direction from current to next
    let dx2 = Math.sign(nx - x)
    let dy2 = Math.sign(ny - y)

    // If next same as current (shouldn't happen), use current direction
    if (dx2 === 0 && dy2 === 0) {
      dx2 = dx1
      dy2 = dy1
    }

    // If no previous direction, use next direction
    if (dx1 === 0 && dy1 === 0) {
      dx1 = dx2
      dy1 = dy2
    }

    // EXACT lookup table from Perl (lines 599-621 of Scout.pm)
    const key = `${dx1},${dy1},${dx2},${dy2}`

    const edgeTypes: Record<string, number> = {
      // Straight edges
      '0,1,0,1': EDGE_VER,      // Down, continue down
      '-1,0,-1,0': EDGE_HOR,    // Left, continue left
      '1,0,1,0': EDGE_HOR,      // Right, continue right
      '0,-1,0,-1': EDGE_VER,    // Up, continue up

      // Corners - South to East/West
      '0,1,-1,0': EDGE_N_W,     // Down then left (┘)
      '0,1,1,0': EDGE_N_E,      // Down then right (└)

      // Corners - North to East/West
      '0,-1,-1,0': EDGE_S_W,    // Up then left (┐)
      '0,-1,1,0': EDGE_S_E,     // Up then right (┌)

      // Corners - East to North/South
      '1,0,0,-1': EDGE_N_W,     // Right then up (┘)
      '1,0,0,1': EDGE_S_W,      // Right then down (┐)

      // Corners - West to North/South
      '-1,0,0,-1': EDGE_S_E,    // Left then up (┌)
      '-1,0,0,1': EDGE_N_E,     // Left then down (└)
    }

    return edgeTypes[key] || EDGE_HOR  // Default to horizontal if not found
  }

  /**
   * Check if cell is blocked
   */
  private isBlocked(x: number, y: number, src: Node, dst: Node): boolean {
    const cell = this.graph.cells.get(gridKey(x, y))
    if (!cell) return false

    // Can pass through source or destination
    if (cell.node === src || cell.node === dst) return false

    // Blocked by nodes
    if (cell.node) return true

    // Blocked by edges from same source/dest (parallel edges)
    // This forces parallel edges to route around each other, creating arcs
    if (cell.edge) {
      const sameSource = cell.edge.from === src || cell.edge.to === src
      const sameDest = cell.edge.from === dst || cell.edge.to === dst
      if (sameSource && sameDest) {
        return true // Block parallel edges
      }
    }

    // Can cross unrelated edges (A* will handle via penalty)
    return false
  }
}
