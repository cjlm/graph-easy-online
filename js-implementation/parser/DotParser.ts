/**
 * DOT/Graphviz Parser
 *
 * Parses Graphviz DOT format and converts to Graph::Easy Graph object
 *
 * Supported syntax:
 * - digraph name { ... }
 * - graph name { ... }
 * - Nodes: nodename [attr=value, ...]
 * - Edges: a -> b or a -- b
 * - Attributes: [color=red, label="text"]
 * - Subgraphs: subgraph name { ... }
 * - Comments: // and C-style block comments
 *
 * Example:
 *   digraph G {
 *     A -> B [label="edge"];
 *     B -> C;
 *   }
 */

import { Graph } from '../core/Graph.ts'
import { Node } from '../core/Node.ts'
// import { Edge } from '../core/Edge.ts'  // Future use
// import { Group } from '../core/Group.ts'  // Future use
import { Parser } from './Parser.ts'

export interface DotParseOptions {
  strict?: boolean
  debug?: boolean
}

export class DotParser {
  private input: string = ''
  private pos: number = 0
  private line: number = 1
  private col: number = 1
  private graph: Graph
  private options: Required<DotParseOptions>
  // @ts-expect-error - Reserved for future use
  private _isDirected: boolean = true

  constructor(options: DotParseOptions = {}) {
    this.graph = new Graph()
    this.options = {
      strict: options.strict ?? false,
      debug: options.debug ?? false,
    }
  }

  /**
   * Check if input is in DOT format
   *
   * DOT format: graph { A -- B }
   * Graph::Easy format: graph { [ A ] -- [ B ] }
   *
   * Key difference: Graph::Easy uses [ ] brackets around node names
   */
  static isDot(input: string): boolean {
    const trimmed = input.trim()

    // Check if it starts with DOT keywords
    const hasDotKeyword = trimmed.startsWith('graph ') ||
           trimmed.startsWith('digraph ') ||
           trimmed.startsWith('strict graph ') ||
           trimmed.startsWith('strict digraph ')

    if (!hasDotKeyword) {
      return false
    }

    // If it has [ ] brackets, it's Graph::Easy, not DOT
    if (trimmed.includes('[') && trimmed.includes(']')) {
      return false
    }

    return true
  }

  /**
   * Parse DOT/Graphviz format and return a Graph object
   */
  parse(input: string): Graph {
    this.input = input
    this.pos = 0
    this.line = 1
    this.col = 1
    this.graph = new Graph()

    try {
      this.skipWhitespaceAndComments()
      this.parseGraph()
      return this.graph
    } catch (error) {
      if (this.options.strict) {
        throw error
      } else {
        console.warn('DOT parse error:', error)
        return this.graph
      }
    }
  }

  // ===== Graph Parsing =====

  private parseGraph(): void {
    this.skipWhitespaceAndComments()

    // Optional 'strict'
    if (this.peek(6) === 'strict') {
      this.expect('strict')
      this.skipWhitespace()
    }

    // Graph type: 'graph' or 'digraph'
    const graphType = this.parseIdentifier()
    this._isDirected = graphType === 'digraph'

    if (graphType === 'graph') {
      this.graph.setAttribute('type', 'undirected')
    }

    this.skipWhitespace()

    // Optional graph name
    if (this.peekChar() !== '{') {
      const name = this.parseIdentifier()
      this.graph.setAttribute('label', name)
      this.skipWhitespace()
    }

    // Graph body
    this.expect('{')
    this.skipWhitespaceAndComments()

    while (this.peekChar() !== '}' && !this.isEOF()) {
      this.parseStatement()
      this.skipWhitespaceAndComments()
    }

    this.expect('}')
  }

  private parseStatement(): void {
    this.skipWhitespaceAndComments()

    // Check for graph/node/edge attributes
    const id = this.parseIdentifier()

    this.skipWhitespace()

    // Check what follows the identifier
    const next = this.peekChar()

    if (next === '[') {
      // Node with attributes: A [color=red];
      this.parseNodeAttributes(id)
    } else if (next === '-') {
      // Edge: A -> B or A -- B
      this.parseEdgeStatement(id)
    } else if (next === '=' || next === ':') {
      // Graph attribute: rankdir=LR;
      this.parseGraphAttribute(id)
    } else if (id === 'graph' || id === 'node' || id === 'edge') {
      // Class attributes: node [color=red];
      this.skipWhitespace()
      if (this.peekChar() === '[') {
        const attrs = this.parseAttributeList()
        for (const [key, value] of Object.entries(attrs)) {
          this.graph.setAttribute(id, key, value)
        }
      }
    } else if (id === 'subgraph') {
      this.parseSubgraph()
    } else {
      // Just a node mention without attributes
      this.graph.addNode(id)
    }

    // Optional semicolon
    this.skipWhitespace()
    if (this.peekChar() === ';') {
      this.advance()
    }
  }

  private parseNodeAttributes(nodeName: string): void {
    const node = this.graph.addNode(nodeName)

    this.skipWhitespace()
    if (this.peekChar() === '[') {
      const attrs = this.parseAttributeList()
      node.setAttributes(this.convertDotAttributes(attrs))
    }
  }

  private parseEdgeStatement(fromName: string): void {
    const from = this.graph.addNode(fromName)

    this.skipWhitespace()

    // Parse edge operator: -> or --
    const edgeOp = this.parseEdgeOp()

    this.skipWhitespace()

    // Parse target node(s)
    const toName = this.parseIdentifier()
    const to = this.graph.addNode(toName)

    // Create edge
    const edge = this.graph.addEdge(from, to)

    // Set edge style based on operator
    if (edgeOp === '--') {
      edge.setAttribute('arrowStyle', 'none')
    } else {
      edge.setAttribute('arrowStyle', 'forward')
    }

    // Parse edge attributes
    this.skipWhitespace()
    if (this.peekChar() === '[') {
      const attrs = this.parseAttributeList()
      edge.setAttributes(this.convertDotAttributes(attrs))
    }

    // Handle chained edges: A -> B -> C
    this.skipWhitespace()
    if (this.peek(2) === '->' || this.peek(2) === '--') {
      this.parseChainedEdges(to)
    }
  }

  private parseChainedEdges(from: Node): void {
    while (this.peek(2) === '->' || this.peek(2) === '--') {
      const edgeOp = this.parseEdgeOp()
      this.skipWhitespace()

      const toName = this.parseIdentifier()
      const to = this.graph.addNode(toName)

      const edge = this.graph.addEdge(from, to)

      if (edgeOp === '--') {
        edge.setAttribute('arrowStyle', 'none')
      } else {
        edge.setAttribute('arrowStyle', 'forward')
      }

      this.skipWhitespace()
      if (this.peekChar() === '[') {
        const attrs = this.parseAttributeList()
        edge.setAttributes(this.convertDotAttributes(attrs))
      }

      from = to
      this.skipWhitespace()
    }
  }

  private parseEdgeOp(): string {
    if (this.tryConsume('->')) {
      return '->'
    } else if (this.tryConsume('--')) {
      return '--'
    } else {
      throw this.error('Expected edge operator (-> or --)')
    }
  }

  private parseGraphAttribute(key: string): void {
    this.skipWhitespace()

    // Skip = or :
    if (this.peekChar() === '=' || this.peekChar() === ':') {
      this.advance()
    }

    this.skipWhitespace()

    const value = this.parseAttributeValue()
    this.graph.setAttribute(this.convertDotAttributeName(key), value)
  }

  private parseSubgraph(): void {
    this.skipWhitespace()

    // Optional subgraph name
    let name = ''
    if (this.peekChar() !== '{') {
      name = this.parseIdentifier()
      this.skipWhitespace()
    } else {
      name = `subgraph_${Math.random().toString(36).substr(2, 9)}`
    }

    // @ts-expect-error - Reserved for future use
    const _group = this.graph.addGroup(name)

    this.expect('{')
    this.skipWhitespaceAndComments()

    // Parse subgraph statements
    // For now, we'll just parse nodes and add them to the group
    // @ts-expect-error - Reserved for future use
    const _savedGraph = this.graph
    while (this.peekChar() !== '}' && !this.isEOF()) {
      this.parseStatement()
      this.skipWhitespaceAndComments()
    }

    this.expect('}')
  }

  // ===== Attribute Parsing =====

  private parseAttributeList(): Record<string, any> {
    const attrs: Record<string, any> = {}

    this.expect('[')
    this.skipWhitespaceAndComments()

    while (this.peekChar() !== ']' && !this.isEOF()) {
      const key = this.parseIdentifier()

      this.skipWhitespace()
      this.expect('=')
      this.skipWhitespace()

      const value = this.parseAttributeValue()

      attrs[key] = value

      this.skipWhitespace()

      // Optional comma or semicolon
      if (this.peekChar() === ',' || this.peekChar() === ';') {
        this.advance()
        this.skipWhitespace()
      }
    }

    this.expect(']')

    return attrs
  }

  private parseAttributeValue(): any {
    this.skipWhitespace()

    // Quoted string
    if (this.peekChar() === '"') {
      return this.parseQuotedString()
    }

    // HTML-like label: <...>
    if (this.peekChar() === '<') {
      return this.parseHtmlLabel()
    }

    // Unquoted value
    let value = ''
    while (!this.isEOF()) {
      const ch = this.peekChar()
      if (ch === ',' || ch === ';' || ch === ']' || ch === '}' || this.isWhitespace(ch)) {
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
    this.expect('"')
    let str = ''

    while (!this.isEOF() && this.peekChar() !== '"') {
      if (this.peekChar() === '\\') {
        this.advance()
        const next = this.advance()
        switch (next) {
          case 'n': str += '\n'; break
          case 't': str += '\t'; break
          case 'r': str += '\r'; break
          case '"': str += '"'; break
          case '\\': str += '\\'; break
          default: str += next
        }
      } else {
        str += this.advance()
      }
    }

    this.expect('"')
    return str
  }

  private parseHtmlLabel(): string {
    this.expect('<')
    let html = ''

    let depth = 1
    while (!this.isEOF() && depth > 0) {
      const ch = this.advance()
      if (ch === '<') depth++
      else if (ch === '>') depth--

      if (depth > 0) html += ch
    }

    return html
  }

  private parseIdentifier(): string {
    this.skipWhitespace()

    // Quoted identifier
    if (this.peekChar() === '"') {
      return this.parseQuotedString()
    }

    // HTML-like identifier
    if (this.peekChar() === '<') {
      return this.parseHtmlLabel()
    }

    // Regular identifier
    let id = ''
    while (!this.isEOF()) {
      const ch = this.peekChar()
      if (/[a-zA-Z0-9_]/.test(ch)) {
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

  // ===== Attribute Conversion =====

  /**
   * Convert DOT attribute names to Graph::Easy names
   */
  private convertDotAttributeName(dotName: string): string {
    const mapping: Record<string, string> = {
      'color': 'color',
      'fillcolor': 'fill',
      'fontcolor': 'fontcolor',
      'fontname': 'font',
      'fontsize': 'fontsize',
      'label': 'label',
      'shape': 'shape',
      'style': 'style',
      'penwidth': 'borderwidth',
      'dir': 'arrowStyle',
      'arrowhead': 'arrowstyle',
      'arrowtail': 'arrowstyle',
    }

    return mapping[dotName] || dotName
  }

  /**
   * Convert DOT attributes to Graph::Easy attributes
   */
  private convertDotAttributes(dotAttrs: Record<string, any>): Record<string, any> {
    const converted: Record<string, any> = {}

    for (const [key, value] of Object.entries(dotAttrs)) {
      const convertedKey = this.convertDotAttributeName(key)
      let convertedValue = value

      // Convert specific values
      if (key === 'style') {
        convertedValue = this.convertDotStyle(value)
      } else if (key === 'dir') {
        convertedValue = this.convertDotDir(value)
      } else if (key === 'shape') {
        convertedValue = this.convertDotShape(value)
      }

      converted[convertedKey] = convertedValue
    }

    return converted
  }

  private convertDotStyle(style: string): string {
    const mapping: Record<string, string> = {
      'solid': 'solid',
      'dashed': 'dashed',
      'dotted': 'dotted',
      'bold': 'bold',
      'invis': 'invisible',
    }

    return mapping[style] || style
  }

  private convertDotDir(dir: string): string {
    const mapping: Record<string, string> = {
      'forward': 'forward',
      'back': 'back',
      'both': 'both',
      'none': 'none',
    }

    return mapping[dir] || dir
  }

  private convertDotShape(shape: string): string {
    const mapping: Record<string, string> = {
      'box': 'rect',
      'circle': 'circle',
      'ellipse': 'ellipse',
      'point': 'point',
      'diamond': 'diamond',
      'triangle': 'triangle',
      'plaintext': 'invisible',
      'none': 'invisible',
    }

    return mapping[shape] || shape
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

      // C++ style comment: //
      if (this.peek(2) === '//') {
        this.skipToNextLine()
        continue
      }

      // C style comment: /* */
      if (this.peek(2) === '/*') {
        this.skipBlockComment()
        continue
      }

      // # comment (also supported)
      if (this.peekChar() === '#') {
        this.skipToNextLine()
        continue
      }

      break
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

  private skipBlockComment(): void {
    this.advance() // /
    this.advance() // *

    while (!this.isEOF()) {
      if (this.peek(2) === '*/') {
        this.advance() // *
        this.advance() // /
        break
      }
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

  private error(message: string): Error {
    return new Error(`DOT parse error at ${this.line}:${this.col}: ${message}`)
  }
}

/**
 * Convenience function to parse DOT format
 */
export function parseDot(input: string, options?: DotParseOptions): Graph {
  const parser = new DotParser(options)
  return parser.parse(input)
}

/**
 * Auto-detect format and parse
 */
export function parseGraphAuto(input: string): Graph {
  const trimmed = input.trim()

  // Check if it's DOT format
  // DOT starts with digraph/graph followed by optional name and { ... }
  // Graph::Easy may have "graph { attr: value }" but will have other content after
  if (trimmed.startsWith('digraph') || trimmed.startsWith('strict')) {
    return parseDot(input)
  }

  // For "graph", check if it looks like DOT or Graph::Easy
  if (trimmed.startsWith('graph')) {
    // If it's "graph {" at the start and has [ or node definitions, it's Graph::Easy
    // If it's the entire content inside one graph block, it's DOT
    const afterGraph = trimmed.substring(5).trim()

    // DOT: "graph { ... }" or "graph name { ... }" where everything is inside the braces
    // Graph::Easy: "graph { flow: south; }\n[A] -> [B]" has content outside the first block

    // Check if there's content after the first closing brace
    let braceDepth = 0
    let inQuotes = false
    let firstBlockEnd = -1

    for (let i = 0; i < afterGraph.length; i++) {
      const char = afterGraph[i]
      if (char === '"' && afterGraph[i - 1] !== '\\') {
        inQuotes = !inQuotes
      } else if (!inQuotes) {
        if (char === '{') braceDepth++
        else if (char === '}') {
          braceDepth--
          if (braceDepth === 0) {
            firstBlockEnd = i
            break
          }
        }
      }
    }

    // If there's non-whitespace content after the first closing brace, it's Graph::Easy
    if (firstBlockEnd >= 0) {
      const afterFirstBlock = afterGraph.substring(firstBlockEnd + 1).trim()
      if (afterFirstBlock.length > 0) {
        // Graph::Easy format
        const parser = new Parser()
        return parser.parse(input)
      }
    }

    // Otherwise treat as DOT
    return parseDot(input)
  }

  // Otherwise assume Graph::Easy format
  const parser = new Parser()
  return parser.parse(input)
}
