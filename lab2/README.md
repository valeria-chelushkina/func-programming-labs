# Lab 2 — Parallel numerical integration

Multithreaded Haskell application that computes a definite integral

\[
J(A,B) = \int_A^B f(x)\,dx
\]

with a requested precision, using parallel algorithms. GHC is compiled with
`-threaded`; the RTS starts with all available capabilities (`-N`).

The function, bounds, and precision are **chosen by the user at runtime** —
there is no single hardcoded variant. A set of standard integrands is built in;
you can add your own in `src/Integrands.hs`.

## Structure

```
lab2/
├── lab2.cabal
├── cabal.project
├── app/Main.hs          CLI: function, bounds, epsilon, mode, timing
├── src/Integrands.hs    selectable functions
├── src/Integration.hs   midpoint rule, Richardson control, parallel driver
└── scripts/Check.hs     checks against known integrals
```

## Build and run

```powershell
cd lab2
cabal build
cabal run lab2 -- --list-functions
```

Examples:

```powershell
# default: 4/(1+x^2) on [0,1] -> pi
cabal run lab2

# choose a function and bounds
cabal run lab2 -- --function x2 0 1 1e-9
cabal run lab2 -- --function sin 0 3.141592653589793 1e-8
cabal run lab2 -- --function gauss -2 2 1e-6

# time each implementation separately
cabal run lab2 -- --mode seq --function inv 0 1 1e-11
cabal run lab2 -- --mode par --function inv 0 1 1e-11
```

CLI:

```
lab2 [--function NAME] [--mode seq|par|both] [A B EPSILON]
lab2 --list-functions
```

Defaults: `--function inv`, `--mode both`, `A = 0`, `B = 1`,
`EPSILON = 1e-6`.

## What the program does

1. Validates `EPSILON > 0` and `A != B`.
2. If `A > B`, swaps the bounds and negates the result.
3. Doubles the number of midpoint-rule intervals until the Richardson error
   estimate is at most `EPSILON`.
4. Prints, for the selected mode(s):

```
value      = ...
intervals  = ...
error est. = ...
time       = ... s
```

If the internal limit of `2^20` intervals is reached before the requested
precision, the result is printed with a warning.

### Error control

For the composite midpoint rule, doubling the grid gives

```text
err   = |M(2n) - M(n)| / 3
value = M(2n) + (M(2n) - M(n)) / 3
```

The returned value is the Richardson-extrapolated one, not the raw midpoint
sum.

## Available functions

| Name | f(x) |
|---|---|
| `x2` | x² |
| `poly` | x³ − 2x + 1 |
| `sin` | sin(x) |
| `cos` | cos(x) |
| `exp` | eˣ |
| `gauss` | e^(−x²) |
| `sqrt` | √x |
| `log` | ln(x) |
| `inv` | 4 / (1 + x²) — π on [0, 1] |

To add another function, append a `NamedFunction` to `functions` in
`src/Integrands.hs`:

```haskell
NamedFunction "my" "my function" (\x -> x * sin x)
```

Keep the interval inside the function's domain (`log` and `sqrt` need a
positive lower bound).

## How the parallel version works

`midpointRuleParallel` asks `getNumCapabilities`, splits the interval into
`min capabilities n` chunks, evaluates each chunk's partial sum in a separate
`async` worker with `mapConcurrently`, and adds the partial sums.

`-threaded` enables the multithreaded runtime; `-with-rtsopts=-N` uses all
available capabilities. To compare, run with `+RTS -N1` and `+RTS -N4`.

## Correctness checks

```powershell
cabal exec -- runghc -isrc scripts\Check.hs
```

The script verifies sequential and parallel results against known integrals:

| Integral | Exact value |
|---|---|
| ∫₀¹ x² dx | 1/3 |
| ∫₀¹ 4/(1+x²) dx | π |
| ∫₀^π sin x dx | 2 |
| ∫₀¹ eˣ dx | e − 1 |
| ∫₀¹ (x³ − 2x + 1) dx | 1/4 |

## Next steps

- implement a different quadrature rule if the lab prescribes one
  (trapezoid / Simpson);
- reuse evaluations between refinements instead of recomputing the grid;
- compare sequential and parallel timings with `+RTS -N1 -s` vs `+RTS -N4 -s`;
- add a short report with the timing table and speedup.
