import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

console.log('Testing simple edge label...\n')

const input = '[ A ] -- { label: "test"; } [ B ]'

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)

console.log('Input:', input)
console.log('\nOutput:')
console.log(result)
