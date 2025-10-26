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

const engine = new PerlLayoutEngine({ boxart: false, debug: false })
await engine.convert(input, 'ascii')

// Access the graph after layout
const parser = new DotParser()
const graph = parser.parse(input)

// Manually run layout to inspect
import { RankAssigner } from './js-implementation/layout/RankAssigner.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const layoutEngine = new LayoutEngine(graph)
layoutEngine.layout()

console.log('\nNode positions after layout:')
for (const node of graph.getNodes()) {
  console.log(`${node.name}: (${node.x}, ${node.y}) size ${node.cx}x${node.cy} rank ${node.rank}`)
}
