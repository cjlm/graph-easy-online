import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const input = `# The famous Seven Bridges problem solved by Euler
graph { flow: east; }

[ North Bank ] { fill: lightgreen; }
[ South Bank ] { fill: lightgreen; }
[ Island Kneiphof ] { fill: lightyellow; }
[ Island Lomse ] { fill: lightyellow; }

# Two bridges connecting North Bank to Kneiphof
[ North Bank ] -- { label: "Bridge 1"; } [ Island Kneiphof ]
[ North Bank ] -- { label: "Bridge 2"; } [ Island Kneiphof ]

# Two bridges connecting South Bank to Kneiphof
[ South Bank ] -- { label: "Bridge 3"; } [ Island Kneiphof ]
[ South Bank ] -- { label: "Bridge 4"; } [ Island Kneiphof ]

# One bridge connecting North to South via Lomse
[ North Bank ] -- { label: "Bridge 5"; } [ Island Lomse ]
[ Island Lomse ] -- { label: "Bridge 6"; } [ South Bank ]

# One bridge connecting Lomse to Kneiphof
[ Island Lomse ] -- { label: "Bridge 7"; } [ Island Kneiphof ]`

const engine = new PerlLayoutEngine({ boxart: false, debug: false })
console.log('TypeScript output:')
const result = await engine.convert(input, 'ascii')
console.log(result)
console.log('\n' + '='.repeat(60))
console.log('Expected: Clean layout with proper edge separation')
