import { GraphEasyASCII } from './js-implementation/GraphEasyASCII'

const converter = await GraphEasyASCII.create()
const output = await converter.convert('[A] -> [B] { label: TestLabel; }')
console.log('Contains TestLabel:', output.includes('TestLabel'))
console.log('Contains A:', output.includes('A'))
console.log('Contains B:', output.includes('B'))
console.log('\nOutput:')
console.log(output)
