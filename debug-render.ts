/**
 * Debug the rendering process
 */

import { GraphEasyASCII } from './js-implementation/GraphEasyASCII'

const converter = await GraphEasyASCII.create({ debug: false })
const input = '[A] -> [B] { label: MyLabel; }'

console.log('Input:', input)

const output = await converter.convert(input)

console.log('Output length:', output.length)
console.log('Output contains "MyLabel":', output.includes('MyLabel'))
console.log('Output contains "A":', output.includes('A'))
console.log('Output contains "B":', output.includes('B'))
console.log()

// Show first 50 lines
const lines = output.split('\n')
console.log(`First 50 lines (of ${lines.length} total):`)
for (let i = 0; i < Math.min(50, lines.length); i++) {
  console.log(`${i.toString().padStart(3)}: ${lines[i]}`)
}
