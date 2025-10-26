/**
 * Graph Conversion Service
 *
 * Handles conversion using either WebPerl or the new JS/WASM implementation
 * with automatic fallback.
 */

import type { OutputFormat } from '../App'

export type ConversionEngine = 'webperl' | 'elk' | 'typescript'

export interface ConversionResult {
  output: string
  engine: ConversionEngine
  timeMs: number
  error?: string
}

export class GraphConversionService {
  private elkConverter: any = null
  private elkInitialized = false
  private typescriptConverter: any = null
  private typescriptInitialized = false
  private preferredEngine: ConversionEngine = 'webperl'
  private perlMutex: Promise<void> = Promise.resolve()

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
   * Initialize the TypeScript converter
   */
  async initializeTypeScript(): Promise<void> {
    if (this.typescriptInitialized) return

    try {
      // Dynamically import TypeScript Perl layout engine
      const { PerlLayoutEngine } = await import('../../js-implementation/PerlLayoutEngine')

      // Create TypeScript converter
      this.typescriptConverter = new PerlLayoutEngine({
        boxart: false,
        debug: false,
      })

      this.typescriptInitialized = true
      console.log('✅ TypeScript converter initialized')
    } catch (error) {
      console.error('Failed to initialize TypeScript converter:', error)
      throw error
    }
  }

  /**
   * Initialize the ELK converter
   */
  async initializeELK(): Promise<void> {
    if (this.elkInitialized) return

    try {
      // Dynamically import ELK-enabled converter
      const { GraphEasyASCII } = await import('../../js-implementation/GraphEasyASCII')

      // Create ELK converter (with ELK layout engine)
      this.elkConverter = await GraphEasyASCII.create({
        strict: false,
        debug: false,
        disableWasm: true, // ELK doesn't use Rust WASM
        useELK: true, // Enable ELK layout
      })

      this.elkInitialized = true
      console.log('✅ ELK converter initialized')
    } catch (error) {
      console.error('Failed to initialize ELK converter:', error)
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
      if (engine === 'typescript') {
        // TypeScript Perl layout engine
        if (format !== 'ascii' && format !== 'boxart') {
          return {
            output: '',
            engine: 'typescript',
            timeMs: performance.now() - startTime,
            error: `TypeScript implementation only supports ASCII and Boxart formats. Selected format: ${format}\n\nPlease select ASCII or Boxart, or switch to WebPerl engine for other formats.`,
          }
        }

        try {
          if (!this.typescriptInitialized) {
            console.log('🔷 Initializing TypeScript engine...')
            await this.initializeTypeScript()
          }

          console.log(`🔷 Converting with TypeScript Perl layout engine...`)
          const output = await this.convertWithTypeScript(input, format)
          const timeMs = performance.now() - startTime

          console.log(`✅ TypeScript conversion succeeded in ${timeMs.toFixed(1)}ms`)

          return {
            output,
            engine: 'typescript',
            timeMs,
          }
        } catch (tsError) {
          const errorMessage = tsError instanceof Error ? tsError.message : String(tsError)
          console.error('❌ TypeScript conversion failed:', errorMessage)

          // NO FALLBACK - return error
          return {
            output: '',
            engine: 'typescript',
            timeMs: performance.now() - startTime,
            error: `TypeScript engine failed: ${errorMessage}\n\nThis is the pure TypeScript reimplementation with no fallback. Please report this issue or try WebPerl/ELK engines.`,
          }
        }
      } else if (engine === 'elk') {
        // ELK engine
        if (format !== 'ascii' && format !== 'boxart') {
          console.warn(`ELK doesn't support ${format} format, using WebPerl`)
          const output = await this.convertWithWebPerl(input, format)
          const timeMs = performance.now() - startTime

          return {
            output,
            engine: 'webperl',
            timeMs,
            error: `Format '${format}' requires WebPerl. Only ASCII/Boxart supported in ELK.`,
          }
        }

        try {
          if (!this.elkInitialized) {
            console.log('🦌 Initializing ELK engine...')
            await this.initializeELK()
          }

          console.log(`🦌 Converting with ELK engine...`)
          const output = await this.convertWithELK(input, format)
          const timeMs = performance.now() - startTime

          console.log(`✅ ELK conversion succeeded in ${timeMs.toFixed(1)}ms`)

          return {
            output,
            engine: 'elk',
            timeMs,
          }
        } catch (elkError) {
          const errorMessage = elkError instanceof Error ? elkError.message : String(elkError)
          console.error('❌ ELK conversion failed:', errorMessage)
          console.warn('⚠️  Falling back to WebPerl...')

          // Fallback to WebPerl
          const output = await this.convertWithWebPerl(input, format)
          const timeMs = performance.now() - startTime

          return {
            output,
            engine: 'webperl',
            timeMs,
            error: `ELK engine failed: ${errorMessage}\n\nFell back to WebPerl. Your graph was still converted successfully.`,
          }
        }
      } else {
        // Use WebPerl directly
        console.log('🐪 Converting with WebPerl engine...')
        const output = await this.convertWithWebPerl(input, format)
        const timeMs = performance.now() - startTime

        console.log(`✅ WebPerl conversion succeeded in ${timeMs.toFixed(1)}ms`)

        return {
          output,
          engine: 'webperl',
          timeMs,
        }
      }
    } catch (error) {
      const timeMs = performance.now() - startTime
      const errorMessage = error instanceof Error ? error.message : String(error)
      console.error('💥 Conversion failed completely:', error)

      return {
        output: '',
        engine,
        timeMs,
        error: errorMessage,
      }
    }
  }


  /**
   * Convert using TypeScript Perl layout engine
   */
  private async convertWithTypeScript(input: string, format: OutputFormat): Promise<string> {
    if (!this.typescriptInitialized) {
      await this.initializeTypeScript()
    }

    // Only ASCII/boxart formats supported
    if (format !== 'ascii' && format !== 'boxart') {
      throw new Error(`Format '${format}' not yet supported in TypeScript. Use WebPerl.`)
    }

    // Set boxart option based on format
    this.typescriptConverter.setOptions({ boxart: format === 'boxart' })

    const result = await this.typescriptConverter.convert(input)

    return result
  }

  /**
   * Convert using ELK layout engine
   */
  private async convertWithELK(input: string, format: OutputFormat): Promise<string> {
    if (!this.elkInitialized) {
      await this.initializeELK()
    }

    // Only ASCII format is supported
    if (format !== 'ascii' && format !== 'boxart') {
      throw new Error(`Format '${format}' not yet supported in ELK. Use WebPerl.`)
    }

    // Set boxart option based on format
    this.elkConverter.setOptions({ boxart: format === 'boxart' })

    const result = await this.elkConverter.convert(input)

    return result
  }

  /**
   * Convert using WebPerl (existing implementation)
   */
  private async convertWithWebPerl(input: string, format: OutputFormat): Promise<string> {
    if (typeof window.Perl === 'undefined') {
      console.error('❌ WebPerl is not defined')
      throw new Error('WebPerl not initialized')
    }

    // Accept Ready, Running, and Ended states (consistent with App.tsx module loading logic)
    const validStates = ['Ready', 'Running', 'Ended']
    if (!validStates.includes(window.Perl.state)) {
      console.error('❌ WebPerl state:', window.Perl.state)
      throw new Error(`WebPerl not ready (state: ${window.Perl.state})`)
    }

    // Check if Graph::Easy modules are loaded in the virtual filesystem
    if (!this.areModulesLoaded()) {
      throw new Error('Graph::Easy modules are still loading. Please wait a moment and try again.')
    }

    // Create a new mutex for this evaluation FIRST
    let releaseMutex!: () => void
    const myMutex = new Promise<void>(resolve => {
      releaseMutex = resolve
    })

    // Atomically swap in the new mutex and get the previous one
    const previousMutex = this.perlMutex
    this.perlMutex = myMutex

    // NOW wait for the previous evaluation to complete
    // This prevents concurrent window.Perl.eval() calls that corrupt interpreter state
    await previousMutex

    try {
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
    } finally {
      // Always release the mutex
      releaseMutex()
    }
  }

  /**
   * Check if ELK is available and initialized
   */
  isELKAvailable(): boolean {
    return this.elkInitialized
  }

  /**
   * Check if Graph::Easy modules are loaded in the virtual filesystem
   */
  private areModulesLoaded(): boolean {
    if (typeof window.FS === 'undefined') {
      return false
    }

    try {
      // Check if the main Graph::Easy.pm module exists
      window.FS.readFile('/lib/Graph/Easy.pm', { encoding: 'utf8' })
      return true
    } catch (e) {
      return false
    }
  }

  /**
   * Check if WebPerl is available
   */
  isWebPerlAvailable(): boolean {
    return typeof window.Perl !== 'undefined' && window.Perl.state === 'Ready' && this.areModulesLoaded()
  }

  /**
   * Get engine status
   */
  getEngineStatus() {
    return {
      typescript: {
        available: this.typescriptInitialized,
        status: this.typescriptInitialized ? 'ready' : 'not-initialized',
      },
      elk: {
        available: this.elkInitialized,
        status: this.elkInitialized ? 'ready' : 'not-initialized',
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
