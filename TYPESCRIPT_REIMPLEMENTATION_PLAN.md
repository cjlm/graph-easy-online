# TypeScript Reimplementation Plan - Graph::Easy Layout Engine

## Project Overview

**Goal:** Reimplement Graph::Easy's state-of-the-art Perl layout algorithm in pure TypeScript

**Scope:**
- ✅ Parse Graph::Easy notation
- ✅ Implement Perl's Sugiyama-based layout algorithm
- ✅ Render ASCII output (boxart optional)
- ❌ NO SVG/HTML/other formats (out of scope)
- ❌ NO fallback to ELK or WebPerl (standalone implementation)

**Success Criteria:**
- Produces identical or near-identical ASCII output to Perl version
- Comprehensive test suite proving each component works
- No dependencies on ELK or WebPerl for layout/rendering
- UI toggle that fails gracefully when TS implementation can't handle input

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    TypeScript Implementation                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Parser (Graph::Easy notation)                              │
│         ↓                                                    │
│  Graph Data Model (Nodes, Edges, Attributes)                │
│         ↓                                                    │
│  Layout Engine                                               │
│    ├─ Phase 1: Rank Assignment (Topological Sort)          │
│    ├─ Phase 2: Chain Detection (Longest Paths)             │
│    ├─ Phase 3: Action Stack Building                       │
│    └─ Phase 4: Backtracking Execution                      │
│         ├─ Node Placement                                   │
│         ├─ Edge Routing (A* Pathfinding)                    │
│         └─ Grid Optimization                                │
│         ↓                                                    │
│  ASCII Renderer                                              │
│    ├─ Grid Sizing                                           │
│    ├─ Character Selection (ASCII vs Boxart)                │
│    └─ Text Output Generation                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 0: Project Setup & Infrastructure (1-2 days)

**Goal:** Set up testing framework and project structure

**Recommended Libraries:**
- ✅ **@datastructures-js/priority-queue** - For heap/priority queue (actively maintained, TypeScript support)
- ✅ **astar-typescript** OR **pathfinding** - For A* implementation (can customize or use as reference)
- ✅ **graphology** - Optional, for graph utilities (traversal, etc.)

**Tasks:**
1. Set up Vitest for unit testing
2. Create test fixtures (known input/output pairs from Perl)
3. Set up test runner with coverage reporting
4. Install recommended libraries:
   ```bash
   npm install @datastructures-js/priority-queue
   npm install astar-typescript  # or: pathfinding + @types/pathfinding
   npm install graphology graphology-types  # optional
   ```
5. Create directory structure:
   ```
   js-implementation/
   ├── core/
   │   ├── Graph.ts (existing)
   │   ├── Node.ts (existing)
   │   ├── Edge.ts (existing)
   │   └── Cell.ts (NEW - grid cell representation)
   ├── layout/
   │   ├── LayoutEngine.ts (NEW - main orchestrator)
   │   ├── RankAssigner.ts (NEW)
   │   ├── ChainDetector.ts (NEW)
   │   ├── NodePlacer.ts (NEW)
   │   ├── EdgeRouter.ts (NEW - A* implementation)
   │   └── GridOptimizer.ts (NEW)
   ├── renderer/
   │   ├── AsciiRenderer.ts (rewrite without ELK)
   │   └── GridSizer.ts (NEW)
   ├── parser/
   │   └── Parser.ts (existing, needs fixes)
   └── __tests__/
       ├── layout/
       ├── renderer/
       └── integration/
   ```

**Tests:**
- Build system works
- Test runner executes successfully
- Can load Perl test fixtures

**Success Criteria:**
- ✅ Tests run with `npm test`
- ✅ Coverage reporting enabled
- ✅ At least 10 Perl test fixtures loaded

---

### Phase 1: Core Data Structures (2-3 days)

**Goal:** Implement Cell class and grid representation

**Tasks:**

1. **Cell.ts** - Grid cell with edge type flags
   ```typescript
   class Cell {
     x: number
     y: number
     type: number  // EDGE_HOR, EDGE_VER, etc. with flags
     edge?: Edge   // Reference to edge if this is edge cell
     node?: Node   // Reference to node if this is node cell
     cx: number    // Column span
     cy: number    // Row span
     width: number  // Rendered width (characters)
     height: number // Rendered height (characters)
   }
   ```

2. **Edge Type Constants** (from Perl)
   ```typescript
   // Basic types
   const EDGE_HOR = 1
   const EDGE_VER = 2
   const EDGE_CROSS = 3
   const EDGE_N_E = 4
   const EDGE_N_W = 5
   const EDGE_S_E = 6
   const EDGE_S_W = 7
   // ... (see Perl constants)

   // Flags
   const EDGE_START_N = 0x100
   const EDGE_START_S = 0x200
   // ... (all start/end flags)

   // Masks
   const EDGE_TYPE_MASK = 0xFF
   const EDGE_FLAG_MASK = 0xFFFF00
   ```

3. **Update Graph.ts** to include:
   ```typescript
   class Graph {
     cells: Map<string, Cell>  // "x,y" => Cell
     chains: Chain[]
     rankPos: Map<number, { x: number; y: number }>
     rankCoord: 'x' | 'y'
     root?: Node
     score: number
   }
   ```

**Tests:**
- ✅ Cell creation with all properties
- ✅ Edge type constants work correctly
- ✅ Type and flag bit operations (masking, OR'ing)
- ✅ Grid coordinate key generation ("x,y")
- ✅ Cell insertion/retrieval from Graph.cells

**Success Criteria:**
- All cell operations tested
- Edge type system verified
- Grid storage working

---

### Phase 2: Rank Assignment (3-4 days)

**Goal:** Implement topological sorting and rank assignment (_assign_ranks)

**Tasks:**

1. **Use @datastructures-js/priority-queue** - No need to implement from scratch!
   ```typescript
   import { MinPriorityQueue } from '@datastructures-js/priority-queue'

   // Usage in rank assignment:
   const heap = new MinPriorityQueue<Node>({
     priority: (node) => Math.abs(node.rank || 0)
   })

   heap.enqueue(rootNode)
   while (!heap.isEmpty()) {
     const node = heap.dequeue().element
     // ... process node
   }
   ```

2. **RankAssigner.ts** - Rank assignment algorithm
   ```typescript
   class RankAssigner {
     assignRanks(graph: Graph): void {
       // 1. Create heap sorted by absolute rank
       // 2. Initialize root node with rank -1
       // 3. Process user-defined ranks (positive)
       // 4. Process auto-ranks (negative, topological order)
       // 5. Handle nodes with no incoming edges
     }
   }
   ```

**Algorithm Steps:**
1. Find root node (or nodes with no predecessors)
2. Create priority heap
3. Process nodes with explicit rank attributes (convert to positive ranks)
4. Process nodes without predecessors (assign auto-rank -1)
5. Iterate through heap:
   - Extract node
   - Assign next rank to all successors
   - Add successors to heap
6. Handle remaining unranked nodes

**Tests:**
- ✅ Simple linear graph: `[A] -> [B] -> [C]` (ranks: -1, -2, -3)
- ✅ Graph with user ranks: `[A] {rank: 1} -> [B] -> [C]` (ranks: 1, -1, -2)
- ✅ Multiple roots: `[A] -> [C], [B] -> [C]` (A and B both rank -1)
- ✅ Diamond graph: `[A] -> [B] -> [D], [A] -> [C] -> [D]`
- ✅ Cyclic graph handling (should not infinite loop)
- ✅ Compare output ranks with Perl version

**Success Criteria:**
- ✅ All test cases pass
- ✅ Ranks match Perl output for 20+ test graphs
- ✅ No infinite loops on cyclic graphs

---

### Phase 3: Chain Detection (4-5 days)

**Goal:** Implement chain finding and merging (_find_chains, _follow_chain)

**Tasks:**

1. **Chain.ts** - Chain data structure
   ```typescript
   class Chain {
     id: string
     start: Node
     end: Node
     nodes: Node[]
     length: number
     graph: Graph
     done: boolean

     addNode(node: Node): void
     merge(other: Chain, at: Node): void
     layout(): Action[]
   }
   ```

2. **ChainDetector.ts** - Chain finding algorithm
   ```typescript
   class ChainDetector {
     findChains(graph: Graph): Chain[]

     private followChain(startNode: Node, graph: Graph): Chain {
       // 1. Create new chain with start node
       // 2. Follow single successors forward
       // 3. When multiple successors found:
       //    - Recursively follow each
       //    - Merge longest chain back
       // 4. Detect and handle cycles
     }
   }
   ```

**Algorithm Steps:**
1. Iterate through all nodes (sorted by ID)
2. For each node not in a chain:
   - Start new chain
   - Follow forward while single successor exists
   - When multiple successors:
     - Recursively follow each
     - Find longest resulting chain
     - Merge that chain back into current
   - Terminate on cycles (node already in this chain)
3. Return all chains

**Tests:**
- ✅ Linear chain: `[A] -> [B] -> [C]` (1 chain of length 3)
- ✅ Branch: `[A] -> [B] -> [D], [B] -> [C]` (chain A-B-D, separate C)
- ✅ Multiple branches: `[A] -> [B], [A] -> [C], [A] -> [D]`
- ✅ Diamond (merge): `[A] -> [B] -> [D], [A] -> [C] -> [D]`
- ✅ Self-loop: `[A] -> [A]`
- ✅ Cycle: `[A] -> [B] -> [C] -> [A]`
- ✅ Compare chain count/length with Perl version

**Success Criteria:**
- ✅ All test cases pass
- ✅ Chain detection matches Perl for 30+ graphs
- ✅ No infinite loops on cycles

---

### Phase 4: Action Stack Building (2-3 days)

**Goal:** Build prioritized action list for backtracking execution

**Tasks:**

1. **Action.ts** - Action type definitions
   ```typescript
   enum ActionType {
     NODE = 0,    // Place node somewhere
     TRACE = 1,   // Trace path from src to dest
     CHAIN = 2,   // Place node in chain with parent
     EDGES = 3,   // Trace all edges
     SPLICE = 4   // Splice in group fillers (future)
   }

   interface Action {
     type: ActionType
     node?: Node
     edge?: Edge
     parent?: Node
     parentEdge?: Edge
     tryCount: number
   }
   ```

2. **ActionStackBuilder.ts**
   ```typescript
   class ActionStackBuilder {
     buildStack(graph: Graph, chains: Chain[]): Action[] {
       // 1. Add root node first
       // 2. Sort chains (root first, longest first, alphabetical)
       // 3. For each chain, call chain.layout()
       // 4. Add any remaining nodes/edges
       // 5. Return ordered action list
     }
   }
   ```

3. **Update Chain.layout()** to return actions:
   ```typescript
   layout(): Action[] {
     const actions: Action[] = []

     // Add first node
     actions.push({ type: NODE, node: this.start, tryCount: 0 })

     // Add chained nodes with parent reference
     let current = this.start.next
     let parent = this.start
     while (current) {
       actions.push({
         type: CHAIN,
         node: current,
         parent: parent,
         parentEdge: edgeBetween(parent, current),
         tryCount: 0
       })
       parent = current
       current = current.next
     }

     // Add direct chain edges
     // Add internal chain edges (sorted by distance)
     // Add self-loops

     return actions
   }
   ```

**Tests:**
- ✅ Simple chain produces correct action sequence
- ✅ Root node action comes first
- ✅ Chain nodes have parent references
- ✅ Edge actions come after node actions
- ✅ Self-loops appear last
- ✅ Action order matches Perl

**Success Criteria:**
- ✅ Action stack builds for all test graphs
- ✅ Order matches Perl implementation
- ✅ All action types generated correctly

---

### Phase 5: Node Placement (5-7 days)

**Goal:** Implement node placement algorithm (_find_node_place, _near_places, _clear_tries)

**Tasks:**

1. **NodePlacer.ts** - Node placement strategies
   ```typescript
   class NodePlacer {
     findNodePlace(
       node: Node,
       tryCount: number,
       parent?: Node,
       edge?: Edge
     ): boolean {
       // Try strategies in order:
       // 1. Rank-based placement (user-defined ranks)
       // 2. Parent-based placement (chained nodes)
       // 3. Shared edge placement
       // 4. Predecessor-based placement
       // 5. Successor-based placement
       // 6. Fallback: find first free position
     }

     private nearPlaces(
       node: Node,
       distance: number,
       flowDir: FlowDirection
     ): Position[] {
       // For single-cell nodes: 4 positions (R, D, L, U)
       // For multi-cell nodes: 2*(cx + cy) positions
       // Shuffle by flow direction preference
     }

     private clearTries(
       node: Node,
       candidates: Position[]
     ): Position[] {
       // Filter candidates that would place node too close
       // Allow parent/child exceptions
     }

     private tryPlaceAt(node: Node, x: number, y: number): boolean {
       // Check if position is free
       // Check if node fits (cx x cy)
       // Actually place node in graph.cells
     }
   }
   ```

2. **Placement Strategy Details:**

   **Strategy 1: Rank-based**
   - If node has user-defined rank (>= 0)
   - Use graph.rankPos[rank] as starting position
   - Try with increasing offsets if occupied

   **Strategy 2: Parent-based**
   - Get nearPlaces() around parent
   - Filter with clearTries()
   - Try each position

   **Strategy 3: Shared edge**
   - If node shares incoming/outgoing edge with others
   - If other shared node already placed
   - Place in same row/column with offset

   **Strategy 4: Predecessor-based**
   - 1 predecessor: near that node
   - 2 predecessors: try middle position or crossing point
   - 3+ predecessors: try near each with increasing distance

   **Strategy 5: Successor-based**
   - Similar to predecessor but with already-placed successors

   **Strategy 6: Fallback**
   - Start at (0, 0) or (predecessor.x, 0)
   - Find first free row/column
   - Place there

**Tests:**
- ✅ Place node at (0, 0) in empty graph
- ✅ Place second node with parent reference (distance 2)
- ✅ Place node with rank attribute at correct position
- ✅ Near places returns correct positions (4 for 1x1 node)
- ✅ Near places for multi-cell node (2x2) returns 8 positions
- ✅ Clear tries filters occupied positions
- ✅ Clear tries allows parent/child placements
- ✅ Shared edge placement works
- ✅ Crossing point calculation for 2 predecessors
- ✅ Fallback placement finds free space
- ✅ Integration: place entire chain correctly
- ✅ Compare final positions with Perl version

**Success Criteria:**
- ✅ All placement strategies tested
- ✅ Node positions match Perl for 50+ graphs
- ✅ No overlapping nodes
- ✅ Respects flow direction

---

### Phase 6: A* Edge Routing (7-10 days) ⭐ CRITICAL

**Goal:** Implement A* pathfinding for edge routing (_find_path, _astar)

**Tasks:**

1. **EdgeRouter.ts** - Main routing orchestrator
   ```typescript
   class EdgeRouter {
     findPath(
       source: Node,
       destination: Node,
       edge: Edge
     ): PathCell[] {
       // 1. Handle self-loops specially
       // 2. Try fast path (straight line)
       // 3. Try fast path (single bend)
       // 4. Fall back to A*
     }

     private findPathStraight(src: Node, dst: Node): PathCell[] | null
     private findPathSingleBend(src: Node, dst: Node): PathCell[] | null
     private findPathAstar(edge: Edge): PathCell[]
     private findPathLoop(node: Node, edge: Edge): PathCell[]
   }
   ```

2. **AStar.ts** - A* implementation (can use library or customize)

   **Option A: Use `astar-typescript` library** (recommended for MVP)
   ```typescript
   import { AStarFinder, Grid } from 'astar-typescript'

   // Adapt to our needs:
   class EdgeRouter {
     findPathAstar(edge: Edge): PathCell[] {
       // Convert graph.cells to Grid
       const grid = this.createGrid(graph)

       // Run A* with custom heuristic
       const finder = new AStarFinder({
         grid: grid,
         heuristic: this.manhattanDistance,
         weight: this.calculateModifier  // crossing penalty, etc.
       })

       const path = finder.findPath(
         { x: src.x, y: src.y },
         { x: dst.x, y: dst.y }
       )

       return this.convertToCells(path)
     }
   }
   ```

   **Option B: Custom implementation** (for full control)
   ```typescript
   import { MinPriorityQueue } from '@datastructures-js/priority-queue'

   interface AStarNode {
     x: number
     y: number
     g: number  // Cost from start
     h: number  // Heuristic to goal
     f: number  // g + h
     parent?: AStarNode
     type?: number  // Edge type at this position
   }

   class AStar {
     search(
       startPositions: Position[],
       goalPositions: Position[],
       edge: Edge,
       graph: Graph
     ): PathCell[] {
       const open = new MinPriorityQueue<AStarNode>({
         priority: (node) => node.f
       })

       // 1. Add start positions to open
       // 2. Main loop:
       //    - Extract lowest f-score from open
       //    - Check if goal reached
       //    - Get neighbors
       //    - Calculate costs with modifiers
       //    - Add to open if better path
       // 3. Backtrack to build path
       // 4. Straighten unnecessary bends
     }

     private manhattanDistance(
       x1: number, y1: number,
       x2: number, y2: number
     ): number {
       const dx = Math.abs(x2 - x1)
       const dy = Math.abs(y2 - y1)
       return dx + dy + (dx > 0 && dy > 0 ? 1 : 0)
     }

     private calculateModifier(
       x: number, y: number,
       parentX: number, parentY: number,
       edge: Edge,
       graph: Graph
     ): number {
       let cost = 1

       // Direction change penalty
       if (directionChanged(x, y, parentX, parentY)) {
         cost += 6
       }

       // Crossing penalty
       const cell = graph.cells.get(`${x},${y}`)
       if (cell && cell.edge && cell.edge !== edge) {
         cost += 30
       }

       return cost
     }

     private getNearNodes(
       x: number, y: number,
       closed: Set<string>
     ): Position[] {
       // Return 4 neighbors (up, down, left, right)
       // Filter out positions in closed set
       // Don't allow diagonal movement
     }

     private straightenPath(path: PathCell[]): PathCell[] {
       // Detect 3-bend sequences that create detours
       // 8 bend patterns from Perl
       // Replace with direct path if no obstacles
     }
   }
   ```

3. **Edge Type Determination**
   ```typescript
   function determineEdgeType(
     x: number, y: number,
     parentX: number, parentY: number,
     nextX?: number, nextY?: number
   ): number {
     // Calculate dx/dy to parent and next
     // Map to EDGE_HOR, EDGE_VER, EDGE_N_E, etc.
     // Return appropriate constant
   }
   ```

4. **Joint Detection** (_get_joints)
   ```typescript
   function getJoints(
     sharedEdges: Edge[],
     graph: Graph
   ): Position[] {
     // For each existing edge
     // For each cell in that edge
     // If cell type supports joints
     // Add neighboring positions as candidates
   }
   ```

5. **Path Straightening**
   ```typescript
   function straightenPath(path: PathCell[]): PathCell[] {
     // Detect patterns:
     // 1. Inward bends: → ↓ → (should be →)
     // 2. Outward bends: similar
     // 3. Check if direct path is clear
     // 4. Replace with shorter path
   }
   ```

**Tests:**

**Straight line tests:**
- ✅ Horizontal: `[A] at (0,0) -> [B] at (4,0)` → path `[(1,0), (2,0), (3,0)]`
- ✅ Vertical: `[A] at (0,0) -> [B] at (0,4)` → path `[(0,1), (0,2), (0,3)]`
- ✅ Adjacent nodes: `[A] at (0,0) -> [B] at (2,0)` → short edge `[(1,0)]`

**Single bend tests:**
- ✅ L-shape: `[A] at (0,0) -> [B] at (4,2)` → horizontal then vertical
- ✅ Reverse L: `[A] at (0,0) -> [B] at (4,2)` → vertical then horizontal
- ✅ Choose better bend based on obstacles

**A* tests:**
- ✅ Path around obstacle: place node in middle, route around it
- ✅ Multiple edges sharing start point (joints)
- ✅ Edge crossing (apply crossing penalty)
- ✅ Manhattan distance heuristic is admissible
- ✅ Path optimality: shortest path found
- ✅ Direction change penalty applied
- ✅ No diagonal movement

**Self-loop tests:**
- ✅ Self-loop going north
- ✅ Self-loop going south
- ✅ Self-loop going east
- ✅ Self-loop going west
- ✅ Choose direction based on available space

**Integration tests:**
- ✅ Route all edges in diamond graph
- ✅ Route all edges in complex network
- ✅ Compare paths with Perl version (may differ but should be similar quality)
- ✅ No infinite loops in pathfinding
- ✅ Pathfinding completes in <100ms for 20-node graph

**Success Criteria:**
- ✅ All A* tests pass
- ✅ Paths are optimal or near-optimal
- ✅ Performance acceptable (<1s for 100-node graph)
- ✅ Edge routing matches Perl quality
- ✅ Handles all edge cases (self-loops, crossings, joints)

---

### Phase 7: Backtracking Execution (3-4 days)

**Goal:** Implement main layout loop with backtracking

**Tasks:**

1. **LayoutEngine.ts** - Main orchestrator
   ```typescript
   class LayoutEngine {
     layout(graph: Graph): number {
       // 1. Drop caches
       // 2. Assign ranks
       const rankAssigner = new RankAssigner()
       rankAssigner.assignRanks(graph)

       // 3. Find chains
       const chainDetector = new ChainDetector()
       const chains = chainDetector.findChains(graph)

       // 4. Build action stack
       const stackBuilder = new ActionStackBuilder()
       const actions = stackBuilder.buildStack(graph, chains)

       // 5. Execute with backtracking
       return this.executeActions(graph, actions)
     }

     private executeActions(graph: Graph, actions: Action[]): number {
       const todo = [...actions]
       const done: Action[] = []
       let tries = 16
       let score = 0

       while (todo.length > 0 && tries > 0) {
         const action = todo.shift()!
         done.push(action)

         let result: number | null = null

         switch (action.type) {
           case ActionType.NODE:
           case ActionType.CHAIN:
             result = this.executeNodeAction(action, graph)
             break

           case ActionType.TRACE:
             result = this.executeTraceAction(action, graph)
             break
         }

         if (result === null) {
           // Failure
           if (action.type === ActionType.NODE || action.type === ActionType.CHAIN) {
             action.tryCount++
             this.undoNodePlacement(action.node!, graph)
             todo.unshift(action)  // Retry
           }
           tries--
         } else {
           score += result
         }
       }

       // 6. Optimize layout
       this.optimizeLayout(graph)

       return score
     }

     private executeNodeAction(action: Action, graph: Graph): number | null {
       const placer = new NodePlacer(graph)
       const success = placer.findNodePlace(
         action.node!,
         action.tryCount,
         action.parent,
         action.parentEdge
       )
       return success ? 0 : null
     }

     private executeTraceAction(action: Action, graph: Graph): number | null {
       const router = new EdgeRouter(graph)
       const path = router.findPath(
         action.edge!.from,
         action.edge!.to,
         action.edge!
       )

       if (path.length === 0) {
         return null
       }

       // Create cells for path
       let score = path.length
       for (const cell of path) {
         graph.cells.set(`${cell.x},${cell.y}`, cell)

         // Add crossing penalty to score
         if (cell.type === EDGE_CROSS) {
           score += 3
         }
       }

       action.edge!.cells = path
       return score
     }

     private undoNodePlacement(node: Node, graph: Graph): void {
       // Remove node's cells from graph.cells
       for (let dx = 0; dx < (node.cx || 1); dx++) {
         for (let dy = 0; dy < (node.cy || 1); dy++) {
           const key = `${node.x! + dx},${node.y! + dy}`
           graph.cells.delete(key)
         }
       }
       node.x = undefined
       node.y = undefined
     }
   }
   ```

**Tests:**
- ✅ Execute simple linear graph successfully
- ✅ Backtracking retries on node placement failure
- ✅ Gives up after 16 failed tries
- ✅ Score calculation correct
- ✅ Undo works correctly
- ✅ Actions execute in correct order
- ✅ Integration: full layout of 10-node graph
- ✅ Integration: full layout of 50-node graph
- ✅ Compare with Perl layout output

**Success Criteria:**
- ✅ Layout completes for all test graphs
- ✅ No infinite loops
- ✅ Backtracking works
- ✅ Results match Perl quality

---

### Phase 8: Grid Optimization (2-3 days)

**Goal:** Compact edge cells and optimize grid

**Tasks:**

1. **GridOptimizer.ts**
   ```typescript
   class GridOptimizer {
     optimize(graph: Graph): void {
       // Compact consecutive same-direction edge cells
       this.compactHorizontalEdges(graph)
       this.compactVerticalEdges(graph)
     }

     private compactHorizontalEdges(graph: Graph): void {
       // Find sequences of EDGE_HOR cells
       // Merge into single cell with combined width
       // Update cx property
     }

     private compactVerticalEdges(graph: Graph): void {
       // Similar for EDGE_VER
     }
   }
   ```

**Tests:**
- ✅ Compact 3 horizontal cells into 1 cell with cx=3
- ✅ Compact vertical cells
- ✅ Don't compact cells with different edges
- ✅ Don't compact cells with labels
- ✅ Compare optimization with Perl

**Success Criteria:**
- ✅ Optimization reduces cell count
- ✅ Doesn't break layout
- ✅ Matches Perl behavior

---

### Phase 9: Grid Sizing (3-4 days)

**Goal:** Calculate final character positions (_prepare_layout)

**Tasks:**

1. **GridSizer.ts**
   ```typescript
   class GridSizer {
     prepareLayout(graph: Graph): {
       rows: Map<number, number>
       cols: Map<number, number>
       maxX: number
       maxY: number
     } {
       // 1. Determine row/column sizes
       const rows = this.calculateRowSizes(graph)
       const cols = this.calculateColumnSizes(graph)

       // 2. Handle multi-cell objects
       this.balanceMultiCellSizes(graph, rows, cols)

       // 3. Calculate cumulative positions
       const rowPositions = this.cumulativePositions(rows)
       const colPositions = this.cumulativePositions(cols)

       // 4. Update cell dimensions
       this.updateCellDimensions(graph, rowPositions, colPositions)

       return { rows: rowPositions, cols: colPositions, ... }
     }

     private calculateRowSizes(graph: Graph): Map<number, number> {
       const sizes = new Map<number, number>()

       for (const cell of graph.cells.values()) {
         if ((cell.cx || 1) + (cell.cy || 1) === 2) {
           // Single cell
           const current = sizes.get(cell.y) || 0
           sizes.set(cell.y, Math.max(current, cell.height))
         }
       }

       return sizes
     }

     private balanceSizes(
       sizes: number[],
       minimum: number
     ): void {
       // Grow columns/rows to meet minimum requirement
       while (sum(sizes) < minimum) {
         const minIndex = indexOfMin(sizes.filter(s => s > 0))
         sizes[minIndex]++
       }
     }

     private cumulativePositions(
       sizes: Map<number, number>
     ): Map<number, number> {
       const positions = new Map<number, number>()
       let pos = 0

       for (const [index, size] of Array.from(sizes.entries()).sort()) {
         positions.set(index, pos)
         pos += size
       }

       return positions
     }
   }
   ```

2. **Update Cell dimensions**
   ```typescript
   updateCellDimensions(
     graph: Graph,
     rows: Map<number, number>,
     cols: Map<number, number>
   ): void {
     for (const cell of graph.cells.values()) {
       const actualX = cols.get(cell.x)!
       const actualY = rows.get(cell.y)!

       const nextCol = cols.get(cell.x + (cell.cx || 1))!
       const nextRow = rows.get(cell.y + (cell.cy || 1))!

       cell.width = nextCol - actualX
       cell.height = nextRow - actualY
     }
   }
   ```

**Tests:**
- ✅ Single-cell sizing works
- ✅ Multi-cell sizing balanced correctly
- ✅ Cumulative positions calculated
- ✅ Final cell dimensions correct
- ✅ Compare with Perl sizing

**Success Criteria:**
- ✅ Grid sizing correct for all test graphs
- ✅ Multi-cell nodes sized properly
- ✅ Matches Perl output

---

### Phase 10: ASCII Renderer (4-5 days)

**Goal:** Generate ASCII art from positioned cells (rewrite without ELK dependency)

**Tasks:**

1. **AsciiRenderer.ts** - Complete rewrite
   ```typescript
   class AsciiRenderer {
     render(graph: Graph, boxart: boolean = false): string {
       // 1. Prepare layout (calculate positions)
       const sizer = new GridSizer()
       const { rows, cols, maxX, maxY } = sizer.prepareLayout(graph)

       // 2. Create character grid
       const grid = this.createCharacterGrid(maxX, maxY)

       // 3. Render nodes
       this.renderNodes(graph, grid, rows, cols, boxart)

       // 4. Render edges
       this.renderEdges(graph, grid, rows, cols, boxart)

       // 5. Render labels
       this.renderLabels(graph, grid, rows, cols)

       // 6. Convert grid to string
       return this.gridToString(grid)
     }

     private createCharacterGrid(width: number, height: number): string[][] {
       return Array(height).fill(null).map(() =>
         Array(width).fill(' ')
       )
     }

     private renderNodes(
       graph: Graph,
       grid: string[][],
       rows: Map<number, number>,
       cols: Map<number, number>,
       boxart: boolean
     ): void {
       for (const cell of graph.cells.values()) {
         if (!cell.node) continue

         const x = cols.get(cell.x)!
         const y = rows.get(cell.y)!
         const w = cell.width
         const h = cell.height

         // Draw box
         this.drawBox(grid, x, y, w, h, boxart)

         // Draw label inside
         const label = cell.node.label || cell.node.name
         this.drawText(grid, x + 2, y + 1, label)
       }
     }

     private renderEdges(
       graph: Graph,
       grid: string[][],
       rows: Map<number, number>,
       cols: Map<number, number>,
       boxart: boolean
     ): void {
       for (const cell of graph.cells.values()) {
         if (!cell.edge) continue

         const x = cols.get(cell.x)!
         const y = rows.get(cell.y)!
         const type = cell.type & EDGE_TYPE_MASK
         const flags = cell.type & EDGE_FLAG_MASK

         const char = this.getEdgeCharacter(type, flags, boxart)
         grid[y][x] = char

         // Handle arrowheads
         if (flags & EDGE_START_MASK) {
           this.drawArrow(grid, x, y, flags, 'start', boxart)
         }
         if (flags & EDGE_END_MASK) {
           this.drawArrow(grid, x, y, flags, 'end', boxart)
         }
       }
     }

     private getEdgeCharacter(
       type: number,
       flags: number,
       boxart: boolean
     ): string {
       if (boxart) {
         return this.getBoxartCharacter(type, flags)
       } else {
         return this.getAsciiCharacter(type, flags)
       }
     }

     private getAsciiCharacter(type: number, flags: number): string {
       switch (type) {
         case EDGE_HOR: return '-'
         case EDGE_VER: return '|'
         case EDGE_CROSS: return '+'
         case EDGE_N_E: return '+'
         case EDGE_N_W: return '+'
         case EDGE_S_E: return '+'
         case EDGE_S_W: return '+'
         // ... all edge types
         default: return '?'
       }
     }

     private getBoxartCharacter(type: number, flags: number): string {
       // Unicode box drawing characters
       switch (type) {
         case EDGE_HOR: return '─'
         case EDGE_VER: return '│'
         case EDGE_CROSS: return '┼'
         case EDGE_N_E: return '└'
         case EDGE_N_W: return '┘'
         case EDGE_S_E: return '┌'
         case EDGE_S_W: return '┐'
         // ... all edge types
         default: return '?'
       }
     }

     private drawBox(
       grid: string[][],
       x: number, y: number,
       w: number, h: number,
       boxart: boolean
     ): void {
       const chars = boxart
         ? { tl: '┌', tr: '┐', bl: '└', br: '┘', h: '─', v: '│' }
         : { tl: '+', tr: '+', bl: '+', br: '+', h: '-', v: '|' }

       // Top and bottom
       for (let i = 1; i < w - 1; i++) {
         grid[y][x + i] = chars.h
         grid[y + h - 1][x + i] = chars.h
       }

       // Left and right
       for (let i = 1; i < h - 1; i++) {
         grid[y + i][x] = chars.v
         grid[y + i][x + w - 1] = chars.v
       }

       // Corners
       grid[y][x] = chars.tl
       grid[y][x + w - 1] = chars.tr
       grid[y + h - 1][x] = chars.bl
       grid[y + h - 1][x + w - 1] = chars.br
     }

     private gridToString(grid: string[][]): string {
       return grid.map(row => row.join('')).join('\n')
     }
   }
   ```

**Tests:**
- ✅ Render single node: `[Hello]`
- ✅ Render horizontal edge: `[A] -> [B]`
- ✅ Render vertical edge: `[A]` above `[B]` with arrow
- ✅ Render corner: L-shaped connection
- ✅ Render crossing: + intersection
- ✅ Render boxart vs ASCII
- ✅ Render node labels
- ✅ Render edge labels
- ✅ Render arrowheads (all 8 directions)
- ✅ Integration: render complete graph
- ✅ **Compare output with Perl character-by-character**

**Success Criteria:**
- ✅ ASCII output matches Perl for 100+ test graphs
- ✅ All character types correct
- ✅ Boxart rendering works
- ✅ No missing/extra characters

---

### Phase 11: Integration & Testing (3-5 days)

**Goal:** End-to-end testing and comparison with Perl

**Tasks:**

1. **Create comprehensive test suite**
   - Load 200+ examples from Perl test suite
   - Run through TypeScript implementation
   - Compare output with Perl output

2. **Performance benchmarking**
   - Measure parse time, layout time, render time
   - Compare with WebPerl times
   - Optimize bottlenecks

3. **Edge case testing**
   - Empty graph
   - Single node
   - Self-loops
   - Cycles
   - Large graphs (100+ nodes)
   - Complex layouts

4. **Regression testing**
   - Save known-good outputs
   - Detect any changes

**Tests:**
- ✅ All Perl test fixtures pass
- ✅ Performance within 2x of Perl (acceptable for TS)
- ✅ No crashes or infinite loops
- ✅ Memory usage reasonable

**Success Criteria:**
- ✅ 95%+ test pass rate
- ✅ Remaining 5% are acceptable differences (not bugs)
- ✅ Performance acceptable (<1s for 100-node graph)

---

### Phase 12: UI Integration (2-3 days)

**Goal:** Add TypeScript toggle to UI (no fallback!)

**Tasks:**

1. **Update graphConversionService.ts**
   ```typescript
   export type ConversionEngine = 'webperl' | 'typescript'

   async convert(
     input: string,
     format: OutputFormat,
     forceEngine?: ConversionEngine
   ): Promise<ConversionResult> {
     const engine = forceEngine || this.preferredEngine

     if (engine === 'typescript') {
       // Only ASCII/boxart supported
       if (format !== 'ascii' && format !== 'boxart') {
         return {
           output: '',
           engine: 'typescript',
           timeMs: 0,
           error: `TypeScript implementation only supports ASCII and Boxart formats. Selected format: ${format}`
         }
       }

       try {
         const output = await this.convertWithTypeScript(input, format)
         return { output, engine: 'typescript', timeMs, error: undefined }
       } catch (error) {
         // NO FALLBACK - just show error
         return {
           output: '',
           engine: 'typescript',
           timeMs: 0,
           error: `TypeScript conversion failed: ${error.message}`
         }
       }
     }

     // ... existing webperl code
   }

   private async convertWithTypeScript(
     input: string,
     format: OutputFormat
   ): Promise<string> {
     const { LayoutEngine } = await import('../js-implementation/layout/LayoutEngine')
     const { Parser } = await import('../js-implementation/parser/Parser')
     const { AsciiRenderer } = await import('../js-implementation/renderer/AsciiRenderer')

     // Parse
     const parser = new Parser()
     const graph = parser.parse(input)

     // Layout
     const engine = new LayoutEngine()
     engine.layout(graph)

     // Render
     const renderer = new AsciiRenderer()
     return renderer.render(graph, format === 'boxart')
   }
   ```

2. **Update App.tsx**
   - Add "TypeScript (Pure)" option to engine selector
   - Disable SVG/HTML options when TypeScript selected
   - Show clear error messages (no silent fallback)

3. **Add engine indicator**
   - Show which engine was used
   - Show timing comparison
   - Show warnings about unsupported features

**Tests:**
- ✅ Toggle to TypeScript works
- ✅ ASCII output displays correctly
- ✅ Error shown for unsupported formats
- ✅ No fallback to WebPerl
- ✅ Performance displayed

**Success Criteria:**
- ✅ UI works with TypeScript engine
- ✅ Clear error messages
- ✅ No silent fallbacks
- ✅ User can see which engine was used

---

## Test-Driven Development Strategy

**Golden Rule:** Write tests BEFORE implementing each feature

**Test Pyramid:**
```
        /\
       /  \      E2E Tests (50 tests)
      /----\     - Full graph layout
     /      \    - Compare with Perl output
    /--------\   Integration Tests (200 tests)
   /          \  - Multi-component workflows
  /------------\ Unit Tests (500 tests)
 /______________\ - Individual functions
                  - Edge cases
```

**Test Fixtures:**
1. Extract 200+ examples from Perl test suite
2. Format as: `{ input: string, expected: string }`
3. Store in `__tests__/fixtures/`
4. Load dynamically in tests

**Comparison Strategy:**
- Character-by-character comparison where possible
- Fuzzy matching for acceptable variations
- Visual diff tool for debugging

---

## Success Metrics

**Phase Completion:**
- ✅ All unit tests pass
- ✅ All integration tests pass
- ✅ Code coverage > 80%

**Final Acceptance:**
- ✅ 95%+ of Perl test fixtures produce identical output
- ✅ Remaining 5% produce acceptable variations
- ✅ No crashes or infinite loops
- ✅ Performance within 2x of Perl
- ✅ Bundle size < 500KB
- ✅ UI toggle works without fallback

---

## Timeline Estimate (Updated with Libraries)

| Phase | Duration (Original) | Duration (With Libs) | Cumulative |
|-------|----------|----------|------------|
| 0. Setup | 1-2 days | 1-2 days | 2 days |
| 1. Data Structures | 2-3 days | 2-3 days | 5 days |
| 2. Rank Assignment | 3-4 days | **2-3 days** ⚡ | 8 days |
| 3. Chain Detection | 4-5 days | 4-5 days | 13 days |
| 4. Action Stack | 2-3 days | 2-3 days | 16 days |
| 5. Node Placement | 5-7 days | 5-7 days | 23 days |
| 6. A* Edge Routing ⭐ | 7-10 days | **4-6 days** ⚡ | 29 days |
| 7. Backtracking | 3-4 days | 3-4 days | 33 days |
| 8. Grid Optimization | 2-3 days | 2-3 days | 36 days |
| 9. Grid Sizing | 3-4 days | 3-4 days | 40 days |
| 10. ASCII Renderer | 4-5 days | 4-5 days | 45 days |
| 11. Integration/Testing | 3-5 days | 3-5 days | 50 days |
| 12. UI Integration | 2-3 days | 2-3 days | **53 days** |

**Total: ~2-2.5 months** (assuming 1 developer full-time)

**Time saved by using libraries:** ~5-8 days (mostly in heap and A* implementation)

**Critical Path:** A* implementation is the most complex component

---

## Risk Mitigation

**Risk 1: A* implementation too complex**
- Mitigation: Use `astar-typescript` library as starting point
- Customize: Add Perl-specific heuristics (crossing penalty, etc.)
- Fallback: Start with library implementation, optimize later if needed

**Risk 2: Output doesn't match Perl**
- Mitigation: Test frequently against Perl fixtures
- Fallback: Acceptable variations are okay (not bug-for-bug compatible)

**Risk 3: Performance issues**
- Mitigation: Profile and optimize hot paths
- Fallback: 2x slower than Perl is acceptable for TS

**Risk 4: Scope creep (adding features)**
- Mitigation: Stick to ASCII output only
- Reminder: NO SVG, NO HTML, NO exports

---

## Open Questions

1. **Parser status:** How many tests are currently failing? Do we need to fix parser first?
2. **Existing code:** Can we reuse any of the existing TypeScript implementation?
3. **Test infrastructure:** Do we have access to Perl test suite?
4. **Performance requirements:** What's acceptable latency for 100-node graph?

---

## Next Steps

**Immediate actions:**
1. Review this plan with stakeholders
2. Answer open questions
3. Set up test infrastructure (Phase 0)
4. Extract Perl test fixtures
5. Begin Phase 1 implementation

**Decision points:**
- Approve timeline estimate
- Confirm scope (ASCII only, no fallback)
- Confirm acceptance criteria (95% match rate)
- Assign resources

---

## Appendix: Key Algorithms Summary

**Rank Assignment:**
- Topological sort with priority heap
- O(N log N) complexity

**Chain Detection:**
- Greedy longest-path finding
- O(N * E) complexity (N nodes, E edges)

**Node Placement:**
- Heuristic-based with backtracking
- O(N * T) where T = tries per node (max 16)

**A* Pathfinding:**
- Classic A* with Manhattan heuristic
- O(N log N) per edge where N = grid cells

**Grid Sizing:**
- Linear scan with cumulative sums
- O(N) complexity

**ASCII Rendering:**
- Grid fill with character lookup
- O(W * H) where W, H = grid dimensions

**Overall Complexity:** O(N² log N) for typical graphs (dominated by pathfinding)

---

## Conclusion

This is an ambitious but achievable reimplementation. The key to success is:

1. **Test-driven development** - prove each component works
2. **Incremental progress** - one phase at a time
3. **No shortcuts** - implement algorithms properly (A*, etc.)
4. **Clear scope** - ASCII only, no fallback
5. **Frequent validation** - compare with Perl often

The state-of-the-art Perl layout algorithm deserves a proper TypeScript implementation. Let's build it right!
