/**
 * Tests for Graphviz DOT format parser
 */

import { describe, it, expect } from 'vitest'
import { DotParser } from './DotParser'

describe('DotParser - Basic Graphs', () => {
  it('should parse simple digraph', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph G { A -> B; }')

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getEdges()).toHaveLength(1)

    const edge = graph.getEdges()[0]
    expect(edge.from.name).toBe('A')
    expect(edge.to.name).toBe('B')
  })

  it('should parse simple graph (undirected)', () => {
    const parser = new DotParser()
    const graph = parser.parse('graph G { A -- B; }')

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getEdges()).toHaveLength(1)
  })

  it('should parse graph without name', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { A -> B; }')

    expect(graph.getEdges()).toHaveLength(1)
  })

  it('should parse strict digraph', () => {
    const parser = new DotParser()
    const graph = parser.parse('strict digraph { A -> B; }')

    expect(graph.getEdges()).toHaveLength(1)
  })
})

describe('DotParser - Nodes', () => {
  it('should parse node declarations', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        A;
        B;
        C;
      }
    `)

    expect(graph.getNodes()).toHaveLength(3)
  })

  it('should parse node with attributes', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { A [label="Node A", color=red]; }')

    const node = graph.getNodes()[0]
    expect(node.getAttribute('label')).toBe('Node A')
    expect(node.getAttribute('color')).toBe('red')
  })

  it('should parse nodes with quoted names', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { "Node 1" -> "Node 2"; }')

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getNodes()[0].name).toBe('Node 1')
    expect(graph.getNodes()[1].name).toBe('Node 2')
  })
})

describe('DotParser - Edges', () => {
  it('should parse multiple edges', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        A -> B;
        B -> C;
        C -> D;
      }
    `)

    expect(graph.getEdges()).toHaveLength(3)
  })

  it('should parse edge with attributes', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { A -> B [label="edge", color=blue]; }')

    const edge = graph.getEdges()[0]
    expect(edge.getAttribute('label')).toBe('edge')
    expect(edge.getAttribute('color')).toBe('blue')
  })

  it('should parse chained edges', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { A -> B -> C -> D; }')

    expect(graph.getNodes()).toHaveLength(4)
    expect(graph.getEdges()).toHaveLength(3)
  })

  it.todo('should parse multiple edges from one node', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { A -> {B; C; D}; }')

    expect(graph.getEdges()).toHaveLength(3)

    const edges = graph.getEdges()
    expect(edges.every(e => e.from.name === 'A')).toBe(true)
  })
})

describe('DotParser - Attributes', () => {
  it.todo('should map DOT attributes to Graph::Easy', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        A [fillcolor=lightblue, fontname=Arial, fontsize=12];
      }
    `)

    const node = graph.getNodes()[0]
    expect(node.getAttribute('fill')).toBe('lightblue')
    expect(node.getAttribute('font')).toBe('Arial')
    expect(node.getAttribute('fontsize')).toBe('12')
  })

  it('should handle node shape attribute', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { A [shape=box]; }')

    const node = graph.getNodes()[0]
    expect(node.getAttribute('shape')).toBe('rect')
  })
})

describe('DotParser - Comments', () => {
  it('should ignore line comments', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        // This is a comment
        A -> B; // Another comment
      }
    `)

    expect(graph.getEdges()).toHaveLength(1)
  })

  it('should ignore block comments', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        /* This is a
           multi-line comment */
        A -> B;
      }
    `)

    expect(graph.getEdges()).toHaveLength(1)
  })
})

describe('DotParser - Complex Graphs', () => {
  it.todo('should parse complex graph', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph G {
        rankdir=LR;

        node [shape=box];

        A [label="Start"];
        B [label="Process"];
        C [label="End"];

        A -> B [label="begin"];
        B -> C [label="finish"];
      }
    `)

    expect(graph.getNodes()).toHaveLength(3)
    expect(graph.getEdges()).toHaveLength(2)
  })

  it('should parse graph with multiple edge styles', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        A -> B [style=solid];
        B -> C [style=dashed];
        C -> D [style=dotted];
      }
    `)

    const edges = graph.getEdges()
    expect(edges).toHaveLength(3)
    expect(edges[0].getAttribute('style')).toBe('solid')
    expect(edges[1].getAttribute('style')).toBe('dashed')
    expect(edges[2].getAttribute('style')).toBe('dotted')
  })
})

describe('DotParser - Subgraphs', () => {
  it('should parse subgraph', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        subgraph cluster_0 {
          A;
          B;
        }
        C;
      }
    `)

    expect(graph.getNodes()).toHaveLength(3)
  })

  it('should handle nested subgraphs', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        subgraph cluster_1 {
          A -> B;
          subgraph cluster_2 {
            C -> D;
          }
        }
      }
    `)

    expect(graph.getNodes()).toHaveLength(4)
    expect(graph.getEdges()).toHaveLength(2)
  })
})

describe('DotParser - Auto-detection', () => {
  it('should detect DOT format', () => {
    const parser = new DotParser()

    // Should parse successfully
    expect(() => {
      parser.parse('digraph { A -> B; }')
    }).not.toThrow()

    expect(() => {
      parser.parse('graph { A -- B; }')
    }).not.toThrow()

    expect(() => {
      parser.parse('strict digraph { A -> B; }')
    }).not.toThrow()
  })
})

describe('DotParser - Edge Cases', () => {
  it('should handle empty graph', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph { }')

    expect(graph.getNodes()).toHaveLength(0)
    expect(graph.getEdges()).toHaveLength(0)
  })

  it('should handle graph with only whitespace', () => {
    const parser = new DotParser()
    const graph = parser.parse('digraph {   \n   }')

    expect(graph.getNodes()).toHaveLength(0)
  })

  it('should reuse nodes across edges', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        A -> B;
        B -> C;
      }
    `)

    // Should have 3 nodes, not 4 (B reused)
    expect(graph.getNodes()).toHaveLength(3)
  })

  it('should handle semicolon-optional syntax', () => {
    const parser = new DotParser()
    const graph = parser.parse(`
      digraph {
        A -> B
        B -> C
      }
    `)

    expect(graph.getEdges()).toHaveLength(2)
  })
})

describe('DotParser - Error Handling', () => {
  it('should handle malformed input gracefully in non-strict mode', () => {
    const parser = new DotParser({ strict: false })

    expect(() => {
      parser.parse('digraph { A -> }')
    }).not.toThrow()
  })

  it('should throw in strict mode for invalid syntax', () => {
    const parser = new DotParser({ strict: true })

    expect(() => {
      parser.parse('invalid syntax')
    }).toThrow()
  })
})
