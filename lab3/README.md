# Lab 3 — Textbook text processing

Haskell application for processing a programming textbook stored in a text
file. The program works with domain types `Symbol`, `Punctuation`, `Word`,
`Sentence`, and `Document`.

The assignment query:

> Find a word in the first sentence that does not occur in any other sentence.

All text formation normalizes tabs and repeated spaces to a single space.

**Status:** project scaffold. File reading, whitespace normalization, sentence
and word tokenization are implemented; the final query is a TODO.

## Structure

```
lab3/
├── lab3.cabal
├── cabal.project
├── app/Main.hs              CLI: read file, print summary, call analysis
├── src/Text/Types.hs        Symbol, Punctuation, Word, Sentence, Document
├── src/Text/Normalize.hs    tabs/spaces -> one space
├── src/Text/Tokenize.hs     text -> sentences -> words
├── src/Text/Analysis.hs     TODO: findWordOnlyInFirst
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
result    = TODO: analysis is not implemented yet
```

## What is implemented

- reading a UTF-8 text file;
- normalizing all whitespace runs (including tabs and newlines) to one space;
- splitting into sentences on `.`, `!`, `?`;
- splitting sentences into words and stripping surrounding punctuation;
- domain types for symbols, punctuation, words, sentences, and the document.

## Next steps

1. Implement `findWordOnlyInFirst` in `src/Text/Analysis.hs`.
2. Decide whether word comparison is case-sensitive.
3. Preserve the actual sentence terminator instead of always using `Period`.
4. Add tests for normalization, tokenization, and the final query.
