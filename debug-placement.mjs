import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = `graph {
  [ A ] -- [ B ]
  [ A ] -- [ B ]
  [ A ] -- [ C ]
  [ A ] -- [ C ]
  [ A ] -- [ D ]
  [ B ] -- [ D ]
  [ C ] -- [ D ]
}`

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input, 'ascii')

// Debug: print node positions
const parser = await import('./js-implementation/parser/Parser.ts')
const p = new parser.Parser()
const graph = p.parse(input)

const layoutEngine = await import('./js-implementation/layout/LayoutEngine.ts')
const layout = new layoutEngine.LayoutEngine(graph)
layout.layout()

console.log('\nNode positions:')
for (const node of graph.getNodes()) {
  console.log(`  ${node.name}: (${node.x}, ${node.y}) size ${node.cx}x${node.cy}`)
}

console.log('\nCells:')
for (const [key, cell] of graph.cells) {
  if (cell.node) {
    console.log(`  ${key}: node ${cell.node.name}`)
  } else if (cell.edge) {
    console.log(`  ${key}: edge`)
  }
}

console.log('\n' + result)
