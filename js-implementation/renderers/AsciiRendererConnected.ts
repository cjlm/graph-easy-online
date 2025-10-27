/**
 * Connected ASCII Renderer - properly connects edge cells
 *
 * Key differences from Simple renderer:
 * 1. Fills in horizontal/vertical edge cells completely
 * 2. Connects adjacent edge cells
 * 3. Uses smaller cell dimensions for more compact output
 */

import { Graph } from '../core/Graph.ts'
import {
  EDGE_HOR,
  EDGE_VER,
  EDGE_N_E,
  EDGE_N_W,
  EDGE_S_E,
  EDGE_S_W,
  EDGE_CROSS,
  EDGE_TYPE_MASK,
  EDGE_LOOP_NORTH,
  EDGE_LOOP_SOUTH,
  EDGE_LOOP_EAST,
  EDGE_LOOP_WEST,
} from '../core/Cell.ts'

const CELL_WIDTH = 5  // EXACT match to Perl: always 5 chars
const CELL_HEIGHT = 3 // EXACT match to Perl: always 3 chars

export class AsciiRendererConnected {
  private graph: Graph

  constructor(graph: Graph) {
    this.graph = graph
  }

  render(): string {
    if (!this.graph.cells || this.graph.cells.size === 0) {
      return ''
    }

    // Find bounds
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

    // Create character grid with padding
    const charWidth = (maxX - minX + 3) * CELL_WIDTH
    const charHeight = (maxY - minY + 3) * CELL_HEIGHT

    const grid: string[][] = []
    for (let y = 0; y < charHeight; y++) {
      grid[y] = new Array(charWidth).fill(' ')
    }

    // Render edges first (so nodes can overwrite them)
    for (const [, cell] of this.graph.cells) {
      if (!cell.edge) continue

      const gridX = cell.x - minX + 1
      const gridY = cell.y - minY + 1

      this.renderEdgeCell(grid, gridX, gridY, cell)
    }

    // Render nodes (overwrites edges)
    for (const node of this.graph.getNodes()) {
      if (node.x === undefined || node.y === undefined) continue

      const gridX = node.x - minX + 1
      const gridY = node.y - minY + 1

      const charX = gridX * CELL_WIDTH
      const charY = gridY * CELL_HEIGHT

      const label = node.label || node.name
      // Box width: label + 2 borders + 2 padding spaces = label.length + 4
      const boxWidth = label.length + 4

      this.drawBox(grid, charX, charY, boxWidth, CELL_HEIGHT, label)
    }

    // Convert to string and remove empty rows
    const lines = grid.map(row => row.join(''))
    const compactLines = lines.filter(line => line.trim().length > 0)

    return compactLines.join('\n')
  }

  /**
   * EXACT implementation matching Perl's As_ascii.pm
   *
   * Cell dimensions: 5 chars wide x 3 chars tall
   * Horizontal lines: drawn at y = h-2 = 1 (middle row)
   * Vertical lines: drawn at x = 2 (center column)
   * Corners: drawn at (2, 1)
   */
  private renderEdgeCell(grid: string[][], gridX: number, gridY: number, cell: any): void {
    const edgeType = cell.type & EDGE_TYPE_MASK

    // Convert grid position to character position
    const charX = gridX * CELL_WIDTH
    const charY = gridY * CELL_HEIGHT

    // Perl positions: horizontal at y=h-2, vertical at x=2, corner at (2,h-2)
    const horizY = charY + (CELL_HEIGHT - 2)  // y = h-2 = 1
    const vertX = charX + 2                    // x = 2 (center of 5-char cell)
    const cornerX = charX + 2                  // x = 2
    const cornerY = charY + (CELL_HEIGHT - 2)  // y = h-2 = 1

    // Horizontal edge: fill entire width with dashes at y=h-2
    if (edgeType === EDGE_HOR) {
      if (horizY >= 0 && horizY < grid.length) {
        for (let x = charX; x < charX + CELL_WIDTH; x++) {
          if (x >= 0 && x < grid[0].length) {
            grid[horizY][x] = '-'
          }
        }
      }
    }

    // Vertical edge: fill entire height with pipes at x=2
    else if (edgeType === EDGE_VER) {
      if (vertX >= 0 && vertX < grid[0].length) {
        for (let y = charY; y < charY + CELL_HEIGHT; y++) {
          if (y >= 0 && y < grid.length) {
            grid[y][vertX] = '|'
          }
        }
      }
    }

    // Corner cells: place '+' at (2, h-2) and extend lines
    else if (edgeType === EDGE_N_E || edgeType === EDGE_N_W ||
             edgeType === EDGE_S_E || edgeType === EDGE_S_W ||
             edgeType === EDGE_CROSS) {

      // Place corner character at (2, h-2)
      if (cornerY >= 0 && cornerY < grid.length &&
          cornerX >= 0 && cornerX < grid[0].length) {
        grid[cornerY][cornerX] = '+'
      }

      // Extend horizontal line at y=h-2
      if (cornerY >= 0 && cornerY < grid.length) {
        for (let x = charX; x < charX + CELL_WIDTH; x++) {
          if (x >= 0 && x < grid[0].length && grid[cornerY][x] === ' ') {
            grid[cornerY][x] = '-'
          }
        }
      }

      // Extend vertical line at x=2
      if (vertX >= 0 && vertX < grid[0].length) {
        for (let y = charY; y < charY + CELL_HEIGHT; y++) {
          if (y >= 0 && y < grid.length && grid[y][vertX] === ' ') {
            grid[y][vertX] = '|'
          }
        }
      }
    }

    // Loop cells - render as arc shapes
    else if (edgeType === EDGE_LOOP_NORTH || edgeType === EDGE_LOOP_SOUTH ||
             edgeType === EDGE_LOOP_EAST || edgeType === EDGE_LOOP_WEST) {
      this.renderLoop(grid, gridX, gridY, edgeType)
    }
  }

  private renderLoop(grid: string[][], gridX: number, gridY: number, loopType: number): void {
    const x0 = gridX * CELL_WIDTH
    const y0 = gridY * CELL_HEIGHT
    const w = CELL_WIDTH
    const h = CELL_HEIGHT

    // Simple loop rendering (can be improved)
    const centerX = x0 + Math.floor(w / 2)
    const centerY = y0 + Math.floor(h / 2)

    if (loopType === EDGE_LOOP_NORTH || loopType === EDGE_LOOP_SOUTH) {
      // Horizontal loop
      if (centerY - 1 >= 0 && centerY + 1 < grid.length) {
        grid[centerY - 1][centerX] = '+'
        grid[centerY][centerX] = '|'
        grid[centerY + 1][centerX] = '+'

        for (let x = x0; x < x0 + w; x++) {
          if (x !== centerX && grid[centerY - 1][x] === ' ') {
            grid[centerY - 1][x] = '-'
          }
        }
      }
    }
  }

  private drawBox(grid: string[][], x: number, y: number, w: number, h: number, label: string): void {
    // Ensure bounds
    if (y < 0 || y + h > grid.length || x < 0 || x + w > grid[0].length) {
      return
    }

    // Top and bottom borders
    for (let i = 1; i < w - 1; i++) {
      grid[y][x + i] = '-'
      grid[y + h - 1][x + i] = '-'
    }

    // Left and right borders
    for (let i = 1; i < h - 1; i++) {
      grid[y + i][x] = '|'
      grid[y + i][x + w - 1] = '|'
    }

    // Corners
    grid[y][x] = '+'
    grid[y][x + w - 1] = '+'
    grid[y + h - 1][x] = '+'
    grid[y + h - 1][x + w - 1] = '+'

    // Label
    const labelY = y + Math.floor(h / 2)
    const innerWidth = w - 2
    const leftPadding = Math.floor((innerWidth - label.length) / 2)
    const labelX = x + 1 + leftPadding

    for (let i = 0; i < label.length; i++) {
      if (labelX + i >= 0 && labelX + i < grid[0].length) {
        grid[labelY][labelX + i] = label[i]
      }
    }
  }
}
