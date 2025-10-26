import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = '[ A ] -- { label: "test"; } [ B ]'

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

console.log('\nAll cells:')
for (const [key, cell] of graph.cells) {
  if (cell.edge) {
    const hasLabelFlag = cell.hasLabel()
    const edgeLabel = cell.edge.label || '(none)'
    console.log(`  ${key}: type=0x${cell.type.toString(16)} hasLabel=${hasLabelFlag} edge.label="${edgeLabel}"`)
  }
}

console.log('\nCells that should render labels:')
for (const [key, cell] of graph.cells) {
  if (cell.hasLabel() && cell.edge?.label) {
    console.log(`  ${key}: YES - will render "${cell.edge.label}"`)
  }
}
