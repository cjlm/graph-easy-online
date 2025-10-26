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

const engine = new PerlLayoutEngine({ debug: true })
const result = await engine.convert(input)

console.log('\n=== OUTPUT ===')
console.log(result)
