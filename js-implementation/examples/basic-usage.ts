/**
 * Basic usage example of the Graph::Easy JavaScript reimplementation
 */

import { Graph } from '../core/Graph'
import { Node } from '../core/Node'
import { Edge } from '../core/Edge'
import { renderAscii, renderBoxart } from '../renderers/AsciiRenderer'

// Example 1: Simple graph creation
async function example1() {
  console.log('Example 1: Simple Graph\n')

  const graph = new Graph()

  // Add nodes
  const bonn = graph.addNode('Bonn')
  const berlin = graph.addNode('Berlin')

  // Add edge
  graph.addEdge(bonn, berlin)

  // Perform layout
  const layout = await graph.layout()

  // Render as ASCII
  const ascii = renderAscii(layout)
  console.log(ascii)
  console.log('\n')
}

// Example 2: Graph with styling
async function example2() {
  console.log('Example 2: Styled Graph\n')

  const graph = new Graph()

  // Add nodes with attributes
  const start = graph.addNode('Start')
  start.setAttribute('fill', 'lightgreen')
  start.setAttribute('shape', 'rect')

  const process = graph.addNode('Process')
  process.setAttribute('fill', 'lightyellow')

  const end = graph.addNode('End')
  end.setAttribute('fill', 'lightblue')

  // Add edges with labels
  graph.addEdge(start, process, 'begin')
  graph.addEdge(process, end, 'finish')

  // Perform layout
  const layout = await graph.layout()

  // Render as boxart
  const boxart = renderBoxart(layout)
  console.log(boxart)
  console.log('\n')
}

// Example 3: Complex graph
async function example3() {
  console.log('Example 3: Complex Graph\n')

  const graph = new Graph({ flow: 'south' } as any)

  // Create a diamond pattern
  const nodes = ['A', 'B', 'C', 'D', 'E'].map(name => graph.addNode(name))

  graph.addEdge('A', 'B')
  graph.addEdge('A', 'C')
  graph.addEdge('B', 'D')
  graph.addEdge('C', 'D')
  graph.addEdge('D', 'E')

  // Perform layout
  const layout = await graph.layout()

  // Render
  const ascii = renderAscii(layout)
  console.log(ascii)
  console.log('\n')

  // Print statistics
  const stats = graph.stats()
  console.log('Graph Statistics:')
  console.log(`  Nodes: ${stats.nodes}`)
  console.log(`  Edges: ${stats.edges}`)
  console.log(`  Is Simple: ${stats.isSimple}`)
  console.log(`  Is Directed: ${stats.isDirected}`)
  console.log('\n')
}

// Example 4: Using groups
async function example4() {
  console.log('Example 4: Groups\n')

  const graph = new Graph()

  // Create nodes
  const web1 = graph.addNode('Web Server 1')
  const web2 = graph.addNode('Web Server 2')
  const db1 = graph.addNode('Database 1')
  const db2 = graph.addNode('Database 2')

  // Create groups
  const webGroup = graph.addGroup('Web Tier')
  webGroup.addMembers(web1, web2)

  const dbGroup = graph.addGroup('Database Tier')
  dbGroup.addMembers(db1, db2)

  // Add edges
  graph.addEdge(web1, db1)
  graph.addEdge(web1, db2)
  graph.addEdge(web2, db1)
  graph.addEdge(web2, db2)

  // Perform layout
  const layout = await graph.layout()

  // Render
  const ascii = renderAscii(layout)
  console.log(ascii)
  console.log('\n')
}

// Example 5: Working with edges
async function example5() {
  console.log('Example 5: Edge Operations\n')

  const graph = new Graph()

  const a = graph.addNode('A')
  const b = graph.addNode('B')
  const c = graph.addNode('C')

  // Add edges with different styles
  const edge1 = graph.addEdge(a, b)
  edge1.setAttribute('style', 'dashed')
  edge1.setAttribute('label', 'optional')

  const edge2 = graph.addEdge(b, c)
  edge2.setAttribute('style', 'double')
  edge2.setAttribute('label', 'required')

  // Check edge properties
  console.log(`Edge from A to B:`)
  console.log(`  Style: ${edge1.style}`)
  console.log(`  Label: ${edge1.label}`)
  console.log(`  Is self-loop: ${edge1.isSelfLoop()}`)
  console.log('\n')

  // Flip an edge
  const edge3 = graph.addEdge(c, a)
  console.log(`Before flip: ${edge3}`)
  edge3.flip()
  console.log(`After flip: ${edge3}`)
  console.log('\n')
}

// Example 6: Integration with Rust layout engine (pseudo-code)
async function example6() {
  console.log('Example 6: Using Rust Layout Engine\n')

  // This would be the actual usage once WASM is compiled:
  /*
  import init, { LayoutEngine } from './wasm/graph_easy_layout'

  await init() // Initialize WASM

  const graph = new Graph()
  graph.addNode('A')
  graph.addNode('B')
  graph.addEdge('A', 'B')

  // Convert to format expected by Rust
  const graphData = {
    nodes: graph.getNodes().map(n => ({
      id: n.id,
      name: n.name,
      label: n.label,
      width: n.getAttribute('width') || 8,
      height: n.getAttribute('height') || 3,
      shape: n.getAttribute('shape') || 'rect',
    })),
    edges: graph.getEdges().map(e => ({
      id: e.id,
      from: e.from.id,
      to: e.to.id,
      label: e.label,
      style: e.style,
    })),
    config: {
      flow: 'east',
      directed: true,
      node_spacing: 2,
      rank_spacing: 3,
    },
  }

  // Call Rust layout engine
  const layoutEngine = new LayoutEngine()
  const layout = layoutEngine.layout(graphData)

  // Render
  const ascii = renderAscii(layout)
  console.log(ascii)
  */

  console.log('(Rust WASM integration example - see code comments)')
  console.log('\n')
}

// Run all examples
async function main() {
  console.log('='.repeat(60))
  console.log('Graph::Easy TypeScript Reimplementation Examples')
  console.log('='.repeat(60))
  console.log('\n')

  await example1()
  await example2()
  await example3()
  await example4()
  await example5()
  await example6()
}

// Execute if running directly
if (require.main === module) {
  main().catch(console.error)
}

export { example1, example2, example3, example4, example5, example6 }
