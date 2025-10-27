import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

// Seven Bridges from the app
const input = `[ North Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ South Bank ] -- [ Island Kneiphof ]
[ North Bank ] -- [ Island Lomse ]
[ Island Lomse ] -- [ South Bank ]
[ Island Lomse ] -- [ Island Kneiphof ]`

console.log('Seven Bridges of Königsberg\n')
console.log('Input:')
console.log(input)
console.log('\n' + '='.repeat(80))
console.log('TypeScript Output:')
console.log('='.repeat(80))

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)
console.log(result)

console.log('\n' + '='.repeat(80))
console.log('Now run the Perl version to compare...')
console.log('='.repeat(80))
