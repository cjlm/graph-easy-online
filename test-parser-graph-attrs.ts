import { Parser } from './js-implementation/parser/Parser'

const parser = new Parser()

try {
  const input = `graph { flow: south; }
[A] -> [B]`

  console.log('Parsing:', input)
  const graph = parser.parse(input)

  console.log('Success!')
  console.log('Nodes:', graph.getNodes().map(n => n.name))
  console.log('Edges:', graph.getEdges().length)
  console.log('Graph flow attr:', graph.getAttribute('flow'))

  // Try layout
  const layout = await graph.layout()
  console.log('Layout nodes:', layout.nodes.length)
  console.log('Layout edges:', layout.edges.length)
  console.log('Layout bounds:', layout.bounds)

} catch (e) {
  console.error('Error:', e.message)
  console.error(e.stack)
}
