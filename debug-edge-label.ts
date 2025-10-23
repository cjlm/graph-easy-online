/**
 * Debug script to trace edge label through the pipeline
 */

import { Parser } from './js-implementation/parser/Parser'

const parser = new Parser({ debug: false })
const input = '[A] -> [B] { label: TestLabel; }'

console.log('Input:', input)
console.log()

// Parse
const graph = parser.parse(input)

// Check the graph
console.log('Nodes:', graph.getNodes().map(n => n.name))
console.log('Edges:', graph.getEdges().length)
console.log()

//  Check the edge
const edges = graph.getEdges()
if (edges.length > 0) {
  const edge = edges[0]
  console.log('Edge ID:', edge.id)
  console.log('Edge from:', edge.from.name)
  console.log('Edge to:', edge.to.name)
  console.log('Edge label property:', edge.label)
  console.log('Edge getAttribute("label"):', edge.getAttribute('label'))
  console.log('Edge all attributes:', edge.getAttributes())
  console.log()
}

// Now run layout
console.log('Running layout...')
const layout = await graph.layout()

console.log('Layout edges:', layout.edges.length)
if (layout.edges.length > 0) {
  const edgeLayout = layout.edges[0]
  console.log('EdgeLayout label:', edgeLayout.label)
  console.log('EdgeLayout:', JSON.stringify(edgeLayout, null, 2))
}
