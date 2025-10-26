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

console.log('\nEdges in graph:')
for (const edge of graph.getEdges()) {
  console.log(`  ${edge.from.name} -> ${edge.to.name} (ID: ${edge.id})`)
}

console.log('\nNode edge counts:')
for (const node of graph.getNodes()) {
  const edges = node.edges()
  console.log(`  ${node.name}: ${edges.length} edges`)
  for (const edge of edges) {
    console.log(`    ${edge.from.name} -> ${edge.to.name}`)
  }
}
