/**
 * ELK to ASCII Orthogonal Graph Renderer
 *
 * Converts elkjs layout output to ASCII art graph representation using
 * orthogonal (right-angle only) edge routing.
 */

/**
 * Character sets for rendering
 */
const UNICODE_CHARS = {
  horizontal: '─',
  vertical: '│',
  cornerTL: '┌',
  cornerTR: '┐',
  cornerBL: '└',
  cornerBR: '┘',
  tJunctionR: '├',
  tJunctionL: '┤',
  tJunctionD: '┬',
  tJunctionU: '┴',
  cross: '┼',
  arrowR: '→',
  arrowL: '←',
  arrowD: '↓',
  arrowU: '↑',
  // For hierarchical nodes
  doubleH: '═',
  doubleV: '║',
  doubleTL: '╔',
  doubleTR: '╗',
  doubleBL: '╚',
  doubleBR: '╝',
} as const

const ASCII_CHARS = {
  horizontal: '-',
  vertical: '|',
  cornerTL: '+',
  cornerTR: '+',
  cornerBL: '+',
  cornerBR: '+',
  tJunctionR: '+',
  tJunctionL: '+',
  tJunctionD: '+',
  tJunctionU: '+',
  cross: '+',
  arrowR: '>',
  arrowL: '<',
  arrowD: 'v',
  arrowU: '^',
  doubleH: '=',
  doubleV: '|',
  doubleTL: '+',
  doubleTR: '+',
  doubleBL: '+',
  doubleBR: '+',
} as const

type CharSet = typeof UNICODE_CHARS | typeof ASCII_CHARS

/**
 * Configuration options
 */
export interface RenderOptions {
  scale?: number              // chars per pixel (0.2-0.5 recommended)
  margin?: number              // canvas padding in chars
  unicode?: boolean            // false for ASCII-only mode
  arrows?: boolean             // show directional arrows on edges
  renderLabels?: boolean       // render node and edge labels
  renderPorts?: boolean        // show port indicators on nodes
  portChar?: string           // character for port markers
  junctionStyle?: 'merge' | 'bridge'  // 'merge' uses ┼, 'bridge' shows overlap
  maxDensity?: number         // if exceeded, warn about collisions
  autoScale?: boolean         // auto-adjust scale if too dense
}

const defaultOptions: Required<RenderOptions> = {
  scale: 0.3,
  margin: 5,
  unicode: true,
  arrows: true,
  renderLabels: true,
  renderPorts: false,
  portChar: '◦',
  junctionStyle: 'merge',
  maxDensity: 0.4,
  autoScale: true,
}

/**
 * Point in grid coordinates
 */
interface GridPoint {
  x: number
  y: number
}

/**
 * Quantized node
 */
interface QuantizedNode {
  id: string
  gridX: number
  gridY: number
  gridW: number
  gridH: number
  labels: Array<{
    text: string
    gridX: number
    gridY: number
    gridW: number
    gridH: number
  }>
  ports: Array<{
    id: string
    gridX: number
    gridY: number
  }>
  isHierarchical: boolean
}

/**
 * Quantized edge
 */
interface QuantizedEdge {
  id: string
  source: string
  target: string
  sourcePort?: string
  targetPort?: string
  sections: Array<{
    id: string
    points: GridPoint[]
  }>
  labels: Array<{
    text: string
    gridX: number
    gridY: number
  }>
}

/**
 * Quantized graph
 */
interface QuantizedGraph {
  nodes: QuantizedNode[]
  edges: QuantizedEdge[]
}

/**
 * Canvas allocation result
 */
interface CanvasResult {
  canvas: string[][]
  offset: GridPoint
  width: number
  height: number
}

/**
 * Occupancy map entry
 */
interface OccupancyEntry {
  type: 'node' | 'edge'
  id: string
  dir?: 'h' | 'v'
}

/**
 * Render result
 */
export interface RenderResult {
  ascii: string | null
  metadata: {
    width?: number
    height?: number
    scale?: number
    nodeCount?: number
    edgeCount?: number
    warnings: string[]
    error?: string
  }
}

/**
 * ELK result types (based on elkjs output)
 */
export interface ELKNode {
  id: string
  x?: number
  y?: number
  width?: number
  height?: number
  labels?: Array<{ text: string; x?: number; y?: number; width?: number; height?: number }>
  ports?: Array<{ id: string; x?: number; y?: number; width?: number; height?: number }>
  children?: ELKNode[]
}

export interface ELKEdge {
  id: string
  sources: string[]
  targets: string[]
  sourcePort?: string
  targetPort?: string
  sections?: Array<{
    id: string
    startPoint: { x: number; y: number }
    endPoint: { x: number; y: number }
    bendPoints?: Array<{ x: number; y: number }>
  }>
  labels?: Array<{ text: string; x?: number; y?: number; width?: number; height?: number }>
}

export interface ELKResult {
  children?: ELKNode[]
  edges?: ELKEdge[]
}

/**
 * Phase 1: Coordinate Quantization
 *
 * Converts floating-point ELK coordinates to grid coordinates
 */
function quantize(elkResult: Required<ELKResult>, scale: number): QuantizedGraph {
  const quantizePoint = (p: { x: number; y: number }): GridPoint => ({
    x: Math.round(p.x * scale),
    y: Math.round(p.y * scale),
  })

  const nodes: QuantizedNode[] = elkResult.children.map(node => ({
    id: node.id,
    gridX: Math.round((node.x || 0) * scale),
    gridY: Math.round((node.y || 0) * scale),
    gridW: Math.max(3, Math.round((node.width || 0) * scale)), // minimum 3 chars
    gridH: Math.max(3, Math.round((node.height || 0) * scale)),
    labels: (node.labels || []).map(l => ({
      text: l.text,
      gridX: Math.round((l.x || 0) * scale),
      gridY: Math.round((l.y || 0) * scale),
      gridW: Math.round((l.width || 0) * scale),
      gridH: Math.round((l.height || 0) * scale),
    })),
    ports: (node.ports || []).map(p => ({
      id: p.id,
      gridX: Math.round(((node.x || 0) + (p.x || 0)) * scale),
      gridY: Math.round(((node.y || 0) + (p.y || 0)) * scale),
    })),
    isHierarchical: (node.children && node.children.length > 0) || false,
  }))

  const edges: QuantizedEdge[] = elkResult.edges.map(edge => ({
    id: edge.id,
    source: edge.sources[0],
    target: edge.targets[0],
    sourcePort: edge.sourcePort,
    targetPort: edge.targetPort,
    sections: (edge.sections || []).map(section => ({
      id: section.id,
      points: [
        quantizePoint(section.startPoint),
        ...(section.bendPoints || []).map(quantizePoint),
        quantizePoint(section.endPoint),
      ],
    })),
    labels: (edge.labels || []).map(l => ({
      text: l.text,
      gridX: Math.round((l.x || 0) * scale),
      gridY: Math.round((l.y || 0) * scale),
    })),
  }))

  return { nodes, edges }
}

/**
 * Phase 2: Canvas Allocation
 *
 * Calculates bounds and creates canvas with margins
 */
function allocateCanvas(
  nodes: QuantizedNode[],
  edges: QuantizedEdge[],
  margin: number
): CanvasResult {
  let minX = Infinity
  let minY = Infinity
  let maxX = -Infinity
  let maxY = -Infinity

  // Calculate bounds from nodes
  nodes.forEach(node => {
    minX = Math.min(minX, node.gridX)
    minY = Math.min(minY, node.gridY)
    maxX = Math.max(maxX, node.gridX + node.gridW)
    maxY = Math.max(maxY, node.gridY + node.gridH)
  })

  // Expand bounds for edge routing
  edges.forEach(edge => {
    edge.sections.forEach(section => {
      section.points.forEach(p => {
        minX = Math.min(minX, p.x)
        minY = Math.min(minY, p.y)
        maxX = Math.max(maxX, p.x)
        maxY = Math.max(maxY, p.y)
      })
    })
  })

  // Handle empty graph
  if (!isFinite(minX)) {
    minX = 0
    minY = 0
    maxX = 10
    maxY = 10
  }

  // Add margins
  const width = maxX - minX + 2 * margin
  const height = maxY - minY + 2 * margin

  // Create canvas
  const canvas = Array(height)
    .fill(null)
    .map(() => Array(width).fill(' '))

  // Offset all coordinates by margin and minX/minY
  const offset = { x: margin - minX, y: margin - minY }

  return { canvas, offset, width, height }
}

/**
 * Wrap text to fit within width
 */
function wrapText(text: string, maxWidth: number): string[] {
  if (text.length <= maxWidth) return [text]
  const words = text.split(' ')
  const lines: string[] = []
  let currentLine = ''

  words.forEach(word => {
    if ((currentLine + word).length <= maxWidth) {
      currentLine += (currentLine ? ' ' : '') + word
    } else {
      if (currentLine) lines.push(currentLine)
      currentLine = word.substring(0, maxWidth)
    }
  })
  if (currentLine) lines.push(currentLine)

  return lines
}

/**
 * Phase 3: Node Rendering
 *
 * Draws nodes on the canvas
 */
function drawNodes(
  canvas: string[][],
  nodes: QuantizedNode[],
  offset: GridPoint,
  chars: CharSet,
  options: Required<RenderOptions>
): Map<string, OccupancyEntry> {
  const occupancy = new Map<string, OccupancyEntry>()

  nodes.forEach(node => {
    const x = node.gridX + offset.x
    const y = node.gridY + offset.y
    const w = node.gridW
    const h = node.gridH

    // Choose box style
    const isDouble = node.isHierarchical && options.unicode
    const [tl, tr, bl, br, horiz, vert] = isDouble
      ? [
          chars.doubleTL,
          chars.doubleTR,
          chars.doubleBL,
          chars.doubleBR,
          chars.doubleH,
          chars.doubleV,
        ]
      : [
          chars.cornerTL,
          chars.cornerTR,
          chars.cornerBL,
          chars.cornerBR,
          chars.horizontal,
          chars.vertical,
        ]

    // Draw box corners
    if (y >= 0 && y < canvas.length && x >= 0 && x < canvas[0].length) {
      canvas[y][x] = tl
    }
    if (y >= 0 && y < canvas.length && x + w - 1 >= 0 && x + w - 1 < canvas[0].length) {
      canvas[y][x + w - 1] = tr
    }
    if (y + h - 1 >= 0 && y + h - 1 < canvas.length && x >= 0 && x < canvas[0].length) {
      canvas[y + h - 1][x] = bl
    }
    if (
      y + h - 1 >= 0 &&
      y + h - 1 < canvas.length &&
      x + w - 1 >= 0 &&
      x + w - 1 < canvas[0].length
    ) {
      canvas[y + h - 1][x + w - 1] = br
    }

    // Top and bottom edges
    for (let i = 1; i < w - 1; i++) {
      if (y >= 0 && y < canvas.length && x + i >= 0 && x + i < canvas[0].length) {
        canvas[y][x + i] = horiz
      }
      if (
        y + h - 1 >= 0 &&
        y + h - 1 < canvas.length &&
        x + i >= 0 &&
        x + i < canvas[0].length
      ) {
        canvas[y + h - 1][x + i] = horiz
      }
    }

    // Left and right edges
    for (let i = 1; i < h - 1; i++) {
      if (y + i >= 0 && y + i < canvas.length && x >= 0 && x < canvas[0].length) {
        canvas[y + i][x] = vert
      }
      if (
        y + i >= 0 &&
        y + i < canvas.length &&
        x + w - 1 >= 0 &&
        x + w - 1 < canvas[0].length
      ) {
        canvas[y + i][x + w - 1] = vert
      }
    }

    // Mark occupancy
    for (let dy = 0; dy < h; dy++) {
      for (let dx = 0; dx < w; dx++) {
        const cellX = x + dx
        const cellY = y + dy
        if (cellY >= 0 && cellY < canvas.length && cellX >= 0 && cellX < canvas[0].length) {
          occupancy.set(`${cellX},${cellY}`, { type: 'node', id: node.id })
        }
      }
    }

    // Render node label (centered)
    if (options.renderLabels && node.labels.length > 0) {
      const label = node.labels[0]
      const lines = wrapText(label.text, w - 2) // -2 for borders
      const startY = y + Math.floor((h - lines.length) / 2)

      lines.forEach((line, i) => {
        const lineY = startY + i
        if (lineY >= y + 1 && lineY < y + h - 1) {
          const startX = x + Math.floor((w - line.length) / 2)
          for (let j = 0; j < line.length && startX + j < x + w - 1; j++) {
            if (
              lineY >= 0 &&
              lineY < canvas.length &&
              startX + j >= 0 &&
              startX + j < canvas[0].length
            ) {
              canvas[lineY][startX + j] = line[j]
            }
          }
        }
      })
    }

    // Render ports
    if (options.renderPorts) {
      node.ports.forEach(port => {
        const px = port.gridX + offset.x
        const py = port.gridY + offset.y
        // Determine if port is on border
        if (
          (py === y || py === y + h - 1) &&
          py >= 0 &&
          py < canvas.length &&
          px >= 0 &&
          px < canvas[0].length
        ) {
          canvas[py][px] = options.portChar
        } else if (
          (px === x || px === x + w - 1) &&
          py >= 0 &&
          py < canvas.length &&
          px >= 0 &&
          px < canvas[0].length
        ) {
          canvas[py][px] = options.portChar
        }
      })
    }
  })

  return occupancy
}

/**
 * Get direction between two points
 */
function getDirection(from: GridPoint, to: GridPoint): 'r' | 'l' | 'd' | 'u' | null {
  if (to.x > from.x) return 'r'
  if (to.x < from.x) return 'l'
  if (to.y > from.y) return 'd'
  if (to.y < from.y) return 'u'
  return null
}

/**
 * Get corner character for direction transition
 */
function getCornerChar(
  fromDir: 'r' | 'l' | 'd' | 'u' | null,
  toDir: 'r' | 'l' | 'd' | 'u' | null,
  chars: CharSet
): string | null {
  if (!fromDir || !toDir) return null

  // Map direction pairs to correct corners
  // fromDir is where we came from, toDir is where we're going
  const corners: Record<string, string> = {
    rd: chars.cornerTR, // right then down: ┐
    ru: chars.cornerBR, // right then up: ┘
    ld: chars.cornerTL, // left then down: ┌
    lu: chars.cornerBL, // left then up: └
    dr: chars.cornerBL, // down then right: └
    dl: chars.cornerBR, // down then left: ┘
    ur: chars.cornerTL, // up then right: ┌
    ul: chars.cornerTR, // up then left: ┐
  }
  return corners[fromDir + toDir] || null
}

/**
 * Merge characters at intersections
 */
function mergeChar(
  existing: string,
  newChar: string,
  direction: 'h' | 'v',
  chars: CharSet
): string {
  // Empty space - use new char
  if (existing === ' ') return newChar

  // Horizontal + Vertical = Cross
  if (existing === chars.horizontal && direction === 'v') return chars.cross
  if (existing === chars.vertical && direction === 'h') return chars.cross

  // Corner + Line = T-junction
  if (existing === chars.cornerTL && direction === 'v') return chars.tJunctionR
  if (existing === chars.cornerTL && direction === 'h') return chars.tJunctionD
  if (existing === chars.cornerTR && direction === 'v') return chars.tJunctionL
  if (existing === chars.cornerTR && direction === 'h') return chars.tJunctionD
  if (existing === chars.cornerBL && direction === 'v') return chars.tJunctionR
  if (existing === chars.cornerBL && direction === 'h') return chars.tJunctionU
  if (existing === chars.cornerBR && direction === 'v') return chars.tJunctionL
  if (existing === chars.cornerBR && direction === 'h') return chars.tJunctionU

  // T-junction + Line = Cross
  if (
    existing === chars.tJunctionR ||
    existing === chars.tJunctionL ||
    existing === chars.tJunctionD ||
    existing === chars.tJunctionU
  ) {
    return chars.cross
  }

  // Already a cross or same direction
  if (existing === chars.cross) return chars.cross
  if (existing === newChar) return existing

  return existing // default: keep existing
}

/**
 * Draw horizontal segment
 */
function drawHorizontalSegment(
  canvas: string[][],
  from: GridPoint,
  to: GridPoint,
  isLastSegment: boolean,
  edgeId: string,
  occupancy: Map<string, OccupancyEntry>,
  edgeOccupancy: Map<string, OccupancyEntry[]>,
  chars: CharSet,
  options: Required<RenderOptions>
): void {
  const dir = to.x > from.x ? 1 : -1
  const endX = isLastSegment ? to.x - dir : to.x // stop before arrow position

  for (let x = from.x; dir > 0 ? x <= endX : x >= endX; x += dir) {
    const key = `${x},${from.y}`

    // Skip if node occupies this cell
    if (occupancy.has(key)) continue

    // Check bounds
    if (from.y < 0 || from.y >= canvas.length || x < 0 || x >= canvas[0].length) continue

    const existing = canvas[from.y][x]
    canvas[from.y][x] = mergeChar(existing, chars.horizontal, 'h', chars)

    // Track edge occupancy
    if (!edgeOccupancy.has(key)) edgeOccupancy.set(key, [])
    edgeOccupancy.get(key)!.push({ type: 'edge', id: edgeId, dir: 'h' })
  }

  // Place arrow if last segment and arrows enabled
  if (isLastSegment && options.arrows) {
    const arrowX = to.x
    const arrowY = to.y
    const key = `${arrowX},${arrowY}`

    // Check bounds
    if (arrowY >= 0 && arrowY < canvas.length && arrowX >= 0 && arrowX < canvas[0].length) {
      // Check if arrow lands on node boundary
      if (occupancy.has(key)) {
        // Adjust node boundary character
        canvas[arrowY][arrowX] = chars.tJunctionL // right arrow into node
      } else {
        canvas[arrowY][arrowX] = dir > 0 ? chars.arrowR : chars.arrowL
      }
    }
  }
}

/**
 * Draw vertical segment
 */
function drawVerticalSegment(
  canvas: string[][],
  from: GridPoint,
  to: GridPoint,
  isLastSegment: boolean,
  edgeId: string,
  occupancy: Map<string, OccupancyEntry>,
  edgeOccupancy: Map<string, OccupancyEntry[]>,
  chars: CharSet,
  options: Required<RenderOptions>
): void {
  const dir = to.y > from.y ? 1 : -1
  const endY = isLastSegment ? to.y - dir : to.y

  for (let y = from.y; dir > 0 ? y <= endY : y >= endY; y += dir) {
    const key = `${from.x},${y}`

    if (occupancy.has(key)) continue

    // Check bounds
    if (y < 0 || y >= canvas.length || from.x < 0 || from.x >= canvas[0].length) continue

    const existing = canvas[y][from.x]
    canvas[y][from.x] = mergeChar(existing, chars.vertical, 'v', chars)

    if (!edgeOccupancy.has(key)) edgeOccupancy.set(key, [])
    edgeOccupancy.get(key)!.push({ type: 'edge', id: edgeId, dir: 'v' })
  }

  if (isLastSegment && options.arrows) {
    const arrowX = to.x
    const arrowY = to.y
    const key = `${arrowX},${arrowY}`

    // Check bounds
    if (arrowY >= 0 && arrowY < canvas.length && arrowX >= 0 && arrowX < canvas[0].length) {
      if (occupancy.has(key)) {
        canvas[arrowY][arrowX] = chars.tJunctionU // down arrow into node
      } else {
        canvas[arrowY][arrowX] = dir > 0 ? chars.arrowD : chars.arrowU
      }
    }
  }
}

/**
 * Fix corner at bend point
 */
function fixCorner(
  canvas: string[][],
  prev: GridPoint,
  curr: GridPoint,
  next: GridPoint,
  chars: CharSet
): void {
  const fromDir = getDirection(prev, curr)
  const toDir = getDirection(curr, next)

  const corner = getCornerChar(fromDir, toDir, chars)
  if (corner && curr.y >= 0 && curr.y < canvas.length && curr.x >= 0 && curr.x < canvas[0].length) {
    canvas[curr.y][curr.x] = corner
  }
}

/**
 * Draw edge label
 */
function drawEdgeLabel(
  canvas: string[][],
  label: { text: string; gridX: number; gridY: number },
  offset: GridPoint,
  occupancy: Map<string, OccupancyEntry>
): void {
  const x = label.gridX + offset.x
  const y = label.gridY + offset.y
  const text = label.text

  // Check bounds
  if (y < 0 || y >= canvas.length) return

  // Clear background for label
  for (let i = 0; i < text.length && x + i < canvas[0].length; i++) {
    if (!occupancy.has(`${x + i},${y}`) && x + i >= 0) {
      canvas[y][x + i] = text[i]
    }
  }
}

/**
 * Draw edge section
 */
function drawEdgeSection(
  canvas: string[][],
  section: { id: string; points: GridPoint[] },
  edge: QuantizedEdge,
  isLastSection: boolean,
  offset: GridPoint,
  occupancy: Map<string, OccupancyEntry>,
  edgeOccupancy: Map<string, OccupancyEntry[]>,
  chars: CharSet,
  options: Required<RenderOptions>
): void {
  const points = section.points.map(p => ({
    x: p.x + offset.x,
    y: p.y + offset.y,
  }))

  // Draw segments between consecutive points
  for (let i = 0; i < points.length - 1; i++) {
    const from = points[i]
    const to = points[i + 1]
    const isLastSegment = isLastSection && i === points.length - 2

    if (from.y === to.y) {
      // Horizontal segment
      drawHorizontalSegment(
        canvas,
        from,
        to,
        isLastSegment,
        edge.id,
        occupancy,
        edgeOccupancy,
        chars,
        options
      )
    } else if (from.x === to.x) {
      // Vertical segment
      drawVerticalSegment(
        canvas,
        from,
        to,
        isLastSegment,
        edge.id,
        occupancy,
        edgeOccupancy,
        chars,
        options
      )
    } else {
      // Should not happen in orthogonal mode
      console.warn('Non-orthogonal segment detected:', from, to)
    }
  }

  // Fix corners at bendpoints
  for (let i = 1; i < points.length - 1; i++) {
    fixCorner(canvas, points[i - 1], points[i], points[i + 1], chars)
  }
}

/**
 * Phase 4: Edge Rendering
 *
 * Draws edges on the canvas
 */
function drawEdges(
  canvas: string[][],
  edges: QuantizedEdge[],
  offset: GridPoint,
  occupancy: Map<string, OccupancyEntry>,
  chars: CharSet,
  options: Required<RenderOptions>
): Map<string, OccupancyEntry[]> {
  const edgeOccupancy = new Map<string, OccupancyEntry[]>()

  edges.forEach(edge => {
    edge.sections.forEach((section, sectionIdx) => {
      const isLastSection = sectionIdx === edge.sections.length - 1
      drawEdgeSection(canvas, section, edge, isLastSection, offset, occupancy, edgeOccupancy, chars, options)
    })

    // Render edge labels
    if (options.renderLabels) {
      edge.labels.forEach(label => {
        drawEdgeLabel(canvas, label, offset, occupancy)
      })
    }
  })

  return edgeOccupancy
}

/**
 * Phase 5: Output Generation
 *
 * Converts canvas to string
 */
function canvasToString(canvas: string[][]): string {
  return canvas.map(row => row.join('')).join('\n')
}

/**
 * Calculate metadata
 */
function calculateMetadata(
  canvas: string[][],
  nodes: QuantizedNode[],
  edges: QuantizedEdge[],
  warnings: string[],
  scale: number
): RenderResult['metadata'] {
  return {
    width: canvas[0]?.length || 0,
    height: canvas.length,
    scale: scale,
    nodeCount: nodes.length,
    edgeCount: edges.length,
    warnings: warnings,
  }
}

/**
 * Main rendering function
 *
 * Converts ELK layout result to ASCII art
 */
export function renderASCII(elkResult: ELKResult, options: RenderOptions = {}): RenderResult {
  const opts: Required<RenderOptions> = { ...defaultOptions, ...options }
  const warnings: string[] = []

  try {
    // Validate input
    if (!elkResult) {
      throw new Error('Invalid ELK result: result is null or undefined')
    }

    // Handle optional children and edges (default to empty arrays)
    const normalizedResult: Required<ELKResult> = {
      children: elkResult.children || [],
      edges: elkResult.edges || [],
    }

    // Phase 1: Quantize coordinates
    const { nodes, edges } = quantize(normalizedResult, opts.scale)

    // Phase 2: Allocate canvas
    const { canvas, offset, width, height } = allocateCanvas(nodes, edges, opts.margin)

    // Select character set
    const chars = opts.unicode ? UNICODE_CHARS : ASCII_CHARS

    // Phase 3: Draw nodes
    const occupancy = drawNodes(canvas, nodes, offset, chars, opts)

    // Phase 4: Draw edges
    const edgeOccupancy = drawEdges(canvas, edges, offset, occupancy, chars, opts)

    // Phase 5: Check density
    const density = edgeOccupancy.size / (width * height)
    if (density > opts.maxDensity) {
      warnings.push(
        `High edge density (${(density * 100).toFixed(1)}%). Consider increasing scale or ELK spacing.`
      )
    }

    // Phase 6: Generate output
    const ascii = canvasToString(canvas)
    const metadata = calculateMetadata(canvas, nodes, edges, warnings, opts.scale)

    return { ascii, metadata }
  } catch (error) {
    return {
      ascii: null,
      metadata: {
        error: error instanceof Error ? error.message : String(error),
        warnings: warnings,
      },
    }
  }
}
