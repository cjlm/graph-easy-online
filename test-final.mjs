import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const engine = new PerlLayoutEngine({ boxart: false, debug: false })

console.log('Test 1: Simple chain')
console.log(await engine.convert('[Bonn] -> [Frankfurt] -> [Dresden]', 'ascii'))

console.log('\nTest 2: Seven Bridges (DOT format)')
const sevenBridges = `graph {
  A -- B
  A -- B
  A -- C
  A -- C
  A -- D
  B -- D
  C -- D
}`
console.log(await engine.convert(sevenBridges, 'ascii'))
