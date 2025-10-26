/**
 * Group class - Represents a group/cluster of nodes
 */

import { Graph } from './Graph.ts'
import { Node } from './Node.ts'
import { Edge } from './Edge.ts'
import { AttributeManager } from './Attributes.ts'

export class Group {
  readonly id: string
  readonly name: string
  private graph_: Graph | null = null
  private members_: Set<Node> = new Set()
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

  // ===== Member Management =====

  /**
   * Add a member (node) to this group
   */
  addMember(node: Node): void {
    if (node.group && node.group !== this) {
      node.group.removeMember(node)
    }

    this.members_.add(node)
    node.setGroup(this)
  }

  /**
   * Add multiple members
   */
  addMembers(...nodes: Node[]): void {
    for (const node of nodes) {
      this.addMember(node)
    }
  }

  /**
   * Remove a member from this group
   */
  removeMember(node: Node): boolean {
    if (!this.members_.has(node)) return false

    this.members_.delete(node)
    node.setGroup(null)
    return true
  }

  /**
   * Get all members
   */
  getMembers(): Node[] {
    return Array.from(this.members_)
  }

  /**
   * Check if a node is a member
   */
  hasMember(node: Node): boolean {
    return this.members_.has(node)
  }

  /**
   * Get the number of members
   */
  size(): number {
    return this.members_.size
  }

  /**
   * Check if group is empty
   */
  isEmpty(): boolean {
    return this.members_.size === 0
  }

  // ===== Edge Operations =====

  /**
   * Get all edges within this group (internal edges)
   */
  getInternalEdges(): Edge[] {
    const edges: Edge[] = []
    const memberSet = this.members_

    for (const node of memberSet) {
      for (const edge of node.outgoingEdges()) {
        if (memberSet.has(edge.to)) {
          edges.push(edge)
        }
      }
    }

    return edges
  }

  /**
   * Get all edges crossing the group boundary
   */
  getCrossingEdges(): Edge[] {
    const edges: Edge[] = []
    const memberSet = this.members_

    for (const node of memberSet) {
      for (const edge of node.edges()) {
        const otherNode = edge.otherNode(node)
        if (otherNode && !memberSet.has(otherNode)) {
          edges.push(edge)
        }
      }
    }

    return edges
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
   * Get the label for this group (defaults to name if not set)
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
   * Check if this is an anonymous group
   */
  isAnon(): boolean {
    return this.name === '' || this.name.startsWith('anon_')
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
      members: this.getMembers().map(n => n.id),
    }
  }

  /**
   * String representation
   */
  toString(): string {
    return `Group(${this.name}, ${this.members_.size} members)`
  }
}

/**
 * Anonymous group
 */
export class AnonGroup extends Group {
  private static anonCounter = 0

  constructor(graph?: Graph) {
    super(`anon_group_${++AnonGroup.anonCounter}`, graph)
  }

  override isAnon(): boolean {
    return true
  }
}
