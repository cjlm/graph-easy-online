import { Parser } from './js-implementation/parser/Parser.ts'
import { LayoutEngine } from './js-implementation/layout/LayoutEngine.ts'

const input = `[ Root ] -> [ A ]
[ Root ] -> [ B ]
[ Root ] -> [ C ]
[ A ] -> [ A1 ]`

console.log('Parsing...')
const parser = new Parser()
const graph = parser.parse(input)
console.log(`Parsed ${graph.getNodes().length} nodes`)

console.log('Starting layout...')
const layout = new LayoutEngine(graph)

// Set a timer to kill if it takes too long
const timer = setTimeout(() => {
  console.log('TIMEOUT after 3 seconds!')
  process.exit(1)
}, 3000)

try {
  const score = layout.layout()
  clearTimeout(timer)
  console.log(`Layout complete! Score: ${score}`)
} catch (e) {
  clearTimeout(timer)
  console.error('Error:', e.message)
  process.exit(1)
}
