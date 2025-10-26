/**
 * ASCII Art Renderer
 *
 * Renders graphs as ASCII art using characters like +, -, |, <, >, etc.
 */

import type { LayoutResult, NodeLayout, EdgeLayout } from '../core/Graph.ts'

export interface AsciiRendererOptions {
  style?: 'ascii' | 'boxart'
  lineEnding?: '\n' | '\r\n'
}

/**
 * Box drawing characters for different styles
 */
const BoxChars = {
  ascii: {
    // Corners
    topLeft: '+',
    topRight: '+',
    bottomLeft: '+',
    bottomRight: '+',

    // Lines
    horizontal: '-',
    vertical: '|',

    // Arrows
    arrowRight: '>',
    arrowLeft: '<',
    arrowUp: '^',
    arrowDown: 'v',
    arrowBoth: '*',
  },

  boxart: {
    // Corners
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',

    // Lines
    horizontal: '─',
    vertical: '│',

    // Arrows
    arrowRight: '→',
    arrowLeft: '←',
    arrowUp: '↑',
    arrowDown: '↓',
    arrowBoth: '↔',
  },
}

export class AsciiRenderer {
  private framebuffer: string[][] = []
  private width: number = 0
  private height: number = 0
  private chars: typeof BoxChars.ascii
  private options: Required<AsciiRendererOptions>
  private edgeLabels: Array<{ x: number; y: number; label: string }> = []

  constructor(options: AsciiRendererOptions = {}) {
    this.options = {
      style: options.style ?? 'ascii',
      lineEnding: options.lineEnding ?? '\n',
    }

    this.chars = BoxChars[this.options.style]
  }

  /**
   * Render layout to ASCII art
   */
  render(layout: LayoutResult): string {
    // Initialize framebuffer
    this.initFramebuffer(layout.bounds.width, layout.bounds.height)
    this.edgeLabels = []

    // Render edges first (they go behind nodes)
    for (const edge of layout.edges) {
      this.renderEdge(edge)
    }

    // Render nodes on top
    for (const node of layout.nodes) {
      this.renderNode(node)
    }

    // Render edge labels last (on top of everything)
    for (const { x, y, label } of this.edgeLabels) {
      this.drawEdgeLabel(x, y, label)
    }

    // Convert framebuffer to string
    return this.framebufferToString()
  }

  /**
   * Initialize the framebuffer with spaces
   */
  private initFramebuffer(width: number, height: number): void {
    this.width = width
    this.height = height
    this.framebuffer = Array.from({ length: height }, () =>
      Array.from({ length: width }, () => ' ')
    )
  }

  /**
   * Render a node as a box
   */
  private renderNode(node: NodeLayout): void {
    const { x, y, width, height, label } = node

    // Draw box
    this.drawBox(x, y, width, height)

    // Draw label (centered)
    this.drawLabel(x, y, width, height, label)
  }

  /**
   * Draw a box at the given position
   */
  private drawBox(x: number, y: number, width: number, height: number): void {
    // Top and bottom borders
    for (let i = 0; i < width; i++) {
      this.setCell(x + i, y, this.chars.horizontal)
      this.setCell(x + i, y + height - 1, this.chars.horizontal)
    }

    // Left and right borders
    for (let i = 0; i < height; i++) {
      this.setCell(x, y + i, this.chars.vertical)
      this.setCell(x + width - 1, y + i, this.chars.vertical)
    }

    // Corners
    this.setCell(x, y, this.chars.topLeft)
    this.setCell(x + width - 1, y, this.chars.topRight)
    this.setCell(x, y + height - 1, this.chars.bottomLeft)
    this.setCell(x + width - 1, y + height - 1, this.chars.bottomRight)
  }

  /**
   * Draw label inside a box (centered)
   */
  private drawLabel(
    x: number,
    y: number,
    width: number,
    height: number,
    label: string
  ): void {
    const lines = label.split('\n')
    const startY = y + Math.floor((height - lines.length) / 2)

    for (let i = 0; i < lines.length && startY + i < y + height - 1; i++) {
      const line = lines[i]
      const maxWidth = width - 4 // Leave space for borders and padding
      const truncated = line.length > maxWidth ? line.substring(0, maxWidth) : line
      const padding = Math.floor((width - truncated.length - 2) / 2)
      const startX = x + 1 + padding

      for (let j = 0; j < truncated.length; j++) {
        this.setCell(startX + j, startY + i, truncated[j])
      }
    }
  }

  /**
   * Render an edge as a line with arrows
   */
  private renderEdge(edge: EdgeLayout): void {
    const { points, label } = edge

    // Draw line segments between points
    for (let i = 0; i < points.length - 1; i++) {
      this.drawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y)
    }

    // Draw arrow at the end
    if (points.length >= 2) {
      const lastPoint = points[points.length - 1]
      const prevPoint = points[points.length - 2]

      const dx = Math.sign(lastPoint.x - prevPoint.x)
      const dy = Math.sign(lastPoint.y - prevPoint.y)

      if (dx > 0) this.setCell(lastPoint.x, lastPoint.y, this.chars.arrowRight)
      else if (dx < 0) this.setCell(lastPoint.x, lastPoint.y, this.chars.arrowLeft)
      else if (dy > 0) this.setCell(lastPoint.x, lastPoint.y, this.chars.arrowDown)
      else if (dy < 0) this.setCell(lastPoint.x, lastPoint.y, this.chars.arrowUp)
    }

    // Store label for later rendering (after nodes)
    if (label && points.length >= 2) {
      const midIdx = Math.floor(points.length / 2)
      const midPoint = points[midIdx]
      this.edgeLabels.push({ x: midPoint.x, y: midPoint.y, label })
    }
  }

  /**
   * Draw a line from (x1, y1) to (x2, y2)
   */
  private drawLine(x1: number, y1: number, x2: number, y2: number): void {
    const dx = Math.abs(x2 - x1)
    const dy = Math.abs(y2 - y1)
    const sx = x1 < x2 ? 1 : -1
    const sy = y1 < y2 ? 1 : -1
    let err = dx - dy

    let x = x1
    let y = y1

    while (true) {
      // Determine line character based on direction
      const char = Math.abs(x2 - x1) > Math.abs(y2 - y1)
        ? this.chars.horizontal
        : this.chars.vertical

      this.setCell(x, y, char)

      if (x === x2 && y === y2) break

      const e2 = 2 * err
      if (e2 > -dy) {
        err -= dy
        x += sx
      }
      if (e2 < dx) {
        err += dx
        y += sy
      }
    }
  }

  /**
   * Draw edge label
   */
  private drawEdgeLabel(x: number, y: number, label: string): void {
    const maxLen = 20
    const truncated = label.length > maxLen ? label.substring(0, maxLen) + '...' : label
    const startX = x - Math.floor(truncated.length / 2)

    for (let i = 0; i < truncated.length; i++) {
      this.setCell(startX + i, y - 1, truncated[i])
    }
  }

  /**
   * Set a cell in the framebuffer
   */
  private setCell(x: number, y: number, char: string): void {
    if (x >= 0 && x < this.width && y >= 0 && y < this.height) {
      this.framebuffer[y][x] = char
    }
  }

  /**
   * Convert framebuffer to string
   */
  private framebufferToString(): string {
    return this.framebuffer
      .map(row => row.join('').trimEnd()) // Remove trailing spaces
      .join(this.options.lineEnding)
      .trimEnd() // Remove trailing empty lines
  }
}

/**
 * Convenience function to render a layout to ASCII
 */
export function renderAscii(
  layout: LayoutResult,
  options?: AsciiRendererOptions
): string {
  const renderer = new AsciiRenderer(options)
  return renderer.render(layout)
}

/**
 * Convenience function to render a layout to boxart
 */
export function renderBoxart(layout: LayoutResult): string {
  return renderAscii(layout, { style: 'boxart' })
}
