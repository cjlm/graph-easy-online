/**
 * Cell - Represents a single cell in the layout grid
 *
 * Based on Graph::Easy::Node::Cell and Graph::Easy::Edge::Cell
 */

import { Node } from './Node.ts'
import { Edge } from './Edge.ts'

// Edge cell type constants (from Perl)
export const EDGE_HOR = 1 // Horizontal line: -
export const EDGE_VER = 2 // Vertical line: |
export const EDGE_CROSS = 3 // Cross/intersection: +
export const EDGE_N_E = 4 // North-East corner: └
export const EDGE_N_W = 5 // North-West corner: ┘
export const EDGE_S_E = 6 // South-East corner: ┌
export const EDGE_S_W = 7 // South-West corner: ┐

// Three-way joints
export const EDGE_N_E_W = 8 // North, East, West: ┴
export const EDGE_N_W_S = 9 // North, West, South: ┤
export const EDGE_E_N_S = 10 // East, North, South: ├
export const EDGE_S_E_W = 11 // South, East, West: ┬

// Self-loops
export const EDGE_LOOP_NORTH = 32
export const EDGE_LOOP_SOUTH = 33
export const EDGE_LOOP_EAST = 34
export const EDGE_LOOP_WEST = 35

// Start flags (where edge begins, arrow pointing away from node)
export const EDGE_START_N = 0x100 // Arrow start pointing north
export const EDGE_START_S = 0x200 // Arrow start pointing south
export const EDGE_START_E = 0x400 // Arrow start pointing east
export const EDGE_START_W = 0x800 // Arrow start pointing west

// End flags (where edge ends, arrow pointing at node)
export const EDGE_END_N = 0x1000 // Arrow end pointing north
export const EDGE_END_S = 0x2000 // Arrow end pointing south
export const EDGE_END_E = 0x4000 // Arrow end pointing east
export const EDGE_END_W = 0x8000 // Arrow end pointing west

// Special flags
export const EDGE_LABEL_CELL = 0x40000 // This cell carries the edge label
export const EDGE_HOLE = 0xffff // Placeholder cell (removed by optimizer)

// Masks
export const EDGE_TYPE_MASK = 0xff // Mask to get just the type bits
export const EDGE_FLAG_MASK = 0xffff00 // Mask to get just the flag bits
export const EDGE_START_MASK = 0xf00 // Mask for all start flags
export const EDGE_END_MASK = 0xf000 // Mask for all end flags

export type CellType = 'node' | 'edge' | 'empty'

/**
 * Cell class - represents one position in the layout grid
 */
export class Cell {
  /** Grid X coordinate */
  x: number

  /** Grid Y coordinate */
  y: number

  /** Cell type and flags (for edge cells) */
  type: number

  /** Column span (for multi-cell nodes) */
  cx: number

  /** Row span (for multi-cell nodes) */
  cy: number

  /** Rendered width in characters */
  width: number

  /** Rendered height in characters */
  height: number

  /** Reference to node if this is a node cell */
  node?: Node

  /** Reference to edge if this is an edge cell */
  edge?: Edge

  /** Label text (for edge labels or node labels) */
  label?: string

  constructor(x: number, y: number, type: number = 0) {
    this.x = x
    this.y = y
    this.type = type
    this.cx = 1
    this.cy = 1
    this.width = 3 // Default node width
    this.height = 3 // Default node height
  }

  /**
   * Get the cell type (node, edge, or empty)
   */
  getCellType(): CellType {
    if (this.node) return 'node'
    if (this.edge) return 'edge'
    return 'empty'
  }

  /**
   * Get just the edge type (without flags)
   */
  getEdgeType(): number {
    return this.type & EDGE_TYPE_MASK
  }

  /**
   * Get just the flags (without edge type)
   */
  getFlags(): number {
    return this.type & EDGE_FLAG_MASK
  }

  /**
   * Check if this cell has a specific flag
   */
  hasFlag(flag: number): boolean {
    return (this.type & flag) !== 0
  }

  /**
   * Add a flag to this cell
   */
  addFlag(flag: number): void {
    this.type |= flag
  }

  /**
   * Remove a flag from this cell
   */
  removeFlag(flag: number): void {
    this.type &= ~flag
  }

  /**
   * Check if this is a start cell (edge begins here)
   */
  isStart(): boolean {
    return (this.type & EDGE_START_MASK) !== 0
  }

  /**
   * Check if this is an end cell (edge ends here)
   */
  isEnd(): boolean {
    return (this.type & EDGE_END_MASK) !== 0
  }

  /**
   * Check if this cell carries an edge label
   */
  hasLabel(): boolean {
    return (this.type & EDGE_LABEL_CELL) !== 0
  }

  /**
   * Create a node cell
   */
  static createNodeCell(x: number, y: number, node: Node): Cell {
    const cell = new Cell(x, y, 0)
    cell.node = node
    cell.cx = 1 // Will be updated if multi-cell node
    cell.cy = 1
    return cell
  }

  /**
   * Create an edge cell
   */
  static createEdgeCell(x: number, y: number, edge: Edge, type: number): Cell {
    const cell = new Cell(x, y, type)
    cell.edge = edge
    cell.width = 1 // Edge cells are 1 character wide/high by default
    cell.height = 1
    return cell
  }

  /**
   * Get a string representation for debugging
   */
  toString(): string {
    if (this.node) {
      return `Cell(${this.x},${this.y}) [Node: ${this.node.name}]`
    }
    if (this.edge) {
      const edgeType = this.getEdgeType()
      const flags = this.getFlags()
      return `Cell(${this.x},${this.y}) [Edge: ${this.edge.from.name}->${this.edge.to.name} type=${edgeType} flags=0x${flags.toString(16)}]`
    }
    return `Cell(${this.x},${this.y}) [Empty]`
  }

  /**
   * Clone this cell
   */
  clone(): Cell {
    const cell = new Cell(this.x, this.y, this.type)
    cell.cx = this.cx
    cell.cy = this.cy
    cell.width = this.width
    cell.height = this.height
    cell.node = this.node
    cell.edge = this.edge
    cell.label = this.label
    return cell
  }
}

/**
 * Helper function to create a grid key from coordinates
 */
export function gridKey(x: number, y: number): string {
  return `${x},${y}`
}

/**
 * Helper function to parse a grid key into coordinates
 */
export function parseGridKey(key: string): [number, number] {
  const [x, y] = key.split(',').map(Number)
  return [x, y]
}
