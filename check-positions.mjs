import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = `graph {
  [ A ] -- [ B ]
  [ A ] -- [ B ]
  [ A ] -- [ C ]
  [ A ] -- [ C ]
  [ A ] -- [ D ]
  [ B ] -- [ D ]
  [ C ] -- [ D ]
}`

const parser = new Parser()
const graph = parser.parse(input)

const layout = new LayoutEngine(graph)
layout.layout()

console.log('\nNode positions:')
for (const node of graph.getNodes()) {
  console.log(`  ${node.name}: (${node.x}, ${node.y})`)
}
