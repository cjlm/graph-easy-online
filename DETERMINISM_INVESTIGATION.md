# Graph::Easy Determinism Investigation - Complete Findings

## Test Setup ✅
Created automated test (`test-determinism.js`) that:
- Runs same graph conversion 10 times
- Compares outputs for consistency  
- **Result: 10 different outputs out of 10 runs** (100% failure rate)

## Root Causes Found

### 1. Random Seed ✅ PARTIALLY FIXED
- **Problem**: `Graph::Easy->new()` calls `randomize()` setting random seed each time
- **Fix Applied**: Set `$graph->seed(12345)` after construction
- **Status**: Seed IS being set (confirmed in debug output)
- **Remaining Issue**: Seed changes during parsing affect graph construction

### 2. Hash Iteration Randomness ❌ PARTIALLY FIXED
- **Problem**: Perl 5.18+ randomizes hash iteration order for security
- **Locations Found**: At least **15 unsorted hash iterations** in Layout.pm:
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
- **Fix Applied**: Only fixed line 274 (enabled commented-out sorted iteration)
- **Status**: ❌ Incomplete - 14 more locations need sorting

### 3. Module Reload Issue ⚠️
- **Problem**: Perl caches modules in `%INC`
- **Attempted Fixes**:
  - `delete $INC{'Graph/Easy/Layout.pm'}` - didn't help
  - Setting `PERL_HASH_SEED=0` - doesn't work in WebPerl
- **Status**: Module HAS our fix (confirmed by file read), but WebPerl may not support `%ENV` for hash seed control

## Why dot-to-ascii.ggerganov.com Works
- Uses **server-side Perl via PHP**
- Each request = fresh Perl process with clean state
- Our implementation = persistent WebPerl interpreter in browser

## Next Steps

To achieve determinism, need to:

1. **Sort ALL hash iterations** in Layout.pm (not just line 274)
2. **Control seed earlier** - before graph construction/parsing
3. **Possible nuclear option**: Patch WebPerl's Perl interpreter to disable hash randomization at compile-time

## Test Results Available
Run `node test-determinism.js` to reproduce the non-determinism yourself.
