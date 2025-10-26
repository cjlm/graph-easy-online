import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = '[ A ] -> [ B ]\n[ A ] -> [ B ]\n[ A ] -> [ B ]'

const parser = new Parser()
const graph = parser.parse(input)

console.log('Edges:', graph.getEdges().length)
for (const edge of graph.getEdges()) {
  console.log(`  ${edge.from.name} -> ${edge.to.name}`)
}

const layout = new LayoutEngine(graph)
layout.layout()

console.log('\nNode positions:')
for (const node of graph.getNodes()) {
  console.log(`  ${node.name}: (${node.x}, ${node.y})`)
}

console.log('\nEdge cells:')
let edgeCount = 0
for (const [key, cell] of graph.cells) {
  if (cell.edge) {
    edgeCount++
    console.log(`  ${key}: edge ${cell.edge.from.name}->${cell.edge.to.name}`)
  }
}
console.log(`Total edge cells: ${edgeCount}`)
