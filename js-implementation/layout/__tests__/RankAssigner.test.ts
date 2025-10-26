/**
 * Tests for RankAssigner
 */

import { describe, it, expect } from 'vitest'
import { Graph } from '../../core/Graph.ts'
import { RankAssigner } from '../RankAssigner.ts'

describe('RankAssigner', () => {
  it('assigns ranks to simple linear graph', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    graph.addEdge(a, b)
    graph.addEdge(b, c)

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    // A should be rank -1 (root)
    // B should be rank -2 (successor of A)
    // C should be rank -3 (successor of B)
    expect(a.rank).toBe(-1)
    expect(b.rank).toBe(-2)
    expect(c.rank).toBe(-3)
  })

  it('assigns ranks to diamond graph', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')
    const d = graph.addNode('D')

    graph.addEdge(a, b)
    graph.addEdge(a, c)
    graph.addEdge(b, d)
    graph.addEdge(c, d)

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    // A should be rank -1 (root)
    // B and C should be rank -2 (successors of A)
    // D should be rank -3 (successor of B and C)
    expect(a.rank).toBe(-1)
    expect(b.rank).toBe(-2)
    expect(c.rank).toBe(-2)
    expect(d.rank).toBe(-3)
  })

  it('handles user-defined ranks', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    // Set explicit rank on A
    a.setAttribute('rank', 1)

    graph.addEdge(a, b)
    graph.addEdge(b, c)

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    // A has user rank 1 -> converted to positive rank 2
    // B should be rank 1 (decremented from 2)
    // C should be rank 0 (decremented from 1)
    expect(a.rank).toBe(2)
    expect(b.rank).toBe(1)
    expect(c.rank).toBe(0)
  })

  it('handles multiple roots', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    // A and B both point to C (both are roots)
    graph.addEdge(a, c)
    graph.addEdge(b, c)

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    // First node with no predecessors gets rank -1
    // Second root also gets rank -1
    // C gets rank -2
    expect(a.rank).toBe(-1)
    expect(b.rank).toBe(-1)
    expect(c.rank).toBe(-2)
  })

  it('handles self-loops', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')

    graph.addEdge(a, a) // Self-loop
    graph.addEdge(a, b)

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    // A is root despite self-loop (self-loops don't count as predecessors)
    // B is successor of A
    expect(a.rank).toBe(-1)
    expect(b.rank).toBe(-2)
  })

  it('handles disconnected components', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')
    const d = graph.addNode('D')

    // Two separate components: A->B and C->D
    graph.addEdge(a, b)
    graph.addEdge(c, d)

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    // Both A and C should be roots
    expect(a.rank).toBe(-1)
    expect(c.rank).toBe(-1)

    // Both B and D should be at rank -2
    expect(b.rank).toBe(-2)
    expect(d.rank).toBe(-2)
  })

  it('handles cycles gracefully', () => {
    const graph = new Graph()
    const a = graph.addNode('A')
    const b = graph.addNode('B')
    const c = graph.addNode('C')

    // Create a cycle: A -> B -> C -> A
    graph.addEdge(a, b)
    graph.addEdge(b, c)
    graph.addEdge(c, a)

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    // Should still assign ranks (first node gets -1)
    // Others get subsequent ranks
    expect(a.rank).toBeDefined()
    expect(b.rank).toBeDefined()
    expect(c.rank).toBeDefined()

    // A should be selected as root
    expect(a.rank).toBe(-1)
  })

  it('handles single node', () => {
    const graph = new Graph()
    const a = graph.addNode('A')

    const assigner = new RankAssigner(graph)
    assigner.assignRanks()

    expect(a.rank).toBe(-1)
  })

  it('handles empty graph', () => {
    const graph = new Graph()

    const assigner = new RankAssigner(graph)
    assigner.assignRanks() // Should not throw

    expect(graph.getNodes().length).toBe(0)
  })
})
