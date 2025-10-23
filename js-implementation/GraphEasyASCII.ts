/**
 * Main API for Graph::Easy ASCII conversion
 *
 * This is the entry point for using the pure JS/WASM implementation.
 *
 * Usage:
 *   import { GraphEasyASCII } from './GraphEasyASCII'
 *
 *   const converter = await GraphEasyASCII.create()
 *   const ascii = await converter.convert('[Bonn] -> [Berlin]')
 *   console.log(ascii)
 */

import { Parser } from './parser/Parser'
import { renderAscii, renderBoxart, AsciiRendererOptions } from './renderers/AsciiRenderer'
import type { Graph } from './core/Graph'
import type { LayoutResult } from './core/Graph'

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
}

export class GraphEasyASCII {
  private parser: Parser
  private layoutEngine: any // Will be the WASM layout engine when integrated
  private options: Required<GraphEasyOptions>
  private initialized: boolean = false

  private constructor(options: GraphEasyOptions = {}) {
    this.options = {
      boxart: options.boxart ?? false,
      strict: options.strict ?? false,
      debug: options.debug ?? false,
      flow: options.flow ?? 'east',
      nodeSpacing: options.nodeSpacing ?? 3,
      rankSpacing: options.rankSpacing ?? 5,
    }

    this.parser = new Parser({
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

    // TODO: Initialize WASM layout engine here when integrated
    /*
    if (typeof window !== 'undefined') {
      // Browser environment
      const { default: init, LayoutEngine } = await import('./wasm/graph_easy_layout')
      await init()
      this.layoutEngine = new LayoutEngine()
    }
    */

    this.initialized = true
  }

  /**
   * Convert Graph::Easy notation to ASCII art
   *
   * @param input - Graph::Easy text notation
   * @returns ASCII art representation
   */
  async convert(input: string): Promise<string> {
    try {
      // 1. Parse the input
      const graph = this.parser.parse(input)

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
   * Parse Graph::Easy notation into a Graph object
   */
  parse(input: string): Graph {
    return this.parser.parse(input)
  }

  /**
   * Perform layout on a graph
   */
  private async layout(graph: Graph): Promise<LayoutResult> {
    if (this.layoutEngine) {
      // Use WASM layout engine when available
      return await this.layoutWithWASM(graph)
    } else {
      // Fallback to TypeScript layout
      return await graph.layout()
    }
  }

  /**
   * Layout using WASM engine
   */
  private async layoutWithWASM(graph: Graph): Promise<LayoutResult> {
    // Convert graph to format expected by WASM
    const graphData = {
      nodes: graph.getNodes().map(node => ({
        id: node.id,
        name: node.name,
        label: node.label,
        width: node.getAttribute('width') || 0,
        height: node.getAttribute('height') || 0,
      })),
      edges: graph.getEdges().map(edge => ({
        id: edge.id,
        from: edge.from.id,
        to: edge.to.id,
        label: edge.label,
      })),
      config: {
        flow: this.options.flow,
        node_spacing: this.options.nodeSpacing,
        rank_spacing: this.options.rankSpacing,
      },
    }

    // Call WASM layout engine
    const result = this.layoutEngine.layout(graphData)

    return result
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

    // Update parser if strict option changed
    if ('strict' in options || 'debug' in options) {
      this.parser = new Parser({
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
