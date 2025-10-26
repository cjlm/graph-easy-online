import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = '[ A ] -> [ X1 ] -> [ X2 ] -> [ X3 ] -> [ B ] { label: "test"; }'

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)

console.log(result)
