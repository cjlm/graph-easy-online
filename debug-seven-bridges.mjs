import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'
import { DotParser } from './js-implementation/parser/DotParser.ts'

const input = `graph {
  A -- B
  A -- B
  A -- C
  A -- C
  A -- D
  B -- D
  C -- D
}`

const parser = new DotParser()
const graph = parser.parse(input)

console.log('Nodes:', graph.getNodes().length)
console.log('Edges:', graph.getEdges().length)

for (const node of graph.getNodes()) {
  console.log(`\nNode ${node.name}:`)
  console.log(`  Rank: ${node.rank}`)
  console.log(`  Position: (${node.x}, ${node.y})`)
  console.log(`  Size: ${node.cx} x ${node.cy}`)

  const edges = node.edges()
  console.log(`  Edges: ${edges.length}`)
  for (const edge of edges) {
    console.log(`    ${edge.from.name} -- ${edge.to.name}`)
  }
}

const engine = new PerlLayoutEngine({ boxart: false, debug: false })
console.log('\nLayout output:')
const result = await engine.convert(input, 'ascii')
console.log(result)
