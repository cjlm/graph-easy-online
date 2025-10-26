import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'
import { AsciiRendererSimple } from './js-implementation/renderers/AsciiRendererSimple.ts'

const input = `
[ North Bank ] -- { label: "Bridge 1"; } [ Island Kneiphof ]
[ North Bank ] -- { label: "Bridge 2"; } [ Island Kneiphof ]
[ South Bank ] -- { label: "Bridge 3"; } [ Island Kneiphof ]
[ South Bank ] -- { label: "Bridge 4"; } [ Island Kneiphof ]
[ North Bank ] -- { label: "Bridge 5"; } [ Island Lomse ]
[ Island Lomse ] -- { label: "Bridge 6"; } [ South Bank ]
[ Island Lomse ] -- { label: "Bridge 7"; } [ Island Kneiphof ]
`

console.log('Parsing graph...')
const parser = new Parser()
const graph = parser.parse(input)

console.log('\n=== All Edges ===')
for (const edge of graph.getEdges()) {
  const label = edge.label || '(none)'
  console.log(`  ${edge.from.name} -> ${edge.to.name}: label="${label}"`)
}

console.log('\n=== Running Layout ===')
const layout = new LayoutEngine(graph)
layout.layout()

console.log('\n=== Node Positions ===')
for (const node of graph.getNodes()) {
  console.log(`  ${node.name}: (${node.x}, ${node.y})`)
}

console.log('\n=== Cells with Labels ===')
for (const [key, cell] of graph.cells) {
  if (cell.hasLabel() && cell.edge) {
    const label = cell.edge.label || '(none)'
    console.log(`  Cell ${key}: ${cell.edge.from.name} -> ${cell.edge.to.name}, label="${label}"`)
  }
}

console.log('\n=== Rendering ===')
const renderer = new AsciiRendererSimple(graph)
const output = renderer.render()
console.log(output)
