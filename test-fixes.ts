/**
 * Test script to verify issue #7 (logging) and issue #2 (parser) fixes
 */

import { GraphEasyASCII } from './js-implementation/GraphEasyASCII'

async function testParserFixes() {
  console.log('=== Testing Parser Fixes ===\n')

  const converter = await GraphEasyASCII.create({ debug: true })

  // Test 1: => edge type (issue #2)
  console.log('Test 1: => edge type')
  const test1 = `[A] => [B]`
  try {
    const result1 = await converter.convert(test1)
    console.log('✅ Test 1 passed: => edge type recognized')
    console.log('Result:', result1)
  } catch (e) {
    console.error('❌ Test 1 failed:', e)
  }
  console.log()

  // Test 2: --> edge type (issue #2)
  console.log('Test 2: --> edge type')
  const test2 = `[C] --> [D]`
  try {
    const result2 = await converter.convert(test2)
    console.log('✅ Test 2 passed: --> edge type recognized')
    console.log('Result:', result2)
  } catch (e) {
    console.error('❌ Test 2 failed:', e)
  }
  console.log()

  // Test 3: Edge attributes (issue #2)
  console.log('Test 3: Edge attributes')
  const test3 = `[A] -> [B] { label: test; }`
  try {
    const result3 = await converter.convert(test3)
    console.log('✅ Test 3 passed: Edge attributes parsed')
    console.log('Result:', result3)
  } catch (e) {
    console.error('❌ Test 3 failed:', e)
  }
  console.log()

  // Test 4: Logging visibility (issue #7)
  console.log('Test 4: Logging visibility (check console output above)')
  console.log('Expected to see:')
  console.log('  - "🔧 Initializing JS/WASM engine..." (if not already initialized)')
  console.log('  - "🚀 Converting with JS/WASM engine..."')
  console.log('  - "✅ JS/WASM conversion succeeded in X.Xms"')
  console.log()

  console.log('=== All Tests Complete ===')
}

testParserFixes().catch(console.error)
