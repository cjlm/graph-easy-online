import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const tests = [
  {
    name: 'Linear chain',
    input: '[ A ] -> [ B ] -> [ C ] -> [ D ]',
    description: 'Simple linear chain, should be horizontal'
  },
  {
    name: 'Y-shaped',
    input: '[ A ] -> [ B ]\n[ A ] -> [ C ]',
    description: 'One source, two targets'
  },
  {
    name: 'Inverted Y',
    input: '[ A ] -> [ C ]\n[ B ] -> [ C ]',
    description: 'Two sources, one target'
  },
  {
    name: 'Diamond',
    input: '[ A ] -> [ B ]\n[ A ] -> [ C ]\n[ B ] -> [ D ]\n[ C ] -> [ D ]',
    description: 'Classic diamond shape'
  },
  {
    name: 'Simple cycle',
    input: '[ A ] -> [ B ] -> [ C ] -> [ A ]',
    description: 'Three-node cycle'
  },
  {
    name: 'Multi-edge',
    input: '[ A ] -> [ B ]\n[ A ] -> [ B ]\n[ A ] -> [ B ]',
    description: 'Multiple edges between same nodes'
  },
  {
    name: 'Self-loop',
    input: '[ A ] -> [ A ]',
    description: 'Node with self-loop'
  },
  {
    name: 'Binary tree',
    input: '[ Root ] -> [ L ]\n[ Root ] -> [ R ]\n[ L ] -> [ L1 ]\n[ L ] -> [ L2 ]\n[ R ] -> [ R1 ]\n[ R ] -> [ R2 ]',
    description: 'Binary tree structure'
  }
]

console.log('Testing graph patterns...\n')

for (const test of tests) {
  console.log('='.repeat(70))
  console.log(`Test: ${test.name}`)
  console.log(`Description: ${test.description}`)
  console.log('='.repeat(70))

  try {
    const engine = new PerlLayoutEngine({ debug: false })
    const result = await engine.convert(test.input)
    console.log(result)
    console.log()
  } catch (e) {
    console.log('❌ ERROR:', e.message)
    console.log()
  }
}

console.log('='.repeat(70))
console.log('All tests completed!')
