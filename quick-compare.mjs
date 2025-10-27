import { PerlLayoutEngine } from './js-implementation/PerlLayoutEngine.ts'

const tests = {
  'Simple Flow': `[ Berlin ] -> [ Frankfurt ]
[ Frankfurt ] -> [ Dresden ]`,

  'Complex Graph': `[ Bonn ] -> [ Berlin ]
[ Bonn ] -> [ Frankfurt ]
[ Frankfurt ] -> [ Berlin ]
[ Berlin ] -> [ Dresden ]
[ Dresden ] -> [ Frankfurt ]`,

  'Network Topology': `[ Internet ] ==> [ Firewall ]
[ Firewall ] ==> [ Router ]
[ Router ] ==> [ Switch ]
[ Switch ] -> [ Server 1 ]
[ Switch ] -> [ Server 2 ]
[ Switch ] -> [ Workstation A ]
[ Switch ] -> [ Workstation B ]
[ Switch ] -> [ Workstation C ]
[ Server 1 ] <-> [ Server 2 ]`
}

const engine = new PerlLayoutEngine({ debug: false })

for (const [name, input] of Object.entries(tests)) {
  console.log('\n' + '='.repeat(80))
  console.log(`📊 ${name}`)
  console.log('='.repeat(80))

  try {
    const result = await engine.convert(input)
    console.log(result)
  } catch (e) {
    console.log('❌ ERROR:', e.message)
  }
}
