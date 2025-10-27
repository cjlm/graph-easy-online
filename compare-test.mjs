import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const testCases = [
  {
    name: 'Linear chain',
    input: '[ A ] -> [ B ] -> [ C ] -> [ D ]'
  },
  {
    name: 'Diamond',
    input: '[ A ] -> [ B ]\n[ A ] -> [ C ]\n[ B ] -> [ D ]\n[ C ] -> [ D ]'
  },
  {
    name: 'Seven Bridges',
    input: `[ Altstadt-Loebenicht ] -- Kraemer Bridge -- [ Kneiphof ]
[ Altstadt-Loebenicht ] -- Schmiedebruecke -- [ Kneiphof ]
[ Kneiphof ] -- Holzbruecke -- [ Vorstadt-Haberberg ]
[ Kneiphof ] -- Honigbruecke -- [ Vorstadt-Haberberg ]
[ Altstadt-Loebenicht ] -- Hohe Bruecke -- [ Vorstadt-Haberberg ]
[ Altstadt-Loebenicht ] -- Koettelbruecke -- [ Vorstadt-Haberberg ]
[ Altstadt-Loebenicht ] -- Gruene Bruecke -- [ Lomse ]`
  }
]

console.log('🔍 Comparing TypeScript output\n')

for (const test of testCases) {
  console.log('='.repeat(80))
  console.log(`📊 ${test.name}`)
  console.log('='.repeat(80))
  console.log('Input:')
  console.log(test.input)
  console.log('\n--- TypeScript Output ---')

  try {
    const engine = new PerlLayoutEngine({ debug: false })
    const result = await engine.convert(test.input)
    console.log(result)
  } catch (e) {
    console.log('❌ ERROR:', e.message)
    if (e.stack) console.log(e.stack)
  }
  console.log()
}
