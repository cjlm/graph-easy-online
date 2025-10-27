import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'
import { AsciiRendererConnected } from './js-implementation/renderers/AsciiRendererConnected.ts'

const input = `graph { flow: east; }

[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Lomse ]
[ Island Lomse ] -- [ South Bank ]
[ Island Lomse ] -- [ Island Kneiphof ]`

console.log('Parsing...')
const parser = new Parser()
const graph = parser.parse(input)

console.log(`\nNodes: ${graph.getNodes().length}`)
for (const node of graph.getNodes()) {
  console.log(`  ${node.name}`)
}

console.log(`\nEdges: ${graph.getEdges().length}`)
for (const edge of graph.getEdges()) {
  console.log(`  ${edge.from.name} -- ${edge.to.name} (offset: ${edge.offset || 0})`)
}

console.log('\nLayingout (with debug)...')
const layoutEngine = new LayoutEngine(graph, true)
const score = layoutEngine.layout()

console.log(`\nLayout score: ${score}`)
console.log(`Total cells: ${graph.cells.size}`)

console.log('\nNode placements:')
for (const node of graph.getNodes()) {
  console.log(`  ${node.name}: (${node.x}, ${node.y}) cx=${node.cx} cy=${node.cy}`)
}

console.log('\nEdge cells:')
const edgeCells = []
for (const [key, cell] of graph.cells) {
  if (cell.edge) {
    edgeCells.push({ key, cell })
  }
}
console.log(`  Total edge cells: ${edgeCells.length}`)

// Group by edge
const byEdge = new Map()
for (const { key, cell } of edgeCells) {
  const edgeKey = `${cell.edge.from.name}->${cell.edge.to.name}`
  if (!byEdge.has(edgeKey)) {
    byEdge.set(edgeKey, [])
  }
  byEdge.get(edgeKey).push({ key, cell })
}

for (const [edgeKey, cells] of byEdge) {
  console.log(`\n  ${edgeKey}: ${cells.length} cells`)
  for (const { key, cell } of cells) {
    console.log(`    ${key} type=${cell.type & 0xFF}`)
  }
}

console.log('\nRendering...')
const renderer = new AsciiRendererConnected(graph)
const ascii = renderer.render()

console.log('\n' + '='.repeat(80))
console.log(ascii)
console.log('='.repeat(80))
