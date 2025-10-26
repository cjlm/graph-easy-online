import { Graph } from './js-implementation/core/Graph.ts'
import { Node } from './js-implementation/core/Node.ts'
import { Cell } from './js-implementation/core/Cell.ts'
import { AsciiRendererNew } from './js-implementation/renderers/AsciiRendererNew.ts'

const graph = new Graph()
graph.cells = new Map()

const nodeA = new Node('A')
nodeA.x = 0
nodeA.y = 0
nodeA.cx = 1
nodeA.cy = 1

const nodeB = new Node('B')
nodeB.x = 2
nodeB.y = 0
nodeB.cx = 1
nodeB.cy = 1

graph.addNode(nodeA)
graph.addNode(nodeB)

// Add cells
const cellA = new Cell(0, 0)
cellA.node = nodeA
graph.cells.set('0,0', cellA)

const cellB = new Cell(2, 0)
cellB.node = nodeB
graph.cells.set('2,0', cellB)

const renderer = new AsciiRendererNew(graph, { boxart: false })
console.log(renderer.render())
