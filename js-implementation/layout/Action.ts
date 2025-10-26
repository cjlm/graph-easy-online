/**
 * Action - Represents an action to be executed during layout
 *
 * Based on Graph::Easy::Layout action constants
 */

import { Node } from '../core/Node.ts'
import { Edge } from '../core/Edge.ts'

/**
 * Action types (from Perl constants)
 */
export enum ActionType {
  NODE = 0,    // Place a node somewhere
  TRACE = 1,   // Trace path from source to destination
  CHAIN = 2,   // Place node in chain (with parent)
  EDGES = 3,   // Trace all edges (shortest connection first)
  SPLICE = 4,  // Splice in group fillers
}

/**
 * Action interface
 */
export interface Action {
  /** Type of action */
  type: ActionType

  /** Node to place (for NODE and CHAIN actions) */
  node?: Node

  /** Edge to route (for TRACE actions) */
  edge?: Edge

  /** Parent node (for CHAIN actions) */
  parent?: Node

  /** Edge connecting to parent (for CHAIN actions) */
  parentEdge?: Edge

  /** Number of times this action has been tried (for backtracking) */
  tryCount: number

  /** Distance hint (for node placement near parent) */
  distance?: number
}

/**
 * Create a NODE action
 */
export function createNodeAction(node: Node): Action {
  return {
    type: ActionType.NODE,
    node,
    tryCount: 0,
  }
}

/**
 * Create a CHAIN action (place node relative to parent)
 */
export function createChainAction(
  node: Node,
  parent: Node,
  parentEdge: Edge,
  distance: number = 2
): Action {
  return {
    type: ActionType.CHAIN,
    node,
    parent,
    parentEdge,
    distance,
    tryCount: 0,
  }
}

/**
 * Create a TRACE action (route an edge)
 */
export function createTraceAction(edge: Edge): Action {
  return {
    type: ActionType.TRACE,
    edge,
    tryCount: 0,
  }
}
