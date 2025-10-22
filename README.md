# Graph::Easy in WebAssembly

A browser-based implementation of [Graph::Easy](https://metacpan.org/pod/Graph::Easy) running entirely client-side using WebAssembly and [WebPerl](https://webperl.zero-g.net/).

## What is this?

This project brings the powerful Perl module Graph::Easy to the browser, allowing you to create ASCII art graphs without installing Perl or any dependencies. Just open `index.html` in your browser and start drawing!

## Inspiration

This project was inspired by:
- [Simon Willison's SLOCCount in WebAssembly](https://simonwillison.net/2025/Oct/22/sloccount-in-webassembly/) - showing how to run Perl tools in the browser
- [SourceTarget Newsletter Edition 17](https://sourcetarget.email/editions/17/) - which noted in 2020 that Graph::Easy was "impossible to find anything I could run directly in the browser"
- [Graph::Easy](https://metacpan.org/pod/Graph::Easy) - the amazing Perl library by Tels

## Features

- **No installation required** - runs entirely in your browser
- **Pure WebAssembly** - uses WebPerl to run actual Perl code
- **Simple syntax** - just write your graph in text format
- **Instant results** - see ASCII art output immediately
- **Multiple examples** - includes several sample graphs to get started

## How to use

1. Open `index.html` in a modern web browser
2. Enter your graph notation in the input panel (or load an example)
3. Click "Convert to ASCII" to see the result

### Example input:

```
[ Bonn ] -> [ Berlin ]
[ Berlin ] -> [ Frankfurt ]
[ Frankfurt ] -> [ Dresden ]
```

### Example output:

```
+------+     +--------+     +-----------+     +---------+
| Bonn | --> | Berlin | --> | Frankfurt | --> | Dresden |
+------+     +--------+     +-----------+     +---------+
```

## Graph Notation

Graph::Easy uses a simple, human-readable syntax:

- `[ Node ]` - creates a node
- `->` - creates a directed edge (arrow)
- `=>` - creates a double arrow
- `..>` - creates a dotted arrow
- `--` - creates an undirected edge
- `{ label: text }` - adds attributes to edges or nodes

More examples are available in the built-in example buttons!

## Technical Details

### Why this works

Graph::Easy is a **pure Perl module** with minimal dependencies:
- No C/XS components
- Only requires `Scalar::Util` (a core Perl module)
- Compatible with Perl 5.8.2+

This makes it perfect for running in WebPerl, which compiles Perl itself to WebAssembly using Emscripten.

### Architecture

```
┌─────────────────────────────────────────┐
│         Browser (index.html)            │
│  ┌───────────────────────────────────┐  │
│  │     JavaScript Interface          │  │
│  └────────────┬──────────────────────┘  │
│               │                          │
│  ┌────────────▼──────────────────────┐  │
│  │   WebPerl (Perl → WebAssembly)   │  │
│  └────────────┬──────────────────────┘  │
│               │                          │
│  ┌────────────▼──────────────────────┐  │
│  │   Graph::Easy Perl Module        │  │
│  │   (from lib/ directory)          │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Files

- `index.html` - The main demo page with UI and WebPerl integration
- `lib/Graph/Easy.pm` - The Graph::Easy Perl module
- `lib/Graph/Easy/` - Supporting modules (Parser, Layout, Node, Edge, etc.)

## Limitations

- Requires a modern browser with WebAssembly support
- Loading may take a few seconds as WebPerl initializes
- Only ASCII output is currently implemented (no SVG/HTML rendering yet)
- Some advanced Graph::Easy features may not work

## Future Enhancements

Possible improvements:
- Add SVG output support
- Add more output formats (HTML, Graphviz)
- File upload/download capabilities
- Shareable URLs with encoded graphs
- Graph visualization editor
- Mobile-optimized interface

## Credits

- **Graph::Easy** - Created by Tels, maintained by Shlomi Fish
- **WebPerl** - Created by Hauke Dämpfling
- **Concept** - Inspired by Simon Willison's WebAssembly experiments

## License

- Graph::Easy: GPL 2.0 or later (original license)
- This demo: MIT License (see below)

```
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Contributing

Found a bug or have a suggestion? Please open an issue or submit a pull request!
