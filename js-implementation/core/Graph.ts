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
  // @ts-expect-error - Reserved for future use
  private _config: GraphConfig

  // Layout state
  private layoutResult?: LayoutResult
  private dirty: boolean = true

  constructor(config: GraphConfig = {}) {
    this._config = {
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

    const result = this.computeLayout()
    this.layoutResult = result
    this.dirty = false

    return result
  }

  /**
   * Compute a simple layered layout for the graph
   */
  private computeLayout(): LayoutResult {
    const nodes = this.getNodes()
    const edges = this.getEdges()

    if (nodes.length === 0) {
      return { nodes: [], edges: [], bounds: { width: 0, height: 0 } }
    }

    const flow = this.getAttribute('flow') || 'east'
    const isHorizontal = flow === 'east' || flow === 'west'

    // Step 1: Assign nodes to ranks (layers)
    const ranks = this.assignRanks()

    // Step 2: Calculate node dimensions
    const nodeLayouts = new Map<string, NodeLayout>()
    const nodeHeight = 5 // Fixed height for ASCII boxes
    const nodeSpacing = 3 // Spacing between nodes within a rank
    const rankSpacing = 5 // Spacing between ranks

    // Step 3: Calculate rank positions (similar to WASM implementation)
    const rankPositions: number[] = []
    let currentPos = 0
    let maxRankSize = 0

    ranks.forEach((rankNodes) => {
      rankPositions.push(currentPos)

      // Find max node width/height in this rank
      const maxNodeSize = Math.max(
        ...rankNodes.map(node => {
          const label = node.name
          return isHorizontal
            ? Math.max(label.length + 4, 10) // Width for horizontal flow
            : nodeHeight // Height for vertical flow
        })
      )

      currentPos += maxNodeSize + rankSpacing
    })

    // Step 4: Position nodes in each rank
    const numRanks = ranks.size
    ranks.forEach((rankNodes, rankIndex) => {
      let offset = 0 // Offset within the rank

      rankNodes.forEach((node) => {
        const label = node.name
        const nodeWidth = Math.max(label.length + 4, 10) // Label + padding, min 10

        let x, y

        if (isHorizontal) {
          // Horizontal flow (east/west): ranks go left-to-right, nodes within rank stack top-to-bottom
          x = rankPositions[rankIndex]
          y = offset
        } else {
          // Vertical flow (north/south): ranks go top-to-bottom, nodes within rank go left-to-right
          x = offset
          y = rankPositions[rankIndex]
        }

        nodeLayouts.set(node.id, {
          id: node.id,
          x,
          y,
          width: nodeWidth,
          height: nodeHeight,
          label: label,
        })

        offset += (isHorizontal ? nodeHeight : nodeWidth) + nodeSpacing
        maxRankSize = Math.max(maxRankSize, offset - nodeSpacing)
      })
    })

    // Step 4: Route edges
    const edgeLayouts: EdgeLayout[] = edges.map(edge => {
      const fromLayout = nodeLayouts.get(edge.from.id)!
      const toLayout = nodeLayouts.get(edge.to.id)!

      // Calculate edge endpoints
      const fromCenterY = fromLayout.y + Math.floor(fromLayout.height / 2)
      const toCenterY = toLayout.y + Math.floor(toLayout.height / 2)

      // Edge exits from right of from-node, enters left of to-node
      // Leave 1 character gap for the arrow before the destination node
      const fromX = fromLayout.x + fromLayout.width
      const fromY = fromCenterY
      const toX = toLayout.x - 1  // Stop 1 char before the node border
      const toY = toCenterY

      // Simple routing: horizontal line, then vertical, then horizontal
      const points = []

      if (isHorizontal) {
        points.push({ x: fromX, y: fromY })

        // If nodes are on different ranks, add elbow
        if (fromY !== toY) {
          const midX = Math.floor((fromX + toX) / 2)
          points.push({ x: midX, y: fromY })
          points.push({ x: midX, y: toY })
        }

        points.push({ x: toX, y: toY })
      } else {
        // Vertical flow (not implemented yet, use horizontal)
        points.push({ x: fromX, y: fromY })
        points.push({ x: toX, y: toY })
      }

      return {
        id: edge.id,
        from: edge.from.id,
        to: edge.to.id,
        points,
        label: edge.label || edge.getAttribute('label'),
      }
    })

    // Calculate bounds based on flow direction
    const boundsWidth = isHorizontal
      ? currentPos  // Horizontal: width is the total accumulated position
      : maxRankSize  // Vertical: width is max rank size

    const boundsHeight = isHorizontal
      ? maxRankSize  // Horizontal: height is max rank size (nodes stack vertically)
      : currentPos  // Vertical: height is the total accumulated position

    return {
      nodes: Array.from(nodeLayouts.values()),
      edges: edgeLayouts,
      bounds: {
        width: boundsWidth,
        height: boundsHeight,
      },
    }
  }

  /**
   * Assign nodes to ranks (layers) using BFS from source nodes
   */
  private assignRanks(): Map<number, Node[]> {
    const nodes = this.getNodes()
    const edges = this.getEdges()
    const ranks = new Map<number, Node[]>()
    const nodeRank = new Map<string, number>()

    // Find source nodes (no incoming edges)
    const inDegree = new Map<string, number>()
    nodes.forEach(node => inDegree.set(node.id, 0))
    edges.forEach(edge => {
      inDegree.set(edge.to.id, (inDegree.get(edge.to.id) || 0) + 1)
    })

    const sources = nodes.filter(node => inDegree.get(node.id) === 0)

    if (sources.length === 0) {
      // Graph has cycles or all nodes have incoming edges
      // Just use all nodes as rank 0
      ranks.set(0, [...nodes])
      return ranks
    }

    // BFS to assign ranks
    const queue: Array<{ node: Node; rank: number }> = sources.map(node => ({
      node,
      rank: 0,
    }))

    const visited = new Set<string>()

    while (queue.length > 0) {
      const { node, rank } = queue.shift()!

      if (visited.has(node.id)) continue
      visited.add(node.id)

      // Assign this node to its rank
      nodeRank.set(node.id, rank)
      if (!ranks.has(rank)) ranks.set(rank, [])
      ranks.get(rank)!.push(node)

      // Find outgoing edges and add their targets to queue
      const outgoingEdges = edges.filter(e => e.from.id === node.id)
      outgoingEdges.forEach(edge => {
        if (!visited.has(edge.to.id)) {
          queue.push({ node: edge.to, rank: rank + 1 })
        }
      })
    }

    // Handle any unvisited nodes (shouldn't happen with proper graph)
    nodes.forEach(node => {
      if (!visited.has(node.id)) {
        const rank = 0
        if (!ranks.has(rank)) ranks.set(rank, [])
        ranks.get(rank)!.push(node)
      }
    })

    return ranks
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
