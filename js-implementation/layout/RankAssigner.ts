/**
 * RankAssigner - Assigns ranks to nodes using topological sort
 *
 * Based on Graph::Easy::Layout::_assign_ranks
 *
 * Algorithm:
 * 1. Find root node (or nodes with no predecessors)
 * 2. Use priority heap sorted by absolute rank value
 * 3. User-defined ranks are positive (1, 2, 3, ...)
 * 4. Auto-assigned ranks are negative (-1, -2, -3, ...)
 * 5. Process nodes in rank order, assigning ranks to successors
 */

import { MinPriorityQueue } from '@datastructures-js/priority-queue'
import { Graph } from '../core/Graph'
import { Node } from '../core/Node'

/**
 * Extend Node to add rank-related properties
 * (In Perl, these are added dynamically)
 */
declare module '../core/Node' {
  interface Node {
    rank?: number
  }
}

export class RankAssigner {
  private graph: Graph

  constructor(graph: Graph) {
    this.graph = graph
  }

  /**
   * Assign ranks to all nodes in the graph
   *
   * Returns: void (modifies nodes in place by setting rank property)
   */
  assignRanks(): void {
    // Create a priority queue sorted by absolute rank value
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const heap = new MinPriorityQueue<Node>((node: any) => Math.abs(node.rank ?? 0))

    // Nodes that haven't been ranked yet
    const unranked: Node[] = []

    // Get root node (if specified)
    const root = this.findRootNode()

    if (root) {
      root.rank = -1
      heap.enqueue(root)
    }

    // Get all nodes sorted by ID for deterministic ordering
    const nodes = this.graph.getNodes().sort((a, b) => a.id.localeCompare(b.id))

    // First pass: categorize nodes
    for (const node of nodes) {
      // Skip root if already processed
      if (root && node === root) continue

      // Check if node has explicit rank attribute
      const rankAttr = node.getAttribute('rank')

      let rank: number | undefined

      if (rankAttr !== undefined && rankAttr !== null && rankAttr !== 'auto') {
        // User-defined rank
        // Perl converts to positive ranks (1, 2, 3, ...)
        if (rankAttr === 'same') {
          rank = 0 // Will be handled specially
        } else {
          rank = Number(rankAttr) + 1 // Convert to 1-based positive
        }
      } else if (this.predecessorCount(node) === 0) {
        // No predecessors = root node
        rank = -1
      }

      if (rank !== undefined) {
        node.rank = rank
        heap.enqueue(node)
      } else {
        unranked.push(node)
      }
    }

    // Main ranking loop
    while (!heap.isEmpty() || unranked.length > 0) {
      // Process all nodes in heap
      while (!heap.isEmpty()) {
        const dequeuedNode = heap.dequeue()
        if (!dequeuedNode) break
        const currentRank = dequeuedNode.rank!

        // Calculate next rank for successors
        const nextRank = this.getNextRank(currentRank)

        // Assign rank to all successors
        for (const successor of this.successors(dequeuedNode)) {
          if (successor.rank === undefined) {
            successor.rank = nextRank

            // Remove from unranked list if present
            const index = unranked.indexOf(successor)
            if (index > -1) {
              unranked.splice(index, 1)
            }

            heap.enqueue(successor)
          }
        }
      }

      // If there are still unranked nodes, pick one and assign rank -1
      // This handles disconnected components
      if (unranked.length > 0) {
        const node = unranked.shift()!
        node.rank = -1
        heap.enqueue(node)
      }
    }
  }

  /**
   * Find the root node (node with 'root' attribute or first node with no predecessors)
   */
  private findRootNode(): Node | undefined {
    const nodes = this.graph.getNodes()

    // Check for explicit root attribute
    for (const node of nodes) {
      if (node.getAttribute('root') === true || node.getAttribute('root') === '1') {
        return node
      }
    }

    // Find first node with no predecessors
    for (const node of nodes) {
      if (this.predecessorCount(node) === 0) {
        return node
      }
    }

    // If graph has cycles or all nodes have predecessors, return first node
    return nodes[0]
  }

  /**
   * Get the count of predecessors for a node
   */
  private predecessorCount(node: Node): number {
    return this.predecessors(node).length
  }

  /**
   * Get all predecessor nodes (nodes with edges pointing to this node)
   */
  private predecessors(node: Node): Node[] {
    const preds: Node[] = []
    const edges = node.edges()

    for (const edge of edges) {
      if (edge.to === node && edge.from !== node) {
        // Incoming edge (but not self-loop)
        if (!preds.includes(edge.from)) {
          preds.push(edge.from)
        }
      }
    }

    return preds
  }

  /**
   * Get all successor nodes (nodes that this node points to)
   */
  private successors(node: Node): Node[] {
    const succs: Node[] = []
    const edges = node.edges()

    for (const edge of edges) {
      if (edge.from === node && edge.to !== node) {
        // Outgoing edge (but not self-loop)
        if (!succs.includes(edge.to)) {
          succs.push(edge.to)
        }
      }
    }

    return succs
  }

  /**
   * Calculate the next rank based on current rank
   *
   * Perl logic:
   * - User ranks (positive): decrement (1 -> 0 -> -1 -> -2 ...)
   * - Auto ranks (negative): decrement (-1 -> -2 -> -3 ...)
   */
  private getNextRank(currentRank: number): number {
    if (currentRank > 0) {
      // User-defined rank: decrement towards negative
      return currentRank - 1
    } else {
      // Auto rank: decrement further into negative
      return currentRank - 1
    }
  }
}
