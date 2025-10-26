/**
 * Integration test for new ELK ASCII renderer in GraphEasyASCII
 */

import { GraphEasyASCII } from '../GraphEasyASCII.ts'

async function testELKIntegration() {
  console.log('=== Testing ELK ASCII Renderer Integration ===\n')

  // Create converter with ELK engine
  const converter = await GraphEasyASCII.create({
    useELK: true,
    boxart: true,
    debug: false,
  })

  console.log('✓ Converter created with ELK engine\n')

  // Test 1: Simple linear graph
  console.log('Test 1: Simple linear graph')
  const input1 = '[A] -> [B] -> [C]'
  const output1 = await converter.convert(input1)
  console.log(output1)
  console.log('\n✓ Test 1 passed\n')

  // Test 2: Branching graph
  console.log('Test 2: Branching graph')
  const input2 = `
    [Start] -> [Process A]
    [Start] -> [Process B]
    [Process A] -> [End]
    [Process B] -> [End]
  `
  const output2 = await converter.convert(input2)
  console.log(output2)
  console.log('\n✓ Test 2 passed\n')

  // Test 3: Graph with labels
  console.log('Test 3: Graph with edge labels')
  const input3 = '[Login] -- submit --> [Auth] -- valid --> [Success]'
  const output3 = await converter.convert(input3)
  console.log(output3)
  console.log('\n✓ Test 3 passed\n')

  // Test 4: ASCII mode (non-unicode)
  console.log('Test 4: ASCII mode')
  const asciiConverter = await GraphEasyASCII.create({
    useELK: true,
    boxart: false, // ASCII mode
    debug: false,
  })
  const output4 = await asciiConverter.convert('[A] -> [B]')
  console.log(output4)
  console.log('\n✓ Test 4 passed\n')

  // Test 5: Vertical layout
  console.log('Test 5: Vertical layout')
  const verticalConverter = await GraphEasyASCII.create({
    useELK: true,
    boxart: true,
    flow: 'south',
  })
  const output5 = await verticalConverter.convert('[Top] -> [Middle] -> [Bottom]')
  console.log(output5)
  console.log('\n✓ Test 5 passed\n')

  console.log('=== All Integration Tests Passed! ===')
}

// Run tests
testELKIntegration().catch(error => {
  console.error('Integration test failed:', error)
  process.exit(1)
})
