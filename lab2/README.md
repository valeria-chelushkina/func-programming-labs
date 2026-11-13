# Lab 2 — Parallel numerical integration

Multithreaded Haskell application that computes a definite integral

\[
J(A,B) = \int_A^B f(x)\,dx
\]

with a requested precision, using parallel algorithms. GHC is compiled with
`-threaded`; the RTS starts with all available capabilities (`-N`).

This is the **starting point**: a working midpoint-rule integration with a
sequential and a parallel implementation. Replace `f` with the function from
your variant and refine the algorithm if the lab requires another rule.

## Structure

```
lab2/
├── lab2.cabal
├── cabal.project
├── app/Main.hs          CLI: parse A, B, epsilon; print results
└── src/Integration.hs   midpoint rule, sequential/parallel drivers
```

## Build and run

```powershell
cd lab2
cabal build
cabal run lab2
```

Defaults: `A = 0`, `B = 1`, `epsilon = 1e-6`.

Or pass the bounds and precision explicitly:

```powershell
cabal run lab2 -- 0 1 1e-8
```

The program prints:

- the value, number of subintervals, and error estimate for the sequential run;
- the same for the parallel run;
- the difference between the two results.

## How the parallel version works

`midpointRuleParallel` splits the `[A, B]` interval into 8 chunks, evaluates
each chunk's partial sum in a separate `async` worker with
`mapConcurrently`, then adds the partial sums. The number of subintervals is
doubled until the change between two successive approximations is at most
`epsilon`.

`-threaded` in `ghc-options` enables the multithreaded runtime; the default
`-with-rtsopts=-N` uses all CPU cores.

## Demo function

`app/Main.hs` currently uses

```haskell
f x = 4 / (1 + x * x)
```

so the default run approximates \(\pi\) on `[0, 1]`. Replace it with the
integrand from your variant.

## Next steps

- implement the exact quadrature rule required by the variant;
- improve the error estimate / stopping criterion;
- tune the number of chunks (e.g. one per capability);
- compare sequential and parallel timings with `+RTS -s`.
