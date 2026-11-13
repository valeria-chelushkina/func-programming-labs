{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.ByteString as BS
import qualified Data.Text.Encoding as TE
import qualified Data.Text.IO as TIO
import System.Environment (getArgs)
import System.IO (hSetEncoding, stdout, utf8)

import Text.Analysis (findWordOnlyInFirst)
import Text.Normalize (normalizeWhitespace)
import Text.Tokenize (toDocument)
import Text.Types

main :: IO ()
main = do
  hSetEncoding stdout utf8
  args <- getArgs
  let path = case args of
        (p : _) -> p
        []      -> "data/sample.txt"
  bytes <- BS.readFile path
  let raw = TE.decodeUtf8 bytes
      doc = toDocument (normalizeWhitespace raw)

  putStrLn ("file      = " ++ path)
  printSummary doc
  case findWordOnlyInFirst doc of
    Nothing -> putStrLn "result    = TODO: analysis is not implemented yet"
    Just w  -> TIO.putStrLn ("result    = " <> unWord w)

printSummary :: Document -> IO ()
printSummary doc = do
  let sentences = documentSentences doc
      wordCount = sum (map (length . sentenceWords) sentences)
  putStrLn ("sentences = " ++ show (length sentences))
  case sentences of
    []    -> putStrLn "words[1]  = 0"
    (s:_) -> putStrLn ("words[1]  = " ++ show (length (sentenceWords s)))
  putStrLn ("words     = " ++ show wordCount)
