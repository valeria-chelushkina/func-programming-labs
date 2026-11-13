{-# LANGUAGE BangPatterns #-}

-- | Numerical integration rules and parallel/sequential drivers.
--
-- The composite midpoint rule is evaluated over equal subintervals, and the
-- number of intervals is doubled until the Richardson error estimate is below
-- the requested epsilon.
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
import GHC.Conc (getNumCapabilities)

-- | Result of one integration run.
data IntegrationResult = IntegrationResult
  { resultValue        :: Double  -- ^ Richardson-extrapolated approximation
  , resultIntervals    :: Int     -- ^ number of subintervals used
  , resultError        :: Double  -- ^ |I(2n) - I(n)| / 3 estimate
  , resultLimitReached :: Bool    -- ^ True if max intervals was hit first
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

-- | Composite midpoint rule split into chunks, one worker per chunk.
--
-- The chunk count is bounded by the number of capabilities and by the number
-- of subintervals, so tiny grids do not spawn useless threads.
midpointRuleParallel :: Int -> RuleIO
midpointRuleParallel caps f a b n = do
  let chunks = max 1 (min caps n)
      chunkSize = max 1 ((n + chunks - 1) `div` chunks)
      h = (b - a) / fromIntegral n
      ranges = chunkRanges chunkSize n
  partials <- mapConcurrently
    (\(lo, hi) -> evaluate (chunkSum f a h lo hi))
    ranges
  pure (h * sum partials)

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
integrateParallel f a b eps = do
  caps <- getNumCapabilities
  refineIO (midpointRuleParallel caps) f a b eps

-- | Double the number of intervals until the Richardson error estimate is
-- below @eps@. The returned value is extrapolated: @M2 + (M2 - M1) / 3@.
refine :: Rule -> (Double -> Double) -> Double -> Double -> Double -> IntegrationResult
refine rule f a b eps = go 1 (rule f a b 1)
  where
    maxIntervals = 2 ^ (20 :: Int)
    go !n !prev =
      let n'    = n * 2
          cur   = rule f a b n'
          delta = cur - prev
          err   = abs delta / 3
          value = cur + delta / 3
       in if err <= eps
            then IntegrationResult value n' err False
            else if n' >= maxIntervals
              then IntegrationResult value n' err True
              else go n' cur

refineIO :: RuleIO -> (Double -> Double) -> Double -> Double -> Double -> IO IntegrationResult
refineIO rule f a b eps = do
  prev <- rule f a b 1
  go 1 prev
  where
    maxIntervals = 2 ^ (20 :: Int)
    go !n !prev = do
      let n'    = n * 2
      cur <- rule f a b n'
      let delta = cur - prev
          err   = abs delta / 3
          value = cur + delta / 3
      if err <= eps
        then pure (IntegrationResult value n' err False)
        else if n' >= maxIntervals
          then pure (IntegrationResult value n' err True)
          else go n' cur
