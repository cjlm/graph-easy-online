/**
 * Compare different layout engines on the same graphs
 */

import { describe, it, expect } from 'vitest'
import { GraphEasyASCII } from '../GraphEasyASCII'

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

describe('Engine Comparison - Seven Bridges', () => {
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
