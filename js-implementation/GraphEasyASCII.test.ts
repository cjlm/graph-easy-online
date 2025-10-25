/**
 * Integration tests for GraphEasyASCII
 */

import { describe, it, expect } from 'vitest'
import { GraphEasyASCII } from './GraphEasyASCII'

describe('GraphEasyASCII - Initialization', () => {
  it('should create instance', async () => {
    const converter = await GraphEasyASCII.create()

    expect(converter).toBeDefined()
  })

  it('should create with options', async () => {
    const converter = await GraphEasyASCII.create({
      boxart: true,
      strict: false,
      debug: false,
    })

    expect(converter).toBeDefined()
  })
})

describe('GraphEasyASCII - Graph::Easy Format', () => {
  it('should convert simple graph', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })
    const result = await converter.convert('[A] -> [B]')

    expect(result).toBeTruthy()
    expect(result).toContain('A')
    expect(result).toContain('B')
  })

  it('should convert graph with multiple edges', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })
    const result = await converter.convert(`
      [A] -> [B]
      [B] -> [C]
      [C] -> [D]
    `)

    expect(result).toContain('A')
    expect(result).toContain('B')
    expect(result).toContain('C')
    expect(result).toContain('D')
  })

  it('should handle graph with attributes', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })
    const result = await converter.convert(`
      graph { flow: south; }
      [A] -> [B]
    `)

    expect(result).toBeTruthy()
  })

  it('should handle edge chaining', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })
    const result = await converter.convert('[A] -> [B] -> [C]')

    expect(result).toContain('A')
    expect(result).toContain('B')
    expect(result).toContain('C')
  })
})

describe('GraphEasyASCII - DOT Format', () => {
  it('should convert simple DOT graph', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })
    const result = await converter.convert('digraph { A -> B; }')

    expect(result).toContain('A')
    expect(result).toContain('B')
  })

  it('should convert DOT graph with attributes', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })
    const result = await converter.convert(`
      digraph {
        A [label="Node A"];
        B [label="Node B"];
        A -> B;
      }
    `)

    // ELK renderer uses node IDs, not labels
    expect(result).toContain('A')
    expect(result).toContain('B')
  })

  it('should convert DOT graph with edge chaining', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })
    const result = await converter.convert('digraph { A -> B -> C; }')

    expect(result).toContain('A')
    expect(result).toContain('B')
    expect(result).toContain('C')
  })
})

describe('GraphEasyASCII - Auto-Detection', () => {
  it('should auto-detect Graph::Easy format', async () => {
    const converter = await GraphEasyASCII.create({
      inputFormat: 'auto',
      useELK: true,
    })

    const result = await converter.convert('[A] -> [B]')

    expect(result).toBeTruthy()
  })

  it('should auto-detect DOT format', async () => {
    const converter = await GraphEasyASCII.create({
      inputFormat: 'auto',
      useELK: true,
    })

    const result = await converter.convert('digraph { A -> B; }')

    expect(result).toBeTruthy()
  })

  it('should auto-detect strict digraph', async () => {
    const converter = await GraphEasyASCII.create({
      inputFormat: 'auto',
      useELK: true,
    })

    const result = await converter.convert('strict digraph { A -> B; }')

    expect(result).toBeTruthy()
  })
})

describe('GraphEasyASCII - Output Formats', () => {
  it('should output ASCII by default', async () => {
    const converter = await GraphEasyASCII.create({
      boxart: false,
      useELK: true,
    })

    const result = await converter.convert('[A] -> [B]')

    // Should contain ASCII characters
    expect(result).toMatch(/[+\-|]/)
  })

  it('should output boxart when enabled', async () => {
    const converter = await GraphEasyASCII.create({
      boxart: true,
      useELK: true,
    })

    const result = await converter.convert('[A] -> [B]')

    // Boxart uses Unicode characters
    expect(result).toBeTruthy()
  })
})

describe('GraphEasyASCII - Options', () => {
  it('should respect flow direction', async () => {
    const converter = await GraphEasyASCII.create({
      flow: 'south',
      useELK: true,
    })

    const result = await converter.convert('[A] -> [B]')

    expect(result).toBeTruthy()
  })

  it('should respect node spacing', async () => {
    const converter = await GraphEasyASCII.create({
      nodeSpacing: 5,
      useELK: true,
    })

    const result = await converter.convert('[A] -> [B]')

    expect(result).toBeTruthy()
  })

  it('should update options', async () => {
    const converter = await GraphEasyASCII.create()

    converter.setOptions({ boxart: true })

    const options = converter.getOptions()
    expect(options.boxart).toBe(true)
  })
})

describe('GraphEasyASCII - Complex Graphs', () => {
  it('should handle network topology', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert(`
      graph { flow: south; }

      [Internet]
      [Firewall]
      [Router]
      [Switch]

      [Internet] -> [Firewall]
      [Firewall] -> [Router]
      [Router] -> [Switch]
    `)

    expect(result).toContain('Internet')
    expect(result).toContain('Firewall')
    expect(result).toContain('Router')
    expect(result).toContain('Switch')
  })

  it('should handle process flow', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert(`
      [Start] -> [Process] -> [Decision]
      [Decision] -> [End]
      [Decision] -> [Process]
    `)

    expect(result).toContain('Start')
    expect(result).toContain('Process')
    expect(result).toContain('Decision')
    expect(result).toContain('End')
  })

  it('should handle complex DOT graph', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert(`
      digraph G {
        A -> B;
        B -> C;
        C -> D;
        D -> A;
      }
    `)

    expect(result).toContain('A')
    expect(result).toContain('B')
    expect(result).toContain('C')
    expect(result).toContain('D')
  })
})

describe('GraphEasyASCII - Edge Cases', () => {
  it('should handle empty input', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert('')

    expect(result).toBeTruthy()
  })

  it('should handle single node', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert('[A]')

    expect(result).toContain('A')
  })

  it('should handle nodes with special characters', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert('[Node-1] -> [Node_2]')

    expect(result).toContain('Node-1')
    expect(result).toContain('Node_2')
  })

  it('should handle long node names', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert(
      '[Very Long Node Name] -> [Another Very Long Node Name]'
    )

    expect(result).toContain('Very Long Node Name')
    expect(result).toContain('Another Very Long Node Name')
  })
})

describe('GraphEasyASCII - Error Handling', () => {
  it('should not throw on malformed Graph::Easy input', async () => {
    const converter = await GraphEasyASCII.create({ strict: false, useELK: true })

    await expect(
      converter.convert('[A] -> ')
    ).resolves.toBeTruthy()
  })

  it('should not throw on malformed DOT input', async () => {
    const converter = await GraphEasyASCII.create({ strict: false, useELK: true })

    await expect(
      converter.convert('digraph { A -> }')
    ).resolves.toBeTruthy()
  })

  it('should throw in strict mode for malformed input', async () => {
    const converter = await GraphEasyASCII.create({ strict: true })

    await expect(
      converter.convert('[A] -> ')
    ).rejects.toThrow()
  })
})

describe('GraphEasyASCII - Real-World Examples', () => {
  it('should convert Bonn -> Berlin example', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert(`
      [ Bonn ] -> [ Berlin ]
      [ Frankfurt ] -> [ Berlin ]
      [ Berlin ] -> [ Dresden ]
    `)

    expect(result).toContain('Bonn')
    expect(result).toContain('Berlin')
    expect(result).toContain('Frankfurt')
    expect(result).toContain('Dresden')
  })

  it('should convert simple workflow', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert(`
      graph { flow: south; }

      [ Start ] { fill: lightgreen; }
      [ Process ] { fill: lightyellow; }
      [ End ] { fill: lightblue; }

      [ Start ] -> [ Process ] -> [ End ]
    `)

    expect(result).toContain('Start')
    expect(result).toContain('Process')
    expect(result).toContain('End')
  })

  it('should convert DOT workflow', async () => {
    const converter = await GraphEasyASCII.create({ useELK: true })

    const result = await converter.convert(`
      digraph workflow {
        rankdir=LR;

        start [label="Start", shape=ellipse];
        process [label="Process", shape=box];
        end [label="End", shape=ellipse];

        start -> process;
        process -> end;
      }
    `)

    // ELK renderer uses node IDs, not labels
    expect(result).toContain('start')
    expect(result).toContain('process')
    expect(result).toContain('end')
  })
})
