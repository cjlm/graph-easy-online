import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = '[ Start ] -> [ Middle ] -> { label: "done"; } [ End ]'

console.log('Parsing...')
const parser = new Parser()
const graph = parser.parse(input)

console.log('\nEdges:')
for (const edge of graph.getEdges()) {
  const label = edge.getAttribute('label') || edge.label || '(no label)'
  console.log(`  ${edge.from.name} -> ${edge.to.name}: label="${label}"`)
}

console.log('\nRunning layout...')
const layout = new LayoutEngine(graph)
layout.layout()

console.log('\nCells with labels:')
for (const [key, cell] of graph.cells) {
  if (cell.hasLabel() && cell.edge?.label) {
    console.log(`  ${key}: will render "${cell.edge.label}"`)
  }
}
