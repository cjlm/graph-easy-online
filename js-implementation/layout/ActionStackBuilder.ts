/**
 * ActionStackBuilder - Builds the prioritized action stack for layout
 *
 * Based on Graph::Easy::Layout action stack construction
 *
 * The action stack determines the order in which:
 * 1. Nodes are placed
 * 2. Edges are routed
 *
 * Priority order:
 * 1. Root node first
 * 2. Nodes in chains (in chain order)
 * 3. Direct chain edges
 * 4. Internal chain edges (sorted by distance)
 * 5. Self-loops
 * 6. Remaining nodes and edges
 */

import { Graph } from '../core/Graph'
import { Node } from '../core/Node'
import { Edge } from '../core/Edge'
import { Chain } from './Chain'
import {
  Action,
  createNodeAction,
  createChainAction,
  createTraceAction,
} from './Action'

/**
 * Extend Edge to track if it's been added to action stack
 */
declare module '../core/Edge' {
  interface Edge {
    _done?: boolean
  }
}

export class ActionStackBuilder {
  private graph: Graph
  private chains: Chain[]

  constructor(graph: Graph, chains: Chain[]) {
    this.graph = graph
    this.chains = chains
  }

  /**
   * Build the complete action stack
   */
  buildStack(): Action[] {
    const actions: Action[] = []

    // Mark all edges as not done
    for (const edge of this.graph.getEdges()) {
      edge._done = false
    }

    // Process chains in order
    for (const chain of this.chains) {
      const chainActions = this.buildChainActions(chain)
      actions.push(...chainActions)
      chain.done = true
    }

    // Add any remaining nodes not in chains
    for (const node of this.graph.getNodes()) {
      if (!node._chain) {
        console.log(`  Adding NODE action for ${node.name} (not in chain)`)
        actions.push(createNodeAction(node))
      } else {
        console.log(`  Skipping ${node.name} (in chain ${node._chain.id})`)
      }
    }

    // Add any remaining edges not yet done
    for (const edge of this.graph.getEdges()) {
      if (!edge._done) {
        actions.push(createTraceAction(edge))
        edge._done = true
      }
    }

    return actions
  }

  /**
   * Build actions for a single chain
   */
  private buildChainActions(chain: Chain): Action[] {
    const actions: Action[] = []

    // First node in chain gets NODE action
    actions.push(createNodeAction(chain.start))

    // Subsequent nodes get CHAIN actions with parent reference
    let parent = chain.start
    for (let i = 1; i < chain.nodes.length; i++) {
      const node = chain.nodes[i]

      // Find edge from parent to this node
      const parentEdge = this.findEdge(parent, node)

      if (parentEdge) {
        // Get minimum edge length (default 2)
        const minLen = parentEdge.getAttribute('minlen') || 2

        actions.push(createChainAction(node, parent, parentEdge, minLen as number))

        // Mark direct chain edge as done
        parentEdge._done = true
      } else {
        // No edge found, just place node
        actions.push(createNodeAction(node))
      }

      parent = node
    }

    // Add internal chain edges (jumps within chain)
    actions.push(...this.buildInternalChainEdges(chain))

    // Add self-loops
    actions.push(...this.buildSelfLoops(chain))

    return actions
  }

  /**
   * Build actions for internal chain edges (forward jumps, backward edges)
   */
  private buildInternalChainEdges(chain: Chain): Action[] {
    const actions: Action[] = []
    const edgeActions: Array<{ distance: number; action: Action }> = []

    for (let i = 0; i < chain.nodes.length; i++) {
      const node = chain.nodes[i]
      const edges = node.edges()

      for (const edge of edges) {
        // Only outgoing edges
        if (edge.from !== node) continue

        // Skip if already done
        if (edge._done) continue

        // Check if target is in same chain
        if (edge.to._chain === chain) {
          // Internal chain edge
          const targetIndex = chain.nodes.indexOf(edge.to)

          if (targetIndex > -1) {
            // Calculate distance
            const distance = Math.abs(targetIndex - i)

            edgeActions.push({
              distance,
              action: createTraceAction(edge),
            })

            edge._done = true
          }
        }
      }
    }

    // Sort by distance (shortest first)
    edgeActions.sort((a, b) => a.distance - b.distance)

    // Extract actions
    actions.push(...edgeActions.map(ea => ea.action))

    return actions
  }

  /**
   * Build actions for self-loops
   */
  private buildSelfLoops(chain: Chain): Action[] {
    const actions: Action[] = []

    for (const node of chain.nodes) {
      const edges = node.edges()

      for (const edge of edges) {
        // Self-loop: from and to are same node
        if (edge.from === node && edge.to === node && !edge._done) {
          actions.push(createTraceAction(edge))
          edge._done = true
        }
      }
    }

    return actions
  }

  /**
   * Find edge between two nodes
   */
  private findEdge(from: Node, to: Node): Edge | undefined {
    const edges = from.edges()

    for (const edge of edges) {
      if (edge.from === from && edge.to === to) {
        return edge
      }
    }

    return undefined
  }
}
