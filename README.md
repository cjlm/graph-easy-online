# Graph::Easy Online

A browser-based implementation of [Graph::Easy](https://metacpan.org/pod/Graph::Easy) running entirely client-side using WebAssembly and [WebPerl](https://webperl.zero-g.net/).

## What is this?

This project brings the Perl module Graph::Easy to the browser, allowing you to create ASCII art graphs without installing Perl or any dependencies. Just open the page and start drawing.

## Inspiration

This project was inspired by:
- [Simon Willison's SLOCCount in WebAssembly](https://simonwillison.net/2025/Oct/22/sloccount-in-webassembly/) - showing how to run Perl tools in the browser
- [SourceTarget Newsletter Edition 17](https://sourcetarget.email/editions/17/) - which noted in 2020 that Graph::Easy was "impossible to find anything I could run directly in the browser"
- [Graph::Easy](https://metacpan.org/pod/Graph::Easy) - the Perl library by Tels

## Features

- No installation required - runs entirely in your browser
- Uses WebPerl to run actual Perl code via WebAssembly
- Live preview as you type
- Supports both Graph::Easy and DOT notation
- ASCII art and Box art output formats

## How to use

1. Open the page in a modern web browser
2. Enter your graph notation in the input panel (or load an example)
3. See the output update live as you type

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

DOT notation is also supported:

```
digraph {
  A -> B -> C
}
```

## Technical Details

### Why this works

Graph::Easy is a pure Perl module with minimal dependencies:
- No C/XS components
- Only requires `Scalar::Util` (a core Perl module)
- Compatible with Perl 5.8.2+

This makes it suitable for running in WebPerl, which compiles Perl itself to WebAssembly using Emscripten.

### Architecture

```
+------------------------------------------+
|         Browser (index.html)             |
|  +------------------------------------+  |
|  |     JavaScript Interface           |  |
|  +----------------+-------------------+  |
|                   |                      |
|  +----------------v-------------------+  |
|  |   WebPerl (Perl via WebAssembly)   |  |
|  +----------------+-------------------+  |
|                   |                      |
|  +----------------v-------------------+  |
|  |   Graph::Easy Perl Module          |  |
|  |   (from lib/ directory)            |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### Files

- `index.html` - The main page with UI and WebPerl integration
- `lib/Graph/Easy.pm` - The Graph::Easy Perl module
- `lib/Graph/Easy/` - Supporting modules (Parser, Layout, Node, Edge, etc.)

## Limitations

- Requires a modern browser with WebAssembly support
- Loading may take a few seconds as WebPerl initializes
- Some advanced Graph::Easy features may not work

## Credits

- **Graph::Easy** - Created by Tels, maintained by Shlomi Fish
- **WebPerl** - Created by Hauke Dämpfling
- **Concept** - Inspired by Simon Willison's WebAssembly experiments

## License

This project is licensed under the GNU General Public License v2.0 or later (GPL-2.0-or-later).

Since this project includes and distributes Graph::Easy (which is licensed under GPL 2.0 or later), the entire project must be licensed under the GPL as well, in accordance with the GPL's copyleft requirements.

See the [LICENSE](LICENSE) file for the full license text.

## Contributing

Found a bug or have a suggestion? Please open an issue at https://github.com/cjlm/graph-easy
