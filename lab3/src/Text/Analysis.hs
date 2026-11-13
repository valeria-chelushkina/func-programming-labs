module Text.Analysis
  ( findWordOnlyInFirst
  ) where

import Prelude hiding (Word)
import Text.Types

-- | Find a word that occurs in the first sentence and in no other sentence.
--
-- TODO: implement the actual comparison. The intended approach is:
--
--   1. take the words of the first sentence;
--   2. collect the words of every other sentence;
--   3. return the first word from step 1 that is absent from step 2.
--
-- Decide whether comparison should be case-sensitive; for a textbook,
-- case-insensitive matching is usually preferable.
findWordOnlyInFirst :: Document -> Maybe Word
findWordOnlyInFirst _ = Nothing
