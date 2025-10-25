/**
 * Tests for Graph core class
 */

import { describe, it, expect } from 'vitest'
import { Graph } from './Graph'
import { Node } from './Node'

describe('Graph - Node Operations', () => {
  it('should create empty graph', () => {
    const graph = new Graph()

    expect(graph.getNodes()).toHaveLength(0)
    expect(graph.getEdges()).toHaveLength(0)
  })

  it('should add node by name', () => {
    const graph = new Graph()
    const node = graph.addNode('Berlin')

    expect(graph.getNodes()).toHaveLength(1)
    expect(node.name).toBe('Berlin')
  })

  it('should add node object', () => {
    const graph = new Graph()
    const node = new Node('Berlin')
    graph.addNode(node)

    expect(graph.getNodes()).toHaveLength(1)
    expect(graph.getNodes()[0]).toBe(node)
  })

  it('should not duplicate nodes with same name', () => {
    const graph = new Graph()
    graph.addNode('Berlin')
    graph.addNode('Berlin')

    expect(graph.getNodes()).toHaveLength(1)
  })

  it('should get node by name', () => {
    const graph = new Graph()
    graph.addNode('Berlin')

    const node = graph.node('Berlin')
    expect(node).toBeDefined()
    expect(node?.name).toBe('Berlin')
  })

  it('should return undefined for non-existent node', () => {
    const graph = new Graph()
    const node = graph.node('NonExistent')

    expect(node).toBeUndefined()
  })

  it('should delete node', () => {
    const graph = new Graph()
    const node = graph.addNode('Berlin')

    expect(graph.deleteNode(node)).toBe(true)
    expect(graph.getNodes()).toHaveLength(0)
  })

  it('should delete node and its edges', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    graph.addEdge(a, b)

    expect(graph.getEdges()).toHaveLength(1)

    graph.deleteNode(a)

    expect(graph.getNodes()).toHaveLength(1)
    expect(graph.getEdges()).toHaveLength(0)
  })
})

describe('Graph - Edge Operations', () => {
  it('should add edge between nodes', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')

    const edge = graph.addEdge(a, b)

    expect(graph.getEdges()).toHaveLength(1)
    expect(edge.from).toBe(a)
    expect(edge.to).toBe(b)
  })

  it('should add edge by node names', () => {
    const graph = new Graph()
    graph.addNode('A')
    graph.addNode('B')

    const edge = graph.addEdge('A', 'B')

    expect(graph.getEdges()).toHaveLength(1)
    expect(edge.from.name).toBe('A')
    expect(edge.to.name).toBe('B')
  })

  it('should create nodes when adding edge', () => {
    const graph = new Graph()
    graph.addEdge('A', 'B')

    expect(graph.getNodes()).toHaveLength(2)
    expect(graph.getEdges()).toHaveLength(1)
  })

  it('should add edge with label', () => {
    const graph = new Graph()
    const edge = graph.addEdge('A', 'B', 'test label')

    expect(edge.label).toBe('test label')
  })

  it('should delete edge', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const edge = graph.addEdge(a, b)

    expect(graph.deleteEdge(edge)).toBe(true)
    expect(graph.getEdges()).toHaveLength(0)
  })

  it('should find edges between nodes', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    graph.addEdge(a, b)
    graph.addEdge(a, c)

    const edges = graph.edgesBetween(a, b)
    expect(edges).toHaveLength(1)
    expect(edges[0].to).toBe(b)
  })

  it('should allow multiple edges between same nodes', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')

    graph.addEdge(a, b, 'edge1')
    graph.addEdge(a, b, 'edge2')

    expect(graph.getEdges()).toHaveLength(2)
  })
})

describe('Graph - Attributes', () => {
  it('should set and get graph attributes', () => {
    const graph = new Graph()
    graph.setAttribute('flow', 'south')

    expect(graph.getAttribute('flow')).toBe('south')
  })

  it.skip('should set multiple attributes', () => {
    const graph = new Graph()
    graph.setAttributes({
      flow: 'south',
      rankdir: 'TB',
    })

    expect(graph.getAttribute('flow')).toBe('south')
    expect(graph.getAttribute('rankdir')).toBe('TB')
  })

  it.skip('should get all attributes', () => {
    const graph = new Graph()
    graph.setAttributes({
      flow: 'south',
      rankdir: 'TB',
    })

    const attrs = graph.getAttributes()
    expect(attrs).toHaveProperty('flow')
    expect(attrs).toHaveProperty('rankdir')
  })
})

describe('Graph - Queries', () => {
  it('should get source nodes (no incoming edges)', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    graph.addEdge(a, b)
    graph.addEdge(b, c)

    const sources = graph.getSourceNodes()
    expect(sources).toHaveLength(1)
    expect(sources[0]).toBe(a)
  })

  it.skip('should get sink nodes (no outgoing edges)', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    graph.addEdge(a, b)
    graph.addEdge(b, c)

    const sinks = graph.getSinkNodes()
    expect(sinks).toHaveLength(1)
    expect(sinks[0]).toBe(c)
  })

  it('should get graph stats', () => {
    const graph = new Graph()
    graph.addEdge('A', 'B')
    graph.addEdge('B', 'C')

    const stats = graph.stats()
    expect(stats.nodes).toBe(3)
    expect(stats.edges).toBe(2)
    expect(stats.isDirected).toBe(true)
  })

  it('should detect simple graph (no multi-edges)', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')

    graph.addEdge(a, b)

    const stats = graph.stats()
    expect(stats.isSimple).toBe(true)
  })

  it('should detect non-simple graph (multi-edges)', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')

    graph.addEdge(a, b, 'edge1')
    graph.addEdge(a, b, 'edge2')

    const stats = graph.stats()
    expect(stats.isSimple).toBe(false)
  })
})

describe('Graph - Groups', () => {
  it('should add group', () => {
    const graph = new Graph()
    const group = graph.addGroup('WebTier')

    expect(graph.getGroups()).toHaveLength(1)
    expect(group.name).toBe('WebTier')
  })

  it('should add nodes to group', () => {
    const graph = new Graph()
    const group = graph.addGroup('WebTier')
    const web1 = graph.addNode('Web1')
    const web2 = graph.addNode('Web2')

    group.addMembers(web1, web2)

    expect(group.size()).toBe(2)
    expect(web1.group).toBe(group)
    expect(web2.group).toBe(group)
  })

  it('should get group by name', () => {
    const graph = new Graph()
    graph.addGroup('WebTier')

    const group = graph.group('WebTier')
    expect(group).toBeDefined()
    expect(group?.name).toBe('WebTier')
  })
})

describe('Graph - Topological Operations', () => {
  it.skip('should detect cycles', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    graph.addEdge(a, b)
    graph.addEdge(b, c)
    graph.addEdge(c, a) // Creates cycle

    expect(graph.hasCycles()).toBe(true)
  })

  it.skip('should detect acyclic graph', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    graph.addEdge(a, b)
    graph.addEdge(b, c)

    expect(graph.hasCycles()).toBe(false)
  })
})

describe('Graph - Serialization', () => {
  it.skip('should convert to JSON', () => {
    const graph = new Graph()
    graph.addEdge('A', 'B')
    graph.addEdge('B', 'C')

    const json = graph.toJSON()

    expect(json.nodes).toHaveLength(3)
    expect(json.edges).toHaveLength(2)
  })

  it.skip('should include attributes in JSON', () => {
    const graph = new Graph()
    const node = graph.addNode('A')
    node.setAttribute('fill', 'red')

    const json = graph.toJSON()

    expect(json.nodes[0].attributes).toHaveProperty('fill')
    expect(json.nodes[0].attributes.fill).toBe('red')
  })
})
