import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

// Simple vertical edge test
const input = `[ A ]
[ B ]`

console.log('Testing vertical edge...')
const engine = new PerlLayoutEngine({ debug: true })
const result = await engine.convert(input)

console.log('\n=== OUTPUT ===')
console.log(result)
