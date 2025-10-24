import { Parser } from './js-implementation/parser/Parser'

const parser = new Parser()

const input = `graph { flow: south; }
[A] -> [B]`

console.log('Parsing:', input)
const graph = parser.parse(input)

const nodes = graph.getNodes()
const edges = graph.getEdges()

console.log('Nodes:', nodes.map(n => ({ name: n.name, id: n.id })))
console.log('Edges:', edges.map(e => ({ from: e.from.name, to: e.to.name })))

// Access private assignRanks method via layout
const layout = await graph.layout()

console.log('\nLayout result:')
console.log('Nodes:', layout.nodes.map(n => ({ label: n.label, x: n.x, y: n.y })))
