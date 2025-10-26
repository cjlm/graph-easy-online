# CRITICAL FINDING: Graph::Easy Does NOT Use Sugiyama Layout

## The Problem

The current TypeScript implementation uses a **Sugiyama-based layout algorithm**, but after analyzing the Perl Graph::Easy source code, **Perl Graph::Easy does NOT use Sugiyama layout at all**.

This explains why the outputs are completely different and cannot be made to match.

## What Graph::Easy Actually Uses

### Algorithm: Chain-Based Grid Placement with A* Edge Routing

**Key Components:**

1. **Rank Assignment** (simple breadth-first, not Sugiyama layering)
   - Auto-assigned ranks: -1, -2, -3, ... (from roots)
   - User-defined ranks: 1, 2, 3, ...
   - No strict layer enforcement

2. **Chain Discovery** (UNIQUE TO GRAPH::EASY)
   - Identifies sequences of nodes where each has one successor
   - Merges chains when they connect
   - Chains processed in priority order (longest first)
   - Creates "backbone" structure of graph

3. **Incremental Node Placement** (flexible grid, not strict layers)
   - Multiple placement strategies tried in order:
     - User-rank constraints
     - Shared port alignment
     - Parent-relative placement
     - Predecessor-based placement
     - Successor-based placement
     - Generic fallback
   - **Backtracking** via action stack

4. **A* Edge Routing** (3-tier pathfinding)
   - **Tier 1**: Try straight horizontal/vertical path
   - **Tier 2**: Try single-bend L-shaped path
   - **Tier 3**: Full A* with Manhattan heuristic

   **A* Features**:
   - Can cross existing edges (with 30-point penalty)
   - Penalizes direction changes (6 points)
   - Creates joints/T-junctions for shared ports
   - Path straightening post-processing

## Key Differences from Sugiyama

| Aspect | Sugiyama | Graph::Easy |
|--------|----------|-------------|
| Philosophy | Hierarchical, phase-based | Incremental, chain-based |
| Node Placement | Strict layers | Flexible grid |
| Crossing Minimization | Explicit phase (barycenter/median) | Implicit via chain ordering |
| Edge Routing | Post-processing splines | A* during layout |
| Backtracking | Rare | Built-in with action stack |
| Multi-edges | Bundled | Individual A* routes with joints |
| Grid-based | No | Yes (Manhattan orthogonal) |

## Example: Seven Bridges Graph

**Input:**
```
[ A ] -- [ B ]
[ A ] -- [ B ]
[ A ] -- [ C ]
[ A ] -- [ C ]
[ A ] -- [ D ]
[ B ] -- [ D ]
[ C ] -- [ D ]
```

**Perl Graph::Easy Output (Correct):**
```
  +-------------------+
  |                   |
+---+     +---+     +---+
|   | --- | C | --- | D |
|   |     +---+     +---+
|   |       |         |
| A | ------+         |
|   |                 |
|   |                 |
|   | -+              |
+---+  |              |
  |    |              |
  |    |              |
  |    |              |
+---+  |              |
| B | -+--------------+
+---+  |
```

**Current TypeScript Output (Wrong - Sugiyama-based):**
```
           +----------+
 +---+    +|---------+|             +---+
 | A |-----+------->+||-----------> | B |---
 +---+   +|---------+v|             +---+
          +----------+|               |
                     ||               |
                     ||             +---+
                     +|-----------> | C |>--
                      |             +---+
```

**Problems with TypeScript version:**
- Uses directed edges (`--->`) instead of undirected (`---`)
- All nodes in horizontal line (Sugiyama layers)
- Fan-out routing instead of A* with edge crossing
- No compact layout or edge joints
- Completely different structure

## What Needs to Change

### Files That Need Rewriting:
1. **`RankAssigner.ts`** - Simplify to match Perl's basic breadth-first
2. **`ChainDetector.ts`** - Already exists but may need fixes
3. **`NodePlacer.ts`** - Complete rewrite for flexible grid placement
4. **`EdgeRouter.ts` / `OrthogonalRouter.ts`** - Replace with A* Scout implementation
5. **`ActionStackBuilder.ts`** - May be mostly correct
6. **`LayoutEngine.ts`** - Coordinate the correct algorithm flow

### New Components Needed:
1. **`AStarScout.ts`** - Implements 3-tier pathfinding with edge crossing
2. **`EdgeJoint.ts`** - Handles shared ports and T-junctions
3. **`PlacementStrategy.ts`** - Multiple placement attempt strategies

### What Can Be Kept:
- Core data structures (Graph, Node, Edge, Cell)
- Action stack concept (already correct)
- Chain data structure (mostly correct)
- Basic rank assignment concept (needs simplification)

## Conclusion

**The current implementation is fundamentally incompatible with Perl Graph::Easy.**

We cannot "fix" the Sugiyama implementation to match Perl output. We need to:

1. Study the Perl source code in detail:
   - `/public/lib/Graph/Easy/Layout.pm` - Main coordination
   - `/public/lib/Graph/Easy/Layout/Chain.pm` - Chain management
   - `/public/lib/Graph/Easy/Layout/Scout.pm` - A* pathfinding (1390 lines!)
   - `/public/lib/Graph/Easy/Layout/Path.pm` - Node placement (722 lines)

2. Reimplement the chain-based algorithm with A* routing

3. Test against Perl outputs to verify exact matching

This is a significant undertaking but necessary to achieve the goal of matching Perl Graph::Easy's output exactly.

## References

- Perl Graph::Easy version: 0.69
- Total Perl code size: ~8,702 lines
- Core layout code: ~3,200 lines (Layout.pm, Chain.pm, Scout.pm, Path.pm)
