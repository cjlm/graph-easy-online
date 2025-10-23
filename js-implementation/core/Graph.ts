/**
 * Graph class - Core data structure for representing graphs
 *
 * This is a modern TypeScript reimplementation of Graph::Easy's graph structure
 */

import { Node } from './Node'
import { Edge } from './Edge'
import { Group } from './Group'
import { AttributeManager, GraphAttributes } from './Attributes'

export interface GraphConfig {
  debug?: boolean
  timeout?: number
  strict?: boolean
  undirected?: boolean
}

export interface LayoutResult {
  nodes: NodeLayout[]
  edges: EdgeLayout[]
  bounds: { width: number; height: number }
}

export interface NodeLayout {
  id: string
  x: number
  y: number
  width: number
  height: number
  label: string
}

export interface EdgeLayout {
  id: string
  from: string
  to: string
  points: Array<{ x: number; y: number }>
  label?: string
}

export class Graph {
  // Core collections
  private nodes: Map<string, Node> = new Map()
  private edges: Map<string, Edge> = new Map()
  private groups: Map<string, Group> = new Map()

  // Attributes and configuration
  private attributes: AttributeManager
  private config: GraphConfig

  // Layout state
  private layoutResult?: LayoutResult
  private dirty: boolean = true

  constructor(config: GraphConfig = {}) {
    this.config = {
      debug: config.debug ?? false,
      timeout: config.timeout ?? 5,
      strict: config.strict ?? true,
      undirected: config.undirected ?? false,
    }

    this.attributes = new AttributeManager({
      type: config.undirected ? 'undirected' : 'directed',
      flow: 'east',
      ...config,
    } as GraphAttributes)
  }

  // ===== Node Management =====

  /**
   * Add a node to the graph
   */
  addNode(nameOrNode: string | Node): Node {
    let node: Node

    if (typeof nameOrNode === 'string') {
      // Check if node already exists
      const existing = this.nodes.get(nameOrNode)
      if (existing) return existing

      node = new Node(nameOrNode, this)
    } else {
      node = nameOrNode

      // Check if node already exists
      const existing = this.nodes.get(node.name)
      if (existing) return existing

      // Attach to this graph
      node.setGraph(this)
    }

    this.nodes.set(node.name, node)
    this.markDirty()

    return node
  }

  /**
   * Add multiple nodes at once
   */
  addNodes(...names: string[]): Node[] {
    return names.map(name => this.addNode(name))
  }

  /**
   * Get a node by name
   */
  node(name: string): Node | undefined {
    return this.nodes.get(name)
  }

  /**
   * Delete a node and all its edges
   */
  deleteNode(nameOrNode: string | Node): boolean {
    const node = typeof nameOrNode === 'string'
      ? this.nodes.get(nameOrNode)
      : nameOrNode

    if (!node) return false

    // Delete all edges connected to this node
    for (const edge of this.edges.values()) {
      if (edge.from === node || edge.to === node) {
        this.deleteEdge(edge)
      }
    }

    // Remove from group if any
    if (node.group) {
      node.group.removeMember(node)
    }

    this.nodes.delete(node.name)
    this.markDirty()

    return true
  }

  /**
   * Get all nodes
   */
  getNodes(): Node[] {
    return Array.from(this.nodes.values())
  }

  /**
   * Get nodes sorted by a field
   */
  getSortedNodes(field: keyof Node = 'id'): Node[] {
    return Array.from(this.nodes.values()).sort((a, b) => {
      const aVal = a[field]
      const bVal = b[field]

      if (typeof aVal === 'string' && typeof bVal === 'string') {
        return aVal.localeCompare(bVal)
      }

      if (typeof aVal === 'number' && typeof bVal === 'number') {
        return aVal - bVal
      }

      return 0
    })
  }

  // ===== Edge Management =====

  /**
   * Add an edge between two nodes
   */
  addEdge(
    from: string | Node,
    to: string | Node,
    edgeOrLabel?: Edge | string
  ): Edge {
    // Convert to nodes
    const fromNode = typeof from === 'string' ? this.addNode(from) : from
    const toNode = typeof to === 'string' ? this.addNode(to) : to

    // Create or use edge
    let edge: Edge
    if (edgeOrLabel instanceof Edge) {
      edge = edgeOrLabel
      edge.setNodes(fromNode, toNode)
    } else {
      edge = new Edge(fromNode, toNode, this)
      if (typeof edgeOrLabel === 'string') {
        edge.setAttribute('label', edgeOrLabel)
      }
    }

    this.edges.set(edge.id, edge)

    // Register edge with nodes
    fromNode.addEdge(edge)
    toNode.addEdge(edge)

    this.markDirty()

    return edge
  }

  /**
   * Add an edge only if it doesn't already exist
   */
  addEdgeOnce(
    from: string | Node,
    to: string | Node,
    edgeOrLabel?: Edge | string
  ): Edge | null {
    const fromNode = typeof from === 'string' ? this.addNode(from) : from
    const toNode = typeof to === 'string' ? this.addNode(to) : to

    // Check if edge already exists
    const existing = this.edge(fromNode, toNode)
    if (existing) return null

    return this.addEdge(fromNode, toNode, edgeOrLabel)
  }

  /**
   * Get edge(s) between two nodes
   */
  edge(from: string | Node, to: string | Node): Edge | null {
    const fromNode = typeof from === 'string' ? this.nodes.get(from) : from
    const toNode = typeof to === 'string' ? this.nodes.get(to) : to

    if (!fromNode || !toNode) return null

    // Find edges from fromNode to toNode
    for (const edge of this.edges.values()) {
      if (edge.from === fromNode && edge.to === toNode) {
        return edge
      }
    }

    return null
  }

  /**
   * Get all edges between two nodes
   */
  edgesBetween(from: string | Node, to: string | Node): Edge[] {
    const fromNode = typeof from === 'string' ? this.nodes.get(from) : from
    const toNode = typeof to === 'string' ? this.nodes.get(to) : to

    if (!fromNode || !toNode) return []

    return Array.from(this.edges.values()).filter(
      edge => edge.from === fromNode && edge.to === toNode
    )
  }

  /**
   * Delete an edge
   */
  deleteEdge(edge: Edge): boolean {
    if (!this.edges.has(edge.id)) return false

    // Remove from nodes
    edge.from.removeEdge(edge)
    edge.to.removeEdge(edge)

    // Remove from group if any
    if (edge.group) {
      edge.group.removeMember(edge)
    }

    this.edges.delete(edge.id)
    this.markDirty()

    return true
  }

  /**
   * Get all edges
   */
  getEdges(): Edge[] {
    return Array.from(this.edges.values())
  }

  /**
   * Flip direction of edges between two nodes
   */
  flipEdges(from: string | Node, to: string | Node): this {
    const edges = this.edgesBetween(from, to)

    for (const edge of edges) {
      edge.flip()
    }

    this.markDirty()
    return this
  }

  // ===== Group Management =====

  /**
   * Add a group
   */
  addGroup(nameOrGroup: string | Group): Group {
    let group: Group

    if (typeof nameOrGroup === 'string') {
      const existing = this.groups.get(nameOrGroup)
      if (existing) return existing

      group = new Group(nameOrGroup, this)
    } else {
      group = nameOrGroup

      const existing = this.groups.get(group.name)
      if (existing) return existing

      group.setGraph(this)
    }

    this.groups.set(group.name, group)
    this.markDirty()

    return group
  }

  /**
   * Get a group by name
   */
  group(name: string): Group | undefined {
    return this.groups.get(name)
  }

  /**
   * Get all groups
   */
  getGroups(): Group[] {
    return Array.from(this.groups.values())
  }

  /**
   * Delete a group
   */
  deleteGroup(nameOrGroup: string | Group): boolean {
    const group = typeof nameOrGroup === 'string'
      ? this.groups.get(nameOrGroup)
      : nameOrGroup

    if (!group) return false

    // Remove all members from group
    for (const member of group.getMembers()) {
      group.removeMember(member)
    }

    this.groups.delete(group.name)
    this.markDirty()

    return true
  }

  // ===== Graph Properties =====

  /**
   * Check if graph is directed
   */
  isDirected(): boolean {
    return this.attributes.get('type') === 'directed'
  }

  /**
   * Check if graph is undirected
   */
  isUndirected(): boolean {
    return this.attributes.get('type') === 'undirected'
  }

  /**
   * Check if graph is simple (no multi-edges)
   */
  isSimple(): boolean {
    const seen = new Set<string>()

    for (const edge of this.edges.values()) {
      const key = `${edge.from.id},${edge.to.id}`
      if (seen.has(key)) return false
      seen.add(key)
    }

    return true
  }

  /**
   * Get source nodes (nodes with only outgoing edges)
   */
  getSourceNodes(): Node[] {
    return this.getNodes().filter(
      node => node.outgoingEdges().length > 0 &&
              node.incomingEdges().length === 0
    )
  }

  /**
   * Get root node if specified
   */
  getRootNode(): Node | undefined {
    const rootName = this.attributes.get('root')
    return rootName ? this.nodes.get(rootName) : undefined
  }

  // ===== Attribute Management =====

  /**
   * Set an attribute on the graph or a class
   */
  setAttribute(name: string, value: any): this
  setAttribute(selector: string, name: string, value: any): this
  setAttribute(
    selectorOrName: string,
    nameOrValue: any,
    value?: any
  ): this {
    if (arguments.length === 2) {
      // Called as: setAttribute(name, value)
      this.attributes.set(selectorOrName, nameOrValue)
    } else {
      // Called as: setAttribute(selector, name, value)
      this.attributes.setForSelector(selectorOrName, nameOrValue, value!)
    }

    this.markDirty()
    return this
  }

  /**
   * Get an attribute value
   */
  getAttribute(name: string): any {
    return this.attributes.get(name)
  }

  // ===== Layout =====

  /**
   * Mark graph as dirty (needs re-layout)
   */
  private markDirty(): void {
    this.dirty = true
    this.layoutResult = undefined
  }

  /**
   * Compute graph layout
   */
  async layout(): Promise<LayoutResult> {
    if (!this.dirty && this.layoutResult) {
      return this.layoutResult
    }

    // This would call into the WASM layout engine
    // For now, return a placeholder

    console.log('Layout would be computed here')

    // Placeholder layout
    const result: LayoutResult = {
      nodes: this.getNodes().map((node, i) => ({
        id: node.id,
        x: i * 100,
        y: 0,
        width: 80,
        height: 40,
        label: node.name,
      })),
      edges: this.getEdges().map(edge => ({
        id: edge.id,
        from: edge.from.id,
        to: edge.to.id,
        points: [
          { x: 0, y: 0 },
          { x: 100, y: 0 },
        ],
      })),
      bounds: {
        width: this.nodes.size * 100,
        height: 100,
      },
    }

    this.layoutResult = result
    this.dirty = false

    return result
  }

  // ===== Statistics =====

  /**
   * Get graph statistics
   */
  stats() {
    return {
      nodes: this.nodes.size,
      edges: this.edges.size,
      groups: this.groups.size,
      isSimple: this.isSimple(),
      isDirected: this.isDirected(),
    }
  }

  /**
   * Generate a unique ID
   */
  private static idCounter = 0
  static generateId(): string {
    return `id_${++Graph.idCounter}`
  }
}
