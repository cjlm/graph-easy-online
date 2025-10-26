/**
 * Edge class - Represents an edge/connection between nodes
 */

import { Graph } from './Graph.ts'
import { Node } from './Node.ts'
import { Group } from './Group.ts'
import { AttributeManager } from './Attributes.ts'

export type EdgeStyle = 'solid' | 'dashed' | 'dotted' | 'wave' | 'double' | 'bold'
export type ArrowType = 'forward' | 'back' | 'both' | 'none'

export class Edge {
  readonly id: string
  private from_: Node
  private to_: Node
  private graph_: Graph | null = null
  private group_: Group | null = null
  private attributes: AttributeManager

  constructor(from: Node, to: Node, graph?: Graph) {
    this.id = Graph.generateId()
    this.from_ = from
    this.to_ = to
    this.attributes = new AttributeManager()

    if (graph) {
      this.graph_ = graph
    }
  }

  // ===== Node Access =====

  get from(): Node {
    return this.from_
  }

  get to(): Node {
    return this.to_
  }

  /**
   * Set the nodes for this edge
   */
  setNodes(from: Node, to: Node): void {
    // Remove from old nodes
    this.from_.removeEdge(this)
    this.to_.removeEdge(this)

    // Set new nodes
    this.from_ = from
    this.to_ = to

    // Add to new nodes
    this.from_.addEdge(this)
    this.to_.addEdge(this)
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
   * Get the label for this edge
   */
  get label(): string | undefined {
    return this.getAttribute('label')
  }

  /**
   * Set the label
   */
  set label(value: string | undefined) {
    if (value === undefined) {
      this.deleteAttribute('label')
    } else {
      this.setAttribute('label', value)
    }
  }

  /**
   * Get the edge style
   */
  get style(): EdgeStyle {
    return this.getAttribute('style') ?? 'solid'
  }

  /**
   * Set the edge style
   */
  set style(value: EdgeStyle) {
    this.setAttribute('style', value)
  }

  /**
   * Get the arrow type
   */
  get arrowStyle(): ArrowType {
    return this.getAttribute('arrowStyle') ?? 'forward'
  }

  /**
   * Check if edge is bidirectional
   */
  isBidirectional(): boolean {
    return this.arrowStyle === 'both'
  }

  /**
   * Check if edge is undirected (no arrows)
   */
  isUndirected(): boolean {
    return this.arrowStyle === 'none'
  }

  /**
   * Get the color
   */
  get color(): string | undefined {
    return this.getAttribute('color')
  }

  /**
   * Get the line width
   */
  get lineWidth(): number {
    return this.getAttribute('lineWidth') ?? 1
  }

  // ===== Operations =====

  /**
   * Flip the direction of this edge
   */
  flip(): this {
    const temp = this.from_
    this.from_ = this.to_
    this.to_ = temp

    // Update arrow style
    if (this.arrowStyle === 'forward') {
      this.setAttribute('arrowStyle', 'back')
    } else if (this.arrowStyle === 'back') {
      this.setAttribute('arrowStyle', 'forward')
    }

    return this
  }

  /**
   * Check if this edge creates a self-loop
   */
  isSelfLoop(): boolean {
    return this.from_ === this.to_
  }

  /**
   * Get the other node (given one endpoint)
   */
  otherNode(node: Node): Node | null {
    if (node === this.from_) return this.to_
    if (node === this.to_) return this.from_
    return null
  }

  // ===== Serialization =====

  /**
   * Convert to plain object for serialization
   */
  toJSON() {
    return {
      id: this.id,
      from: this.from_.id,
      to: this.to_.id,
      attributes: this.attributes.getAll(),
      group: this.group_?.name,
    }
  }

  /**
   * String representation
   */
  toString(): string {
    const arrow = this.getArrowString()
    return `Edge(${this.from_.name} ${arrow} ${this.to_.name})`
  }

  /**
   * Get the arrow string for this edge type
   */
  private getArrowString(): string {
    const style = this.style
    const arrowStyle = this.arrowStyle

    // Build arrow based on style and direction
    let left = ''
    let middle = '-'
    let right = '>'

    // Left arrow
    if (arrowStyle === 'back' || arrowStyle === 'both') {
      left = '<'
    }

    // Right arrow
    if (arrowStyle === 'none' || arrowStyle === 'back') {
      right = ''
    }

    // Middle style
    switch (style) {
      case 'double':
        middle = '='
        break
      case 'dotted':
        middle = '.'
        break
      case 'wave':
        middle = '~'
        break
      case 'bold':
        middle = '━'
        break
      default:
        middle = '-'
    }

    // Build full arrow
    if (arrowStyle === 'none') {
      return `${left}${middle}${middle}`
    }

    return `${left}${middle}${right}`
  }
}
