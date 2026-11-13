module Text.Normalize
  ( normalizeWhitespace
  ) where

import Data.Text (Text)
import qualified Data.Text as T

-- | Replace tabs, newlines, and runs of spaces with a single space.
--
-- @T.words@ splits on every kind of whitespace and @T.unwords@ joins the
-- pieces with exactly one space.
normalizeWhitespace :: Text -> Text
normalizeWhitespace = T.unwords . T.words
