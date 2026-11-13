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
├── app/Main.hs          CLI: choose function, A, B, epsilon; print results
├── src/Integrands.hs    selectable functions
└── src/Integration.hs   midpoint rule, sequential/parallel drivers
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
```

Default values: `--function inv`, `A = 0`, `B = 1`, `epsilon = 1e-6`.

The program prints:

- the chosen function, interval, and epsilon;
- value, number of subintervals, and error estimate for the sequential run;
- the same for the parallel run;
- the difference between the two results.

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

Keep the integration interval inside the function's domain (`log` and `sqrt`
need a positive lower bound).

## How the parallel version works

`midpointRuleParallel` splits the `[A, B]` interval into 8 chunks, evaluates
each chunk's partial sum in a separate `async` worker with
`mapConcurrently`, then adds the partial sums. The number of subintervals is
doubled until the change between two successive approximations is at most
`epsilon`.

`-threaded` in `ghc-options` enables the multithreaded runtime; the default
`-with-rtsopts=-N` uses all CPU cores.

## Next steps

- implement the exact quadrature rule required by the lab (midpoint, trapezoid,
  Simpson) if it is prescribed;
- improve the error estimate / stopping criterion;
- choose the chunk count from `getNumCapabilities`;
- compare sequential and parallel timings with `+RTS -N1` vs `+RTS -N4`.
