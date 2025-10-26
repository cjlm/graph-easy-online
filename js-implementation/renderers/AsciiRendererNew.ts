/**
 * ASCII Renderer - Converts positioned cells to ASCII art
 *
 * Based on Graph::Easy::As_ascii
 *
 * This is a rewrite that works with our TypeScript layout engine
 * (not dependent on ELK)
 */

import { Graph } from '../core/Graph.ts'
import { Cell,
  EDGE_HOR,
  EDGE_VER,
  EDGE_CROSS,
  EDGE_N_E,
  EDGE_N_W,
  EDGE_S_E,
  EDGE_S_W,
  EDGE_TYPE_MASK,
} from '../core/Cell.ts'

export interface AsciiRendererOptions {
  boxart?: boolean  // Use Unicode box drawing characters
}

export class AsciiRendererNew {
  private graph: Graph
  private options: AsciiRendererOptions

  constructor(graph: Graph, options: AsciiRendererOptions = {}) {
    this.graph = graph
    this.options = options
  }

  /**
   * Render the graph as ASCII art
   */
  render(): string {
    if (this.graph.cells.size === 0) {
      return ''
    }

    // Get bounds
    const bounds = this.getBounds()
    const width = bounds.maxX - bounds.minX + 3
    const height = bounds.maxY - bounds.minY + 3

    // Create character grid
    const grid: string[][] = []
    for (let y = 0; y < height; y++) {
      grid[y] = []
      for (let x = 0; x < width; x++) {
        grid[y][x] = ' '
      }
    }

    // Render nodes first
    this.renderNodes(grid, bounds)

    // Render edges
    this.renderEdges(grid, bounds)

    // Convert grid to string
    return this.gridToString(grid)
  }

  /**
   * Render nodes
   */
  private renderNodes(grid: string[][], bounds: any): void {
    const nodeCells = new Map<string, Cell>()

    // Collect node cells
    for (const [key, cell] of this.graph.cells) {
      if (cell.node) {
        nodeCells.set(key, cell)
      }
    }

    // Group by node
    const nodeGroups = new Map<string, Cell[]>()
    for (const cell of nodeCells.values()) {
      const nodeId = cell.node!.id
      if (!nodeGroups.has(nodeId)) {
        nodeGroups.set(nodeId, [])
      }
      nodeGroups.get(nodeId)!.push(cell)
    }

    // Render each node
    for (const cells of nodeGroups.values()) {
      if (cells.length === 0) continue

      const node = cells[0].node!

      // Find bounding box of node cells
      let minX = Infinity
      let minY = Infinity
      let maxX = -Infinity
      let maxY = -Infinity

      for (const cell of cells) {
        minX = Math.min(minX, cell.x)
        minY = Math.min(minY, cell.y)
        maxX = Math.max(maxX, cell.x)
        maxY = Math.max(maxY, cell.y)
      }

      // Draw box
      const boxMinX = minX - bounds.minX + 1
      const boxMinY = minY - bounds.minY + 1
      const boxMaxX = maxX - bounds.minX + 1
      const boxMaxY = maxY - bounds.minY + 1

      this.drawBox(grid, boxMinX, boxMinY, boxMaxX - boxMinX + 1, boxMaxY - boxMinY + 1)

      // Draw label (centered)
      const label = node.label || node.name
      const labelY = boxMinY + 1
      const boxWidth = boxMaxX - boxMinX + 1
      const innerWidth = boxWidth - 2  // Subtract borders
      const leftPadding = Math.floor((innerWidth - label.length) / 2)
      const labelX = boxMinX + 1 + leftPadding

      for (let i = 0; i < label.length && labelX + i < grid[0].length; i++) {
        if (grid[labelY]) {
          grid[labelY][labelX + i] = label[i]
        }
      }
    }
  }

  /**
   * Draw a box
   */
  private drawBox(grid: string[][], x: number, y: number, w: number, h: number): void {
    if (this.options.boxart) {
      // Unicode box drawing
      const chars = {
        tl: '┌', tr: '┐', bl: '└', br: '┘',
        h: '─', v: '│',
      }

      // Top and bottom
      for (let i = 1; i < w - 1; i++) {
        grid[y][x + i] = chars.h
        grid[y + h - 1][x + i] = chars.h
      }

      // Left and right
      for (let i = 1; i < h - 1; i++) {
        grid[y + i][x] = chars.v
        grid[y + i][x + w - 1] = chars.v
      }

      // Corners
      grid[y][x] = chars.tl
      grid[y][x + w - 1] = chars.tr
      grid[y + h - 1][x] = chars.bl
      grid[y + h - 1][x + w - 1] = chars.br
    } else {
      // ASCII
      const chars = {
        tl: '+', tr: '+', bl: '+', br: '+',
        h: '-', v: '|',
      }

      // Top and bottom
      for (let i = 1; i < w - 1; i++) {
        grid[y][x + i] = chars.h
        grid[y + h - 1][x + i] = chars.h
      }

      // Left and right
      for (let i = 1; i < h - 1; i++) {
        grid[y + i][x] = chars.v
        grid[y + i][x + w - 1] = chars.v
      }

      // Corners
      grid[y][x] = chars.tl
      grid[y][x + w - 1] = chars.tr
      grid[y + h - 1][x] = chars.bl
      grid[y + h - 1][x + w - 1] = chars.br
    }
  }

  /**
   * Render edges
   */
  private renderEdges(grid: string[][], bounds: any): void {
    // Group cells by edge
    const edgeCells = new Map<string, Cell[]>()
    for (const [_key, cell] of this.graph.cells) {
      if (!cell.edge) continue

      const edgeId = cell.edge.id
      if (!edgeCells.has(edgeId)) {
        edgeCells.set(edgeId, [])
      }
      edgeCells.get(edgeId)!.push(cell)
    }

    // Render each edge
    for (const [_edgeId, cells] of edgeCells) {
      const edge = cells[0].edge!

      // Find endpoint cells (closest to to-node)
      const toNode = edge.to
      let endpointCell: Cell | null = null
      let minDist = Infinity

      for (const cell of cells) {
        if (toNode.x !== undefined && toNode.y !== undefined) {
          const dist = Math.abs(cell.x - toNode.x) + Math.abs(cell.y - toNode.y)
          if (dist < minDist) {
            minDist = dist
            endpointCell = cell
          }
        }
      }

      // Render all cells
      for (const cell of cells) {
        const x = cell.x - bounds.minX + 1
        const y = cell.y - bounds.minY + 1

        if (y >= 0 && y < grid.length && x >= 0 && x < grid[0].length) {
          // Only draw if not already occupied by node
          if (grid[y][x] === ' ') {
            const edgeType = cell.type & EDGE_TYPE_MASK
            let char = this.getEdgeCharacter(edgeType)

            // Add arrowhead at endpoint (only for directed edges)
            if (cell === endpointCell && !edge.isUndirected()) {
              if (edgeType === EDGE_HOR) {
                char = '>'
              } else if (edgeType === EDGE_VER) {
                char = 'v'
              }
            }

            grid[y][x] = char
          }
        }
      }
    }
  }

  /**
   * Get character for edge type
   */
  private getEdgeCharacter(edgeType: number): string {
    if (this.options.boxart) {
      switch (edgeType) {
        case EDGE_HOR: return '─'
        case EDGE_VER: return '│'
        case EDGE_CROSS: return '┼'
        case EDGE_N_E: return '└'
        case EDGE_N_W: return '┘'
        case EDGE_S_E: return '┌'
        case EDGE_S_W: return '┐'
        default: return '-'
      }
    } else {
      switch (edgeType) {
        case EDGE_HOR: return '-'
        case EDGE_VER: return '|'
        case EDGE_CROSS: return '+'
        case EDGE_N_E: return '+'
        case EDGE_N_W: return '+'
        case EDGE_S_E: return '+'
        case EDGE_S_W: return '+'
        default: return '-'
      }
    }
  }

  /**
   * Get layout bounds
   */
  private getBounds(): { minX: number; minY: number; maxX: number; maxY: number } {
    let minX = Infinity
    let minY = Infinity
    let maxX = -Infinity
    let maxY = -Infinity

    for (const cell of this.graph.cells.values()) {
      minX = Math.min(minX, cell.x)
      minY = Math.min(minY, cell.y)
      maxX = Math.max(maxX, cell.x)
      maxY = Math.max(maxY, cell.y)
    }

    return { minX, minY, maxX, maxY }
  }

  /**
   * Convert grid to string
   */
  private gridToString(grid: string[][]): string {
    return grid.map(row => row.join('')).join('\n')
  }
}
