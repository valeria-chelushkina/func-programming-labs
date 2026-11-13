-- | Selectable integrands. Add your own function here.
module Integrands
  ( NamedFunction (..)
  , functions
  , findFunction
  , defaultFunction
  ) where

import Data.List (find)
import Data.Maybe (fromMaybe)

data NamedFunction = NamedFunction
  { fnName        :: String
  , fnDescription :: String
  , fnValue       :: Double -> Double
  }

functions :: [NamedFunction]
functions =
  [ NamedFunction "x2"    "x^2"                          (\x -> x * x)
  , NamedFunction "poly"  "x^3 - 2x + 1"                 (\x -> x ** 3 - 2 * x + 1)
  , NamedFunction "sin"   "sin(x)"                       sin
  , NamedFunction "cos"   "cos(x)"                       cos
  , NamedFunction "exp"   "exp(x)"                       exp
  , NamedFunction "gauss" "exp(-x^2)"                    (\x -> exp (-(x * x)))
  , NamedFunction "heavy" "sum sin(k*x), k=1..20 (benchmark)" (\x -> sum [sin (fromIntegral k * x) | k <- [1 .. 20 :: Int]])
  , NamedFunction "sqrt"  "sqrt(x)"                      sqrt
  , NamedFunction "log"   "log(x)"                       log
  , NamedFunction "inv"   "4 / (1 + x^2)  (pi on [0,1])" (\x -> 4 / (1 + x * x))
  ]

findFunction :: String -> Maybe NamedFunction
findFunction name = find ((== name) . fnName) functions

defaultFunction :: NamedFunction
defaultFunction = fromMaybe (error "Integrands: no functions defined") (findFunction "inv")
