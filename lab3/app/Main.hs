{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.ByteString as BS
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.IO as TIO
import System.Environment (getArgs)
import System.IO (hSetEncoding, stdout, utf8)

import Text.Analysis (findWordOnlyInFirst, findWordsOnlyInFirst)
import Text.Normalize (normalizeWhitespace)
import Text.Tokenize (toDocument)
import Text.Types

main :: IO ()
main = do
  hSetEncoding stdout utf8
  args <- getArgs
  let allFlag = any isAllFlag args
      path = case filter (not . isAllFlag) args of
        (p : _) -> p
        []      -> "data/sample.txt"
  bytes <- BS.readFile path
  let raw = TE.decodeUtf8 bytes
      doc = toDocument (normalizeWhitespace raw)

  putStrLn ("file      = " ++ path)
  printSummary doc
  if allFlag
    then printAllCandidates doc
    else printFirstCandidate doc

isAllFlag :: String -> Bool
isAllFlag s = s `elem` ["--all", "--all-candidates"]

printFirstCandidate :: Document -> IO ()
printFirstCandidate doc =
  case findWordOnlyInFirst doc of
    Nothing -> putStrLn "result    = no such word"
    Just w  -> TIO.putStrLn ("result    = " <> unWord w)

printAllCandidates :: Document -> IO ()
printAllCandidates doc =
  case findWordsOnlyInFirst doc of
    []  -> putStrLn "result    = no such word"
    ws  -> TIO.putStrLn ("result    = " <> T.intercalate ", " (map unWord ws))

printSummary :: Document -> IO ()
printSummary doc = do
  let sentences = documentSentences doc
      wordCount = sum (map (length . sentenceWords) sentences)
  putStrLn ("sentences = " ++ show (length sentences))
  case sentences of
    []    -> putStrLn "words[1]  = 0"
    (s:_) -> putStrLn ("words[1]  = " ++ show (length (sentenceWords s)))
  putStrLn ("words     = " ++ show wordCount)
