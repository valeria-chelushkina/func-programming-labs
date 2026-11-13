# Lab 3 — Textbook text processing

Haskell application for processing a programming textbook stored in a text
file. The program works with domain types `Symbol`, `Punctuation`, `Word`,
`Sentence`, and `Document`.

The assignment query:

> Find a word in the first sentence that does not occur in any other sentence.

All text formation normalizes tabs and repeated spaces to a single space.

**Status:** complete — file reading, whitespace normalization, sentence/word
tokenization, the final query, and tests are implemented.

## Structure

```
lab3/
├── lab3.cabal
├── cabal.project
├── app/Main.hs              CLI: read file, print summary, call analysis
├── src/Text/Types.hs        Symbol, Punctuation, Word, Sentence, Document
├── src/Text/Normalize.hs    tabs/spaces -> one space
├── src/Text/Tokenize.hs     text -> sentences -> words
├── src/Text/Analysis.hs     find word(s) only in the first sentence
├── test/Check.hs            normalization/tokenization/query tests
└── data/sample.txt          small demo text
```

## Build and run

```powershell
cd lab3
cabal build
cabal run lab3
```

Use a specific file:

```powershell
cabal run lab3 -- path\to\textbook.txt
```

Current output:

```
file      = data/sample.txt
sentences = 3
words[1]  = 5
words     = 13
result    = Функціональне
```

## What is implemented

- reading a UTF-8 text file;
- normalizing all whitespace runs (including tabs and newlines) to one space;
- splitting into sentences on `.`, `!`, `?`, preserving the actual terminator;
- not splitting decimals (`3.14`) or common abbreviations (`т.д.`, `e.g.`);
- splitting sentences into words and stripping surrounding punctuation;
- domain types for symbols, punctuation, words, sentences, and the document;
- finding words that occur only in the first sentence;
- case-insensitive comparison and duplicate removal;
- tests for normalization, tokenization, punctuation, abbreviations, and the query.

## Tests

```powershell
cabal test
```

The test suite covers:

- tabs/spaces normalization;
- sentence splitting;
- preserved sentence terminators;
- decimals and common abbreviations;
- last sentence without a terminator;
- the main query;
- case-insensitive matching;
- duplicates in the first sentence;
- punctuation stripping;
- single-sentence and empty documents.

## Next steps

1. Decide how to treat hyphenated words and numbers.
2. Handle quotes and parentheses around sentence boundaries.
3. Run the program on the real textbook file.
