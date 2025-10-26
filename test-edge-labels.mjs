import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = '[ A ] -> [ B ] { label: "edge label"; }'

console.log('Testing edge labels...')
const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)

console.log(result)
