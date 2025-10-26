/**
 * Quick test of TypeScript layout engine
 */

import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

async function test() {
  console.log('Testing TypeScript Layout Engine...\n')

  const engine = new PerlLayoutEngine({
    boxart: false,
    debug: false,
  })

  // Test 1: Simple two-node graph
  console.log('Test 1: Simple graph (A -> B)')
  const input1 = '[A] -> [B]'
  try {
    const result1 = await engine.convert(input1, 'ascii')
    console.log('✓ Success!')
    console.log(result1)
    console.log()
  } catch (err) {
    console.error('✗ Failed:', err.message)
    console.error(err.stack)
    process.exit(1)
  }

  // Test 2: Three-node chain
  console.log('Test 2: Chain (A -> B -> C)')
  const input2 = '[A] -> [B] -> [C]'
  try {
    const result2 = await engine.convert(input2, 'ascii')
    console.log('✓ Success!')
    console.log(result2)
    console.log()
  } catch (err) {
    console.error('✗ Failed:', err.message)
    console.error(err.stack)
    process.exit(1)
  }

  // Test 3: Diamond graph
  console.log('Test 3: Diamond (A -> B, A -> C, B -> D, C -> D)')
  const input3 = '[A] -> [B] -> [D]\n[A] -> [C] -> [D]'
  try {
    const result3 = await engine.convert(input3, 'ascii')
    console.log('✓ Success!')
    console.log(result3)
    console.log()
  } catch (err) {
    console.error('✗ Failed:', err.message)
    console.error(err.stack)
    process.exit(1)
  }

  console.log('All tests passed!')
}

test().catch(err => {
  console.error('Test failed:', err)
  process.exit(1)
})
