/**
 * Tests for Graph::Easy notation parser
 */

import { describe, it, expect } from 'vitest'
import { Parser } from './Parser.ts'

describe('Parser - Basic Nodes', () => {
  it('should parse a single node', () => {
    const parser = new Parser()
    const graph = parser.parse('[Berlin]')

    expect(graph.getNodes()).toHaveLength(1)
    const node = graph.getNodes()[0]
    expect(node.name).toBe('Berlin')
  })

  it('should parse multiple nodes', () => {
    const parser = new Parser()
    const graph = parser.parse('[Berlin] [Munich] [Hamburg]')

    expect(graph.getNodes()).toHaveLength(3)
    const names = graph.getNodes().map(n => n.name)
    expect(names).toContain('Berlin')
    expect(names).toContain('Munich')
    expect(names).toContain('Hamburg')
  })

  it('should parse nodes with spaces in names', () => {
    const parser = new Parser()
    const graph = parser.parse('[New York] [Los Angeles]')

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getNodes()[0].name).toBe('New York')
    expect(graph.getNodes()[1].name).toBe('Los Angeles')
  })
})

describe('Parser - Basic Edges', () => {
  it('should parse a simple edge with ->', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] -> [B]')

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getEdges()).toHaveLength(1)

    const edge = graph.getEdges()[0]
    expect(edge.from.name).toBe('A')
    expect(edge.to.name).toBe('B')
  })

  it('should parse a simple edge with =>', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] => [B]')

    expect(graph.getEdges()).toHaveLength(1)
    const edge = graph.getEdges()[0]
    expect(edge.getAttribute('style')).toBe('double')
  })

  it('should parse dotted edge with ..>', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] ..> [B]')

    expect(graph.getEdges()).toHaveLength(1)
    const edge = graph.getEdges()[0]
    expect(edge.getAttribute('style')).toBe('dotted')
  })

  it('should parse dashed edge with -->', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] --> [B]')

    expect(graph.getEdges()).toHaveLength(1)
    const edge = graph.getEdges()[0]
    expect(edge.getAttribute('style')).toBe('dashed')
  })

  it('should parse bidirectional edge with <->', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] <-> [B]')

    const edges = graph.getEdges()
    expect(edges).toHaveLength(1)
    expect(edges[0].isBidirectional()).toBe(true)
  })

  it('should parse edge without arrow with --', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] -- [B]')

    const edges = graph.getEdges()
    expect(edges).toHaveLength(1)
    expect(edges[0].arrowStyle).toBe('none')
  })
})

describe('Parser - Edge Chaining', () => {
  it('should parse chained edges', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] -> [B] -> [C]')

    expect(graph.getNodes()).toHaveLength(3)
    expect(graph.getEdges()).toHaveLength(2)

    const edges = graph.getEdges()
    expect(edges[0].from.name).toBe('A')
    expect(edges[0].to.name).toBe('B')
    expect(edges[1].from.name).toBe('B')
    expect(edges[1].to.name).toBe('C')
  })

  it('should parse complex chain', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] -> [B] => [C] ..> [D]')

    expect(graph.getNodes()).toHaveLength(4)
    expect(graph.getEdges()).toHaveLength(3)
  })
})

describe('Parser - Attributes', () => {
  it('should parse node attributes', () => {
    const parser = new Parser()
    const graph = parser.parse('[Berlin] { fill: lightblue; }')

    const node = graph.getNodes()[0]
    expect(node.getAttribute('fill')).toBe('lightblue')
  })

  it('should parse multiple node attributes', () => {
    const parser = new Parser()
    const graph = parser.parse('[Berlin] { fill: lightblue; shape: circle; }')

    const node = graph.getNodes()[0]
    expect(node.getAttribute('fill')).toBe('lightblue')
    expect(node.getAttribute('shape')).toBe('circle')
  })

  it('should parse edge attributes', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] -> [B] { label: test; }')

    const edge = graph.getEdges()[0]
    expect(edge.getAttribute('label')).toBe('test')
  })

  it('should parse edge label', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] -> [B] { label: "Edge Label"; }')

    const edge = graph.getEdges()[0]
    expect(edge.getAttribute('label')).toBe('Edge Label')
  })

  it('should parse graph attributes', () => {
    const parser = new Parser()
    const graph = parser.parse('graph { flow: south; }')

    expect(graph.getAttribute('flow')).toBe('south')
  })
})

describe('Parser - Comments', () => {
  it('should ignore single-line comments', () => {
    const parser = new Parser()
    const graph = parser.parse(`
      # This is a comment
      [A] -> [B]
      # Another comment
    `)

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getEdges()).toHaveLength(1)
  })

  it('should ignore inline comments', () => {
    const parser = new Parser()
    const graph = parser.parse('[A] -> [B] # edge from A to B')

    expect(graph.getEdges()).toHaveLength(1)
  })
})

describe('Parser - Multi-line Graphs', () => {
  it('should parse multi-line graph definition', () => {
    const parser = new Parser()
    const graph = parser.parse(`
      [Bonn] -> [Berlin]
      [Berlin] -> [Dresden]
      [Dresden] -> [Munich]
    `)

    expect(graph.getNodes()).toHaveLength(4)
    expect(graph.getEdges()).toHaveLength(3)
  })

  it('should parse complex graph', () => {
    const parser = new Parser()
    const graph = parser.parse(`
      graph { flow: south; }

      [Start] { fill: lightgreen; }
      [Process] { fill: lightyellow; }
      [End] { fill: lightblue; }

      [Start] -> [Process] -> [End]
    `)

    expect(graph.getAttribute('flow')).toBe('south')
    expect(graph.getNodes()).toHaveLength(3)
    expect(graph.getEdges()).toHaveLength(2)
  })
})

describe('Parser - Edge Cases', () => {
  it('should handle empty input', () => {
    const parser = new Parser()
    const graph = parser.parse('')

    expect(graph.getNodes()).toHaveLength(0)
    expect(graph.getEdges()).toHaveLength(0)
  })

  it('should handle whitespace-only input', () => {
    const parser = new Parser()
    const graph = parser.parse('   \n  \t  \n  ')

    expect(graph.getNodes()).toHaveLength(0)
  })

  it('should handle nodes with special characters', () => {
    const parser = new Parser()
    const graph = parser.parse('[Node-1] -> [Node_2]')

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getNodes()[0].name).toBe('Node-1')
    expect(graph.getNodes()[1].name).toBe('Node_2')
  })

  it('should reuse existing nodes', () => {
    const parser = new Parser()
    const graph = parser.parse(`
      [A] -> [B]
      [B] -> [C]
    `)

    // Should be 3 nodes, not 4 (B should be reused)
    expect(graph.getNodes()).toHaveLength(3)
  })
})

describe('Parser - Error Handling', () => {
  it('should handle malformed input gracefully', () => {
    const parser = new Parser({ strict: false })

    // Should not throw
    expect(() => {
      parser.parse('[A] -> ')
    }).not.toThrow()
  })

  it('should throw in strict mode for malformed input', () => {
    const parser = new Parser({ strict: true })

    expect(() => {
      parser.parse('[A] -> ')
    }).toThrow()
  })
})
