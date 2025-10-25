#!/usr/bin/env node
/**
 * Test script to verify Graph::Easy determinism
 * Runs the same graph conversion multiple times and checks if output is identical
 */

import { chromium } from 'playwright';

const TEST_GRAPH = `digraph {
    subgraph cluster_0 {
        a0 -> a1 -> a2 -> a3;
        label = "process #1";
    }

    subgraph cluster_1 {
        b0 -> b1 -> b2 -> b3;
        label = "process #2";
    }

    start -> a0;
    start -> b0;
    a1 -> b3;
    b2 -> a3;
    a3 -> a0;
    a3 -> end;
    b3 -> end;
}`;

// Mimic PHP preprocessing: remove comments, then newlines
const TEST_GRAPH_PREPROCESSED = TEST_GRAPH
  .replace(/\/\*[\s\S]*?\*\/|\/\/.*|#.*/g, '')  // remove comments
  .replace(/\r|\n/g, ' ');  // remove newlines like PHP does

async function testDeterminism() {
  console.log('🧪 Testing Graph::Easy determinism...\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  // Navigate to the app (use preview server)
  console.log('Loading app...');
  await page.goto('http://localhost:4174/graph-easy/', { waitUntil: 'networkidle' });

  // Wait for Perl to be ready
  console.log('Waiting for Perl to initialize...');

  // Wait longer for WebPerl to initialize
  let perlReady = false;
  for (let i = 0; i < 60; i++) {
    const status = await page.evaluate(() => {
      if (typeof window.Perl !== 'undefined') {
        return { exists: true, state: window.Perl.state };
      }
      return { exists: false, state: null };
    });

    console.log(`  Check ${i + 1}: Perl exists=${status.exists}, state=${status.state}`);

    if (status.exists && (status.state === 'Ready' || status.state === 'Running' || status.state === 'Ended')) {
      perlReady = true;
      break;
    }

    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  if (!perlReady) {
    throw new Error('Perl did not initialize in time');
  }

  console.log('✅ Perl is ready\n');

  // Run conversion multiple times
  const iterations = 10;
  const outputs = [];

  console.log(`Running ${iterations} conversions...`);

  for (let i = 0; i < iterations; i++) {
    const result = await page.evaluate((graph) => {
      const output = window.Perl.eval(`
        use strict;
        use warnings;

        # Force reload of Layout module
        BEGIN {
          delete $INC{'Graph/Easy/Layout.pm'} if $INC{'Graph/Easy/Layout.pm'};
        }

        use lib '/lib';
        use Graph::Easy;

        my $input = <<'END_INPUT';
${graph}
END_INPUT

        my $output;
        my $debug = "";

        # Try to disable hash randomization like old Perl
        BEGIN {
          $ENV{PERL_HASH_SEED} = 0;
          $ENV{PERL_PERTURB_KEYS} = 0;
        }

        # Set Perl's random seed BEFORE creating graph
        # This must happen before Graph::Easy->new() which calls randomize()
        srand(12345);

        eval {
          my $graph = Graph::Easy->new($input);
          $graph->seed(12345);

          # Check Perl version
          my $perl_version = $];

          # Check state
          use Hash::Util qw(hash_seed);
          my $perl_hash_seed = unpack("H*", hash_seed());
          my $grapheasy_seed = $graph->seed();

          # Test if hash iteration changes WITHIN same eval
          my %test_hash = (a => 1, b => 2, c => 3, d => 4, e => 5);
          my $keys1 = join(",", keys %test_hash);
          my $keys2 = join(",", keys %test_hash);
          my $keys3 = join(",", keys %test_hash);
          my $same_within_call = ($keys1 eq $keys2 && $keys2 eq $keys3) ? "YES" : "NO";

          $debug = "Perl version: $perl_version\\n";
          $debug .= "Perl hash_seed: $perl_hash_seed\\n";
          $debug .= "Graph::Easy seed: $grapheasy_seed\\n";
          $debug .= "Hash keys (1st call): $keys1\\n";
          $debug .= "Hash keys (2nd call): $keys2\\n";
          $debug .= "Hash keys (3rd call): $keys3\\n";
          $debug .= "Same within call: $same_within_call\\n";

          # Check if Layout.pm was loaded/reloaded BEFORE layout
          if (exists $INC{'Graph/Easy/Layout.pm'}) {
            $debug .= "BEFORE: Layout.pm in %INC: " . $INC{'Graph/Easy/Layout.pm'} . "\\n";
          } else {
            $debug .= "BEFORE: Layout.pm NOT in %INC\\n";
          }

          $output = $graph->as_ascii();

          # Check AFTER layout
          if (exists $INC{'Graph/Easy/Layout.pm'}) {
            $debug .= "AFTER: Layout.pm loaded from: " . $INC{'Graph/Easy/Layout.pm'} . "\\n";
          }

          # Check file modification time to verify we have the right file
          my $layout_path = "/lib/Graph/Easy/Layout.pm";
          if (-e $layout_path) {
            my $mtime = (stat($layout_path))[9];
            $debug .= "Layout.pm mtime: $mtime\\n";

            # Read a snippet to verify it has our fix
            open my $fh, '<', $layout_path;
            my $content = do { local $/; <$fh> };
            close $fh;

            if ($content =~ /Enable sorted iteration for deterministic output/) {
              $debug .= "✓ Layout.pm HAS our determinism fix\\n";
            } else {
              $debug .= "✗ Layout.pm MISSING our determinism fix\\n";
            }
          }
        };

        if ($@) {
          $output = "Error: $@";
        }

        $debug . "---OUTPUT---\\n" . $output;
      `);

      // Split debug and output
      const parts = output.split('---OUTPUT---\n');
      return {
        debug: parts[0] || '',
        output: parts[1] || output
      };
    }, TEST_GRAPH_PREPROCESSED); // Use preprocessed version

    outputs.push(result.output);
    if (i === 0) {
      console.log('\nDebug from first run:\n' + result.debug);
    }
    process.stdout.write(`  Iteration ${i + 1}/${iterations} - ${result.output.length} chars\r`);
  }

  console.log('\n');

  // Check if all outputs are identical
  const firstOutput = outputs[0];
  const allIdentical = outputs.every(output => output === firstOutput);

  if (allIdentical) {
    console.log('✅ SUCCESS! All outputs are IDENTICAL');
    console.log(`   Output length: ${firstOutput.length} characters`);
    console.log('\nFirst few lines:');
    console.log(firstOutput.split('\n').slice(0, 10).join('\n'));
  } else {
    console.log('❌ FAILURE! Outputs are NOT identical');

    // Find which outputs differ
    const uniqueOutputs = [...new Set(outputs)];
    console.log(`   Found ${uniqueOutputs.length} different outputs:`);

    uniqueOutputs.forEach((output, idx) => {
      const count = outputs.filter(o => o === output).length;
      console.log(`\n   Output variant ${idx + 1}: ${count}/${iterations} times`);
      console.log(`   Length: ${output.length} characters`);
      console.log('   First few lines:');
      console.log(output.split('\n').slice(0, 5).join('\n'));
    });

    // Show diff between first two different outputs
    if (uniqueOutputs.length >= 2) {
      console.log('\n   Character-by-character comparison:');
      const out1 = uniqueOutputs[0];
      const out2 = uniqueOutputs[1];
      const minLen = Math.min(out1.length, out2.length);

      for (let i = 0; i < minLen; i++) {
        if (out1[i] !== out2[i]) {
          console.log(`   First difference at position ${i}:`);
          console.log(`   Output 1: "${out1.substring(i, i + 20)}..."`);
          console.log(`   Output 2: "${out2.substring(i, i + 20)}..."`);
          break;
        }
      }
    }
  }

  await browser.close();

  return allIdentical;
}

// Run the test
testDeterminism()
  .then(success => {
    process.exit(success ? 0 : 1);
  })
  .catch(err => {
    console.error('❌ Test failed with error:', err);
    process.exit(1);
  });
