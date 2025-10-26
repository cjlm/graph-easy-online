import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

console.log('Testing OLD syntax (label after second node)...\n')

const input = '[ A ] -- [ B ] { label: "test"; }'

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)

console.log('Input:', input)
console.log('\nOutput:')
console.log(result)
