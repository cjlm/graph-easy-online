import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = `[ Root ] -> [ A ]
[ Root ] -> [ B ]
[ A ] -> [ A1 ]`

const engine = new PerlLayoutEngine({ debug: true })
const result = await engine.convert(input)

console.log('\n=== OUTPUT ===')
console.log(result)
