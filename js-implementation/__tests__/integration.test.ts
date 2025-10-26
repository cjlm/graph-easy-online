/**
 * Integration tests for the complete Perl layout engine
 */

import { describe, it, expect } from 'vitest'
import { PerlLayoutEngine } from '../PerlLayoutEngine'

describe('PerlLayoutEngine Integration', () => {
  it('converts simple linear graph', async () => {
    const input = '[ A ] -> [ B ] -> [ C ]'

    const engine = new PerlLayoutEngine({ debug: true })
    const result = await engine.convert(input)

    expect(result).toBeTruthy()
    expect(result.length).toBeGreaterThan(0)

    // Should contain node names
    expect(result).toContain('A')
    expect(result).toContain('B')
    expect(result).toContain('C')

    // Should contain box characters
    expect(result).toMatch(/[\+\-\|]/)

    console.log('\n📊 Result:\n')
    console.log(result)
  })

  it('converts diamond graph', async () => {
    const input = `[ A ] -> [ B ] -> [ D ]
[ A ] -> [ C ] -> [ D ]`

    const engine = new PerlLayoutEngine({ debug: true })
    const result = await engine.convert(input)

    expect(result).toBeTruthy()
    expect(result).toContain('A')
    expect(result).toContain('B')
    expect(result).toContain('C')
    expect(result).toContain('D')

    console.log('\n📊 Result:\n')
    console.log(result)
  })

  it('converts with boxart', async () => {
    const input = '[ A ] -> [ B ]'

    const engine = new PerlLayoutEngine({ boxart: true })
    const result = await engine.convert(input)

    expect(result).toBeTruthy()

    // Should contain Unicode box drawing characters
    const hasBoxChars = /[┌┐└┘─│]/.test(result)
    expect(hasBoxChars).toBe(true)

    console.log('\n📊 Boxart Result:\n')
    console.log(result)
  })

  it('handles south flow direction', async () => {
    const input = `graph { flow: south; }

[ Start ] -> [ Middle ] -> [ End ]`

    const engine = new PerlLayoutEngine({ debug: true })
    const result = await engine.convert(input)

    expect(result).toBeTruthy()
    expect(result).toContain('Start')
    expect(result).toContain('Middle')
    expect(result).toContain('End')

    console.log('\n📊 South Flow Result:\n')
    console.log(result)
  })

  it('handles single node', async () => {
    const input = '[ Hello ]'

    const engine = new PerlLayoutEngine()
    const result = await engine.convert(input)

    expect(result).toBeTruthy()
    expect(result).toContain('Hello')

    console.log('\n📊 Single Node Result:\n')
    console.log(result)
  })

  it('handles multiple separate graphs', async () => {
    const input = `[ A ] -> [ B ]
[ C ] -> [ D ]`

    const engine = new PerlLayoutEngine()
    const result = await engine.convert(input)

    expect(result).toBeTruthy()
    expect(result).toContain('A')
    expect(result).toContain('B')
    expect(result).toContain('C')
    expect(result).toContain('D')

    console.log('\n📊 Multiple Graphs Result:\n')
    console.log(result)
  })
})
