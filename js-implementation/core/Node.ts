/**
 * Node class - Represents a node/vertex in the graph
 */

import type { Graph } from './Graph'
import type { Edge } from './Edge'
import type { Group } from './Group'
import { AttributeManager } from './Attributes'

export class Node {
  readonly id: string
  readonly name: string
  private graph_: Graph | null = null
  private edges_: Set<Edge> = new Set()
  private group_: Group | null = null
  private attributes: AttributeManager

  constructor(name: string, graph?: Graph) {
    this.id = Graph.generateId()
    this.name = name
    this.attributes = new AttributeManager()

    if (graph) {
      this.graph_ = graph
    }
  }

  // ===== Graph Association =====

  get graph(): Graph | null {
    return this.graph_
  }

  setGraph(graph: Graph): void {
    this.graph_ = graph
  }

  // ===== Group Association =====

  get group(): Group | null {
    return this.group_
  }

  setGroup(group: Group | null): void {
    this.group_ = group
  }

  /**
   * Add this node to a group
   */
  addToGroup(group: Group): void {
    if (this.group_ && this.group_ !== group) {
      this.group_.removeMember(this)
    }

    this.group_ = group
    group.addMember(this)
  }

  // ===== Edge Management =====

  /**
   * Add an edge to this node's edge list
   */
  addEdge(edge: Edge): void {
    this.edges_.add(edge)
  }

  /**
   * Remove an edge from this node's edge list
   */
  removeEdge(edge: Edge): void {
    this.edges_.delete(edge)
  }

  /**
   * Get all edges connected to this node
   */
  edges(): Edge[] {
    return Array.from(this.edges_)
  }

  /**
   * Get edges going TO this node
   */
  incomingEdges(): Edge[] {
    return Array.from(this.edges_).filter(e => e.to === this)
  }

  /**
   * Get edges going FROM this node
   */
  outgoingEdges(): Edge[] {
    return Array.from(this.edges_).filter(e => e.from === this)
  }

  /**
   * Get edges going TO a specific node
   */
  edgesTo(target: Node): Edge[] {
    return this.outgoingEdges().filter(e => e.to === target)
  }

  /**
   * Get edges coming FROM a specific node
   */
  edgesFrom(source: Node): Edge[] {
    return this.incomingEdges().filter(e => e.from === source)
  }

  /**
   * Check if this node has predecessors (incoming edges)
   */
  hasPredecessors(): boolean {
    return this.incomingEdges().length > 0
  }

  /**
   * Check if this node has successors (outgoing edges)
   */
  hasSuccessors(): boolean {
    return this.outgoingEdges().length > 0
  }

  /**
   * Get all predecessor nodes
   */
  predecessors(): Node[] {
    return this.incomingEdges().map(e => e.from)
  }

  /**
   * Get all successor nodes
   */
  successors(): Node[] {
    return this.outgoingEdges().map(e => e.to)
  }

  /**
   * Get all neighbors (connected nodes)
   */
  neighbors(): Node[] {
    const neighbors = new Set<Node>()

    for (const edge of this.edges_) {
      if (edge.from === this) neighbors.add(edge.to)
      if (edge.to === this) neighbors.add(edge.from)
    }

    return Array.from(neighbors)
  }

  // ===== Attributes =====

  /**
   * Set an attribute
   */
  setAttribute(name: string, value: any): this {
    this.attributes.set(name, value)
    return this
  }

  /**
   * Set multiple attributes
   */
  setAttributes(attrs: Record<string, any>): this {
    for (const [name, value] of Object.entries(attrs)) {
      this.setAttribute(name, value)
    }
    return this
  }

  /**
   * Get an attribute value
   */
  getAttribute(name: string): any {
    return this.attributes.get(name)
  }

  /**
   * Get all attributes
   */
  getAttributes(): Record<string, any> {
    return this.attributes.getAll()
  }

  /**
   * Delete an attribute
   */
  deleteAttribute(name: string): boolean {
    return this.attributes.delete(name)
  }

  /**
   * Check if attribute exists
   */
  hasAttribute(name: string): boolean {
    return this.attributes.has(name)
  }

  // ===== Computed Properties =====

  /**
   * Get the label for this node (defaults to name if not set)
   */
  get label(): string {
    return this.getAttribute('label') ?? this.name
  }

  /**
   * Set the label
   */
  set label(value: string) {
    this.setAttribute('label', value)
  }

  /**
   * Get the shape
   */
  get shape(): string {
    return this.getAttribute('shape') ?? 'rect'
  }

  /**
   * Get the fill color
   */
  get fill(): string | undefined {
    return this.getAttribute('fill')
  }

  /**
   * Get the border style
   */
  get border(): string | undefined {
    return this.getAttribute('border')
  }

  /**
   * Check if this is an anonymous node
   */
  isAnon(): boolean {
    return this.name === '' || this.name.startsWith('anon_')
  }

  // ===== Degree =====

  /**
   * Get the degree (total number of edges)
   */
  degree(): number {
    return this.edges_.size
  }

  /**
   * Get the in-degree (number of incoming edges)
   */
  inDegree(): number {
    return this.incomingEdges().length
  }

  /**
   * Get the out-degree (number of outgoing edges)
   */
  outDegree(): number {
    return this.outgoingEdges().length
  }

  // ===== Serialization =====

  /**
   * Convert to plain object for serialization
   */
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      attributes: this.attributes.getAll(),
      group: this.group_?.name,
      edges: this.edges().map(e => e.id),
    }
  }

  /**
   * String representation
   */
  toString(): string {
    return `Node(${this.name})`
  }
}

/**
 * Anonymous node - a node with no label
 */
export class AnonNode extends Node {
  private static anonCounter = 0

  constructor(graph?: Graph) {
    super(`anon_${++AnonNode.anonCounter}`, graph)
    this.setAttribute('label', ' ')
  }

  override isAnon(): boolean {
    return true
  }
}

/**
 * Empty node - used for layout spacing
 */
export class EmptyNode extends Node {
  private static emptyCounter = 0

  constructor(graph?: Graph) {
    super(`empty_${++EmptyNode.emptyCounter}`, graph)
    this.setAttribute('shape', 'invisible')
  }
}
