/**
 * Test Seven Bridges of Königsberg
 */

import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

async function test() {
  const engine = new PerlLayoutEngine({
    boxart: false,
    debug: false,
  })

  // Seven Bridges input from the example
  const input = `graph {
  A -- B
  A -- B
  A -- C
  A -- C
  A -- D
  B -- D
  C -- D
}`

  console.log('Seven Bridges of Königsberg:')
  console.log(input)
  console.log('\nTypeScript output:')

  const result = await engine.convert(input, 'ascii')
  console.log(result)
}

test().catch(err => {
  console.error('Test failed:', err)
  process.exit(1)
})
