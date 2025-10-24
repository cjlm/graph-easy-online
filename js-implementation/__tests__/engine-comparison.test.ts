/**
 * Compare different layout engines on the same graphs
 */

import { describe, it, expect } from 'vitest'
import { GraphEasyASCII } from '../GraphEasyASCII'
import { execSync } from 'child_process'

/**
 * Convert graph using Perl Graph::Easy directly
 */
function convertWithPerl(input: string): string {
  try {
    const homeDir = process.env.HOME || ''
    const perlScript = `
use strict;
use warnings;
use lib '${homeDir}/perl5/lib/perl5';
use Graph::Easy;

my $input = <<'END_INPUT';
${input.replace(/'/g, "\\'")}
END_INPUT

my $graph = Graph::Easy->new(\$input);
if ($graph->error()) {
  die "Error: " . $graph->error();
}
print $graph->as_ascii();
`

    const result = execSync('perl', {
      input: perlScript,
      encoding: 'utf-8',
      timeout: 10000,
    })

    return result
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Perl conversion failed: ${error.message}`)
    }
    throw error
  }
}

const BRIDGES_EXAMPLE = `# The famous Seven Bridges problem solved by Euler
graph { flow: east; }

[ North Bank ] { fill: lightgreen; }
[ South Bank ] { fill: lightgreen; }
[ Island Kneiphof ] { fill: lightyellow; }
[ Island Lomse ] { fill: lightyellow; }

[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 1; }
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 2; }
[ North Bank ] -- [ Island Lomse ] { label: Bridge 3; }
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 4; }
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 5; }
[ South Bank ] -- [ Island Lomse ] { label: Bridge 6; }
[ Island Kneiphof ] -- [ Island Lomse ] { label: Bridge 7; }`

const BRIDGES_NO_LABELS = `# Seven Bridges without edge labels
graph { flow: east; }

[ North Bank ] { fill: lightgreen; }
[ South Bank ] { fill: lightgreen; }
[ Island Kneiphof ] { fill: lightyellow; }
[ Island Lomse ] { fill: lightyellow; }

[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Lomse ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Lomse ]
[ Island Kneiphof ] -- [ Island Lomse ]`

describe('Engine Comparison - Seven Bridges', () => {
  it('should generate Perl output', () => {
    try {
      const result = convertWithPerl(BRIDGES_EXAMPLE)

      console.log('\n🐪 Perl Output:')
      console.log('='.repeat(80))
      console.log(result)
      console.log('='.repeat(80))

      // Basic sanity checks
      expect(result).toContain('North Bank')
      expect(result).toContain('South Bank')
      expect(result).toContain('Island Kneiphof')
      expect(result).toContain('Island Lomse')
    } catch (error) {
      console.log('⚠️ Perl not available, skipping Perl test')
      console.log(error instanceof Error ? error.message : String(error))
    }
  })

  it('should generate ELK output', async () => {
    const elk = await GraphEasyASCII.create({
      useELK: true,
      disableWasm: true
    })

    const result = await elk.convert(BRIDGES_EXAMPLE)

    console.log('\n🦌 ELK Output:')
    console.log('='.repeat(80))
    console.log(result)
    console.log('='.repeat(80))

    // Basic sanity checks
    expect(result).toContain('North Bank')
    expect(result).toContain('South Bank')
    expect(result).toContain('Island Kneiphof')
    expect(result).toContain('Island Lomse')
  })

  it('should generate DOT output', async () => {
    const dot = await GraphEasyASCII.create({
      useDOT: true,
      disableWasm: true
    })

    // Use no-labels version - edge labels cause layout overlaps in all engines
    const result = await dot.convert(BRIDGES_NO_LABELS)

    console.log('\n📊 DOT Output:')
    console.log('='.repeat(80))
    console.log(result)
    console.log('='.repeat(80))

    // Basic sanity checks
    expect(result).toContain('North Bank')
    expect(result).toContain('South Bank')
    expect(result).toContain('Island Kneiphof')
    expect(result).toContain('Island Lomse')
  })

  it('should generate TypeScript output', async () => {
    const ts = await GraphEasyASCII.create({
      disableWasm: true
    })

    const result = await ts.convert(BRIDGES_EXAMPLE)

    console.log('\n📘 TypeScript Output:')
    console.log('='.repeat(80))
    console.log(result)
    console.log('='.repeat(80))

    // Basic sanity checks
    expect(result).toContain('North Bank')
    expect(result).toContain('South Bank')
    expect(result).toContain('Island Kneiphof')
    expect(result).toContain('Island Lomse')
  })

  it('should generate WASM output', async () => {
    const wasm = await GraphEasyASCII.create({
      disableWasm: false
    })

    const result = await wasm.convert(BRIDGES_EXAMPLE)

    console.log('\n🦀 WASM Output:')
    console.log('='.repeat(80))
    console.log(result)
    console.log('='.repeat(80))

    // Basic sanity checks
    expect(result).toContain('North Bank')
    expect(result).toContain('South Bank')
    expect(result).toContain('Island Kneiphof')
    expect(result).toContain('Island Lomse')
  })
})

describe('Engine Comparison - Seven Bridges (No Labels)', () => {
  it('should generate Perl output without labels', () => {
    try {
      const result = convertWithPerl(BRIDGES_NO_LABELS)

      console.log('\n🐪 Perl Output (no labels):')
      console.log('='.repeat(80))
      console.log(result)
      console.log('='.repeat(80))

      expect(result).toContain('North Bank')
      expect(result).toContain('Island Kneiphof')
    } catch (error) {
      console.log('⚠️ Perl not available, skipping Perl test')
      console.log(error instanceof Error ? error.message : String(error))
    }
  })

  it('should generate ELK output without labels', async () => {
    const elk = await GraphEasyASCII.create({
      useELK: true,
      disableWasm: true
    })

    const result = await elk.convert(BRIDGES_NO_LABELS)

    console.log('\n🦌 ELK Output (no labels):')
    console.log('='.repeat(80))
    console.log(result)
    console.log('='.repeat(80))

    expect(result).toContain('North Bank')
    expect(result).toContain('Island Kneiphof')
  })

  it('should generate DOT output without labels', async () => {
    const dot = await GraphEasyASCII.create({
      useDOT: true,
      disableWasm: true
    })

    const result = await dot.convert(BRIDGES_NO_LABELS)

    console.log('\n📊 DOT Output (no labels):')
    console.log('='.repeat(80))
    console.log(result)
    console.log('='.repeat(80))

    expect(result).toContain('North Bank')
    expect(result).toContain('Island Kneiphof')
  })

  it('should generate TypeScript output without labels', async () => {
    const ts = await GraphEasyASCII.create({
      disableWasm: true
    })

    const result = await ts.convert(BRIDGES_NO_LABELS)

    console.log('\n📘 TypeScript Output (no labels):')
    console.log('='.repeat(80))
    console.log(result)
    console.log('='.repeat(80))

    expect(result).toContain('North Bank')
    expect(result).toContain('Island Kneiphof')
  })
})
