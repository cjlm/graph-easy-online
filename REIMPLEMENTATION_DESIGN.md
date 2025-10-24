# Graph::Easy Reimplementation in JavaScript/WASM

## Overview

This document outlines a plan to reimplement the Graph::Easy Perl library in pure JavaScript/TypeScript with performance-critical parts in Rust/WASM.

## Current Architecture (WebPerl)

```
┌──────────────────────────────────────────────────────┐
│ Browser                                              │
│  ┌────────────────────────────────────────────────┐ │
│  │ React UI (TypeScript)                          │ │
│  └─────────────┬──────────────────────────────────┘ │
│                │ Perl.eval()                         │
│  ┌─────────────▼──────────────────────────────────┐ │
│  │ WebPerl Runtime (WASM)                         │ │
│  │ - Entire Perl interpreter in WASM              │ │
│  │ - ~12MB compressed                              │ │
│  └─────────────┬──────────────────────────────────┘ │
│                │                                      │
│  ┌─────────────▼──────────────────────────────────┐ │
│  │ Graph::Easy Modules (Perl)                     │ │
│  │ - Parser, Layout, Rendering                    │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

**Pros:**
- Exact compatibility with Graph::Easy
- No rewrite needed
- All Perl features available

**Cons:**
- Large bundle size (~12MB)
- Slow cold start
- Limited optimization opportunities
- Difficult to debug
- Hard to extend with modern features

## Proposed Architecture (Pure JS/WASM)

### Hybrid Approach

```
┌──────────────────────────────────────────────────────────┐
│ Browser                                                  │
│  ┌────────────────────────────────────────────────────┐ │
│  │ React UI + High-Level API (TypeScript)            │ │
│  └─────┬────────────────────────────────┬─────────────┘ │
│        │                                │                │
│  ┌─────▼────────────────────┐  ┌───────▼─────────────┐ │
│  │ Graph Data Model (TS)    │  │ Parser (TS)         │ │
│  │ - Node                   │  │ - PEG.js based      │ │
│  │ - Edge                   │  │ - Graph description │ │
│  │ - Group                  │  │   language          │ │
│  │ - Attributes             │  └─────────────────────┘ │
│  └─────┬────────────────────┘                          │
│        │                                                │
│  ┌─────▼─────────────────────────────────────────────┐ │
│  │ Layout Engine (Rust → WASM)                       │ │
│  │ - Grid-based Manhattan layout                     │ │
│  │ - Path finding (A* algorithm)                     │ │
│  │ - Edge routing                                    │ │
│  │ - Collision detection                             │ │
│  │ - ~200KB compressed                               │ │
│  └─────┬─────────────────────────────────────────────┘ │
│        │                                                │
│  ┌─────▼─────────────────────────────────────────────┐ │
│  │ Renderers (TypeScript)                            │ │
│  │ - ASCII/BoxArt (string builder)                   │ │
│  │ - HTML (DOM/template)                             │ │
│  │ - SVG (inline/Canvas API)                         │ │
│  │ - Graphviz DOT (serializer)                       │ │
│  └───────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Module Breakdown

### 1. Core Data Structures (TypeScript)

**Why TypeScript:** Type safety, easy to debug, good for object relationships

```typescript
// src/core/Graph.ts
class Graph {
  nodes: Map<string, Node>
  edges: Map<string, Edge>
  groups: Map<string, Group>
  attributes: AttributeManager

  addNode(name: string): Node
  addEdge(from: Node, to: Node): Edge
  layout(): LayoutResult
}

// src/core/Node.ts
class Node {
  id: string
  name: string
  attributes: Map<string, any>
  edges: Edge[]
  group?: Group

  edgesTo(node: Node): Edge[]
  hasPredecessors(): boolean
}

// src/core/Edge.ts
class Edge {
  id: string
  from: Node
  to: Node
  attributes: Map<string, any>
  bidirectional: boolean
}
```

### 2. Parser (TypeScript with PEG.js)

**Why PEG.js:**
- Expressive grammar
- Good error messages
- Maintainable

```typescript
// src/parser/grammar.pegjs
Graph
  = _ statements:Statement* _ { return buildGraph(statements) }

Statement
  = NodeStatement
  / EdgeStatement
  / AttributeStatement
  / Comment

NodeStatement
  = "[" _ name:NodeName _ "]" _ attrs:Attributes? {
      return { type: 'node', name, attrs }
    }

EdgeStatement
  = from:NodeRef _ arrow:Arrow _ to:NodeRef _ attrs:Attributes? {
      return { type: 'edge', from, to, arrow, attrs }
    }

Arrow
  = "-->" / "==>" / "..>" / "--" / "<->" / "<=>"
```

### 3. Layout Engine (Rust → WASM)

**Why Rust:**
- Performance critical operations
- Memory safety
- Great WASM tooling (wasm-pack)

```rust
// rust-layout/src/lib.rs
use wasm_bindgen::prelude::*;
use std::collections::HashMap;

#[wasm_bindgen]
pub struct LayoutEngine {
    grid: Grid,
    config: LayoutConfig,
}

#[wasm_bindgen]
impl LayoutEngine {
    #[wasm_bindgen(constructor)]
    pub fn new(config: JsValue) -> Self {
        let config: LayoutConfig = config.into_serde().unwrap();
        Self {
            grid: Grid::new(),
            config,
        }
    }

    pub fn layout(&mut self, graph_json: JsValue) -> Result<JsValue, JsValue> {
        let graph: GraphData = graph_json.into_serde()
            .map_err(|e| JsValue::from_str(&e.to_string()))?;

        // Manhattan grid-based layout algorithm
        let positioned_nodes = self.grid_layout(&graph)?;
        let routed_edges = self.route_edges(&graph, &positioned_nodes)?;

        Ok(JsValue::from_serde(&LayoutResult {
            nodes: positioned_nodes,
            edges: routed_edges,
        }).unwrap())
    }

    fn grid_layout(&mut self, graph: &GraphData) -> Result<Vec<NodePosition>, String> {
        // Implement graph layout algorithm
        // 1. Topological sort
        // 2. Layer assignment
        // 3. Crossing minimization
        // 4. Position assignment
        todo!()
    }

    fn route_edges(&self, graph: &GraphData, nodes: &[NodePosition])
        -> Result<Vec<EdgePath>, String> {
        // A* pathfinding for edge routing
        // Avoid node collisions
        // Minimize crossings
        todo!()
    }
}

#[derive(Serialize, Deserialize)]
struct NodePosition {
    id: String,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
}

#[derive(Serialize, Deserialize)]
struct EdgePath {
    id: String,
    points: Vec<(i32, i32)>,
    arrow_start: Option<ArrowType>,
    arrow_end: Option<ArrowType>,
}
```

### 4. Renderers (TypeScript)

**Why TypeScript:**
- Easy string manipulation
- Direct DOM access
- Canvas/SVG APIs

```typescript
// src/renderers/AsciiRenderer.ts
export class AsciiRenderer {
  private framebuffer: string[][]

  render(layout: LayoutResult): string {
    this.initFramebuffer(layout.bounds)

    // Render edges first (background)
    for (const edge of layout.edges) {
      this.renderEdge(edge)
    }

    // Render nodes on top
    for (const node of layout.nodes) {
      this.renderNode(node)
    }

    return this.framebufferToString()
  }

  private renderNode(node: NodePosition) {
    const box = this.createBox(node.width, node.height, node.label)
    this.blitToFramebuffer(node.x, node.y, box)
  }

  private renderEdge(edge: EdgePath) {
    // Draw line segments between points
    for (let i = 0; i < edge.points.length - 1; i++) {
      this.drawLine(edge.points[i], edge.points[i + 1])
    }
  }
}

// src/renderers/SvgRenderer.ts
export class SvgRenderer {
  render(layout: LayoutResult): string {
    const svg = this.createSvg(layout.bounds)

    // Add edge elements
    layout.edges.forEach(edge => {
      svg.appendChild(this.createEdgeElement(edge))
    })

    // Add node elements
    layout.nodes.forEach(node => {
      svg.appendChild(this.createNodeElement(node))
    })

    return svg.outerHTML
  }
}
```

## Implementation Plan

### Phase 1: Core Foundation (2-3 weeks)
- [ ] Set up TypeScript project structure
- [ ] Implement core classes (Graph, Node, Edge, Group)
- [ ] Implement attribute system
- [ ] Write comprehensive tests
- [ ] Create simple examples

### Phase 2: Parser (1-2 weeks)
- [ ] Write PEG.js grammar for Graph::Easy syntax
- [ ] Implement parser with error handling
- [ ] Support all edge types and attributes
- [ ] Add parser tests

### Phase 3: Layout Engine - Pure JS Prototype (2 weeks)
- [ ] Implement basic grid layout in TypeScript
- [ ] Test with simple graphs
- [ ] Benchmark performance
- [ ] Identify bottlenecks

### Phase 4: Layout Engine - Rust Rewrite (3-4 weeks)
- [ ] Set up Rust + wasm-pack project
- [ ] Port layout algorithm to Rust
- [ ] Implement A* pathfinding for edge routing
- [ ] Optimize for WASM
- [ ] Add WASM bindings
- [ ] Performance testing

### Phase 5: Renderers (2-3 weeks)
- [ ] ASCII art renderer
- [ ] Box art (Unicode) renderer
- [ ] HTML table renderer
- [ ] SVG renderer
- [ ] Graphviz DOT exporter

### Phase 6: Integration & Polish (2 weeks)
- [ ] Integrate with existing React UI
- [ ] Add progressive loading
- [ ] Error handling and user feedback
- [ ] Documentation
- [ ] Performance optimization

## Performance Comparison

### Expected Improvements

| Metric | WebPerl | Pure JS/WASM | Improvement |
|--------|---------|--------------|-------------|
| Bundle Size | ~12 MB | ~500 KB | 24x smaller |
| Cold Start | 3-5s | <100ms | 30-50x faster |
| Parse Time | 50-100ms | 5-10ms | 10x faster |
| Layout Time (small) | 20ms | 5ms | 4x faster |
| Layout Time (large) | 200ms | 30-50ms | 4-6x faster |
| Memory Usage | ~50MB | ~5MB | 10x less |

## Technical Advantages

### 1. **Bundle Size**
- WebPerl: Entire Perl interpreter + modules
- Pure JS/WASM: Only what's needed
- Tree-shaking and code splitting possible

### 2. **Performance**
- Rust/WASM is near-native speed
- No interpreter overhead
- Direct memory access
- SIMD optimizations possible

### 3. **Debugging**
- Source maps for TypeScript
- Chrome DevTools integration
- Rust panic messages in WASM
- No Perl debugging required

### 4. **Extensibility**
- Easy to add new features
- Modern JavaScript ecosystem
- NPM packages available
- Web APIs directly accessible

### 5. **Maintainability**
- Type safety with TypeScript
- Modern tooling (ESLint, Prettier)
- Better IDE support
- Easier to onboard contributors

## Migration Strategy

### Option 1: Big Bang (Risky)
Replace everything at once
- High risk
- Long development time
- Hard to test incrementally

### Option 2: Gradual Migration (Recommended)

1. **Phase 1**: Keep WebPerl, add new JS API alongside
   - Both systems run in parallel
   - Feature flag to switch between them
   - A/B testing possible

2. **Phase 2**: Migrate renderers first
   - WebPerl for parsing + layout
   - New JS renderers
   - Easy to compare output

3. **Phase 3**: Add new parser
   - Test extensively against WebPerl parser
   - Ensure compatibility

4. **Phase 4**: Add layout engine
   - Most complex part
   - Thorough testing needed
   - Performance benchmarking

5. **Phase 5**: Deprecate WebPerl
   - Remove fallback
   - Clean up code

## Challenges and Solutions

### Challenge 1: Algorithm Fidelity
**Problem:** Graph::Easy has complex layout heuristics
**Solution:**
- Start with test-driven development
- Extract test cases from Perl test suite
- Visual regression testing
- Allow small differences in layout

### Challenge 2: Attribute System
**Problem:** 150+ attributes with complex inheritance
**Solution:**
- Generate TypeScript types from Perl specs
- Create comprehensive attribute test suite
- Use schema validation (Zod/Yup)

### Challenge 3: Parser Compatibility
**Problem:** Need to support existing Graph::Easy syntax
**Solution:**
- Use PEG.js for expressive grammar
- Test against large corpus of examples
- Maintain syntax compatibility
- Add better error messages

### Challenge 4: Performance Expectations
**Problem:** Users expect immediate results
**Solution:**
- Web Workers for layout
- Incremental rendering
- Progress indicators
- Stream large graphs

## Alternative Approaches

### Alternative 1: Pure TypeScript
**Pros:** Simpler toolchain, easier debugging
**Cons:** Slower for large graphs, ~3-5x slower than Rust

### Alternative 2: Pure Rust/WASM
**Pros:** Maximum performance
**Cons:** Less flexible, harder to debug UI integration

### Alternative 3: AssemblyScript
**Pros:** TypeScript-like syntax, compiles to WASM
**Cons:** Limited ecosystem, less mature than Rust

### Recommendation
**Hybrid TypeScript + Rust/WASM** offers the best balance of:
- Development speed (TypeScript for structure)
- Runtime performance (Rust for algorithms)
- Maintainability (clear separation of concerns)
- Ecosystem access (NPM + Cargo)

## Code Organization

```
graph-easy-js/
├── packages/
│   ├── core/                  # Core TS library
│   │   ├── src/
│   │   │   ├── graph.ts
│   │   │   ├── node.ts
│   │   │   ├── edge.ts
│   │   │   ├── group.ts
│   │   │   └── attributes.ts
│   │   └── package.json
│   │
│   ├── parser/                # Parser
│   │   ├── src/
│   │   │   ├── grammar.pegjs
│   │   │   └── parser.ts
│   │   └── package.json
│   │
│   ├── layout/                # Rust layout engine
│   │   ├── src/
│   │   │   ├── lib.rs
│   │   │   ├── grid.rs
│   │   │   ├── pathfinding.rs
│   │   │   └── optimize.rs
│   │   ├── Cargo.toml
│   │   └── package.json
│   │
│   ├── renderers/             # All renderers
│   │   ├── src/
│   │   │   ├── ascii.ts
│   │   │   ├── boxart.ts
│   │   │   ├── html.ts
│   │   │   ├── svg.ts
│   │   │   └── graphviz.ts
│   │   └── package.json
│   │
│   └── web/                   # React app
│       ├── src/
│       │   ├── App.tsx
│       │   └── components/
│       └── package.json
│
├── tools/
│   ├── test-extractor/        # Extract tests from Perl
│   └── benchmark/             # Performance tests
│
└── docs/
    ├── api/
    ├── migration-guide.md
    └── architecture.md
```

## Testing Strategy

### 1. Unit Tests
- Each class/module tested independently
- Mock dependencies
- Fast, run on every commit

### 2. Integration Tests
- Parser → Graph → Layout → Renderer
- Test full pipeline
- Compare with known good outputs

### 3. Visual Regression Tests
- Screenshot comparison
- Percy or similar
- Catch layout differences

### 4. Performance Tests
- Benchmark suite
- Compare with WebPerl
- Track over time

### 5. Compatibility Tests
- Run Perl test suite
- Compare outputs
- Track compatibility score

## Next Steps

To proceed with this reimplementation:

1. **Proof of Concept (1 week)**
   - Implement minimal Graph, Node, Edge in TS
   - Simple grid layout in TS
   - ASCII renderer
   - Compare with WebPerl on 5 examples

2. **Evaluation**
   - Review performance
   - Assess complexity
   - Decide on full implementation

3. **If approved, start Phase 1**
   - Set up monorepo
   - Core data structures
   - Test infrastructure

## Conclusion

Reimplementing Graph::Easy in JavaScript/WASM offers significant advantages:

- **24x smaller bundle** (500KB vs 12MB)
- **30-50x faster startup** (<100ms vs 3-5s)
- **4-6x faster layout** for large graphs
- **Better developer experience** (debugging, tooling)
- **More extensible** (modern ecosystem)

The hybrid TypeScript + Rust approach provides the best balance of development speed and runtime performance, while maintaining compatibility with the original Graph::Easy syntax and output.

Estimated total development time: **12-16 weeks** with one developer, or **6-8 weeks** with a small team.
