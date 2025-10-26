import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const tests = [
  { name: 'Simple chain', input: '[ A ] -> [ B ] -> [ C ]' },
  { name: 'Diamond', input: '[ A ] -> [ B ]\n[ A ] -> [ C ]\n[ B ] -> [ D ]\n[ C ] -> [ D ]' },
  { name: 'Tree', input: '[ Root ] -> [ A ]\n[ Root ] -> [ B ]\n[ Root ] -> [ C ]' },
  { name: 'Undirected', input: '[ A ] -- [ B ]' },
]

for (const test of tests) {
  console.log('\n' + '='.repeat(60))
  console.log('Test: ' + test.name)
  console.log('='.repeat(60))

  try {
    const engine = new PerlLayoutEngine({ debug: false })
    const result = await engine.convert(test.input)
    console.log(result)
    console.log('✅ PASS')
  } catch (e) {
    console.log('❌ FAIL:', e.message)
  }
}

console.log('\n' + '='.repeat(60))
console.log('All tests completed!')
