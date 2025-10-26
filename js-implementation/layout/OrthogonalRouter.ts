/**
 * OrthogonalRouter - Routes edges using only horizontal/vertical segments
 *
 * Based on Perl Graph::Easy orthogonal routing
 *
 * Key principles:
 * 1. Edges only go horizontal or vertical (no diagonals)
 * 2. Multi-edges are bundled and offset in parallel
 * 3. Uses Manhattan routing: out -> across -> in
 * 4. Avoids nodes and minimizes crossings
 */

import { Graph } from '../core/Graph.ts'
import { Node } from '../core/Node.ts'
import { Edge } from '../core/Edge.ts'
import {
  gridKey,
  EDGE_HOR,
  EDGE_VER,
  EDGE_N_E,
  EDGE_S_E,
} from '../core/Cell.ts'

interface PathCell {
  x: number
  y: number
  type: number
}

export class OrthogonalRouter {
  private graph: Graph
  private edgeCountBySource: Map<string, number> = new Map()

  constructor(graph: Graph) {
    this.graph = graph
  }

  /**
   * Route an edge using orthogonal (Manhattan) routing
   */
  routeEdge(edge: Edge): PathCell[] {
    const src = edge.from
    const dst = edge.to

    if (src.x === undefined || src.y === undefined) {
      throw new Error(`Source node ${src.name} not placed`)
    }
    if (dst.x === undefined || dst.y === undefined) {
      throw new Error(`Destination node ${dst.name} not placed`)
    }

    // Track edges by source node to properly offset multi-edges
    // This ensures all edges from a node get unique offsets
    const srcKey = src.id
    const count = this.edgeCountBySource.get(srcKey) || 0
    this.edgeCountBySource.set(srcKey, count + 1)

    // Calculate offset for this edge based on source node's edge count
    const offset = count

    // Route orthogonally
    return this.routeManhattan(src, dst, offset)
  }

  /**
   * Manhattan routing: go out, across, then in
   *
   * For horizontal flow (east):
   * 1. Exit source node going right
   * 2. Move to appropriate Y level (offset for multi-edges)
   * 3. Move horizontally toward destination
   * 4. Move vertically to destination Y
   * 5. Enter destination node
   */
  private routeManhattan(src: Node, dst: Node, offset: number): PathCell[] {
    const path: PathCell[] = []

    const srcCx = src.cx || 1
    const srcCy = src.cy || 1
    const dstCy = dst.cy || 1

    // Source and destination centers
    const srcCenterY = src.y! + Math.floor(srcCy / 2)
    const dstCenterY = dst.y! + Math.floor(dstCy / 2)

    // All edges exit from the center of the source node
    const exitX = src.x! + srcCx
    const exitY = srcCenterY

    // Calculate the routing Y level based on offset
    // Use 1 cell per offset, alternating above/below center
    let routingYOffset = 0
    if (offset > 0) {
      const n = Math.ceil(offset / 2)
      routingYOffset = (offset % 2 === 0) ? -n : n
    }
    const routingY = srcCenterY + routingYOffset

    // Destination entry point
    const enterX = dst.x! - 1
    const enterY = dstCenterY

    // If routing Y equals both exit and enter Y, use simple horizontal path
    if (routingY === exitY && routingY === enterY && offset === 0) {
      // Simple horizontal path for first edge when all are aligned
      for (let x = exitX; x < enterX; x++) {
        if (!this.isBlocked(x, exitY, src, dst)) {
          path.push({ x, y: exitY, type: EDGE_HOR })
        }
      }
      return path
    }

    // Fan-out routing strategy:
    // 1. Exit horizontally for a short distance
    // 2. Turn and go vertically to routing Y level
    // 3. Route horizontally at routing Y level
    // 4. Turn and go vertically to destination center
    // 5. Enter horizontally

    // Calculate midX with offset for horizontal routing
    const baseMidX = Math.floor((exitX + enterX) / 2)
    const midX = baseMidX + Math.floor(offset / 2)

    // Fan-out distance: vary slightly by offset to stagger turns
    // Use smaller increment to avoid excessive horizontal spread
    const fanOutX = exitX + 3 + Math.floor(offset / 2)

    // Phase 1: Exit horizontally from source center
    for (let x = exitX; x < fanOutX; x++) {
      if (!this.isBlocked(x, exitY, src, dst)) {
        path.push({ x, y: exitY, type: EDGE_HOR })
      }
    }

    // Phase 2: Turn and go vertically to routing Y level
    if (routingY !== exitY) {
      const yStep = routingY > exitY ? 1 : -1
      for (let y = exitY; yStep > 0 ? y <= routingY : y >= routingY; y += yStep) {
        if (y === exitY) {
          const cornerType = routingY > exitY ? EDGE_S_E : EDGE_N_E
          path.push({ x: fanOutX, y, type: cornerType })
        } else if (y === routingY) {
          const cornerType = routingY > exitY ? EDGE_N_E : EDGE_S_E
          path.push({ x: fanOutX, y, type: cornerType })
        } else {
          path.push({ x: fanOutX, y, type: EDGE_VER })
        }
      }
    }

    // Phase 3: Route horizontally at routing Y level to midpoint
    const startX = fanOutX + 1
    for (let x = startX; x < midX; x++) {
      if (!this.isBlocked(x, routingY, src, dst)) {
        path.push({ x, y: routingY, type: EDGE_HOR })
      }
    }

    // Phase 4: Turn and go vertically to destination center
    if (routingY !== enterY) {
      const yStep = enterY > routingY ? 1 : -1
      for (let y = routingY; yStep > 0 ? y <= enterY : y >= enterY; y += yStep) {
        if (y === routingY) {
          const cornerType = enterY > routingY ? EDGE_S_E : EDGE_N_E
          path.push({ x: midX, y, type: cornerType })
        } else if (y === enterY) {
          const cornerType = enterY > routingY ? EDGE_N_E : EDGE_S_E
          path.push({ x: midX, y, type: cornerType })
        } else {
          path.push({ x: midX, y, type: EDGE_VER })
        }
      }
    }

    // Phase 5: Enter destination horizontally
    for (let x = midX + 1; x < enterX; x++) {
      if (!this.isBlocked(x, enterY, src, dst)) {
        path.push({ x, y: enterY, type: EDGE_HOR })
      }
    }

    return path
  }

  /**
   * Check if a cell is blocked by a node
   */
  private isBlocked(x: number, y: number, src: Node, dst: Node): boolean {
    const cell = this.graph.cells.get(gridKey(x, y))
    if (!cell) return false

    // Can pass through source or destination
    if (cell.node === src || cell.node === dst) return false

    // Blocked by other nodes
    return cell.node !== undefined
  }
}
