{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Exception (evaluate)
import Control.Monad (when)
import Data.Time.Clock (UTCTime, diffUTCTime, getCurrentTime)
import GHC.Conc (getNumCapabilities)
import System.Environment (getArgs)
import Text.Printf (printf)
import Text.Read (readMaybe)

import Integrands
import Integration

data Mode = ModeSeq | ModePar | ModeBoth
  deriving (Eq, Show)

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
      Right (fn, mode, a, b, eps) ->
        case validate a b eps of
          Left err -> do
            putStrLn ("error: " <> err)
            putStrLn ""
            putStrLn usage
          Right () -> do
            caps <- getNumCapabilities
            let (lo, hi, sign) = normalizeBounds a b
            putStrLn ("function     = " <> fnName fn <> "  (" <> fnDescription fn <> ")")
            putStrLn ("interval     = [" <> show lo <> ", " <> show hi <> "]")
            putStrLn ("epsilon      = " <> show eps)
            putStrLn ("capabilities = " <> show caps)
            putStrLn ""

            let runSeq = do
                  start <- getCurrentTime
                  let r = signed sign (integrateSequential (fnValue fn) lo hi eps)
                  _ <- evaluate (resultValue r)
                  end <- getCurrentTime
                  pure (r, elapsed start end)
                runPar = do
                  start <- getCurrentTime
                  r0 <- integrateParallel (fnValue fn) lo hi eps
                  let r = signed sign r0
                  _ <- evaluate (resultValue r)
                  end <- getCurrentTime
                  pure (r, elapsed start end)

            case mode of
              ModeSeq -> do
                (r, t) <- runSeq
                printResult "Sequential (midpoint rule)" r t
              ModePar -> do
                (r, t) <- runPar
                printResult "Parallel (midpoint rule)" r t
              ModeBoth -> do
                (r1, t1) <- runSeq
                (r2, t2) <- runPar
                printResult "Sequential (midpoint rule)" r1 t1
                putStrLn ""
                printResult "Parallel (midpoint rule)" r2 t2
                putStrLn ""
                putStrLn ("difference between methods = "
                          <> show (abs (resultValue r1 - resultValue r2)))

printResult :: String -> IntegrationResult -> Double -> IO ()
printResult label r t = do
  putStrLn (label <> ":")
  putStrLn ("  value      = " <> show (resultValue r))
  putStrLn ("  intervals  = " <> show (resultIntervals r))
  putStrLn ("  error est. = " <> show (resultError r))
  printf "  time       = %.3f s\n" t
  when (resultLimitReached r) $
    putStrLn "  warning    = maximum interval count reached; epsilon may not be met"

elapsed :: UTCTime -> UTCTime -> Double
elapsed start end = realToFrac (diffUTCTime end start)

validate :: Double -> Double -> Double -> Either String ()
validate a b eps
  | eps <= 0   = Left "epsilon must be positive"
  | a == b     = Left "A and B must be different"
  | otherwise  = Right ()

normalizeBounds :: Double -> Double -> (Double, Double, Double)
normalizeBounds a b
  | a <= b    = (a, b, 1)
  | otherwise = (b, a, -1)

signed :: Double -> IntegrationResult -> IntegrationResult
signed sign r = r { resultValue = sign * resultValue r }

listFunctions :: IO ()
listFunctions = do
  putStrLn "Available functions:"
  mapM_ (\f -> putStrLn ("  " <> pad (fnName f) <> "  " <> fnDescription f)) functions
  putStrLn ""
  putStrLn "usage: lab2 [--function NAME] [--mode seq|par|both] [A B EPSILON]"
  where
    pad s = s ++ replicate (max 0 (8 - length s)) ' '

usage :: String
usage = unlines
  [ "usage: lab2 [--function NAME] [--mode seq|par|both] [A B EPSILON]"
  , "       lab2 --list-functions"
  , ""
  , "default: --function inv --mode both, A = 0, B = 1, EPSILON = 1e-6"
  , "example: lab2 --function sin --mode par 0 3.141592653589793 1e-8"
  ]

parseArgs :: [String] -> Either String (NamedFunction, Mode, Double, Double, Double)
parseArgs = go defaultFunction ModeBoth
  where
    go fn mode [] = Right (fn, mode, 0, 1, 1e-6)

    go _ mode ("--function" : name : rest) =
      case findFunction name of
        Nothing -> Left ("unknown function: " <> name <> " (try --list-functions)")
        Just f  -> go f mode rest

    go _ _ ["--function"] = Left "--function needs a name"

    go fn _ ("--mode" : name : rest) =
      case parseMode name of
        Nothing -> Left ("unknown mode: " <> name <> " (seq, par, both)")
        Just m  -> go fn m rest

    go _ _ ["--mode"] = Left "--mode needs a value"

    go fn mode [a, b, eps] = do
      a'   <- readDouble a
      b'   <- readDouble b
      eps' <- readDouble eps
      pure (fn, mode, a', b', eps')

    go _ _ _ = Left "expected A B EPSILON after the options"

parseMode :: String -> Maybe Mode
parseMode "seq"        = Just ModeSeq
parseMode "par"        = Just ModePar
parseMode "both"       = Just ModeBoth
parseMode "sequential" = Just ModeSeq
parseMode "parallel"   = Just ModePar
parseMode _            = Nothing

readDouble :: String -> Either String Double
readDouble s =
  case readMaybe s of
    Just x  -> Right x
    Nothing -> Left ("not a number: " <> s)
