/**
 * Graph Conversion Service
 *
 * Handles conversion using either WebPerl or the new JS/WASM implementation
 * with automatic fallback.
 */

import type { OutputFormat } from '../App'

export type ConversionEngine = 'webperl' | 'jswasm'

export interface ConversionResult {
  output: string
  engine: ConversionEngine
  timeMs: number
  error?: string
}

export class GraphConversionService {
  private jsWasmConverter: any = null
  private jsWasmInitialized = false
  private preferredEngine: ConversionEngine = 'jswasm'

  /**
   * Set the preferred conversion engine
   */
  setPreferredEngine(engine: ConversionEngine): void {
    this.preferredEngine = engine
    localStorage.setItem('preferredConversionEngine', engine)
  }

  /**
   * Get the current preferred engine
   */
  getPreferredEngine(): ConversionEngine {
    const saved = localStorage.getItem('preferredConversionEngine') as ConversionEngine | null
    return saved || this.preferredEngine
  }

  /**
   * Initialize the JS/WASM converter
   */
  async initializeJsWasm(): Promise<void> {
    if (this.jsWasmInitialized) return

    try {
      // Dynamically import the new implementation
      const { GraphEasyASCII } = await import('../../js-implementation/GraphEasyASCII')

      this.jsWasmConverter = await GraphEasyASCII.create({
        strict: false, // Don't throw on minor errors
        debug: false,
      })

      this.jsWasmInitialized = true
      console.log('✅ JS/WASM converter initialized')
    } catch (error) {
      console.error('Failed to initialize JS/WASM converter:', error)
      throw error
    }
  }

  /**
   * Convert graph using the preferred engine with automatic fallback
   */
  async convert(
    input: string,
    format: OutputFormat,
    forceEngine?: ConversionEngine
  ): Promise<ConversionResult> {
    const engine = forceEngine || this.preferredEngine
    const startTime = performance.now()

    try {
      if (engine === 'jswasm') {
        // Try JS/WASM first
        try {
          const output = await this.convertWithJsWasm(input, format)
          const timeMs = performance.now() - startTime

          return {
            output,
            engine: 'jswasm',
            timeMs,
          }
        } catch (jsError) {
          console.warn('JS/WASM conversion failed, falling back to WebPerl:', jsError)

          // Fallback to WebPerl
          const output = this.convertWithWebPerl(input, format)
          const timeMs = performance.now() - startTime

          return {
            output,
            engine: 'webperl',
            timeMs,
            error: `JS/WASM failed: ${jsError.message}. Used WebPerl fallback.`,
          }
        }
      } else {
        // Use WebPerl directly
        const output = this.convertWithWebPerl(input, format)
        const timeMs = performance.now() - startTime

        return {
          output,
          engine: 'webperl',
          timeMs,
        }
      }
    } catch (error) {
      const timeMs = performance.now() - startTime
      throw {
        output: '',
        engine,
        timeMs,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Convert using the new JS/WASM implementation
   */
  private async convertWithJsWasm(input: string, format: OutputFormat): Promise<string> {
    if (!this.jsWasmInitialized) {
      await this.initializeJsWasm()
    }

    // For now, only ASCII format is supported
    if (format !== 'ascii' && format !== 'boxart') {
      throw new Error(`Format '${format}' not yet supported in JS/WASM. Use WebPerl.`)
    }

    // Use the converter
    const result = await this.jsWasmConverter.convert(input)

    return result
  }

  /**
   * Convert using WebPerl (existing implementation)
   */
  private convertWithWebPerl(input: string, format: OutputFormat): string {
    if (typeof window.Perl === 'undefined') {
      throw new Error('WebPerl not initialized')
    }

    const escapedInput = input
      .replace(/\\/g, '\\\\')
      .replace(/\$/g, '\\$')

    const formatMethodMap: Record<OutputFormat, string> = {
      ascii: 'as_ascii()',
      boxart: 'as_boxart()',
      html: 'as_html()',
      svg: 'as_svg()',
      graphviz: 'as_graphviz()',
      graphml: 'as_graphml()',
      vcg: 'as_vcg()',
      txt: 'as_txt()',
    }

    const perlMethod = formatMethodMap[format]

    const perlScript = `
      use strict;
      use warnings;
      use lib '/lib';
      use Graph::Easy;

      my $input = <<'END_INPUT';
${escapedInput}
END_INPUT

      my $output;

      eval {
        my $graph = Graph::Easy->new($input);

        if ($graph->error()) {
          $output = "Error: " . $graph->error();
        } else {
          $output = $graph->${perlMethod};
        }
      };

      if ($@) {
        $output = "Error: $@";
      }

      $output;
    `

    const result = window.Perl.eval(perlScript)

    if (result && result.startsWith('Error:')) {
      throw new Error(result)
    }

    return result
  }

  /**
   * Check if JS/WASM is available and initialized
   */
  isJsWasmAvailable(): boolean {
    return this.jsWasmInitialized
  }

  /**
   * Check if WebPerl is available
   */
  isWebPerlAvailable(): boolean {
    return typeof window.Perl !== 'undefined' && window.Perl.state === 'Ready'
  }

  /**
   * Get engine status
   */
  getEngineStatus() {
    return {
      jswasm: {
        available: this.jsWasmInitialized,
        status: this.jsWasmInitialized ? 'ready' : 'not-initialized',
      },
      webperl: {
        available: this.isWebPerlAvailable(),
        status: window.Perl?.state || 'not-loaded',
      },
      preferred: this.preferredEngine,
    }
  }
}

// Singleton instance
export const graphConversionService = new GraphConversionService()
