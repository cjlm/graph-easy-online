import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

console.log('Testing edge label with longer edge...\n')

const input = '[ Start ] -> [ Middle ] -> { label: "done"; } [ End ]'

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)

console.log('Input:', input)
console.log('\nOutput:')
console.log(result)
