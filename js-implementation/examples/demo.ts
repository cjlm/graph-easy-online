/**
 * Working Demo of Pure JS/WASM Graph::Easy Implementation
 *
 * Run with: node --loader ts-node/esm demo.ts
 * Or compile first: tsc && node dist/demo.js
 */

import { GraphEasyASCII, convertToASCII, convertToBoxart } from '../GraphEasyASCII'
import { Parser } from '../parser/Parser'

console.log('='.repeat(70))
console.log('Graph::Easy Pure JS/WASM Implementation - Demo')
console.log('='.repeat(70))
console.log()

// ===== Example 1: Simple Graph =====

async function example1() {
  console.log('Example 1: Simple Graph')
  console.log('-'.repeat(70))

  const input = '[Bonn] -> [Berlin]'

  console.log('Input:')
  console.log(input)
  console.log()

  const ascii = await convertToASCII(input)

  console.log('Output:')
  console.log(ascii)
  console.log()
}

// ===== Example 2: Chain of Nodes =====

async function example2() {
  console.log('Example 2: Chain of Nodes')
  console.log('-'.repeat(70))

  const input = '[Bonn] -> [Berlin] -> [Dresden]'

  console.log('Input:')
  console.log(input)
  console.log()

  const ascii = await convertToASCII(input)

  console.log('Output:')
  console.log(ascii)
  console.log()
}

// ===== Example 3: Multiple Edges =====

async function example3() {
  console.log('Example 3: Multiple Edges')
  console.log('-'.repeat(70))

  const input = `
[Bonn] -> [Berlin]
[Bonn] -> [Frankfurt]
[Berlin] -> [Dresden]
[Frankfurt] -> [Dresden]
  `.trim()

  console.log('Input:')
  console.log(input)
  console.log()

  const ascii = await convertToASCII(input)

  console.log('Output:')
  console.log(ascii)
  console.log()
}

// ===== Example 4: Different Edge Styles =====

async function example4() {
  console.log('Example 4: Different Edge Styles')
  console.log('-'.repeat(70))

  const input = `
[A] -> [B]
[B] ==> [C]
[C] ..> [D]
[D] -- [E]
  `.trim()

  console.log('Input:')
  console.log(input)
  console.log()

  const ascii = await convertToASCII(input)

  console.log('Output:')
  console.log(ascii)
  console.log()
}

// ===== Example 5: With Edge Labels =====

async function example5() {
  console.log('Example 5: With Edge Labels')
  console.log('-'.repeat(70))

  const input = `
[Bonn] -> [Berlin] { label: train; }
[Berlin] -> [Dresden] { label: bus; }
  `.trim()

  console.log('Input:')
  console.log(input)
  console.log()

  const ascii = await convertToASCII(input)

  console.log('Output:')
  console.log(ascii)
  console.log()
}

// ===== Example 6: Graph Attributes =====

async function example6() {
  console.log('Example 6: Graph Attributes')
  console.log('-'.repeat(70))

  const input = `
graph { flow: south; }

[Start] -> [Process] -> [End]
  `.trim()

  console.log('Input:')
  console.log(input)
  console.log()

  const ascii = await convertToASCII(input)

  console.log('Output:')
  console.log(ascii)
  console.log()
}

// ===== Example 7: With Comments =====

async function example7() {
  console.log('Example 7: With Comments')
  console.log('-'.repeat(70))

  const input = `
# This is a simple workflow
[Start] -> [Process]

# Process leads to end
[Process] -> [End]
  `.trim()

  console.log('Input:')
  console.log(input)
  console.log()

  const ascii = await convertToASCII(input)

  console.log('Output:')
  console.log(ascii)
  console.log()
}

// ===== Example 8: Boxart (Unicode) =====

async function example8() {
  console.log('Example 8: Boxart (Unicode)')
  console.log('-'.repeat(70))

  const input = '[Bonn] -> [Berlin] -> [Dresden]'

  console.log('Input:')
  console.log(input)
  console.log()

  const boxart = await convertToBoxart(input)

  console.log('Output (Unicode box drawing):')
  console.log(boxart)
  console.log()
}

// ===== Example 9: Parser Only (Direct API) =====

async function example9() {
  console.log('Example 9: Using Parser Directly')
  console.log('-'.repeat(70))

  const input = '[A] -> [B] -> [C]'

  console.log('Input:')
  console.log(input)
  console.log()

  // Use parser directly
  const parser = new Parser()
  const graph = parser.parse(input)

  console.log('Parsed Graph:')
  console.log(`  Nodes: ${graph.getNodes().length}`)
  console.log(`  Edges: ${graph.getEdges().length}`)
  console.log()

  const nodes = graph.getNodes()
  console.log('  Node names:')
  nodes.forEach(node => {
    console.log(`    - ${node.name} (id: ${node.id})`)
  })
  console.log()

  const edges = graph.getEdges()
  console.log('  Edges:')
  edges.forEach(edge => {
    console.log(`    - ${edge.from.name} -> ${edge.to.name}`)
  })
  console.log()
}

// ===== Example 10: Reusable Converter =====

async function example10() {
  console.log('Example 10: Reusable Converter Instance')
  console.log('-'.repeat(70))

  // Create converter once
  const converter = await GraphEasyASCII.create({
    flow: 'east',
    boxart: false,
  })

  const graphs = [
    '[A] -> [B]',
    '[X] -> [Y] -> [Z]',
    '[Start] -> [End]',
  ]

  console.log('Converting multiple graphs:')
  console.log()

  for (const input of graphs) {
    console.log(`Input: ${input}`)
    const ascii = await converter.convert(input)
    console.log(ascii)
    console.log()
  }
}

// ===== Run All Examples =====

async function main() {
  try {
    await example1()
    await example2()
    await example3()
    await example4()
    await example5()
    await example6()
    await example7()
    await example8()
    await example9()
    await example10()

    console.log('='.repeat(70))
    console.log('All examples completed successfully!')
    console.log('='.repeat(70))
  } catch (error) {
    console.error('Error running examples:', error)
    process.exit(1)
  }
}

// Run if executed directly
if (require.main === module) {
  main()
}

export {
  example1,
  example2,
  example3,
  example4,
  example5,
  example6,
  example7,
  example8,
  example9,
  example10,
}
