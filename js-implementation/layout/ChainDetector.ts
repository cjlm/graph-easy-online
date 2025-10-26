/**
 * ChainDetector - Finds chains (linear sequences) in the graph
 *
 * Based on Graph::Easy::Layout::_find_chains and _follow_chain
 *
 * Algorithm:
 * 1. Iterate through all nodes (sorted by ID for determinism)
 * 2. For each node not in a chain, start following forward
 * 3. Continue while node has exactly one successor
 * 4. When multiple successors found:
 *    - Recursively follow each successor
 *    - Find longest resulting chain
 *    - Merge that chain back into current chain
 * 5. Terminate on cycles (node already in this chain)
 */

import { Graph } from '../core/Graph'
import { Node } from '../core/Node'
import { Edge } from '../core/Edge'
import { Chain } from './Chain'

export class ChainDetector {
  private graph: Graph

  constructor(graph: Graph) {
    this.graph = graph
  }

  /**
   * Find all chains in the graph
   *
   * Returns: Array of chains, sorted by:
   * 1. Contains root node (first)
   * 2. Length (longest first)
   * 3. Alphabetical by start node name
   */
  findChains(): Chain[] {
    const chains: Chain[] = []

    // Get all nodes sorted by ID for deterministic ordering
    const nodes = this.graph.getNodes().sort((a, b) => a.id.localeCompare(b.id))

    // Process each node
    for (const node of nodes) {
      // Skip if already in a chain
      if (node._chain) continue

      // Start a new chain from this node
      const chain = this.followChain(node)
      chains.push(chain)
    }

    // Sort chains by priority
    return this.sortChains(chains)
  }

  /**
   * Follow a chain starting from a node
   *
   * This implements the Perl _follow_chain logic with recursive merging
   */
  private followChain(startNode: Node): Chain {
    const chain = new Chain(startNode, this.graph)

    let currentNode = startNode

    while (true) {
      // Get unique successors (ignoring self-loops, multi-edges, same-chain nodes)
      const successors = this.getUniqueSuccessors(currentNode, chain)

      if (successors.length === 0) {
        // Chain ends here
        break
      }

      if (successors.length === 1) {
        // Single successor: continue chain
        const successor = successors[0]

        // Check if already in this chain (cycle detection)
        if (chain.contains(successor)) {
          break
        }

        // Check if already in another chain
        if (successor._chain) {
          break
        }

        chain.addNode(successor)
        currentNode = successor
        continue
      }

      // Multiple successors: recursively follow each and merge longest
      let longestChain: Chain | null = null
      let maxLength = 0

      for (const successor of successors) {
        // Skip if already in a chain
        if (successor._chain) continue

        // Recursively follow this successor
        const successorChain = this.followChain(successor)

        // Track longest chain
        if (successorChain.length > maxLength) {
          maxLength = successorChain.length
          longestChain = successorChain
        }
      }

      // Merge longest chain back into current chain
      if (longestChain) {
        chain.merge(longestChain, currentNode)
      }

      // Done with this chain
      break
    }

    return chain
  }

  /**
   * Get unique successors of a node
   *
   * Filters out:
   * - Self-loops
   * - Duplicate edges to same node
   * - Nodes already in the given chain
   */
  private getUniqueSuccessors(node: Node, chain: Chain): Node[] {
    const successors: Node[] = []
    const seen = new Set<string>()

    const edges = node.edges()

    for (const edge of edges) {
      // Only outgoing edges
      if (edge.from !== node) continue

      // Skip self-loops
      if (edge.to === node) continue

      // Skip if already in chain
      if (chain.contains(edge.to)) continue

      // Skip duplicates
      if (seen.has(edge.to.id)) continue

      successors.push(edge.to)
      seen.add(edge.to.id)
    }

    return successors
  }

  /**
   * Sort chains by priority:
   * 1. Chain containing root node first
   * 2. Longer chains first
   * 3. Alphabetical by start node name
   */
  private sortChains(chains: Chain[]): Chain[] {
    const rootNode = this.findRootNode()

    return chains.sort((a, b) => {
      // Root chain first
      const aHasRoot = rootNode && a.contains(rootNode)
      const bHasRoot = rootNode && b.contains(rootNode)

      if (aHasRoot && !bHasRoot) return -1
      if (!aHasRoot && bHasRoot) return 1

      // Longer chains first
      if (a.length !== b.length) {
        return b.length - a.length
      }

      // Alphabetical by start node name
      return a.start.name.localeCompare(b.start.name)
    })
  }

  /**
   * Find the root node (same logic as RankAssigner)
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

    return nodes[0]
  }

  /**
   * Count predecessors of a node
   */
  private predecessorCount(node: Node): number {
    let count = 0
    const edges = node.edges()

    for (const edge of edges) {
      if (edge.to === node && edge.from !== node) {
        count++
      }
    }

    return count
  }
}
