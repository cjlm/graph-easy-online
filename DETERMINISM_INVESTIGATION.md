# Graph::Easy Determinism Investigation - FINAL FINDINGS

## Automated Test Created ✅
- `test-determinism.js`: Playwright-based test running 10 conversions
- **Result:** 6-10 different outputs per run (non-deterministic)

## Root Cause: WebPerl Hash Iteration Bug 🐛

**The smoking gun:** WebPerl's hash iteration is **NON-DETERMINISTIC** even with constant hash seed!

### Test Results

```bash
# Hash seed is CONSTANT across all runs:
Perl hash_seed: 436795db7ebc2c7622abfeebbcf7f670708f752f6fd2a3a0 (all 10 runs)

# rand() is DETERMINISTIC after srand(12345):
rand() values: 0.225328512796299, 0.919183068533556 (all 10 runs)

# But hash iteration is RANDOM:
Hash keys order for {a=>1, b=>2, c=>3, d=>4, e=>5}:
- 7 DIFFERENT orders out of 10 runs!
- a,e,b,d,c
- b,e,a,d,c
- c,d,b,e,a (2x)
- d,c,b,e,a (2x)
- e,b,a,d,c (3x)
```

**Conclusion:** WebPerl's `keys %hash` and `values %hash` produce random order on each call, regardless of hash seed.

## Why dot-to-ascii.ggerganov.com Works

NOT because of "server-side vs client-side" - that was my incorrect assessment.

The real reason: They spawn fresh Perl processes via `proc_open()`, and **native Perl** (unlike WebPerl) properly implements deterministic hash iteration when hash seed is constant.

## Solution: Sort ALL Hash Iterations

We fixed **1 of 15** unsorted hash iterations:

### Fixed ✅
- `Layout.pm:274` - sorted successor iteration

### Still Need Fixing ❌ 
**Layout.pm (14 locations):**
- Line 196: `for my $e (values %{$node->{edges}})`
- Line 348: `foreach my $n (values %{$self->{nodes}}, values %{$self->{groups}})`
- Line 510: `foreach my $n (values %{$self->{nodes}}, values %{$self->{groups}})`
- Line 528: `for my $n (values %{$self->{nodes}})`
- Line 541: `for my $g (values %{$self->{groups}})`
- Line 582: `for values %{$self->{nodes}}`
- Line 600: `values %{$self->{chains}}`
- Line 607: `for my $edge (values %{$self->{edges}})`
- Line 632: `values %{$self->{chains}}`
- Line 649: `for my $n (values %{$self->{nodes}})`
- Line 690: `for my $n (values %{$self->{groups}})`
- Line 863: `for my $n (values %{$self->{nodes}})`
- Line 870: `for my $e (values %{$self->{edges}})`
- Line 894: `for my $e (values %{$self->{edges}})`

**Parser/Graphviz.pm (4 locations):**
- Line 660: `for my $t (keys %$old_scope)`
- Line 665: `for my $k (keys %$s)`  
- Line 862: `for my $k (keys %$att)`
- Line 1908: `for my $e (values %{$n->{edges}})`

## Test Infrastructure

Run `node test-determinism.js` to verify determinism after fixes.

Current status: ❌ FAILS (6-10 different outputs)
Target: ✅ PASS (1 identical output)
