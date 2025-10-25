# ELK to ASCII Orthogonal Graph Renderer

A complete implementation of an ELK (Eclipse Layout Kernel) to ASCII art graph renderer with orthogonal (right-angle only) edge routing.

## Features

- ✅ **Orthogonal Edge Routing**: All edges use right-angle paths
- ✅ **Unicode & ASCII Modes**: Beautiful Unicode box-drawing characters or classic ASCII
- ✅ **Directional Arrows**: Optional arrow indicators on edges
- ✅ **Label Support**: Render node and edge labels
- ✅ **Port Support**: Display port markers on nodes
- ✅ **Hierarchical Nodes**: Double-line boxes for nodes with children
- ✅ **Smart Junctions**: Automatic handling of edge intersections
- ✅ **Configurable Scale**: Adjust character density
- ✅ **Density Warnings**: Alerts for overly complex graphs
- ✅ **Error Handling**: Graceful handling of invalid inputs

## Installation

The renderer is part of the graph-easy-wasm project and located at:
```
js-implementation/renderers/elk-ascii-renderer.ts
```

## Usage

### Basic Example

```typescript
import ELK from 'elkjs'
import { renderASCII, type ELKResult } from './renderers/elk-ascii-renderer'

const elk = new ELK()

// Configure ELK graph with ORTHOGONAL edge routing
const graph = {
  id: 'root',
  layoutOptions: {
    'elk.algorithm': 'layered',
    'elk.edgeRouting': 'ORTHOGONAL',  // Important!
    'elk.spacing.nodeNode': '80',
    'elk.layered.spacing.nodeNodeBetweenLayers': '100'
  },
  children: [
    { id: 'n1', width: 60, height: 40, labels: [{ text: 'Node 1' }] },
    { id: 'n2', width: 60, height: 40, labels: [{ text: 'Node 2' }] },
    { id: 'n3', width: 60, height: 40, labels: [{ text: 'Node 3' }] }
  ],
  edges: [
    { id: 'e1', sources: ['n1'], targets: ['n2'] },
    { id: 'e2', sources: ['n2'], targets: ['n3'] }
  ]
}

// Perform ELK layout
const result = await elk.layout(graph)

// Render to ASCII
const { ascii, metadata } = renderASCII(result as ELKResult, {
  scale: 0.3,
  unicode: true,
  arrows: true
})

console.log(ascii)
console.log('Metadata:', metadata)
```

Output:
```
     ┌────────┐          ┌────────┐          ┌────────┐
     │ Node 1 │─────────→│ Node 2 │─────────→│ Node 3 │
     └────────┘          └────────┘          └────────┘
```

## Configuration Options

### RenderOptions

```typescript
interface RenderOptions {
  scale?: number              // chars per pixel (0.2-0.5 recommended)
  margin?: number             // canvas padding in chars
  unicode?: boolean           // false for ASCII-only mode
  arrows?: boolean            // show directional arrows on edges
  renderLabels?: boolean      // render node and edge labels
  renderPorts?: boolean       // show port indicators on nodes
  portChar?: string          // character for port markers
  junctionStyle?: 'merge' | 'bridge'  // junction rendering style
  maxDensity?: number        // if exceeded, warn about collisions
  autoScale?: boolean        // auto-adjust scale if too dense
}
```

### Default Options

```typescript
{
  scale: 0.3,              // Good balance for most graphs
  margin: 5,               // 5 character margin
  unicode: true,           // Use Unicode box-drawing
  arrows: true,            // Show directional arrows
  renderLabels: true,      // Show all labels
  renderPorts: false,      // Hide ports by default
  portChar: '◦',          // Port marker character
  junctionStyle: 'merge',  // Use ┼ for intersections
  maxDensity: 0.4,        // 40% edge density threshold
  autoScale: true         // Auto-adjust if needed
}
```

## Character Sets

### Unicode Mode

```
Horizontal: ─    Vertical: │
Corners: ┌ ┐ └ ┘
T-junctions: ├ ┤ ┬ ┴
Cross: ┼
Arrows: → ← ↓ ↑
Double (hierarchical): ═ ║ ╔ ╗ ╚ ╝
```

### ASCII Mode

```
Horizontal: -    Vertical: |
Corners: + + + +
T-junctions: + + + +
Cross: +
Arrows: > < v ^
Double: = | + + + +
```

## Examples

### Example 1: ASCII Mode

```typescript
const { ascii } = renderASCII(elkResult, {
  scale: 0.3,
  unicode: false,  // ASCII mode
  arrows: true
})
```

Output:
```
     +--------+          +--------+
     | Node 1 |--------->| Node 2 |
     +--------+          +--------+
```

### Example 2: Vertical Layout

```typescript
const graph = {
  id: 'root',
  layoutOptions: {
    'elk.algorithm': 'layered',
    'elk.direction': 'DOWN',  // Top to bottom
    'elk.edgeRouting': 'ORTHOGONAL'
  },
  children: [...],
  edges: [...]
}

const elkResult = await elk.layout(graph)
const { ascii } = renderASCII(elkResult, {
  scale: 0.3,
  unicode: true,
  arrows: true
})
```

Output:
```
     ┌────────┐
     │  Top   │
     └────┬───┘
          │
          ↓
     ┌────────┐
     │ Middle │
     └────┬───┘
          │
          ↓
     ┌────────┐
     │ Bottom │
     └────────┘
```

### Example 3: Without Arrows

```typescript
const { ascii } = renderASCII(elkResult, {
  scale: 0.3,
  unicode: true,
  arrows: false  // No arrows
})
```

Output:
```
     ┌────────┐          ┌────────┐
     │ Node 1 │──────────│ Node 2 │
     └────────┘          └────────┘
```

### Example 4: Edge Labels

```typescript
const graph = {
  // ...
  edges: [
    {
      id: 'e1',
      sources: ['n1'],
      targets: ['n2'],
      labels: [{ text: 'connects' }]  // Edge label
    }
  ]
}

const { ascii } = renderASCII(elkResult, {
  renderLabels: true
})
```

### Example 5: Hierarchical Nodes

For nodes with children, double-line boxes are used in Unicode mode:

```
     ╔══════════╗
     ║ Parent   ║
     ║  Node    ║
     ╚══════════╝
```

### Example 6: Scale Adjustment

```typescript
// Compact (scale = 0.2)
const compact = renderASCII(elkResult, { scale: 0.2 })

// Normal (scale = 0.3)
const normal = renderASCII(elkResult, { scale: 0.3 })

// Spacious (scale = 0.5)
const spacious = renderASCII(elkResult, { scale: 0.5 })
```

## Return Value

### RenderResult

```typescript
interface RenderResult {
  ascii: string | null        // The rendered ASCII art (null on error)
  metadata: {
    width?: number           // Canvas width in characters
    height?: number          // Canvas height in characters
    scale?: number           // Scale factor used
    nodeCount?: number       // Number of nodes rendered
    edgeCount?: number       // Number of edges rendered
    warnings: string[]       // Any warnings (e.g., high density)
    error?: string          // Error message if rendering failed
  }
}
```

## Implementation Details

### Phase 1: Coordinate Quantization

Converts floating-point ELK coordinates to integer grid coordinates:
- Applies scale factor to convert pixels to characters
- Enforces minimum node dimensions (3x3 characters)
- Quantizes all points (nodes, edges, labels, ports)

### Phase 2: Canvas Allocation

Creates the character canvas:
- Calculates bounding box from all elements
- Adds margins
- Creates 2D array filled with spaces
- Computes offset for centering

### Phase 3: Node Rendering

Draws nodes with boxes:
- Single-line boxes for regular nodes
- Double-line boxes for hierarchical nodes (Unicode mode)
- Centered labels with word wrapping
- Optional port markers

### Phase 4: Edge Rendering

Draws edges with orthogonal routing:
- Horizontal and vertical segments only
- Automatic corner detection at bend points
- Smart junction merging (├ ┤ ┬ ┴ ┼)
- Directional arrows at endpoints
- Edge label placement

### Phase 5: Output Generation

Converts canvas to string:
- Joins rows with newlines
- Calculates metadata
- Provides warnings if needed

## ELK Configuration

For best results, configure ELK with:

```typescript
{
  'elk.algorithm': 'layered',           // Layered algorithm works best
  'elk.edgeRouting': 'ORTHOGONAL',      // Required for right-angle edges
  'elk.spacing.nodeNode': '80',         // Good default node spacing
  'elk.layered.spacing.nodeNodeBetweenLayers': '100',  // Layer spacing
  'elk.portConstraints': 'FREE',        // Allow flexible port positions
}
```

### Direction Options

```typescript
'elk.direction': 'RIGHT'  // Left to right (default)
'elk.direction': 'LEFT'   // Right to left
'elk.direction': 'DOWN'   // Top to bottom
'elk.direction': 'UP'     // Bottom to top
```

## Testing

Run the test suite:

```bash
npm test elk-ascii-renderer.test.ts
```

Run the demo examples:

```bash
npx tsx js-implementation/examples/elk-ascii-demo.ts
```

## Test Coverage

The implementation includes tests for:

1. ✅ Single straight edge (horizontal and vertical)
2. ✅ L-shaped edge with one corner
3. ✅ Complex path with multiple bends
4. ✅ Multiple edges intersecting at junction
5. ✅ Edge entering node at different sides
6. ✅ Self-loop edge (source === target)
7. ✅ Hierarchical node containing children
8. ✅ Dense graph with many overlapping edges
9. ✅ Graph with edge and node labels
10. ✅ Graph with ports

## Error Handling

The renderer handles various error conditions:

- **Invalid ELK Result**: Returns error in metadata
- **Missing Properties**: Uses safe defaults
- **Out of Bounds**: Checks canvas boundaries
- **Zero Dimensions**: Enforces minimums
- **Non-Orthogonal Segments**: Logs warnings

## Performance Considerations

- **Scale Factor**: Lower scale = smaller output = faster rendering
- **Graph Complexity**: O(nodes + edges) time complexity
- **Canvas Size**: Determined by graph bounds + margins
- **Memory**: Canvas stored as 2D array

## Limitations

1. **Orthogonal Only**: Requires ELK's ORTHOGONAL edge routing
2. **Grid-Based**: Output resolution limited by character grid
3. **ASCII Simplicity**: Some visual fidelity lost vs. graphical rendering
4. **Label Overflow**: Long labels may be truncated in narrow nodes

## Tips for Best Results

1. **Use Appropriate Scale**: 0.3 is a good starting point
2. **Adjust ELK Spacing**: Increase spacing for complex graphs
3. **Unicode Mode**: Produces much better looking results
4. **Test Different Options**: Try various configurations
5. **Check Warnings**: Adjust if density warnings appear

## Future Enhancements

Potential improvements:

- [ ] Bridge-style junction rendering
- [ ] Self-loop edge support
- [ ] Better label overflow handling
- [ ] Auto-scale based on terminal width
- [ ] Color support for terminal output
- [ ] SVG-like styling attributes

## License

GPL-2.0-or-later (same as parent project)

## References

- [ELK Documentation](https://www.eclipse.org/elk/)
- [elkjs on npm](https://www.npmjs.com/package/elkjs)
- [Unicode Box Drawing](https://en.wikipedia.org/wiki/Box-drawing_character)
