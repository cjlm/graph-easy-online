# Graph::Easy ASCII-Only Pure JS/WASM Implementation

## Focused Scope

This implementation focuses **exclusively on ASCII art conversion**, removing SVG, HTML, and other output formats from scope. This makes the project much more achievable while still delivering the core value proposition.

## Why ASCII-Only?

1. **Core Use Case**: ASCII art is the primary use case for Graph::Easy
2. **Simpler Scope**: Removes complexity of multiple renderers
3. **Faster Delivery**: Can ship a working implementation much faster
4. **Same Performance Gains**: Still get 24x smaller bundle, 30-50x faster startup
5. **Easier to Test**: Single output format to validate

## Architecture (Simplified)

```
┌─────────────────────────────────────────────┐
│ Input: Graph::Easy Text Notation           │
│   "[Bonn] -> [Berlin]"                     │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│ Parser (PEG.js)                             │
│ - Parse node/edge syntax                    │
│ - Parse attributes                          │
│ - Build Graph object                        │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│ TypeScript Graph Model                      │
│ - Graph, Node, Edge classes                 │
│ - Attribute management                      │
│ - ~1,200 lines                              │
└──────────────────┬──────────────────────────┘
                   │
                   │ Serialize to JSON
                   │
┌──────────────────▼──────────────────────────┐
│ Rust Layout Engine (WASM)                   │
│ - Topological sort                          │
│ - Grid-based layout                         │
│ - Edge routing                              │
│ - ~200KB compressed                         │
└──────────────────┬──────────────────────────┘
                   │
                   │ Returns positioned nodes/edges
                   │
┌──────────────────▼──────────────────────────┐
│ ASCII Renderer (TypeScript)                 │
│ - Draw boxes with +,-,|                     │
│ - Draw arrows with >,<,^,v                  │
│ - ~400 lines                                │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│ Output: ASCII Art                           │
│   +------+     +--------+                   │
│   | Bonn | --> | Berlin |                   │
│   +------+     +--------+                   │
└─────────────────────────────────────────────┘
```

## Components to Build

### 1. Parser (PEG.js) ⚡ NEW PRIORITY

**File**: `js-implementation/parser/GraphEasyParser.pegjs`

Parse Graph::Easy syntax:
- `[Node]` - nodes
- `->`, `=>`, `..>`, `--`, etc. - edges
- `{ attr: value }` - attributes
- `# comments`

**Lines**: ~200-300

### 2. Core TypeScript ✅ DONE

Already implemented:
- Graph.ts
- Node.ts
- Edge.ts
- Group.ts
- Attributes.ts

**Lines**: ~1,200

### 3. Rust Layout Engine ⚡ NEEDS COMPLETION

**File**: `js-implementation/layout-engine-rust/src/lib.rs`

Implement:
- ✅ Data structures (done)
- ✅ WASM bindings (done)
- ⚡ Topological sort (skeleton exists)
- ⚡ Grid positioning
- ⚡ Edge routing

**Lines**: ~600 (currently ~400)

### 4. ASCII Renderer ✅ DONE

Already implemented in `renderers/AsciiRenderer.ts`

**Lines**: ~400

### 5. Integration Layer ⚡ NEW

**File**: `js-implementation/GraphEasyASCII.ts`

Main API that ties everything together:

```typescript
import { GraphEasyASCII } from './GraphEasyASCII'

const converter = await GraphEasyASCII.create()
const ascii = await converter.convert('[Bonn] -> [Berlin]')
console.log(ascii)
```

**Lines**: ~100

## Updated File Structure

```
js-implementation/
├── ASCII_FOCUSED_PLAN.md          # This file
│
├── core/                           # ✅ DONE (1,200 lines)
│   ├── Graph.ts
│   ├── Node.ts
│   ├── Edge.ts
│   ├── Group.ts
│   └── Attributes.ts
│
├── parser/                         # ⚡ TO DO
│   ├── GraphEasyParser.pegjs      # PEG.js grammar
│   └── index.ts                   # Parser wrapper
│
├── layout-engine-rust/             # ⚡ TO COMPLETE
│   ├── Cargo.toml
│   └── src/
│       └── lib.rs                 # Layout implementation
│
├── renderers/                      # ✅ DONE (400 lines)
│   └── AsciiRenderer.ts
│
├── GraphEasyASCII.ts              # ⚡ TO DO (main API)
│
├── examples/
│   └── demo.ts                    # ⚡ TO DO (working demo)
│
└── tests/                         # ⚡ TO DO
    ├── parser.test.ts
    ├── layout.test.ts
    └── renderer.test.ts
```

## Implementation Priority

### Phase 1: Parser (2-3 days) ⚡
- [ ] Write PEG.js grammar
- [ ] Parse nodes: `[Name]`
- [ ] Parse edges: `->`, `=>`, `..>`, etc.
- [ ] Parse attributes: `{ color: red }`
- [ ] Handle comments
- [ ] Error handling
- [ ] Tests

### Phase 2: Complete Layout (3-4 days) ⚡
- [ ] Finish topological sort
- [ ] Implement grid positioning
- [ ] Basic edge routing (straight lines)
- [ ] Calculate bounds
- [ ] Tests

### Phase 3: Integration (1-2 days) ⚡
- [ ] Create main API class
- [ ] Wire Parser → Graph → Layout → Renderer
- [ ] Error handling
- [ ] Tests

### Phase 4: Demo & Polish (1 day)
- [ ] Working demo
- [ ] Documentation
- [ ] Performance testing
- [ ] Bug fixes

**Total: 7-10 days** to working implementation

## Bundle Size Estimate

```
TypeScript code:
  - Core classes: ~30KB (minified)
  - Parser: ~20KB (PEG.js runtime + grammar)
  - Renderer: ~10KB
  - Integration: ~5KB
  - Total: ~65KB

Rust WASM:
  - Layout engine: ~150-200KB (compressed)

Grand Total: ~265KB (vs 12MB with WebPerl)
```

## Performance Targets

| Metric | Target | WebPerl |
|--------|--------|---------|
| Bundle Size | <300KB | 12MB |
| Cold Start | <100ms | 3-5s |
| Parse Time | <10ms | 50ms |
| Layout Time | <20ms | 50ms |
| Render Time | <5ms | 10ms |
| **Total Time** | **<135ms** | **~3-5s** |

## Success Criteria

1. ✅ Parse all Graph::Easy syntax for nodes/edges
2. ✅ Handle attributes (at least basic ones)
3. ✅ Layout graphs correctly (may differ slightly from Perl)
4. ✅ Render ASCII art that matches WebPerl output >90%
5. ✅ Bundle size <500KB
6. ✅ Total conversion time <200ms
7. ✅ Works with all examples in current app

## What We're NOT Doing (Out of Scope)

- ❌ SVG output
- ❌ HTML output
- ❌ Graphviz DOT export
- ❌ GraphML export
- ❌ VCG/GDL export
- ❌ Box art (Unicode) - maybe later, it's similar to ASCII
- ❌ Perfect layout matching - accept minor differences
- ❌ All 150+ attributes - support common ones
- ❌ Groups/clusters rendering - parse but don't render specially

## Minimal Feature Set

### Must Have ✅
- Parse: `[Node]`, `->`, `=>`, `..>`, `--`, `<->`, `<=>`
- Attributes: `label`, `color`, `fill`, `shape` (basic)
- Layout: Directed acyclic graphs
- Render: ASCII boxes and arrows

### Nice to Have 📋
- Parse: All edge styles (`- >`, `~~>`, `.->`)
- Attributes: More complete set
- Layout: Graphs with cycles
- Render: Box art (Unicode)

### Future 🔮
- Groups rendering
- Complete attribute support
- SVG/HTML output
- Interactive editor

## Next Steps

1. ✅ Update design docs ← WE ARE HERE
2. ⚡ Implement parser (start here!)
3. ⚡ Complete Rust layout
4. ⚡ Wire everything together
5. ⚡ Create working demo

Let's build this! 🚀
