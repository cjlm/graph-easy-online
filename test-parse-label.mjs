import { Parser } from './js-implementation/parser/Parser.ts'

const input = '[ A ] -> [ B ] { label: "edge label"; }'

const parser = new Parser()
const graph = parser.parse(input)

console.log('Nodes:', graph.getNodes().length)
console.log('Edges:', graph.getEdges().length)

for (const edge of graph.getEdges()) {
  console.log('Edge:', edge.from.name, '->', edge.to.name)
  console.log('  label attr:', edge.getAttribute('label'))
  console.log('  edge.label:', edge.label)
}
