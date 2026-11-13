-- | Correctness checks against known integrals.
--
-- Run from lab2/:
--   cabal exec -- runghc -isrc scripts\Check.hs
module Main where

import Control.Monad (unless)
import Data.List (find)

import Integrands
import Integration

cases :: [(String, String, Double, Double, Double)]
cases =
  [ ("x^2 on [0,1]",        "x2",   0, 1, 1 / 3)
  , ("4/(1+x^2) on [0,1]",  "inv",  0, 1, pi)
  , ("sin(x) on [0,pi]",    "sin",  0, pi, 2)
  , ("exp(x) on [0,1]",     "exp",  0, 1, exp 1 - 1)
  , ("x^3-2x+1 on [0,1]",   "poly", 0, 1, 0.25)
  ]

main :: IO ()
main = do
  results <- mapM check cases
  unless (and results) (ioError (userError "integration check failed"))
  putStrLn ""
  putStrLn "ALL INTEGRATION CHECKS PASSED"

check :: (String, String, Double, Double, Double) -> IO Bool
check (label, fname, a, b, exact) =
  case findFunction fname of
    Nothing -> do
      putStrLn ("[FAIL] " <> label <> ": unknown function " <> fname)
      pure False
    Just fn -> do
      let eps = 1e-8
          seqR = integrateSequential (fnValue fn) a b eps
      parR <- integrateParallel (fnValue fn) a b eps
      let tol = 1e-6
          okS = abs (resultValue seqR - exact) <= tol
          okP = abs (resultValue parR - exact) <= tol
      report label "sequential" okS (resultValue seqR) exact
      report label "parallel" okP (resultValue parR) exact
      pure (okS && okP)

report :: String -> String -> Bool -> Double -> Double -> IO ()
report label mode ok got exact =
  putStrLn
    ((if ok then "[PASS] " else "[FAIL] ")
      <> label <> " (" <> mode <> "): got " <> show got
      <> ", expected " <> show exact)
