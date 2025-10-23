import { GraphEasyASCII } from './js-implementation/GraphEasyASCII'

const converter = await GraphEasyASCII.create({ debug: true })

const input = `graph { flow: south; }
[A] -> [B]`

console.log('Input:', input)
console.log()

try {
  const output = await converter.convert(input)
  console.log('Output length:', output.length)
  console.log('Output:', output)
} catch (error) {
  console.error('Error:', error)
}
