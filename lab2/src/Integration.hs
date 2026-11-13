{-# LANGUAGE BangPatterns #-}

-- | Numerical integration rules and parallel/sequential drivers.
--
-- This is the starting point for the lab: the composite midpoint rule is
-- evaluated over equal subintervals, and the number of intervals is doubled
-- until the change between two approximations is below the requested epsilon.
module Integration
  ( IntegrationResult (..)
  , Rule
  , midpointRule
  , midpointRuleParallel
  , integrateSequential
  , integrateParallel
  ) where

import Control.Concurrent.Async (mapConcurrently)
import Control.Exception (evaluate)

-- | Result of one integration run.
data IntegrationResult = IntegrationResult
  { resultValue     :: Double  -- ^ approximation of the integral
  , resultIntervals :: Int     -- ^ number of subintervals used
  , resultError     :: Double  -- ^ |I(2n) - I(n)| estimate
  } deriving (Show, Eq)

-- | A sequential quadrature rule: function, bounds, number of subintervals.
type Rule = (Double -> Double) -> Double -> Double -> Int -> Double

-- | A parallel quadrature rule (runs in IO so it can use worker threads).
type RuleIO = (Double -> Double) -> Double -> Double -> Int -> IO Double

-- | Composite midpoint rule, evaluated on one thread.
midpointRule :: Rule
midpointRule f a b n =
  let h = (b - a) / fromIntegral n
   in h * chunkSum f a h 0 n

-- | Composite midpoint rule split into chunks, one thread per chunk.
--
-- Each chunk is evaluated with 'evaluate' inside 'mapConcurrently', so the
-- work really runs on multiple capabilities (with GHC's @-threaded@ runtime).
midpointRuleParallel :: RuleIO
midpointRuleParallel f a b n = do
  let h = (b - a) / fromIntegral n
      chunkSize = max 1 ((n + chunks - 1) `div` chunks)
      ranges = chunkRanges chunkSize n
  partials <- mapConcurrently
    (\(lo, hi) -> evaluate (chunkSum f a h lo hi))
    ranges
  pure (h * sum partials)
  where
    chunks = 8

chunkSum :: (Double -> Double) -> Double -> Double -> Int -> Int -> Double
chunkSum f a h lo hi = go lo 0
  where
    go !i !acc
      | i >= hi   = acc
      | otherwise = go (i + 1) (acc + f (a + (fromIntegral i + 0.5) * h))

chunkRanges :: Int -> Int -> [(Int, Int)]
chunkRanges size total = go 0
  where
    go lo
      | lo >= total = []
      | otherwise   = (lo, min total (lo + size)) : go (lo + size)

integrateSequential :: (Double -> Double) -> Double -> Double -> Double -> IntegrationResult
integrateSequential = refine midpointRule

integrateParallel :: (Double -> Double) -> Double -> Double -> Double -> IO IntegrationResult
integrateParallel = refineIO midpointRuleParallel

-- | Double the number of intervals until the approximation stops changing
-- by more than @eps@. The final error is an estimate, not a guaranteed bound.
refine :: Rule -> (Double -> Double) -> Double -> Double -> Double -> IntegrationResult
refine rule f a b eps = go 1 (rule f a b 1)
  where
    maxIntervals = 2 ^ (20 :: Int)
    go !n !prev =
      let n'  = n * 2
          cur = rule f a b n'
          err = abs (cur - prev)
       in if err <= eps || n' >= maxIntervals
            then IntegrationResult cur n' err
            else go n' cur

refineIO :: RuleIO -> (Double -> Double) -> Double -> Double -> Double -> IO IntegrationResult
refineIO rule f a b eps = do
  prev <- rule f a b 1
  go 1 prev
  where
    maxIntervals = 2 ^ (20 :: Int)
    go !n !prev = do
      let n' = n * 2
      cur <- rule f a b n'
      let err = abs (cur - prev)
      if err <= eps || n' >= maxIntervals
        then pure (IntegrationResult cur n' err)
        else go n' cur
