/**
 * PerlLayoutEngine - Main API for Perl-style layout
 *
 * This is a replacement for the ELK-based GraphEasyASCII
 * that uses our TypeScript reimplementation of the Perl layout algorithm
 */

import { Parser } from './parser/Parser'
import { DotParser } from './parser/DotParser'
import { LayoutEngine } from './layout/LayoutEngine'
import { AsciiRendererNew } from './renderers/AsciiRendererNew'

export interface PerlLayoutOptions {
  boxart?: boolean
  flow?: 'east' | 'west' | 'north' | 'south'
  debug?: boolean
}

export class PerlLayoutEngine {
  private options: PerlLayoutOptions

  constructor(options: PerlLayoutOptions = {}) {
    this.options = {
      boxart: options.boxart ?? false,
      flow: options.flow ?? 'east',
      debug: options.debug ?? false,
    }
  }

  /**
   * Convert graph notation to ASCII art
   */
  async convert(input: string): Promise<string> {
    if (this.options.debug) {
      console.log('📥 Input:', input)
    }

    // 1. Parse
    if (this.options.debug) {
      console.log('🔍 Parsing...')
    }

    // Detect format (DOT vs Graph::Easy)
    const isDot = DotParser.isDot(input)
    const parser = isDot ? new DotParser() : new Parser()
    const graph = parser.parse(input)

    // Set graph attributes
    if (this.options.flow) {
      graph.setAttribute('flow', this.options.flow)
    }

    if (this.options.debug) {
      console.log(`  Parsed ${graph.getNodes().length} nodes, ${graph.getEdges().length} edges`)
    }

    // 2. Layout
    if (this.options.debug) {
      console.log('📐 Laying out...')
    }

    const layoutEngine = new LayoutEngine(graph)
    const score = layoutEngine.layout()

    if (this.options.debug) {
      console.log(`  Layout score: ${score}`)
      console.log(`  Cells: ${graph.cells.size}`)
    }

    // 3. Render
    if (this.options.debug) {
      console.log('🎨 Rendering...')
    }

    const renderer = new AsciiRendererNew(graph, {
      boxart: this.options.boxart,
    })

    const ascii = renderer.render()

    if (this.options.debug) {
      console.log('✅ Complete!')
    }

    return ascii
  }

  /**
   * Set options
   */
  setOptions(options: Partial<PerlLayoutOptions>): void {
    Object.assign(this.options, options)
  }
}

/**
 * Convenience function for one-off conversions
 */
export async function convertWithPerlLayout(
  input: string,
  options?: PerlLayoutOptions
): Promise<string> {
  const engine = new PerlLayoutEngine(options)
  return await engine.convert(input)
}
