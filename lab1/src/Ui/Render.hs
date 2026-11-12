{-# LANGUAGE OverloadedStrings #-}

-- | Turning domain values into console output.
module Ui.Render
  ( printResource
  ) where

import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Model.Resource (Resource (..))

printResource :: Resource -> IO ()
printResource r =
  TIO.putStrLn ("  #" <> T.pack (show (resId r)) <> "  " <> resName r)
