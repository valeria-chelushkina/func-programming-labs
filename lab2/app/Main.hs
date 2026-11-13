module Main where

import System.Environment (getArgs)
import Text.Read (readMaybe)

import Integrands
import Integration

main :: IO ()
main = do
  args <- getArgs
  if "--list-functions" `elem` args
    then listFunctions
    else case parseArgs args of
      Left err -> do
        putStrLn ("error: " <> err)
        putStrLn ""
        putStrLn usage
      Right (fn, a, b, eps) -> do
        putStrLn ("function  = " <> fnName fn <> "  (" <> fnDescription fn <> ")")
        putStrLn ("interval  = [" <> show a <> ", " <> show b <> "]")
        putStrLn ("epsilon   = " <> show eps)
        putStrLn ""

        let seqResult = integrateSequential (fnValue fn) a b eps
        parResult <- integrateParallel (fnValue fn) a b eps

        putStrLn "Sequential (midpoint rule):"
        printResult seqResult
        putStrLn ""
        putStrLn "Parallel (midpoint rule, 8 chunks):"
        printResult parResult
        putStrLn ""
        putStrLn ("difference between methods = "
                  <> show (abs (resultValue seqResult - resultValue parResult)))

printResult :: IntegrationResult -> IO ()
printResult r = do
  putStrLn ("  value      = " <> show (resultValue r))
  putStrLn ("  intervals  = " <> show (resultIntervals r))
  putStrLn ("  error est. = " <> show (resultError r))

listFunctions :: IO ()
listFunctions = do
  putStrLn "Available functions:"
  mapM_ (\f -> putStrLn ("  " <> pad (fnName f) <> "  " <> fnDescription f)) functions
  putStrLn ""
  putStrLn "usage: lab2 [--function NAME] [A B EPSILON]"
  where
    pad s = s ++ replicate (max 0 (8 - length s)) ' '

usage :: String
usage = unlines
  [ "usage: lab2 [--function NAME] [A B EPSILON]"
  , "       lab2 --list-functions"
  , ""
  , "default: --function inv, A = 0, B = 1, EPSILON = 1e-6"
  , "example: lab2 --function sin 0 3.141592653589793 1e-8"
  ]

parseArgs :: [String] -> Either String (NamedFunction, Double, Double, Double)
parseArgs args = do
  (mfn, rest) <- extractFunction args
  (a, b, eps) <- parseBounds rest
  pure (maybe defaultFunction id mfn, a, b, eps)

extractFunction :: [String] -> Either String (Maybe NamedFunction, [String])
extractFunction ("--function" : name : rest) =
  case findFunction name of
    Nothing -> Left ("unknown function: " <> name <> " (try --list-functions)")
    Just f  -> Right (Just f, rest)
extractFunction ["--function"] = Left "--function needs a name"
extractFunction args = Right (Nothing, args)

parseBounds :: [String] -> Either String (Double, Double, Double)
parseBounds [] = Right (0, 1, 1e-6)
parseBounds [a, b, eps] =
  (,,) <$> readDouble a <*> readDouble b <*> readDouble eps
parseBounds _ = Left "expected A B EPSILON after the function name"

readDouble :: String -> Either String Double
readDouble s =
  case readMaybe s of
    Just x  -> Right x
    Nothing -> Left ("not a number: " <> s)
