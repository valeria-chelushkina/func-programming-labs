module Main where

import System.Environment (getArgs)
import Text.Read (readMaybe)

import Integration

-- | Demo integrand. Replace it with the function required by your variant.
-- For [0, 1] this integrates to pi.
f :: Double -> Double
f x = 4 / (1 + x * x)

main :: IO ()
main = do
  args <- getArgs
  case parseArgs args of
    Left err -> do
      putStrLn ("error: " <> err)
      putStrLn usage
    Right (a, b, eps) -> do
      putStrLn ("f(x) = 4 / (1 + x^2), interval [" <> show a <> ", " <> show b <> "]")
      putStrLn ("epsilon = " <> show eps)
      putStrLn ""

      let seqResult = integrateSequential f a b eps
      parResult <- integrateParallel f a b eps

      putStrLn "Sequential (midpoint rule):"
      printResult seqResult
      putStrLn ""
      putStrLn "Parallel (midpoint rule, 8 chunks):"
      printResult parResult
      putStrLn ""
      putStrLn ("difference between methods = "
                <> show (abs (resultValue seqResult - resultValue parResult)))
      putStrLn ("reference pi (for [0,1])   = " <> show (pi :: Double))

printResult :: IntegrationResult -> IO ()
printResult r = do
  putStrLn ("  value      = " <> show (resultValue r))
  putStrLn ("  intervals  = " <> show (resultIntervals r))
  putStrLn ("  error est. = " <> show (resultError r))

usage :: String
usage = "usage: lab2 [A B EPSILON]   (default: 0 1 1e-6)"

parseArgs :: [String] -> Either String (Double, Double, Double)
parseArgs [] = Right (0, 1, 1e-6)
parseArgs [a, b, eps] =
  (,,) <$> readDouble a <*> readDouble b <*> readDouble eps
parseArgs _ = Left "expected 0 or 3 arguments"

readDouble :: String -> Either String Double
readDouble s =
  case readMaybe s of
    Just x  -> Right x
    Nothing -> Left ("not a number: " <> s)
