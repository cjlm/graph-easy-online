import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = '[ Bonn ] -> [ Frankfurt ] -> [ Dresden ]'

const parser = new Parser()
const graph = parser.parse(input)

const layout = new LayoutEngine(graph)
layout.layout()

console.log('\nNode positions:')
for (const node of graph.getNodes()) {
  console.log(`  ${node.name}: (${node.x}, ${node.y}) size ${node.cx}x${node.cy}`)
}

console.log('\nCells:')
for (const [key, cell] of graph.cells) {
  if (cell.node) {
    console.log(`  ${key}: node ${cell.node.name}`)
  }
}
