/**
 * Test fixtures with known Perl outputs
 *
 * These will be used to verify our TypeScript implementation
 * matches the Perl version's output
 */

export interface TestCase {
  name: string
  input: string
  expectedAscii?: string  // Will be populated by running through Perl
  expectedBoxart?: string
}

export const testCases: TestCase[] = [
  {
    name: 'simple-linear',
    input: `[ Berlin ] -> [ Frankfurt ]
[ Frankfurt ] -> [ Dresden ]`,
  },
  {
    name: 'simple-three-nodes',
    input: `[ A ] -> [ B ] -> [ C ]`,
  },
  {
    name: 'diamond',
    input: `[ A ] -> [ B ] -> [ D ]
[ A ] -> [ C ] -> [ D ]`,
  },
  {
    name: 'self-loop',
    input: `[ A ] -> [ A ]`,
  },
  {
    name: 'bidirectional',
    input: `[ A ] <-> [ B ]`,
  },
  {
    name: 'double-arrow',
    input: `[ A ] ==> [ B ]`,
  },
  {
    name: 'dotted-arrow',
    input: `[ A ] ..> [ B ]`,
  },
  {
    name: 'simple-branch',
    input: `[ A ] -> [ B ]
[ A ] -> [ C ]`,
  },
  {
    name: 'four-node-complex',
    input: `[ Bonn ] -> [ Berlin ] { label: via train; }
[ Bonn ] -> [ Frankfurt ]
[ Frankfurt ] -> [ Berlin ]
[ Berlin ] -> [ Dresden ]
[ Dresden ] -> [ Frankfurt ]`,
  },
  {
    name: 'with-flow-south',
    input: `graph { flow: south; }

[ Start ] -> [ Process ] -> [ End ]`,
  },
  {
    name: 'with-attributes',
    input: `graph { flow: south; }

[ Start ] { fill: lightgreen; }
[ Process ] { fill: lightyellow; }
[ End ] { fill: lightblue; }

[ Start ] -> [ Process ] -> [ End ]`,
  },
  {
    name: 'long-chain',
    input: `[ A ] -> [ B ] -> [ C ] -> [ D ] -> [ E ]`,
  },
  {
    name: 'multiple-edges',
    input: `[ A ] -> [ B ]
[ A ] -> [ B ]`,
  },
  {
    name: 'tree-structure',
    input: `[ Root ] -> [ Child1 ]
[ Root ] -> [ Child2 ]
[ Root ] -> [ Child3 ]
[ Child1 ] -> [ Leaf1 ]
[ Child1 ] -> [ Leaf2 ]
[ Child2 ] -> [ Leaf3 ]`,
  },
  {
    name: 'cycle',
    input: `[ A ] -> [ B ] -> [ C ] -> [ A ]`,
  },
  {
    name: 'complex-dag',
    input: `[ aa ] -> [ab]
[ aa ] -> [ac]
[ ab ] -> [ad]
[ ac ] -> [ad]
[ ad ] -> [ae]
[ ad ] -> [af]`,
  },
]
