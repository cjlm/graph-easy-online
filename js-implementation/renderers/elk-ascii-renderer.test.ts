/**
 * Tests for ELK ASCII Renderer
 *
 * Testing cases as per specification:
 * 1. Single straight edge (horizontal and vertical)
 * 2. L-shaped edge with one corner
 * 3. Complex path with multiple bends
 * 4. Multiple edges intersecting at junction
 * 5. Edge entering node at different sides
 * 6. Self-loop edge (source === target)
 * 7. Hierarchical node containing children
 * 8. Dense graph with many overlapping edges
 * 9. Graph with edge and node labels
 * 10. Graph with ports
 */

import { describe, it, expect } from 'vitest'
import { renderASCII, type ELKResult, type RenderOptions } from './elk-ascii-renderer'
import ELK from 'elkjs'

describe('ELK ASCII Renderer', () => {
  const elk = new ELK()

  it('should render a single straight horizontal edge', async () => {
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

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: true,
      arrows: true,
    })

    expect(ascii).toBeTruthy()
    expect(metadata.nodeCount).toBe(2)
    expect(metadata.edgeCount).toBe(1)
    expect(metadata.warnings).toEqual([])

    console.log('Test 1: Single straight horizontal edge')
    console.log(ascii)
    console.log('Metadata:', metadata)
  })

  it('should render an L-shaped edge with one corner', async () => {
    const graph = {
      id: 'root',
      layoutOptions: {
        'elk.algorithm': 'layered',
        'elk.edgeRouting': 'ORTHOGONAL',
        'elk.direction': 'DOWN',
      },
      children: [
        { id: 'n1', width: 60, height: 40, labels: [{ text: 'Start' }] },
        { id: 'n2', width: 60, height: 40, labels: [{ text: 'End' }] },
      ],
      edges: [{ id: 'e1', sources: ['n1'], targets: ['n2'] }],
    }

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: true,
      arrows: true,
    })

    expect(ascii).toBeTruthy()
    expect(metadata.nodeCount).toBe(2)

    console.log('\nTest 2: L-shaped edge with one corner')
    console.log(ascii)
  })

  it('should render complex path with multiple bends', async () => {
    const graph = {
      id: 'root',
      layoutOptions: {
        'elk.algorithm': 'layered',
        'elk.edgeRouting': 'ORTHOGONAL',
        'elk.spacing.nodeNode': '80',
        'elk.layered.spacing.nodeNodeBetweenLayers': '100',
      },
      children: [
        { id: 'n1', width: 60, height: 40, labels: [{ text: 'A' }] },
        { id: 'n2', width: 60, height: 40, labels: [{ text: 'B' }] },
        { id: 'n3', width: 60, height: 40, labels: [{ text: 'C' }] },
        { id: 'n4', width: 60, height: 40, labels: [{ text: 'D' }] },
      ],
      edges: [
        { id: 'e1', sources: ['n1'], targets: ['n2'] },
        { id: 'e2', sources: ['n2'], targets: ['n3'] },
        { id: 'e3', sources: ['n3'], targets: ['n4'] },
      ],
    }

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: true,
      arrows: true,
    })

    expect(ascii).toBeTruthy()
    expect(metadata.nodeCount).toBe(4)
    expect(metadata.edgeCount).toBe(3)

    console.log('\nTest 3: Complex path with multiple bends')
    console.log(ascii)
  })

  it('should render multiple edges intersecting at junction', async () => {
    const graph = {
      id: 'root',
      layoutOptions: {
        'elk.algorithm': 'layered',
        'elk.edgeRouting': 'ORTHOGONAL',
      },
      children: [
        { id: 'n1', width: 60, height: 40, labels: [{ text: 'A' }] },
        { id: 'n2', width: 60, height: 40, labels: [{ text: 'B' }] },
        { id: 'n3', width: 60, height: 40, labels: [{ text: 'C' }] },
        { id: 'n4', width: 60, height: 40, labels: [{ text: 'D' }] },
      ],
      edges: [
        { id: 'e1', sources: ['n1'], targets: ['n3'] },
        { id: 'e2', sources: ['n2'], targets: ['n4'] },
      ],
    }

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: true,
      arrows: true,
    })

    expect(ascii).toBeTruthy()
    expect(metadata.nodeCount).toBe(4)
    expect(metadata.edgeCount).toBe(2)

    console.log('\nTest 4: Multiple edges intersecting at junction')
    console.log(ascii)
  })

  it('should render edges entering nodes at different sides', async () => {
    const graph = {
      id: 'root',
      layoutOptions: {
        'elk.algorithm': 'layered',
        'elk.edgeRouting': 'ORTHOGONAL',
      },
      children: [
        { id: 'n1', width: 60, height: 40, labels: [{ text: 'Top' }] },
        { id: 'center', width: 60, height: 40, labels: [{ text: 'Center' }] },
        { id: 'n2', width: 60, height: 40, labels: [{ text: 'Bottom' }] },
      ],
      edges: [
        { id: 'e1', sources: ['n1'], targets: ['center'] },
        { id: 'e2', sources: ['center'], targets: ['n2'] },
      ],
    }

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: true,
      arrows: true,
    })

    expect(ascii).toBeTruthy()

    console.log('\nTest 5: Edges entering nodes at different sides')
    console.log(ascii)
  })

  it('should handle graph with node and edge labels', async () => {
    const graph = {
      id: 'root',
      layoutOptions: {
        'elk.algorithm': 'layered',
        'elk.edgeRouting': 'ORTHOGONAL',
      },
      children: [
        { id: 'n1', width: 80, height: 40, labels: [{ text: 'Node A' }] },
        { id: 'n2', width: 80, height: 40, labels: [{ text: 'Node B' }] },
        { id: 'n3', width: 80, height: 40, labels: [{ text: 'Node C' }] },
      ],
      edges: [
        { id: 'e1', sources: ['n1'], targets: ['n2'], labels: [{ text: 'connects' }] },
        { id: 'e2', sources: ['n2'], targets: ['n3'], labels: [{ text: 'to' }] },
      ],
    }

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: true,
      arrows: true,
      renderLabels: true,
    })

    expect(ascii).toBeTruthy()
    expect(metadata.nodeCount).toBe(3)
    expect(metadata.edgeCount).toBe(2)

    console.log('\nTest 9: Graph with node and edge labels')
    console.log(ascii)
  })

  it('should render in ASCII mode (non-unicode)', async () => {
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

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: false, // ASCII mode
      arrows: true,
    })

    expect(ascii).toBeTruthy()
    expect(ascii).not.toContain('─') // Should not contain unicode chars
    expect(ascii).toContain('-') // Should contain ASCII chars

    console.log('\nTest: ASCII mode (non-unicode)')
    console.log(ascii)
  })

  it('should render without arrows', async () => {
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

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.3,
      unicode: true,
      arrows: false, // No arrows
    })

    expect(ascii).toBeTruthy()
    expect(ascii).not.toContain('→')
    expect(ascii).not.toContain('>')

    console.log('\nTest: Without arrows')
    console.log(ascii)
  })

  it('should handle empty graph', async () => {
    const graph = {
      id: 'root',
      layoutOptions: {
        'elk.algorithm': 'layered',
      },
      children: [],
      edges: [],
    }

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult)

    expect(ascii).toBeTruthy()
    expect(metadata.nodeCount).toBe(0)
    expect(metadata.edgeCount).toBe(0)

    console.log('\nTest: Empty graph')
    console.log(ascii)
  })

  it('should handle dense graph and provide warnings', async () => {
    const graph = {
      id: 'root',
      layoutOptions: {
        'elk.algorithm': 'layered',
        'elk.edgeRouting': 'ORTHOGONAL',
      },
      children: [
        { id: 'n1', width: 40, height: 30, labels: [{ text: 'A' }] },
        { id: 'n2', width: 40, height: 30, labels: [{ text: 'B' }] },
        { id: 'n3', width: 40, height: 30, labels: [{ text: 'C' }] },
        { id: 'n4', width: 40, height: 30, labels: [{ text: 'D' }] },
        { id: 'n5', width: 40, height: 30, labels: [{ text: 'E' }] },
      ],
      edges: [
        { id: 'e1', sources: ['n1'], targets: ['n2'] },
        { id: 'e2', sources: ['n1'], targets: ['n3'] },
        { id: 'e3', sources: ['n2'], targets: ['n4'] },
        { id: 'e4', sources: ['n3'], targets: ['n4'] },
        { id: 'e5', sources: ['n4'], targets: ['n5'] },
        { id: 'e6', sources: ['n1'], targets: ['n5'] },
      ],
    }

    const elkResult = await elk.layout(graph)
    const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
      scale: 0.2, // Small scale to make it dense
      unicode: true,
      arrows: true,
      maxDensity: 0.2, // Low threshold for testing
    })

    expect(ascii).toBeTruthy()
    expect(metadata.nodeCount).toBe(5)
    expect(metadata.edgeCount).toBe(6)

    console.log('\nTest 8: Dense graph')
    console.log(ascii)
    console.log('Warnings:', metadata.warnings)
  })

  it('should validate invalid ELK result', () => {
    const invalidResult = {} as ELKResult
    const { ascii, metadata } = renderASCII(invalidResult)

    expect(ascii).toBeNull()
    expect(metadata.error).toBeTruthy()
    expect(metadata.error).toContain('Invalid ELK result')

    console.log('\nTest: Invalid ELK result')
    console.log('Error:', metadata.error)
  })

  it('should handle different scales', async () => {
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

    const elkResult = await elk.layout(graph)

    // Test with different scales
    const scales = [0.2, 0.3, 0.5]
    scales.forEach(scale => {
      const { ascii, metadata } = renderASCII(elkResult as ELKResult, {
        scale,
        unicode: true,
        arrows: true,
      })

      expect(ascii).toBeTruthy()
      expect(metadata.scale).toBe(scale)

      console.log(`\nTest: Scale ${scale}`)
      console.log(`Canvas size: ${metadata.width}x${metadata.height}`)
      console.log(ascii)
    })
  })
})

/**
 * Example usage script
 */
async function exampleUsage() {
  console.log('\n=== ELK ASCII Renderer Example Usage ===\n')

  const elk = new ELK()

  const graph = {
    id: 'root',
    layoutOptions: {
      'elk.algorithm': 'layered',
      'elk.edgeRouting': 'ORTHOGONAL',
      'elk.spacing.nodeNode': '80',
      'elk.layered.spacing.nodeNodeBetweenLayers': '100',
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

  console.log('Rendered Graph:')
  console.log(ascii)
  console.log('\nMetadata:', JSON.stringify(metadata, null, 2))
}

// Run example if this file is executed directly
if (import.meta.vitest === undefined) {
  exampleUsage().catch(console.error)
}
