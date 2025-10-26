import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = `[ Root ] -> [ A ]
[ Root ] -> [ B ]
[ Root ] -> [ C ]
[ A ] -> [ A1 ]
[ A ] -> [ A2 ]`

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)

console.log(result)
