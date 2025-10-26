import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const engine = new PerlLayoutEngine({ boxart: false, debug: false })

// Test the exact same input the user is testing
const input = '[Bonn] -> [Frankfurt] -> [Dresden]'
console.log('Input:', input)
console.log('Output:')
const result = await engine.convert(input, 'ascii')
console.log(result)
console.log('\n---')
console.log('Character analysis:')
const lines = result.split('\n')
lines.forEach((line, i) => {
  console.log(`Line ${i}: "${line}" (length: ${line.length})`)
  for (let j = 0; j < line.length; j++) {
    if (line[j] !== ' ') {
      console.log(`  [${j}] = '${line[j]}'`)
    }
  }
})
