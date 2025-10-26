import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const engine = new PerlLayoutEngine({ boxart: false, debug: false })

console.log('=== Test 1: Simple Chain ===')
const chain = await engine.convert('[A] -> [B] -> [C]', 'ascii')
console.log(chain)

console.log('\n=== Test 2: Diamond ===')
const diamond = `graph {
  A -- B
  A -- C
  B -- D
  C -- D
}`
console.log(await engine.convert(diamond, 'ascii'))

console.log('\n=== Test 3: Star (multi-edges from center) ===')
const star = `graph {
  Center -- A
  Center -- B
  Center -- C
  Center -- D
}`
console.log(await engine.convert(star, 'ascii'))

console.log('\n=== Test 4: Parallel edges ===')
const parallel = `graph {
  A -- B
  A -- B
  A -- B
}`
console.log(await engine.convert(parallel, 'ascii'))

console.log('\n=== Test 5: Complex (Seven Bridges) ===')
const complex = `graph {
  A -- B
  A -- B
  A -- C
  A -- C
  A -- D
  B -- D
  C -- D
}`
console.log(await engine.convert(complex, 'ascii'))

console.log('\nAll tests completed!')
