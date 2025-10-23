import { GraphEasyASCII } from './js-implementation/GraphEasyASCII'

const converter = await GraphEasyASCII.create({ debug: false })

const input = `graph { flow: south; }
[A] -> [B]`

console.log('1. Parsing...')
const graph = converter.parse(input)
console.log('   Nodes:', graph.getNodes().length)
console.log('   Edges:', graph.getEdges().length)
console.log('   Flow attr:', graph.getAttribute('flow'))

console.log('\n2. Layout...')
const layout = await graph.layout()
console.log('   Layout nodes:', layout.nodes.length)
console.log('   Layout edges:', layout.edges.length)
console.log('   Bounds:', layout.bounds)

console.log('\n3. Rendering...')
const { renderAscii } = await import('./js-implementation/renderers/AsciiRenderer.js')
const output = renderAscii(layout)
console.log('   Output length:', output.length)
console.log('   Output:')
console.log(output)
