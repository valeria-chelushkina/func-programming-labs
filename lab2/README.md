# Lab Work 2 — Variant 4 — Parallel numerical integration

Multithreaded Haskell application that computes a definite integral

$$J(A, B) = \int_A^B f(x) dx$$

with a requested precision, using parallel algorithms. GHC is compiled with
`-threaded`, and the runtime starts with all available capabilities (`-N`).

The function, bounds, and precision are **chosen by the user at runtime**:
there is no single hardcoded variant. A set of standard integrands is built in,
and new ones can be added in `src/Integrands.hs`.

## 1. What this work is

Implemented features:

- user chooses the integrand, `A`, `B`, and `ε` from the command line;
- composite **midpoint rule** with automatic interval doubling;
- **Richardson error control**: `err = |M(2n) − M(n)| / 3`;
- **parallel evaluation** of interval chunks, one worker per capability;
- **sequential and parallel modes** with wall-clock timing;
- quiet mode that prints only the numeric result;
- correctness tests against known integrals;
- benchmark script for `-N1 / -N2 / -N4 / -N8`;
- validation of bounds, epsilon, and non-finite results.

## 2. Technology stack

| Layer | Technology |
|---|---|
| Language | Haskell, GHC 9.10.3 |
| Build | cabal 3.16 |
| Concurrency | `async` (`mapConcurrently`), GHC threaded runtime |
| Timing | `time` (`getCurrentTime`, `diffUTCTime`) |
| Runtime flags | `-threaded -rtsopts -with-rtsopts=-N` |
| Interface | console CLI |
| Tests | cabal `exitcode-stdio-1.0` test suite |
| Benchmark | PowerShell script (`scripts/bench.ps1`) |

## 3. How to start the app

### Requirements

- GHC 9.10.3 and cabal 3.16
- PowerShell (for the benchmark script; the app itself is cross-platform)

### 1. Clone the repository

```bash
git clone https://github.com/valeria-chelushkina/func-programming-labs.git
cd func-programming-labs/lab2
```

### 2. Build

```powershell
cabal update
cabal build
```

The first build downloads `async` and compiles the project; later builds are
incremental.

### 3. Run

```powershell
cabal run lab2 -- --list-functions
cabal run lab2 -- --function x2 0 1 1e-9
```

Defaults: `--function inv`, `--mode both`, `A = 0`, `B = 1`, `ε = 1e-6`.

## 4. Main architecture

```
lab2/
├── lab2.cabal               build + test suite + -threaded flags
├── cabal.project
├── app/Main.hs              CLI parsing, validation, timing, output
├── src/Integrands.hs        selectable functions (name, description, f)
├── src/Integration.hs       midpoint rule, error control, parallel driver
├── test/Check.hs            correctness checks (cabal test)
└── scripts/bench.ps1        sequential/parallel benchmark
```

| Layer | Responsibility |
|---|---|
| `Main` | parse arguments, validate input, run selected mode, print results |
| `Integrands` | the registry of available `f(x)` functions |
| `Integration` | numerical rule, interval refinement, parallel chunks |
| `test/Check.hs` | compare results with known exact integrals |
| `bench.ps1` | run `-N1..-N8` and print a speedup table |

Data flow:

```
argv
  → Main (parse + validate)
  → Integrands (choose f)
  → Integration
       ├── sequential: midpointRule
       └── parallel:   midpointRuleParallel (async chunks)
  → IntegrationResult
  → printed value / intervals / error / time
```

### Integration algorithm

For `n` equal subintervals of `[A, B]`, with `h = (B − A) / n`:

$$M(n) = h \sum_{i=0}^{n-1} f\left(A + \left(i+\tfrac12\right)h\right)$$

The grid is doubled until the Richardson estimate is within `ε`:

```text
err   = |M(2n) − M(n)| / 3
value = M(2n) + (M(2n) − M(n)) / 3
```

The returned value is extrapolated, not the raw midpoint sum. The internal
limit is `2^20` intervals; if it is reached first, the program prints a warning.

### Parallel decomposition

`midpointRuleParallel` asks `getNumCapabilities`, divides the interval into
`min capabilities n` chunks, evaluates every chunk with `mapConcurrently`, and
sums the partial results. The sequential driver evaluates the same chunks on
one thread.

## 5. Main CLI interface

```
lab2 [--function NAME] [--mode seq|par|both] [--quiet] [A B EPSILON]
lab2 --list-functions
```

| Option | Meaning |
|---|---|
| `--function NAME` | choose an integrand (`x2`, `sin`, `inv`, …) |
| `--mode seq` | run only the sequential implementation |
| `--mode par` | run only the parallel implementation |
| `--mode both` | run both and print the difference (default) |
| `--quiet`, `-q` | print only the numeric result |
| `--list-functions` | list available functions |
| `A B EPSILON` | integration bounds and requested precision |

Examples:

```powershell
cabal run lab2 -- --function x2 0 1 1e-9
cabal run lab2 -- --function sin 0 3.141592653589793 1e-8
cabal run lab2 -- --mode par --function gauss -2 2 1e-6
cabal run lab2 -- -q --function inv 0 1 1e-10
```

Available functions:

| Name | f(x) |
|---|---|
| `x2` | x² |
| `poly` | x³ − 2x + 1 |
| `sin` | sin(x) |
| `cos` | cos(x) |
| `exp` | eˣ |
| `gauss` | e^(−x²) |
| `heavy` | sum sin(kx), k = 1..20 — benchmark |
| `sqrt` | √x |
| `log` | ln(x) |
| `inv` | 4 / (1 + x²) — π on [0, 1] |

To add a function:

```haskell
NamedFunction "my" "my function" (\x -> x * sin x)
```

### Validation

- `A`, `B`, `ε` must be finite;
- `ε > 0`;
- `A ≠ B`;
- if `A > B`, bounds are swapped and the result is negated;
- a `NaN`/`Infinity` result (e.g. `log` on an invalid interval) is rejected
  with an error and exit code `1` instead of being printed.

## 6. Example output

This lab has no GUI; the interface is the terminal.

```powershell
cabal run lab2 -- --mode both --function inv 0 1 1e-9
```

```
function     = inv  (4 / (1 + x^2)  (pi on [0,1]))
interval     = [0.0, 1.0]
epsilon      = 1.0e-9
capabilities = 12

Sequential (midpoint rule):
  value      = 3.1415926535897802
  intervals  = 16384
  error est. = 3.104442628891017e-10
  time       = 0.001 s

Parallel (midpoint rule):
  value      = 3.1415926535897922
  intervals  = 16384
  error est. = 3.104408582051595e-10
  time       = 0.003 s

difference between methods = 1.199040866595169e-14
```

Quiet mode:

```powershell
cabal run lab2 -- -q --function x2 0 1 1e-8
# 0.3333333333333333
```

Invalid domain:

```powershell
cabal run lab2 -- --function log -1 1 1e-6
# error: integral result is NaN or Infinity (check the function domain on [A, B])
```

## 7. Correctness checks

```powershell
cabal test
```

| Integral | Exact value |
|---|---|
| ∫₀¹ x² dx | 1/3 |
| ∫₀¹ 4/(1+x²) dx | π |
| ∫₀^π sin x dx | 2 |
| ∫₀¹ eˣ dx | e − 1 |
| ∫₀¹ (x³ − 2x + 1) dx | 1/4 |

Both sequential and parallel implementations are checked. Expected result:

```
[PASS] ... (sequential)
[PASS] ... (parallel)
ALL INTEGRATION CHECKS PASSED
Test suite lab2-tests: PASS
```

## 8. Benchmark

```powershell
.\scripts\bench.ps1
```

The script runs the sequential version and the parallel version with
`-N1/-N2/-N4/-N8`, averages several runs, and prints a table. Example on a
12-thread machine (`heavy`, `ε = 1e-10`):

| N | mode | time (s) | speedup |
|---:|---|---:|---:|
| 1 | seq | 1.345 | 1.00× |
| 1 | par | 1.241 | 1.08× |
| 2 | par | 0.591 | 2.28× |
| 4 | par | 0.315 | 4.28× |
| 8 | par | 0.197 | 6.84× |

Small integrands finish in microseconds, so use a heavier `f` or a tighter
epsilon to see scaling.
