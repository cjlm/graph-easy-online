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

import { Graph } from '../core/Graph'
import { Node } from '../core/Node'
import { Edge } from '../core/Edge'
import {
  gridKey,
  EDGE_HOR,
  EDGE_VER,
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

export class OrthogonalRouter {
  private graph: Graph
  private multiEdgeCount: Map<string, number> = new Map()

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

    // Track multi-edges
    const edgeKey = this.getEdgeKey(src, dst)
    const count = this.multiEdgeCount.get(edgeKey) || 0
    this.multiEdgeCount.set(edgeKey, count + 1)

    // Calculate offset for this edge
    const offset = count

    // Route orthogonally
    return this.routeManhattan(src, dst, offset)
  }

  /**
   * Get edge key for multi-edge tracking
   */
  private getEdgeKey(src: Node, dst: Node): string {
    const ids = [src.id, dst.id].sort()
    return `${ids[0]}-${ids[1]}`
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

    // Calculate offset Y (alternating above/below center)
    let yOffset = 0
    if (offset > 0) {
      const n = Math.ceil(offset / 2)
      yOffset = (offset % 2 === 0) ? -n : n
    }

    // Exit source node (right side, at center + offset)
    const exitX = src.x! + srcCx
    const exitY = srcCenterY + yOffset

    // Enter destination node (left side, at center + offset)
    const enterX = dst.x! - 1
    const enterY = dstCenterY + yOffset

    // If nodes are at same Y level and horizontally aligned, simple path
    if (exitY === enterY) {
      // Simple horizontal path
      for (let x = exitX; x < enterX; x++) {
        if (!this.isBlocked(x, exitY, src, dst)) {
          path.push({ x, y: exitY, type: EDGE_HOR })
        }
      }
      return path
    }

    // Otherwise: out -> across -> in

    // Step 1: Exit source horizontally a bit
    const outDistance = 2
    let currentX = exitX
    for (let i = 0; i < outDistance; i++) {
      if (currentX < enterX) {
        path.push({ x: currentX, y: exitY, type: EDGE_HOR })
        currentX++
      }
    }

    // Step 2: Move vertically to destination Y level
    const step = enterY > exitY ? 1 : -1
    let currentY = exitY
    for (let y = exitY; step > 0 ? y < enterY : y > enterY; y += step) {
      if (y !== exitY) {
        path.push({ x: currentX, y, type: EDGE_VER })
      }
      currentY = y
    }

    // Add corner if we changed direction
    if (currentY !== exitY && currentX !== exitX) {
      // Replace last cell with corner
      if (path.length > 0) {
        const last = path[path.length - 1]
        if (enterY > exitY) {
          last.type = currentX > exitX ? EDGE_S_E : EDGE_S_W
        } else {
          last.type = currentX > exitX ? EDGE_N_E : EDGE_N_W
        }
      }
    }

    // Step 3: Move horizontally to destination X
    for (let x = currentX; x < enterX; x++) {
      path.push({ x, y: enterY, type: EDGE_HOR })
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
