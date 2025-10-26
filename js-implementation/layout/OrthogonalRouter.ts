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
  EDGE_S_E,
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
    // Use larger spacing (2 cells per offset) for better visual separation
    let yOffset = 0
    if (offset > 0) {
      const n = Math.ceil(offset / 2)
      yOffset = (offset % 2 === 0) ? -(n * 2) : (n * 2)
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

    // Otherwise: Manhattan routing (out -> over -> in)
    // Strategy: exit horizontally, turn vertically at midpoint, enter horizontally

    const midX = Math.floor((exitX + enterX) / 2)

    // Phase 1: Exit horizontally to midpoint
    for (let x = exitX; x < midX; x++) {
      if (!this.isBlocked(x, exitY, src, dst)) {
        path.push({ x, y: exitY, type: EDGE_HOR })
      }
    }

    // Phase 2: Turn corner and go vertically
    const yStep = enterY > exitY ? 1 : -1

    for (let y = exitY; yStep > 0 ? y <= enterY : y >= enterY; y += yStep) {
      if (y === exitY) {
        // First corner cell
        const cornerType = enterY > exitY ? EDGE_S_E : EDGE_N_E
        path.push({ x: midX, y, type: cornerType })
      } else if (y === enterY) {
        // Last corner cell before horizontal run
        const cornerType = enterY > exitY ? EDGE_N_E : EDGE_S_E
        path.push({ x: midX, y, type: cornerType })
      } else {
        // Vertical segment
        path.push({ x: midX, y, type: EDGE_VER })
      }
    }

    // Phase 3: Enter horizontally from midpoint to destination
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
