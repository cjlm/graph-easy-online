declare module 'graph-easy-ts' {
  export class Graph {
    id: string
    timeout: number
    seed: number
    preserveLabelWhitespace: boolean

    layout(): void
    asAscii(): string
    asBoxart(): string
    asTxt(): string
    asGraphviz(): string
  }

  export class Parser {
    static fromFile(filePath: string): Graph
    static fromText(text: string): Graph
  }

  export class Node {
    id: string
    label: string
  }

  export class Edge {
    id: number
    from: Node
    to: Node
    label: string
  }

  export class Group {
    id: string
    name: string
  }
}
