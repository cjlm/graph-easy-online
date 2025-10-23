/**
 * Quick verification that everything is wired up correctly
 */

import { graphConversionService } from './src/services/graphConversionService'

console.log('Testing JS/WASM integration...\n')

// Test 1: Simple graph
const test1 = '[A] -> [B]'
console.log('Test 1: Simple graph')
console.log('Input:', test1)

try {
  const result = await graphConversionService.convert(test1, 'ascii', 'jswasm')
  console.log('✅ Success!')
  console.log('Engine used:', result.engine)
  console.log('Time:', result.timeMs.toFixed(1), 'ms')
  console.log('Output length:', result.output.length)
  console.log('Output:\n', result.output)
} catch (err) {
  console.error('❌ Failed:', err)
}

console.log('\n---\n')

// Test 2: With edge label (Issue #2)
const test2 = '[A] -> [B] { label: TestLabel; }'
console.log('Test 2: Edge with label (Issue #2)')
console.log('Input:', test2)

try {
  const result = await graphConversionService.convert(test2, 'ascii', 'jswasm')
  console.log('✅ Success!')
  console.log('Engine used:', result.engine)
  console.log('Contains "TestLabel":', result.output.includes('TestLabel'))
  console.log('Output:\n', result.output)
} catch (err) {
  console.error('❌ Failed:', err)
}

console.log('\n---\n')

// Test 3: Graph attributes
const test3 = `graph { flow: south; }
[A] -> [B]`
console.log('Test 3: Graph attributes')
console.log('Input:', test3)

try {
  const result = await graphConversionService.convert(test3, 'ascii', 'jswasm')
  console.log('✅ Success!')
  console.log('Engine used:', result.engine)
  console.log('Output length:', result.output.length)
  console.log('Output:\n', result.output)
} catch (err) {
  console.error('❌ Failed:', err)
}
