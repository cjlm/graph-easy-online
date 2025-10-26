import { Parser } from './js-implementation/parser/Parser.ts'
import { RankAssigner } from './js-implementation/layout/RankAssigner.ts'
import { ChainDetector } from './js-implementation/layout/ChainDetector.ts'
import { ActionStackBuilder } from './js-implementation/layout/ActionStackBuilder.ts'
import { NodePlacer } from './js-implementation/layout/NodePlacerNew.ts'

const input = `[ Root ] -> [ A ]
[ Root ] -> [ B ]
[ Root ] -> [ C ]
[ A ] -> [ A1 ]`

const parser = new Parser()
const graph = parser.parse(input)

const rankAssigner = new RankAssigner(graph)
rankAssigner.assignRanks()

const chainDetector = new ChainDetector(graph)
const chains = chainDetector.findChains()

console.log('Chains:')
for (const chain of chains) {
  console.log('  ' + chain.toString())
}

const stackBuilder = new ActionStackBuilder(graph, chains)
const actions = stackBuilder.buildStack()

console.log('\nActions:')
for (const action of actions) {
  const desc = action.node ? action.node.name : (action.edge.from.name + '->' + action.edge.to.name)
  console.log('  ' + action.type + ': ' + desc)
}

console.log('\nPlacing nodes...')
const nodePlacer = new NodePlacer(graph)

let count = 0
for (const action of actions) {
  if (action.type === 0 || action.type === 2) {  // NODE or CHAIN
    console.log(count + '. Placing ' + action.node.name + '...')
    const success = nodePlacer.placeNode(action.node, 0, action.parent, action.parentEdge)
    console.log('   Result: ' + success + ', position: (' + action.node.x + ', ' + action.node.y + ')')
    count++

    if (count > 10) {
      console.log('Stopping after 10 placements')
      break
    }
  }
}

console.log('\nFinal positions:')
for (const node of graph.getNodes()) {
  console.log('  ' + node.name + ': (' + node.x + ', ' + node.y + ')')
}
