/**
 * Graph Conversion Service
 *
 * Handles conversion using WebPerl Graph::Easy
 */

import type { OutputFormat } from '../App'

export interface ConversionResult {
  output: string
  timeMs: number
  error?: string
}

export class GraphConversionService {
  private perlMutex: Promise<void> = Promise.resolve()

  /**
   * Convert graph using WebPerl
   */
  async convert(input: string, format: OutputFormat): Promise<ConversionResult> {
    const startTime = performance.now()

    try {
      console.log('🐪 Converting with WebPerl engine...')
      const output = await this.convertWithWebPerl(input, format)
      const timeMs = performance.now() - startTime

      console.log(`✅ WebPerl conversion succeeded in ${timeMs.toFixed(1)}ms`)

      return {
        output,
        timeMs,
      }
    } catch (error) {
      const timeMs = performance.now() - startTime
      const errorMessage = error instanceof Error ? error.message : String(error)
      console.error('💥 Conversion failed:', error)

      return {
        output: '',
        timeMs,
        error: errorMessage,
      }
    }
  }

  /**
   * Convert using WebPerl
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

        # Set Perl's random seed BEFORE Graph::Easy->new() to avoid randomize()
        # Graph::Easy->new() calls randomize() which calls srand() with no args,
        # reseeding from system. We need to control this from the start.
        srand(12345);

        my $input = <<'END_INPUT';
${escapedInput}
END_INPUT

        my $output;

        eval {
          my $graph = Graph::Easy->new($input);

          # Set Graph::Easy's internal seed as well
          $graph->seed(12345);

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
}

// Singleton instance
export const graphConversionService = new GraphConversionService()
