/**
 * Main API for Graph::Easy ASCII conversion
 *
 * Supports both Graph::Easy notation and Graphviz DOT format as input.
 *
 * Usage:
 *   import { GraphEasyASCII } from './GraphEasyASCII'
 *
 *   const converter = await GraphEasyASCII.create()
 *
 *   // Graph::Easy format
 *   await converter.convert('[Bonn] -> [Berlin]')
 *
 *   // DOT format (auto-detected)
 *   await converter.convert('digraph { A -> B; }')
 */

import { Parser } from './parser/Parser'
import { DotParser, parseGraphAuto } from './parser/DotParser'
import { renderAscii, renderBoxart, AsciiRendererOptions } from './renderers/AsciiRenderer'
import type { Graph } from './core/Graph'
import type { LayoutResult } from './core/Graph'

export type InputFormat = 'auto' | 'grapheasy' | 'dot'

export interface GraphEasyOptions {
  /**
   * Use boxart (Unicode) instead of ASCII
   */
  boxart?: boolean

  /**
   * Strict parsing (throw on errors)
   */
  strict?: boolean

  /**
   * Enable debug output
   */
  debug?: boolean

  /**
   * Input format ('auto', 'grapheasy', or 'dot')
   * Default: 'auto' (auto-detect)
   */
  inputFormat?: InputFormat

  /**
   * Graph flow direction
   */
  flow?: 'east' | 'west' | 'north' | 'south'

  /**
   * Node spacing (in grid units)
   */
  nodeSpacing?: number

  /**
   * Rank spacing (in grid units)
   */
  rankSpacing?: number

  /**
   * Disable WASM and use pure TypeScript layout
   */
  disableWasm?: boolean
}

export class GraphEasyASCII {
  private graphEasyParser: Parser
  private dotParser: DotParser
  private layoutEngine: any // Will be the WASM layout engine when integrated
  private options: Required<GraphEasyOptions>
  private initialized: boolean = false

  private constructor(options: GraphEasyOptions = {}) {
    this.options = {
      boxart: options.boxart ?? false,
      strict: options.strict ?? false,
      debug: options.debug ?? false,
      inputFormat: options.inputFormat ?? 'auto',
      flow: options.flow ?? 'east',
      nodeSpacing: options.nodeSpacing ?? 3,
      rankSpacing: options.rankSpacing ?? 5,
      disableWasm: options.disableWasm ?? false,
    }

    this.graphEasyParser = new Parser({
      strict: this.options.strict,
      debug: this.options.debug,
    })

    this.dotParser = new DotParser({
      strict: this.options.strict,
      debug: this.options.debug,
    })
  }

  /**
   * Create a new GraphEasyASCII instance
   *
   * This is async to allow for WASM initialization in the future.
   */
  static async create(options?: GraphEasyOptions): Promise<GraphEasyASCII> {
    const instance = new GraphEasyASCII(options)
    await instance.initialize()
    return instance
  }

  /**
   * Initialize the converter (load WASM if needed)
   */
  private async initialize(): Promise<void> {
    if (this.initialized) return

    if (!this.options.disableWasm) {
      try {
        // Initialize WASM layout engine
        const { default: init, LayoutEngine } = await import('./layout-engine-rust/pkg/graph_easy_layout.js')
        await init()
        this.layoutEngine = new LayoutEngine()
        console.log('✅ WASM layout engine initialized')
      } catch (error) {
        console.warn('⚠️  WASM unavailable, using TypeScript fallback')
        // Continue without WASM - will use TypeScript layout
      }
    } else {
      console.log('✅ TypeScript-only mode (WASM disabled)')
    }

    this.initialized = true
  }

  /**
   * Convert graph notation to ASCII art
   *
   * Supports both Graph::Easy and DOT formats (auto-detected by default)
   *
   * @param input - Graph::Easy notation or DOT format
   * @returns ASCII art representation
   */
  async convert(input: string): Promise<string> {
    try {
      // 1. Parse the input
      const graph = this.parse(input)

      // 2. Apply graph-level options
      if (this.options.flow) {
        graph.setAttribute('flow', this.options.flow)
      }

      // 3. Perform layout
      const layout = await this.layout(graph)

      // 4. Render as ASCII
      const ascii = this.render(layout)

      return ascii
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(`Conversion failed: ${error.message}`)
      }
      throw error
    }
  }

  /**
   * Parse input into a Graph object
   *
   * Automatically detects format or uses specified format
   */
  parse(input: string): Graph {
    switch (this.options.inputFormat) {
      case 'grapheasy':
        return this.graphEasyParser.parse(input)

      case 'dot':
        return this.dotParser.parse(input)

      case 'auto':
      default:
        return parseGraphAuto(input)
    }
  }

  /**
   * Perform layout on a graph
   */
  private async layout(graph: Graph): Promise<LayoutResult> {
    if (this.layoutEngine) {
      // Use WASM layout engine when available
      console.log('🦀 Using Rust/WASM layout engine')
      return await this.layoutWithWASM(graph)
    } else {
      // Fallback to TypeScript layout
      console.log('📘 Using TypeScript layout engine')
      return await graph.layout()
    }
  }

  /**
   * Layout using WASM engine
   */
  private async layoutWithWASM(graph: Graph): Promise<LayoutResult> {
    // Create a fresh LayoutEngine instance for each layout to avoid stale state
    const { LayoutEngine } = await import('./layout-engine-rust/pkg/graph_easy_layout.js')
    const engine = new LayoutEngine()

    // Convert graph to format expected by WASM
    const graphData = {
      nodes: graph.getNodes().map(node => ({
        id: node.id,
        name: node.name || '',
        label: node.label || node.name || '',
        width: node.getAttribute('width') || 0,
        height: node.getAttribute('height') || 0,
      })),
      edges: graph.getEdges().map(edge => ({
        id: edge.id,
        from: edge.from.id,
        to: edge.to.id,
        label: edge.label || '',
      })),
      config: {
        flow: this.options.flow,
        node_spacing: this.options.nodeSpacing,
        rank_spacing: this.options.rankSpacing,
      },
    }

    // Call WASM layout engine
    try {
      console.log('🦀 WASM input nodes:', graphData.nodes.map(n => ({ id: n.id, name: n.name, label: n.label })))
      const result = engine.layout(graphData)

      // Explicitly free the engine instance
      if (typeof engine.free === 'function') {
        engine.free()
      }

      return result
    } catch (error) {
      console.error('🦀 WASM layout failed:', error)
      console.error('Input that caused error:', JSON.stringify(graphData, null, 2))

      // Clean up even on error
      if (typeof engine.free === 'function') {
        engine.free()
      }

      throw error
    }
  }

  /**
   * Render a layout result as ASCII
   */
  private render(layout: LayoutResult): string {
    const rendererOptions: AsciiRendererOptions = {
      style: this.options.boxart ? 'boxart' : 'ascii',
    }

    if (this.options.boxart) {
      return renderBoxart(layout)
    } else {
      return renderAscii(layout, rendererOptions)
    }
  }

  /**
   * Set options
   */
  setOptions(options: Partial<GraphEasyOptions>): void {
    Object.assign(this.options, options)

    // Update parsers if strict/debug options changed
    if ('strict' in options || 'debug' in options) {
      this.graphEasyParser = new Parser({
        strict: this.options.strict,
        debug: this.options.debug,
      })

      this.dotParser = new DotParser({
        strict: this.options.strict,
        debug: this.options.debug,
      })
    }
  }

  /**
   * Get current options
   */
  getOptions(): Readonly<Required<GraphEasyOptions>> {
    return { ...this.options }
  }
}

/**
 * Convenience function for one-off conversions
 */
export async function convertToASCII(
  input: string,
  options?: GraphEasyOptions
): Promise<string> {
  const converter = await GraphEasyASCII.create(options)
  return await converter.convert(input)
}

/**
 * Convenience function for boxart output
 */
export async function convertToBoxart(input: string): Promise<string> {
  return convertToASCII(input, { boxart: true })
}

/**
 * Convert DOT format specifically
 */
export async function convertDotToASCII(
  dotInput: string,
  options?: Omit<GraphEasyOptions, 'inputFormat'>
): Promise<string> {
  return convertToASCII(dotInput, { ...options, inputFormat: 'dot' })
}

/**
 * Convert Graph::Easy format specifically
 */
export async function convertGraphEasyToASCII(
  graphEasyInput: string,
  options?: Omit<GraphEasyOptions, 'inputFormat'>
): Promise<string> {
  return convertToASCII(graphEasyInput, { ...options, inputFormat: 'grapheasy' })
}
