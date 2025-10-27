import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = `[ A ] -- [ B ]
[ A ] -- [ B ]`

console.log('Testing multi-edge layout\n')
console.log('Input:')
console.log(input)
console.log('\nOutput:')

const engine = new PerlLayoutEngine({ debug: true })
const result = await engine.convert(input)
console.log('\nFinal result:')
console.log(result)
