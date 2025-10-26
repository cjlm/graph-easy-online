/**
 * Simple test to verify WASM actually works
 */

import { GraphEasyASCII } from './GraphEasyASCII.ts'

async function testWasmActuallyWorks() {
  console.log('🧪 Testing if WASM actually loads and works...\n')

  try {
    // Create converter with debug enabled
    const converter = await GraphEasyASCII.create({
      debug: true,
      strict: false,
    })

    console.log('✅ GraphEasyASCII instance created\n')

    // Test simple graph
    console.log('Testing simple graph: [A] -> [B]\n')
    const result = await converter.convert('[A] -> [B]')

    console.log('Output:')
    console.log(result)
    console.log('\n')

    // Test if output looks reasonable
    if (result.includes('A') && result.includes('B')) {
      console.log('✅ Output contains expected nodes\n')
    } else {
      console.log('❌ Output missing expected nodes\n')
      return false
    }

    // Test DOT format
    console.log('Testing DOT format: digraph { A -> B; }\n')
    const dotResult = await converter.convert('digraph { A -> B; }')

    console.log('Output:')
    console.log(dotResult)
    console.log('\n')

    if (dotResult.includes('A') && dotResult.includes('B')) {
      console.log('✅ DOT conversion works\n')
    } else {
      console.log('❌ DOT conversion failed\n')
      return false
    }

    return true
  } catch (error) {
    console.error('❌ Test failed with error:', error)
    return false
  }
}

// Run test
testWasmActuallyWorks().then(success => {
  if (success) {
    console.log('\n🎉 All tests passed!')
    process.exit(0)
  } else {
    console.log('\n💥 Tests failed!')
    process.exit(1)
  }
})
