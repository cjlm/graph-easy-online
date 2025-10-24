/**
 * Compare ELK and TypeScript layout engines locally (without server)
 */

import { GraphEasyASCII } from '../js-implementation/GraphEasyASCII.ts'

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

async function main() {
  console.log('🔧 Initializing engines...\n')

  // Create ELK engine
  const elkEngine = await GraphEasyASCII.create({
    useELK: true,
    disableWasm: true
  })

  // Create TypeScript engine
  const tsEngine = await GraphEasyASCII.create({
    disableWasm: true
  })

  console.log('🦌 ELK Engine Output:')
  console.log('='.repeat(80))
  try {
    const elkResult = await elkEngine.convert(BRIDGES_EXAMPLE)
    console.log(elkResult)
  } catch (err) {
    console.error('❌ ELK failed:', err.message)
  }

  console.log('\n' + '='.repeat(80))
  console.log('📘 TypeScript Engine Output:')
  console.log('='.repeat(80))
  try {
    const tsResult = await tsEngine.convert(BRIDGES_EXAMPLE)
    console.log(tsResult)
  } catch (err) {
    console.error('❌ TypeScript failed:', err.message)
  }

  console.log('\n' + '='.repeat(80))
  console.log('\n✅ Comparison complete!')
}

main().catch(err => {
  console.error('Fatal error:', err)
  process.exit(1)
})
