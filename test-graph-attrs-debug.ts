import { GraphEasyASCII } from './js-implementation/GraphEasyASCII'

const converter = await GraphEasyASCII.create({ debug: false })

const input = `graph { flow: south; }
[A] -> [B]`

console.log('Input:', input)

try {
  const output = await converter.convert(input)
  console.log('Success! Output length:', output.length)
  if (output.length > 0) {
    console.log(output)
  }
} catch (error) {
  console.error('Convert() threw error:')
  console.error(error)
  console.error('\nStack:')
  console.error(error.stack)
}
