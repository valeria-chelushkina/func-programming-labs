# Lab Work 3 — Variant 3 — Textbook text processing

Haskell application that processes a programming textbook stored in a text
file. It works with the domain types `Symbol`, `Punctuation`, `Word`,
`Sentence`, and `Document`, and answers the assignment query:

> Find a word in the first sentence that does not occur in any other sentence.

All text formation normalizes tabs and repeated spaces to a single space.

## 1. What this work is

Implemented features:

- read a UTF-8 text file;
- collapse tabs, newlines, and repeated spaces to one space;
- split the text into sentences and preserve the real terminator
  (`.`, `!`, `?`, or none);
- avoid splitting decimals (`3.14`) and common abbreviations (`т.д.`, `e.g.`);
- split sentences into words, stripping surrounding punctuation;
- ignore pure numbers (`3.14`, `2024`) as non-words;
- keep hyphenated words (`alpha-beta`) as one word;
- keep closing quotes/brackets with the sentence they close;
- find the first word of the first sentence that occurs nowhere else;
- `--all` mode that prints every such word;
- case-insensitive comparison with duplicate removal;
- tests for normalization, tokenization, punctuation, abbreviations, and the
  query.

## 2. Technology stack

| Layer | Technology |
|---|---|
| Language | Haskell, GHC 9.10.3 |
| Build | cabal 3.16 |
| Text | `text` (`Text`, `Text.IO`, `Text.Encoding`) |
| File I/O | `bytestring` (`ByteString`, UTF-8 decoding) |
| Sets | `containers` (`Data.Set`) |
| Windows console | `Win32` (UTF-8 code pages, Windows-only) |
| Interface | console CLI |
| Tests | cabal `exitcode-stdio-1.0` test suite |

## 3. How to start the app

### Requirements

- GHC 9.10.3 and cabal 3.16
- A UTF-8 encoded plain-text textbook file

### 1. Clone the repository

```bash
git clone https://github.com/valeria-chelushkina/func-programming-labs.git
cd func-programming-labs/lab3
```

### 2. Build

```powershell
cabal update
cabal build
```

### 3. Run

```powershell
cabal run lab3
```

The default file is `data/sample.txt`.

Use the real textbook:

```powershell
cabal run lab3 -- path\to\textbook.txt
```

Print all candidate words instead of only the first one:

```powershell
cabal run lab3 -- --all path\to\textbook.txt
```

On Windows the program switches the console to UTF-8 automatically, so
Ukrainian text is displayed correctly without a manual `chcp 65001`.

### Input format

The program reads **plain text encoded as UTF-8**. The file extension does not
matter (`txt`, `md`, `csv`, source code), but the content must be text.

| Input | Supported |
|---|---|
| UTF-8 `.txt` | ✅ |
| UTF-8 `.md`, `.csv`, source code | ✅ (treated as plain text) |
| UTF-8 with BOM | ⚠️ BOM can stick to the first word |
| UTF-16, Windows-1251 | ❌ |
| PDF, DOCX, ODT, RTF | ❌ (convert to text first) |

Convert Word/PDF files before running:

```powershell
pandoc textbook.docx -t plain -o textbook.txt
pdftotext -enc UTF-8 textbook.pdf textbook.txt
```

## 4. Main architecture

```
lab3/
├── lab3.cabal               build + test suite + Windows UTF-8 flag
├── cabal.project
├── app/Main.hs              CLI, UTF-8 console setup, summary output
├── src/Text/Types.hs        Symbol, Punctuation, Word, Sentence, Document
├── src/Text/Normalize.hs    tabs/spaces -> one space
├── src/Text/Tokenize.hs     text -> sentences -> words
├── src/Text/Analysis.hs     the main query
├── test/Check.hs            correctness tests (cabal test)
└── data/sample.txt          small demo text
```

| Layer | Responsibility |
|---|---|
| `Main` | parse flags, read file, configure console, print results |
| `Text.Normalize` | whitespace normalization required by the task |
| `Text.Tokenize` | sentence boundary detection and word extraction |
| `Text.Analysis` | first-sentence vs other-sentences comparison |
| `Text.Types` | the domain model |
| `test/Check.hs` | known cases for all of the above |

### Domain types

| Type | Meaning |
|---|---|
| `Symbol` | one character of the source text |
| `Punctuation` | `.` `!` `?` `,` `;` `:` quotes, brackets, `NoPunctuation`, … |
| `Word` | a token containing at least one letter |
| `Sentence` | `[Word]` plus the sentence terminator |
| `Document` | a list of sentences |

### Processing pipeline

```
file bytes
  → decodeUtf8
  → normalizeWhitespace
  → splitSentences        (preserves terminators, skips decimals/abbreviations)
  → toSentenceWith        (words + punctuation stripping)
  → Document
  → findWordsOnlyInFirst
  → result
```

### The query

1. Take the words of the first sentence.
2. Build the set of case-folded keys of all words in the remaining sentences.
3. Keep the first-sentence words whose key is absent from that set.
4. Remove duplicates inside the first sentence (first occurrence wins).
5. `findWordOnlyInFirst` returns the first remaining word;
   `findWordsOnlyInFirst` returns all of them.

## 5. Main CLI interface

```
lab3 [--all] [FILE]
```

| Option | Meaning |
|---|---|
| `FILE` | path to a UTF-8 text file (default `data/sample.txt`) |
| `--all`, `--all-candidates` | print every matching word, not just the first |

Output labels:

```
file      = data/sample.txt
sentences = 3
words[1]  = 5
words     = 13
result    = Функціональне
```

## 6. Example output

Default mode:

```powershell
cabal run lab3
```

```
file      = data/sample.txt
sentences = 3
words[1]  = 5
words     = 13
result    = Функціональне
```

All candidates:

```powershell
cabal run lab3 -- --all
```

```
result    = Функціональне, використовує, чисті, функції
```

No candidate:

```
result    = no such word
```

## 7. Correctness checks

```powershell
cabal test
```

The test suite covers:

- tabs/spaces normalization;
- sentence splitting;
- preserved sentence terminators;
- decimals and common abbreviations;
- last sentence without a terminator;
- numbers, hyphenated words, and closing quotes;
- the main query;
- case-insensitive matching;
- duplicates in the first sentence;
- punctuation stripping;
- single-sentence and empty documents.

Expected result:

```
[PASS] ...
ALL TEXT CHECKS PASSED
Test suite lab3-tests: PASS
