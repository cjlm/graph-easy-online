/**
 * ELK ASCII Renderer Demo
 *
 * Demonstrates usage of the ELK to ASCII orthogonal graph renderer
 */

import ELK from 'elkjs'
import { renderASCII, type ELKResult, type RenderOptions } from '../renderers/elk-ascii-renderer.ts'

/**
 * Example 1: Simple linear graph
 */
async function example1_SimpleLinear() {
  console.log('=== Example 1: Simple Linear Graph ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
    },
    children: [
      { id: 'n1', width: 60, height: 40, labels: [{ text: 'Node 1' }] },
      { id: 'n2', width: 60, height: 40, labels: [{ text: 'Node 2' }] },
      { id: 'n3', width: 60, height: 40, labels: [{ text: 'Node 3' }] },
    ],
    edges: [
      { id: 'e1', sources: ['n1'], targets: ['n2'] },
      { id: 'e2', sources: ['n2'], targets: ['n3'] },
    ],
  }

  const result = await elk.layout(graph)
  const { ascii, metadata } = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: true,
    arrows: true,
  })

  console.log(ascii)
  console.log('Metadata:', metadata)
  console.log('\n')
}

/**
 * Example 2: Branching graph
 */
async function example2_Branching() {
  console.log('=== Example 2: Branching Graph ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
      'elk.spacing.nodeNode': '60',
      'elk.layered.spacing.nodeNodeBetweenLayers': '80',
    },
    children: [
      { id: 'start', width: 80, height: 40, labels: [{ text: 'Start' }] },
      { id: 'processA', width: 80, height: 40, labels: [{ text: 'Process A' }] },
      { id: 'processB', width: 80, height: 40, labels: [{ text: 'Process B' }] },
      { id: 'end', width: 80, height: 40, labels: [{ text: 'End' }] },
    ],
    edges: [
      { id: 'e1', sources: ['start'], targets: ['processA'] },
      { id: 'e2', sources: ['start'], targets: ['processB'] },
      { id: 'e3', sources: ['processA'], targets: ['end'] },
      { id: 'e4', sources: ['processB'], targets: ['end'] },
    ],
  }

  const result = await elk.layout(graph)
  const { ascii, metadata } = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: true,
    arrows: true,
  })

  console.log(ascii)
  console.log('Metadata:', metadata)
  console.log('\n')
}

/**
 * Example 3: Vertical layout
 */
async function example3_VerticalLayout() {
  console.log('=== Example 3: Vertical Layout (Top to Bottom) ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.direction': 'DOWN',
      'elk.edgeRouting': 'ORTHOGONAL',
    },
    children: [
      { id: 'header', width: 100, height: 30, labels: [{ text: 'Header' }] },
      { id: 'main', width: 100, height: 30, labels: [{ text: 'Main Content' }] },
      { id: 'footer', width: 100, height: 30, labels: [{ text: 'Footer' }] },
    ],
    edges: [
      { id: 'e1', sources: ['header'], targets: ['main'] },
      { id: 'e2', sources: ['main'], targets: ['footer'] },
    ],
  }

  const result = await elk.layout(graph)
  const { ascii, metadata } = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: true,
    arrows: true,
  })

  console.log(ascii)
  console.log('Metadata:', metadata)
  console.log('\n')
}

/**
 * Example 4: ASCII mode (non-unicode)
 */
async function example4_AsciiMode() {
  console.log('=== Example 4: ASCII Mode (Non-Unicode) ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
    },
    children: [
      { id: 'A', width: 50, height: 30, labels: [{ text: 'A' }] },
      { id: 'B', width: 50, height: 30, labels: [{ text: 'B' }] },
      { id: 'C', width: 50, height: 30, labels: [{ text: 'C' }] },
    ],
    edges: [
      { id: 'e1', sources: ['A'], targets: ['B'] },
      { id: 'e2', sources: ['B'], targets: ['C'] },
    ],
  }

  const result = await elk.layout(graph)
  const { ascii, metadata } = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: false, // ASCII mode
    arrows: true,
  })

  console.log(ascii)
  console.log('Metadata:', metadata)
  console.log('\n')
}

/**
 * Example 5: Complex graph with labels
 */
async function example5_ComplexWithLabels() {
  console.log('=== Example 5: Complex Graph with Edge Labels ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
      'elk.spacing.nodeNode': '70',
      'elk.layered.spacing.nodeNodeBetweenLayers': '90',
    },
    children: [
      { id: 'login', width: 80, height: 40, labels: [{ text: 'Login' }] },
      { id: 'auth', width: 80, height: 40, labels: [{ text: 'Authenticate' }] },
      { id: 'success', width: 80, height: 40, labels: [{ text: 'Success' }] },
      { id: 'fail', width: 80, height: 40, labels: [{ text: 'Failed' }] },
    ],
    edges: [
      { id: 'e1', sources: ['login'], targets: ['auth'], labels: [{ text: 'submit' }] },
      { id: 'e2', sources: ['auth'], targets: ['success'], labels: [{ text: 'valid' }] },
      { id: 'e3', sources: ['auth'], targets: ['fail'], labels: [{ text: 'invalid' }] },
    ],
  }

  const result = await elk.layout(graph)
  const { ascii, metadata } = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: true,
    arrows: true,
    renderLabels: true,
  })

  console.log(ascii)
  console.log('Metadata:', metadata)
  console.log('\n')
}

/**
 * Example 6: Different scale factors
 */
async function example6_DifferentScales() {
  console.log('=== Example 6: Different Scale Factors ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
    },
    children: [
      { id: 'n1', width: 60, height: 40, labels: [{ text: 'A' }] },
      { id: 'n2', width: 60, height: 40, labels: [{ text: 'B' }] },
    ],
    edges: [{ id: 'e1', sources: ['n1'], targets: ['n2'] }],
  }

  const result = await elk.layout(graph)

  const scales = [0.2, 0.3, 0.5]
  for (const scale of scales) {
    console.log(`\nScale: ${scale}`)
    const { ascii, metadata } = renderASCII(result as ELKResult, {
      scale,
      unicode: true,
      arrows: true,
    })
    console.log(`Canvas size: ${metadata.width}x${metadata.height}`)
    console.log(ascii)
  }

  console.log('\n')
}

/**
 * Example 7: Without arrows
 */
async function example7_NoArrows() {
  console.log('=== Example 7: Graph Without Arrows ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
    },
    children: [
      { id: 'n1', width: 60, height: 40, labels: [{ text: 'Node 1' }] },
      { id: 'n2', width: 60, height: 40, labels: [{ text: 'Node 2' }] },
      { id: 'n3', width: 60, height: 40, labels: [{ text: 'Node 3' }] },
    ],
    edges: [
      { id: 'e1', sources: ['n1'], targets: ['n2'] },
      { id: 'e2', sources: ['n2'], targets: ['n3'] },
    ],
  }

  const result = await elk.layout(graph)
  const { ascii, metadata } = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: true,
    arrows: false, // No arrows
  })

  console.log(ascii)
  console.log('Metadata:', metadata)
  console.log('\n')
}

/**
 * Example 8: Custom margins
 */
async function example8_CustomMargins() {
  console.log('=== Example 8: Custom Margins ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
    },
    children: [
      { id: 'n1', width: 60, height: 40, labels: [{ text: 'A' }] },
      { id: 'n2', width: 60, height: 40, labels: [{ text: 'B' }] },
    ],
    edges: [{ id: 'e1', sources: ['n1'], targets: ['n2'] }],
  }

  const result = await elk.layout(graph)

  console.log('With margin = 2:')
  const result1 = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: true,
    arrows: true,
    margin: 2,
  })
  console.log(result1.ascii)

  console.log('\nWith margin = 10:')
  const result2 = renderASCII(result as ELKResult, {
    scale: 0.3,
    unicode: true,
    arrows: true,
    margin: 10,
  })
  console.log(result2.ascii)

  console.log('\n')
}

/**
 * Main function to run all examples
 */
async function main() {
  console.log('\n' + '='.repeat(60))
  console.log('ELK ASCII Renderer - Comprehensive Examples')
  console.log('='.repeat(60) + '\n')

  try {
    await example1_SimpleLinear()
    await example2_Branching()
    await example3_VerticalLayout()
    await example4_AsciiMode()
    await example5_ComplexWithLabels()
    await example6_DifferentScales()
    await example7_NoArrows()
    await example8_CustomMargins()

    console.log('='.repeat(60))
    console.log('All examples completed successfully!')
    console.log('='.repeat(60))
  } catch (error) {
    console.error('Error running examples:', error)
    process.exit(1)
  }
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main()
}

export {
  example1_SimpleLinear,
  example2_Branching,
  example3_VerticalLayout,
  example4_AsciiMode,
  example5_ComplexWithLabels,
  example6_DifferentScales,
  example7_NoArrows,
  example8_CustomMargins,
}
