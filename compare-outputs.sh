#!/bin/bash

echo "=== PERL OUTPUT ==="
echo 'graph { A -- B; A -- B; A -- C; A -- C; A -- D; B -- D; C -- D }' | graph-easy

echo ""
echo "=== TYPESCRIPT OUTPUT ==="
npx tsx test-final.mjs 2>&1 | tail -20
