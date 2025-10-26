import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = `# The famous Seven Bridges problem solved by Euler
graph { flow: east; }

[ North Bank ] { fill: lightgreen; }
[ South Bank ] { fill: lightgreen; }
[ Island Kneiphof ] { fill: lightyellow; }
[ Island Lomse ] { fill: lightyellow; }

# Two bridges connecting North Bank to Kneiphof
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 1; }
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 2; }

# Two bridges connecting South Bank to Kneiphof
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 3; }
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 4; }

# One bridge connecting North to South via Lomse
[ North Bank ] -- [ Island Lomse ] { label: Bridge 5; }
[ Island Lomse ] -- [ South Bank ] { label: Bridge 6; }

# One bridge connecting Lomse to Kneiphof
[ Island Lomse ] -- [ Island Kneiphof ] { label: Bridge 7; }`

const parser = new Parser()
const graph = parser.parse(input)

const layoutEngine = new LayoutEngine(graph)
layoutEngine.layout()

console.log('\nNode positions:')
for (const node of graph.getNodes()) {
  console.log(`${node.name}: (${node.x}, ${node.y}) size ${node.cx}x${node.cy} rank ${node.rank}`)
}

console.log('\nEdges:')
const edges = graph.getEdges()
console.log(`Total edges: ${edges.length}`)
for (const edge of edges) {
  console.log(`  ${edge.from.name} -- ${edge.to.name}`)
}
