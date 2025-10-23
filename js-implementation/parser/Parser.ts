/**
 * Parser for Graph::Easy notation
 *
 * Supports:
 * - Nodes: [Name], [ Name ]
 * - Edges: ->, =>, ..>, ->, <->, <=>, --, etc.
 * - Attributes: { key: value; key2: value2 }
 * - Comments: # comment
 * - Graph attributes: graph { key: value }
 *
 * Example:
 *   [Bonn] -> [Berlin] { label: train; }
 *   [Berlin] => [Dresden]
 *   # This is a comment
 */

import { Graph } from '../core/Graph'
import { Node } from '../core/Node'
import { Edge } from '../core/Edge'

export interface ParseOptions {
  strict?: boolean
  debug?: boolean
}

export class Parser {
  private input: string = ''
  private pos: number = 0
  private line: number = 1
  private col: number = 1
  private graph: Graph
  private options: Required<ParseOptions>

  constructor(options: ParseOptions = {}) {
    this.graph = new Graph()
    this.options = {
      strict: options.strict ?? false,
      debug: options.debug ?? false,
    }
  }

  /**
   * Parse Graph::Easy notation and return a Graph object
   */
  parse(input: string): Graph {
    this.input = input
    this.pos = 0
    this.line = 1
    this.col = 1
    this.graph = new Graph()

    while (!this.isEOF()) {
      this.skipWhitespaceAndComments()
      if (this.isEOF()) break

      try {
        this.parseStatement()
      } catch (error) {
        if (this.options.strict) {
          throw error
        } else {
          console.warn(`Parse warning at ${this.line}:${this.col}:`, error)
          // Skip to next line on error
          this.skipToNextLine()
        }
      }
    }

    return this.graph
  }

  // ===== Statement Parsing =====

  private parseStatement(): void {
    this.skipWhitespaceAndComments()

    // Check for graph attributes: graph { ... }
    if (this.peek(5) === 'graph' && this.isWhitespace(this.peekChar(5))) {
      this.parseGraphAttributes()
      return
    }

    // Check for node or edge
    if (this.peekChar() === '[') {
      this.parseNodeOrEdge()
      return
    }

    // Unknown statement
    if (!this.isEOF()) {
      throw this.error(`Unexpected character: '${this.peekChar()}'`)
    }
  }

  private parseGraphAttributes(): void {
    this.expect('graph')
    this.skipWhitespace()

    const attrs = this.parseAttributes()

    for (const [key, value] of Object.entries(attrs)) {
      this.graph.setAttribute(key, value)
    }
  }

  private parseNodeOrEdge(): void {
    // Parse first node
    const firstNode = this.parseNode()

    this.skipWhitespace()

    // Check if there's an edge
    const edgeType = this.parseEdgeType()

    if (!edgeType) {
      // Just a standalone node
      return
    }

    // Parse second node
    this.skipWhitespace()
    const secondNode = this.parseNode()

    // Create edge
    const edge = this.graph.addEdge(firstNode, secondNode)

    // Set edge style based on type
    this.applyEdgeStyle(edge, edgeType)

    // Parse edge attributes if present
    this.skipWhitespace()
    if (this.peekChar() === '{') {
      const attrs = this.parseAttributes()
      edge.setAttributes(attrs)
    }

    // Check for chained edges: A -> B -> C
    this.skipWhitespace()
    const nextEdgeType = this.parseEdgeType()

    if (nextEdgeType) {
      // Continue with the chain
      this.continueEdgeChain(secondNode, nextEdgeType)
    }
  }

  private continueEdgeChain(fromNode: Node, edgeType: string): void {
    this.skipWhitespace()
    const toNode = this.parseNode()

    const edge = this.graph.addEdge(fromNode, toNode)
    this.applyEdgeStyle(edge, edgeType)

    this.skipWhitespace()
    if (this.peekChar() === '{') {
      const attrs = this.parseAttributes()
      edge.setAttributes(attrs)
    }

    // Continue chain if more edges
    this.skipWhitespace()
    const nextEdgeType = this.parseEdgeType()
    if (nextEdgeType) {
      this.continueEdgeChain(toNode, nextEdgeType)
    }
  }

  // ===== Node Parsing =====

  private parseNode(): Node {
    this.expect('[')
    this.skipWhitespace()

    const name = this.parseNodeName()

    this.skipWhitespace()
    this.expect(']')

    const node = this.graph.addNode(name)

    // Parse attributes if present
    this.skipWhitespace()
    if (this.peekChar() === '{') {
      const attrs = this.parseAttributes()
      node.setAttributes(attrs)
    }

    return node
  }

  private parseNodeName(): string {
    let name = ''

    while (!this.isEOF() && this.peekChar() !== ']') {
      name += this.advance()
    }

    return name.trim()
  }

  // ===== Edge Parsing =====

  private parseEdgeType(): string | null {
    const saved = this.savePosition()

    // Try to match edge patterns
    // Order matters - check longer patterns first!

    // Bidirectional double: <=>
    if (this.tryConsume('<=>')) return '<=>'

    // Bidirectional: <->
    if (this.tryConsume('<->')) return '<->'

    // Double forward: ==>
    if (this.tryConsume('==>')) return '==>'

    // Dotted: ..>
    if (this.tryConsume('..>')) return '..>'

    // Dot-dash: .->
    if (this.tryConsume('.->')) return '.->'

    // Wave: ~~>
    if (this.tryConsume('~~>')) return '~~>'

    // Dashed: - > (with space)
    if (this.tryConsume('- >')) return '- >'

    // Regular forward: ->
    if (this.tryConsume('->')) return '->'

    // Backward: <-
    if (this.tryConsume('<-')) return '<-'

    // Undirected: --
    if (this.tryConsume('--')) return '--'

    // No edge found
    this.restorePosition(saved)
    return null
  }

  private applyEdgeStyle(edge: Edge, edgeType: string): void {
    switch (edgeType) {
      case '->':
        edge.setAttribute('style', 'solid')
        edge.setAttribute('arrowStyle', 'forward')
        break

      case '<-':
        edge.setAttribute('style', 'solid')
        edge.setAttribute('arrowStyle', 'back')
        break

      case '<->':
        edge.setAttribute('style', 'solid')
        edge.setAttribute('arrowStyle', 'both')
        break

      case '==>':
        edge.setAttribute('style', 'double')
        edge.setAttribute('arrowStyle', 'forward')
        break

      case '<=>':
        edge.setAttribute('style', 'double')
        edge.setAttribute('arrowStyle', 'both')
        break

      case '..>':
        edge.setAttribute('style', 'dotted')
        edge.setAttribute('arrowStyle', 'forward')
        break

      case '.->':
        edge.setAttribute('style', 'dotdash')
        edge.setAttribute('arrowStyle', 'forward')
        break

      case '~~>':
        edge.setAttribute('style', 'wave')
        edge.setAttribute('arrowStyle', 'forward')
        break

      case '- >':
        edge.setAttribute('style', 'dashed')
        edge.setAttribute('arrowStyle', 'forward')
        break

      case '--':
        edge.setAttribute('style', 'solid')
        edge.setAttribute('arrowStyle', 'none')
        break

      default:
        edge.setAttribute('style', 'solid')
        edge.setAttribute('arrowStyle', 'forward')
    }
  }

  // ===== Attribute Parsing =====

  private parseAttributes(): Record<string, any> {
    const attrs: Record<string, any> = {}

    this.expect('{')
    this.skipWhitespace()

    while (this.peekChar() !== '}' && !this.isEOF()) {
      // Parse key
      const key = this.parseIdentifier()

      this.skipWhitespace()
      this.expect(':')
      this.skipWhitespace()

      // Parse value
      const value = this.parseAttributeValue()

      attrs[key] = value

      this.skipWhitespace()

      // Optional semicolon
      if (this.peekChar() === ';') {
        this.advance()
        this.skipWhitespace()
      }

      // Allow comma as separator too
      if (this.peekChar() === ',') {
        this.advance()
        this.skipWhitespace()
      }
    }

    this.expect('}')

    return attrs
  }

  private parseIdentifier(): string {
    let id = ''

    while (!this.isEOF()) {
      const ch = this.peekChar()
      if (/[a-zA-Z0-9_-]/.test(ch)) {
        id += this.advance()
      } else {
        break
      }
    }

    if (id.length === 0) {
      throw this.error('Expected identifier')
    }

    return id
  }

  private parseAttributeValue(): any {
    this.skipWhitespace()

    // Quoted string
    if (this.peekChar() === '"' || this.peekChar() === "'") {
      return this.parseQuotedString()
    }

    // Unquoted value (until ; or } or ,)
    let value = ''

    while (!this.isEOF()) {
      const ch = this.peekChar()
      if (ch === ';' || ch === '}' || ch === ',') {
        break
      }
      value += this.advance()
    }

    value = value.trim()

    // Try to parse as number
    const num = Number(value)
    if (!isNaN(num) && value !== '') {
      return num
    }

    return value
  }

  private parseQuotedString(): string {
    const quote = this.advance() // " or '
    let str = ''

    while (!this.isEOF() && this.peekChar() !== quote) {
      if (this.peekChar() === '\\') {
        this.advance() // skip backslash
        // Handle escape sequences
        const next = this.advance()
        switch (next) {
          case 'n': str += '\n'; break
          case 't': str += '\t'; break
          case 'r': str += '\r'; break
          default: str += next
        }
      } else {
        str += this.advance()
      }
    }

    this.expect(quote)

    return str
  }

  // ===== Utility Methods =====

  private skipWhitespace(): void {
    while (!this.isEOF() && this.isWhitespace(this.peekChar())) {
      this.advance()
    }
  }

  private skipWhitespaceAndComments(): void {
    while (!this.isEOF()) {
      this.skipWhitespace()

      // Check for comment
      if (this.peekChar() === '#') {
        this.skipToNextLine()
      } else {
        break
      }
    }
  }

  private skipToNextLine(): void {
    while (!this.isEOF() && this.peekChar() !== '\n') {
      this.advance()
    }
    if (this.peekChar() === '\n') {
      this.advance()
    }
  }

  private isWhitespace(ch: string): boolean {
    return /\s/.test(ch)
  }

  private isEOF(): boolean {
    return this.pos >= this.input.length
  }

  private peekChar(offset: number = 0): string {
    return this.input[this.pos + offset] || ''
  }

  private peek(length: number): string {
    return this.input.substring(this.pos, this.pos + length)
  }

  private advance(): string {
    const ch = this.input[this.pos]
    this.pos++

    if (ch === '\n') {
      this.line++
      this.col = 1
    } else {
      this.col++
    }

    return ch
  }

  private expect(str: string): void {
    for (let i = 0; i < str.length; i++) {
      if (this.peekChar() !== str[i]) {
        throw this.error(`Expected '${str}' but found '${this.peekChar()}'`)
      }
      this.advance()
    }
  }

  private tryConsume(str: string): boolean {
    if (this.peek(str.length) === str) {
      for (let i = 0; i < str.length; i++) {
        this.advance()
      }
      return true
    }
    return false
  }

  private savePosition(): { pos: number; line: number; col: number } {
    return { pos: this.pos, line: this.line, col: this.col }
  }

  private restorePosition(saved: { pos: number; line: number; col: number }): void {
    this.pos = saved.pos
    this.line = saved.line
    this.col = saved.col
  }

  private error(message: string): Error {
    return new Error(`Parse error at ${this.line}:${this.col}: ${message}`)
  }
}

/**
 * Convenience function to parse a graph
 */
export function parseGraph(input: string, options?: ParseOptions): Graph {
  const parser = new Parser(options)
  return parser.parse(input)
}
