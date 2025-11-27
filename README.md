# Graph::Easy Online

A webapp to turn simple text descriptions of graphs into ASCII art diagrams, in the browser.

Based on [Graph::Easy](https://metacpan.org/pod/Graph::Easy), running client-side via [WebPerl](https://webperl.zero-g.net/).

## Background

The journey of building this is documented here: [The Port I Couldn't Ship](https://ammil.industries/the-port-i-couldnt-ship/)

## Features

- Runs in your browser (nothing to install)
- Live preview while you type
- Support for Graph::Easy and DOT notation inputs
- Quickly copy the current output to the clipboard
- Share current graphs via the URL
- Pre-loaded with example graphs
- ASCII art and Box art output
- Mobile device support

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

### [Architecture](https://graph-easy.online/?input=graph+%7B+flow%3A+south%3B+%7D%0A%28+Browser+%28index.html%29%0A++%5B+JavaScript+Interface+%5D+-%3E+%7B+start%3A+south%3B+end%3A+north%3B+%7D+%0A++%5B+WebPerl+%28Perl+via+WebAssembly%29+%5D+-%3E+%7B+start%3A+south%3B+end%3A+north%3B+%7D+%0A++%5B+Graph%3A%3AEasy+Perl+Module+%28from+lib%2F+directory%29+%5D%0A%29&format=ascii)

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
- Loading may take a few seconds as WebPerl initialises
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

Found a bug or have a suggestion? Please open an issue at https://github.com/cjlm/graph-easy-online
