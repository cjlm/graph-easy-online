/**
 * Analyze the Bridges graph structure
 */

import { Parser } from '../js-implementation/parser/Parser.ts'

const BRIDGES_EXAMPLE = `# The famous Seven Bridges problem solved by Euler
graph { flow: east; }

[ North Bank ] { fill: lightgreen; }
[ South Bank ] { fill: lightgreen; }
[ Island Kneiphof ] { fill: lightyellow; }
[ Island Lomse ] { fill: lightyellow; }

[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 1; }
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 2; }
[ North Bank ] -- [ Island Lomse ] { label: Bridge 3; }
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 4; }
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 5; }
[ South Bank ] -- [ Island Lomse ] { label: Bridge 6; }
[ Island Kneiphof ] -- [ Island Lomse ] { label: Bridge 7; }`

const parser = new Parser()
const graph = parser.parse(BRIDGES_EXAMPLE)

const nodes = graph.getNodes()
const edges = graph.getEdges()

console.log('📊 Graph Analysis:\n')
console.log(`Nodes: ${nodes.length}`)
console.log(`Edges: ${edges.length}`)
console.log(`Flow: ${graph.getAttribute('flow')}`)
console.log()

console.log('Node names:')
nodes.forEach(n => console.log(`  - ${n.name}`))
console.log()

console.log('Edge structure:')
const edgeGroups = new Map()
edges.forEach(edge => {
  const key = `${edge.from.name} -- ${edge.to.name}`
  if (!edgeGroups.has(key)) {
    edgeGroups.set(key, [])
  }
  edgeGroups.get(key).push(edge.label || 'no label')
})

edgeGroups.forEach((labels, key) => {
  console.log(`  ${key}: ${labels.length} edge(s) [${labels.join(', ')}]`)
})
