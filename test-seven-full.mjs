import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = `graph { flow: east; }

[ North Bank ] -- { label: Bridge 1; } [ Island Kneiphof ]
[ North Bank ] -- { label: Bridge 2; } [ Island Kneiphof ]
[ South Bank ] -- { label: Bridge 3; } [ Island Kneiphof ]
[ South Bank ] -- { label: Bridge 4; } [ Island Kneiphof ]
[ North Bank ] -- { label: Bridge 5; } [ Island Lomse ]
[ Island Lomse ] -- { label: Bridge 6; } [ South Bank ]
[ Island Lomse ] -- { label: Bridge 7; } [ Island Kneiphof ]`

console.log('Seven Bridges with flow:east and labels\n')
console.log('TypeScript Output:')
console.log('='.repeat(80))

const engine = new PerlLayoutEngine({ debug: false })
const result = await engine.convert(input)
console.log(result)
