import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = `
[ North Bank ] -- { label: "Bridge 1"; } [ Island Kneiphof ]
[ North Bank ] -- { label: "Bridge 2"; } [ Island Kneiphof ]
[ North Bank ] -- { label: "Bridge 3"; } [ Island Lomse ]
[ South Bank ] -- { label: "Bridge 4"; } [ Island Kneiphof ]
[ South Bank ] -- { label: "Bridge 5"; } [ Island Kneiphof ]
[ South Bank ] -- { label: "Bridge 6"; } [ Island Lomse ]
[ Island Lomse ] -- { label: "Bridge 7"; } [ Island Kneiphof ]
`

console.log('Parsing graph...')
const parser = new Parser()
const graph = parser.parse(input)

console.log('\nEdges and their labels:')
for (const edge of graph.getEdges()) {
  const label = edge.getAttribute('label') || edge.label || '(no label)'
  console.log(`  ${edge.from.name} -> ${edge.to.name}: "${label}"`)
}

console.log('\nRunning layout...')
const layout = new LayoutEngine(graph)
layout.layout()

console.log('\nEdge cells with labels:')
let labelCount = 0
for (const [key, cell] of graph.cells) {
  if (cell.edge && cell.hasLabel()) {
    labelCount++
    console.log(`  Cell ${key}: edge ${cell.edge.from.name}->${cell.edge.to.name}, label="${cell.edge.label}"`)
  }
}
console.log(`Total cells with labels: ${labelCount}`)
