import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = `# The famous Seven Bridges problem solved by Euler
graph { flow: east; }

[ North Bank ] { fill: lightgreen; }
[ South Bank ] { fill: lightgreen; }
[ Island Kneiphof ] { fill: lightyellow; }
[ Island Lomse ] { fill: lightyellow; }

# Two bridges connecting North Bank to Kneiphof
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 1; }
[ North Bank ] -- [ Island Kneiphof ] { label: Bridge 2; }

# Two bridges connecting South Bank to Kneiphof
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 3; }
[ South Bank ] -- [ Island Kneiphof ] { label: Bridge 4; }

# One bridge connecting North to South via Lomse
[ North Bank ] -- [ Island Lomse ] { label: Bridge 5; }
[ Island Lomse ] -- [ South Bank ] { label: Bridge 6; }

# One bridge connecting Lomse to Kneiphof
[ Island Lomse ] -- [ Island Kneiphof ] { label: Bridge 7; }`

const engine = new PerlLayoutEngine({ boxart: false, debug: false })
console.log('TypeScript output:')
const result = await engine.convert(input, 'ascii')
console.log(result)
console.log('\n' + '='.repeat(60))
console.log('Expected: Clean layout with proper edge separation')
