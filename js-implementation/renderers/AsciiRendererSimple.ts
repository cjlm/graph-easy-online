/**
 * Simple ASCII Renderer with proper grid-to-character scaling
 *
 * Each layout grid cell renders as 5x3 character cells
 */

import { Graph } from '../core/Graph.ts'
import {
  EDGE_HOR,
  EDGE_VER,
  EDGE_N_E,
  EDGE_N_W,
  EDGE_S_E,
  EDGE_S_W,
  EDGE_TYPE_MASK,
} from '../core/Cell.ts'

const CELL_WIDTH = 5   // Each grid cell is 5 characters wide
const CELL_HEIGHT = 3  // Each grid cell is 3 characters tall

export class AsciiRendererSimple {
  private graph: Graph

  constructor(graph: Graph) {
    this.graph = graph
  }

  render(): string {
    if (!this.graph.cells || this.graph.cells.size === 0) {
      return ''
    }

    // Find bounds in grid coordinates
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

    // Convert to character coordinates with padding
    const charWidth = (maxX - minX + 3) * CELL_WIDTH
    const charHeight = (maxY - minY + 3) * CELL_HEIGHT

    // Create character grid
    const grid: string[][] = []
    for (let y = 0; y < charHeight; y++) {
      grid[y] = new Array(charWidth).fill(' ')
    }

    // Render nodes
    for (const node of this.graph.getNodes()) {
      if (node.x === undefined || node.y === undefined) continue

      const charX = (node.x - minX + 1) * CELL_WIDTH
      const charY = (node.y - minY + 1) * CELL_HEIGHT

      const label = node.label || node.name
      const boxWidth = Math.max(label.length + 2, 5)

      // Draw box
      this.drawBox(grid, charX, charY, boxWidth, CELL_HEIGHT, label)
    }

    // Render edges
    for (const [, cell] of this.graph.cells) {
      if (!cell.edge) continue

      const charX = (cell.x - minX + 1) * CELL_WIDTH + Math.floor(CELL_WIDTH / 2)
      const charY = (cell.y - minY + 1) * CELL_HEIGHT + Math.floor(CELL_HEIGHT / 2)

      if (charY >= 0 && charY < grid.length && charX >= 0 && charX < grid[0].length) {
        if (grid[charY][charX] === ' ') {
          const edgeType = cell.type & EDGE_TYPE_MASK
          let char = this.getEdgeChar(edgeType)

          // Check if endpoint (for arrows)
          const isEndpoint = this.isEndpoint(cell, cell.edge!)
          if (isEndpoint && !cell.edge!.isUndirected()) {
            if (edgeType === EDGE_HOR) char = '>'
            if (edgeType === EDGE_VER) char = 'v'
          }

          grid[charY][charX] = char
        }
      }

      // Render edge label if this cell has one
      if (cell.hasLabel() && cell.edge!.label) {
        const label = cell.edge!.label
        const labelStartX = charX - Math.floor(label.length / 2)
        const DEBUG = false  // Set to true to debug label rendering

        if (DEBUG) {
          console.log(`\nChecking label "${label}" at cell (${cell.x},${cell.y}) charX=${charX} charY=${charY}`)
          console.log(`  labelStartX=${labelStartX}, labelEndX=${labelStartX + label.length}`)
        }

        // Check if there's enough CLEAR space for the label
        // We need empty space (or just edge chars) on both sides
        let canRender = true

        // Check all positions where label would be placed
        for (let i = 0; i < label.length; i++) {
          const lx = labelStartX + i

          if (lx < 0 || lx >= grid[0].length || charY < 0 || charY >= grid.length) {
            canRender = false
            break
          }

          const existingChar = grid[charY][lx]

          // Only allow rendering over spaces, edge characters, and arrows
          // This naturally prevents overlap with boxes while allowing placement on edges
          if (existingChar !== ' ' && existingChar !== '-' && existingChar !== '>' && existingChar !== 'v' && existingChar !== '<' && existingChar !== '^') {
            if (DEBUG) console.log(`  Label position ${lx}: char='${existingChar}' BLOCKED`)
            canRender = false
            break
          }
          if (DEBUG) console.log(`  Label position ${lx}: char='${existingChar}' OK`)
        }

        // Only render if we have completely clear space with buffer
        if (canRender) {
          if (DEBUG) console.log(`  ✅ RENDERING label "${label}"`)
          for (let i = 0; i < label.length; i++) {
            const lx = labelStartX + i
            if (lx >= 0 && lx < grid[0].length) {
              grid[charY][lx] = label[i]
            }
          }
        } else {
          if (DEBUG) console.log(`  ❌ NOT rendering label "${label}" - space check failed`)
        }
      }
    }

    // Convert to string
    return grid.map(row => row.join('')).join('\n')
  }

  private drawBox(grid: string[][], x: number, y: number, w: number, h: number, label: string): void {
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

    // Label (centered in middle row)
    const labelY = y + Math.floor(h / 2)
    const innerWidth = w - 2
    const leftPadding = Math.floor((innerWidth - label.length) / 2)
    const labelX = x + 1 + leftPadding

    for (let i = 0; i < label.length; i++) {
      if (labelX + i < grid[0].length) {
        grid[labelY][labelX + i] = label[i]
      }
    }
  }

  private getEdgeChar(type: number): string {
    switch (type) {
      case EDGE_HOR: return '-'
      case EDGE_VER: return '|'
      case EDGE_N_E: return '+'
      case EDGE_N_W: return '+'
      case EDGE_S_E: return '+'
      case EDGE_S_W: return '+'
      default: return '-'
    }
  }

  private isEndpoint(cell: any, edge: any): boolean {
    if (!edge.to || edge.to.x === undefined) return false

    // Check if this cell is closest to destination
    let minDist = Infinity
    let closestCell = null

    for (const [, c] of this.graph.cells) {
      if (c.edge !== edge) continue
      const dist = Math.abs(c.x - edge.to.x) + Math.abs(c.y - edge.to.y)
      if (dist < minDist) {
        minDist = dist
        closestCell = c
      }
    }

    return closestCell === cell
  }
}
