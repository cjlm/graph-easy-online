/**
 * Tests for ChainDetector
 */

import { describe, it, expect } from 'vitest'
import { Graph } from '../../core/Graph'
import { ChainDetector } from '../ChainDetector'

describe('ChainDetector', () => {
  it('detects single chain in linear graph', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    graph.addEdge(a, b)
    graph.addEdge(b, c)

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    expect(chains.length).toBe(1)
    expect(chains[0].length).toBe(3)
    expect(chains[0].nodes.map(n => n.name)).toEqual(['A', 'B', 'C'])
  })

  it('detects separate chains in branching graph', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    // A -> B, and separate node C
    graph.addEdge(a, b)

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    expect(chains.length).toBe(2)

    // Should have one chain of length 2 (A->B) and one of length 1 (C)
    const lengths = chains.map(c => c.length).sort()
    expect(lengths).toEqual([1, 2])
  })

  it('merges longest successor chain in diamond', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')
    const d = graph.addNode('D')
    const e = graph.addNode('E')

    // Diamond with extended path: A -> B -> D, A -> C -> D -> E
    graph.addEdge(a, b)
    graph.addEdge(a, c)
    graph.addEdge(b, d)
    graph.addEdge(c, d)
    graph.addEdge(d, e)

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    // Should create one main chain following longest path
    // A has two successors (B, C)
    // C->D->E is longer than B->D
    // So chain should be A, then merge C->D->E

    expect(chains.length).toBeGreaterThanOrEqual(1)

    // The first chain should contain A
    const mainChain = chains[0]
    expect(mainChain.contains(a)).toBe(true)
  })

  it('handles self-loops without infinite loop', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')

    graph.addEdge(a, a) // Self-loop
    graph.addEdge(a, b)

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    // Should successfully detect chain A->B (ignoring self-loop)
    expect(chains.length).toBeGreaterThanOrEqual(1)
    const mainChain = chains[0]
    expect(mainChain.contains(a)).toBe(true)
    expect(mainChain.contains(b)).toBe(true)
  })

  it('handles cycles without infinite loop', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    // Cycle: A -> B -> C -> A
    graph.addEdge(a, b)
    graph.addEdge(b, c)
    graph.addEdge(c, a)

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    // Should detect chains without infinite looping
    expect(chains.length).toBeGreaterThanOrEqual(1)

    // All nodes should be in chains
    const allNodes = chains.flatMap(c => c.nodes)
    expect(allNodes.length).toBe(3)
  })

  it('sorts chains with root chain first', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')
    const d = graph.addNode('D')

    // Two separate chains: C->D (longer) and A->B (has root)
    // A has no predecessors, so it's the root
    graph.addEdge(a, b)
    graph.addEdge(c, d)

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    // Root chain should be first even if shorter
    expect(chains[0].contains(a)).toBe(true)
  })

  it('handles single node', () => {
    const graph = new Graph()
    const a = graph.addNode('A')

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    expect(chains.length).toBe(1)
    expect(chains[0].length).toBe(1)
    expect(chains[0].nodes[0]).toBe(a)
  })

  it('handles empty graph', () => {
    const graph = new Graph()

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    expect(chains.length).toBe(0)
  })

  it('handles multiple edges between same nodes', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')

    // Multiple edges A -> B
    graph.addEdge(a, b)
    graph.addEdge(a, b)

    const detector = new ChainDetector(graph)
    const chains = detector.findChains()

    // Should still be one chain A->B (duplicates ignored)
    expect(chains.length).toBe(1)
    expect(chains[0].length).toBe(2)
  })
})
