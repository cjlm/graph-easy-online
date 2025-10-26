/**
 * Test diamond graph layout
 */

import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

async function test() {
  const engine = new PerlLayoutEngine({
    boxart: false,
    debug: true,
  })

  // Diamond: A splits to B and C, then joins at D
  const input = `[A] -> [B] -> [D]
[A] -> [C] -> [D]`

  console.log('Input:')
  console.log(input)
  console.log('\nExpected Perl layout:')
  console.log('       +---+')
  console.log('       | B |')
  console.log(' +---+ +---+ +---+')
  console.log(' | A |       | D |')
  console.log(' +---+ +---+ +---+')
  console.log('       | C |')
  console.log('       +---+')
  console.log('\nActual TypeScript output:')

  const result = await engine.convert(input, 'ascii')
  console.log(result)
}

test().catch(err => {
  console.error('Test failed:', err)
  process.exit(1)
})
