import { Parser } from './js-implementation/parser/Parser'
import { renderAscii } from './js-implementation/renderers/AsciiRenderer'

const parser = new Parser()

const input = `graph { flow: south; }
[A] -> [B]`

console.log('Parsing:', input)
const graph = parser.parse(input)
console.log('Parsed! Nodes:', graph.getNodes().length)

const layout = await graph.layout()
console.log('Layout computed! Bounds:', layout.bounds)
console.log('Node layouts:', layout.nodes)
console.log('Edge layouts:', layout.edges)

const ascii = renderAscii(layout)
console.log('ASCII length:', ascii.length)
console.log('ASCII output:')
console.log(ascii)
console.log('---END---')
