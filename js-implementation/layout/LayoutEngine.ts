/**
 * LayoutEngine - Main layout orchestrator
 *
 * Based on Graph::Easy::Layout::layout()
 *
 * Phases:
 * 1. Assign ranks (topological sort)
 * 2. Find chains (longest paths)
 * 3. Build action stack
 * 4. Execute actions with backtracking
 * 5. Optimize layout
 */

import { Graph } from '../core/Graph.ts'
import { Cell } from '../core/Cell.ts'
import { RankAssigner } from './RankAssigner.ts'
import { ChainDetector } from './ChainDetector.ts'
import { ActionStackBuilder } from './ActionStackBuilder.ts'
import { NodePlacer } from './NodePlacer.ts'
import { Scout } from './Scout.ts'
import { Action, ActionType } from './Action.ts'

export class LayoutEngine {
  private graph: Graph
  private maxTries: number

  constructor(graph: Graph) {
    this.graph = graph
    this.maxTries = 16 // Maximum backtracking attempts
  }

  /**
   * Main layout method
   *
   * Returns: layout score
   */
  layout(): number {
    console.log('🎯 Starting layout...')

    // Phase 1: Assign ranks
    console.log('📊 Phase 1: Assigning ranks...')
    const rankAssigner = new RankAssigner(this.graph)
    rankAssigner.assignRanks()

    // Debug: log ranks
    for (const node of this.graph.getNodes()) {
      console.log(`  ${node.name}: rank ${node.rank}`)
    }

    // Phase 2: Find chains
    console.log('🔗 Phase 2: Finding chains...')
    const chainDetector = new ChainDetector(this.graph)
    const chains = chainDetector.findChains()

    console.log(`  Found ${chains.length} chains:`)
    for (const chain of chains) {
      console.log(`    ${chain.toString()}`)
    }

    // Phase 3: Build action stack
    console.log('📝 Phase 3: Building action stack...')
    const stackBuilder = new ActionStackBuilder(this.graph, chains)
    const actions = stackBuilder.buildStack()

    console.log(`  Created ${actions.length} actions`)

    // Phase 4: Execute with backtracking
    console.log('⚡ Phase 4: Executing actions...')
    const score = this.executeActions(actions)

    console.log(`✅ Layout complete. Score: ${score}`)

    return score
  }

  /**
   * Execute actions with backtracking
   */
  private executeActions(actions: Action[]): number {
    const todo = [...actions]
    const done: Action[] = []
    let tries = this.maxTries
    let score = 0

    const nodePlacer = new NodePlacer(this.graph)
    const scout = new Scout(this.graph, false)  // A* pathfinding scout

    while (todo.length > 0 && tries > 0) {
      const action = todo.shift()!
      done.push(action)

      let result: number | null = null

      try {
        switch (action.type) {
          case ActionType.NODE:
            result = this.executeNodeAction(action, nodePlacer)
            break

          case ActionType.CHAIN:
            result = this.executeNodeAction(action, nodePlacer)
            // After placing chained node, route the edge from parent
            if (result !== null && action.parentEdge) {
              const edgeResult = this.executeTraceAction(
                { type: ActionType.TRACE, edge: action.parentEdge, tryCount: 0 },
                scout
              )
              if (edgeResult !== null) {
                result += edgeResult
              }
            }
            break

          case ActionType.TRACE:
            result = this.executeTraceAction(action, scout)
            break

          default:
            console.warn(`Unknown action type: ${action.type}`)
            result = 0
        }
      } catch (error) {
        console.error(`Action failed: ${error}`)
        result = null
      }

      if (result === null) {
        // Action failed
        console.log(`  ❌ Action failed: ${this.actionToString(action)} (try ${action.tryCount + 1})`)

        if (action.type === ActionType.NODE || action.type === ActionType.CHAIN) {
          // Undo node placement
          if (action.node) {
            nodePlacer.removeNode(action.node)
          }

          // Retry with incremented try count
          action.tryCount++
          todo.unshift(action)
        }

        tries--
      } else {
        // Action succeeded
        console.log(`  ✅ ${this.actionToString(action)} (score +${result})`)
        score += result
      }
    }

    if (tries === 0) {
      console.warn('⚠️  Reached maximum backtracking attempts')
    }

    return score
  }

  /**
   * Execute node placement action
   */
  private executeNodeAction(action: Action, placer: NodePlacer): number | null {
    if (!action.node) {
      throw new Error('Node action missing node')
    }

    const success = placer.placeNode(
      action.node,
      action.tryCount,
      action.parent,
      action.parentEdge
    )

    return success ? 0 : null
  }

  /**
   * Execute edge routing action
   */
  private executeTraceAction(action: Action, scout: Scout): number | null {
    if (!action.edge) {
      throw new Error('Trace action missing edge')
    }

    try {
      const path = scout.findPath(action.edge)

      if (path.length === 0) {
        return null // No path found
      }

      // Create cells for the path
      let pathScore = path.length

      for (const pathCell of path) {
        const cell = Cell.createEdgeCell(pathCell.x, pathCell.y, action.edge, pathCell.type)

        // Check if crossing existing edge
        const key = `${pathCell.x},${pathCell.y}`
        const existing = this.graph.cells.get(key)
        if (existing && existing.edge && existing.edge !== action.edge) {
          pathScore += 3 // Crossing penalty
        }

        this.graph.cells.set(key, cell)
      }

      return pathScore
    } catch (error) {
      console.error(`Edge routing failed: ${error}`)
      return null
    }
  }

  /**
   * Convert action to string for logging
   */
  private actionToString(action: Action): string {
    switch (action.type) {
      case ActionType.NODE:
        return `Place ${action.node?.name}`
      case ActionType.CHAIN:
        return `Chain ${action.node?.name} after ${action.parent?.name}`
      case ActionType.TRACE:
        return `Route ${action.edge?.from.name} -> ${action.edge?.to.name}`
      default:
        return `Unknown action`
    }
  }

  /**
   * Get the bounds of the layout
   */
  getBounds(): { minX: number; minY: number; maxX: number; maxY: number } {
    let minX = Infinity
    let minY = Infinity
    let maxX = -Infinity
    let maxY = -Infinity

    for (const cell of this.graph.cells.values()) {
      minX = Math.min(minX, cell.x)
      minY = Math.min(minY, cell.y)
      maxX = Math.max(maxX, cell.x)
      maxY = Math.max(maxY, cell.y)
    }

    return { minX, minY, maxX, maxY }
  }
}
