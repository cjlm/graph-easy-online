import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = '[ Bonn ] -> [ Frankfurt ] -> [ Dresden ]'

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)

console.log(result)
