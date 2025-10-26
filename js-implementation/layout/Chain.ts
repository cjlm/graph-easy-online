/**
 * Chain - Represents a linear sequence of connected nodes
 *
 * Based on Graph::Easy::Layout::Chain
 *
 * A chain is a sequence of nodes connected in a line, which allows
 * the layout algorithm to place them efficiently without branches.
 */

import { Graph } from '../core/Graph.ts'
import { Node } from '../core/Node.ts'

// Edge import kept for module augmentation declarations
// @ts-ignore - used in module augmentation
import { Edge } from '../core/Edge.ts'

/**
 * Extend Node to add chain-related properties
 */
declare module '../core/Node' {
  interface Node {
    _chain?: Chain
    _next?: Node
  }
}

export class Chain {
  /** Unique identifier */
  id: string

  /** First node in chain */
  start: Node

  /** Last node in chain */
  end: Node

  /** All nodes in order */
  nodes: Node[]

  /** Parent graph */
  graph: Graph

  /** Whether this chain has been laid out */
  done: boolean

  constructor(startNode: Node, graph: Graph) {
    this.id = `chain_${Math.random().toString(36).substr(2, 9)}`
    this.start = startNode
    this.end = startNode
    this.nodes = [startNode]
    this.graph = graph
    this.done = false

    // Mark node as belonging to this chain
    startNode._chain = this
  }

  /**
   * Get the length of the chain (number of nodes)
   */
  get length(): number {
    return this.nodes.length
  }

  /**
   * Add a node to the end of the chain
   */
  addNode(node: Node): void {
    // Set up linked list structure
    this.end._next = node
    this.end = node
    this.nodes.push(node)

    // Mark node as belonging to this chain
    node._chain = this
  }

  /**
   * Merge another chain into this chain at a specific position
   *
   * @param otherChain - Chain to merge
   * @param atNode - Node at which to merge (must be in this chain)
   */
  merge(otherChain: Chain, atNode: Node): void {
    // Find position of atNode in this chain
    const index = this.nodes.indexOf(atNode)
    if (index === -1) {
      throw new Error(`Node ${atNode.name} not found in chain`)
    }

    // Detect loops: if any node in otherChain is already in this chain, stop
    for (const node of otherChain.nodes) {
      if (this.nodes.includes(node)) {
        // Loop detected, don't merge
        return
      }
    }

    // Insert other chain's nodes after atNode
    const before = this.nodes.slice(0, index + 1)
    const after = this.nodes.slice(index + 1)
    this.nodes = [...before, ...otherChain.nodes, ...after]

    // Update chain references
    for (const node of otherChain.nodes) {
      node._chain = this
    }

    // Update linked list pointers
    atNode._next = otherChain.start
    otherChain.end._next = after[0] || undefined

    // Update end pointer if we merged at the end
    if (after.length === 0) {
      this.end = otherChain.end
    }
  }

  /**
   * Check if a node is in this chain
   */
  contains(node: Node): boolean {
    return this.nodes.includes(node)
  }

  /**
   * Get a string representation for debugging
   */
  toString(): string {
    const names = this.nodes.map(n => n.name).join(' -> ')
    return `Chain[${this.id}]: ${names}`
  }
}
