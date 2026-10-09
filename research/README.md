# Mindfield for Researchers

A personal semantic memory field built from your own literature.

This directory contains tools purpose-built for individual scientists and researchers
who want a private, offline, searchable knowledge base across their entire reading history.

---

## What you get

- Semantic search across thousands of papers, notes, and lab books — by meaning, not keyword
- Citation metadata from your BibTeX library (Zotero, Mendeley, Papers) preserved in every result
- Section-aware chunking that keeps Abstract, Methods, Results intact
- arXiv integration — fetch any paper by ID, metadata included
- Jupyter notebook ingestion — lab notes, experimental write-ups, analysis narratives
- Direct note-writing — "Just read Smith 2023, key observation: X" goes straight to memory
- Source deduplication — won't re-ingest a paper you've already loaded
- Completely local, completely offline, zero cloud dependency

---

## What this is not

This is a **retrieval system**, not a generation system. It does not summarise papers,
write literature reviews, or generate responses. It finds the most relevant passages
from your own corpus for any query you give it. That is the whole deliverable.

The gap between "finds relevant passages" and "generates a coherent review" is real.
What you have is the harder part — a semantically indexed personal library.
Generation can be layered on top with any local GGUF model pointed at the results.

---

## Setup

```bash
# Install the standard dependencies first
python setup.py

# Install the research extras
pip install pymupdf          # much better academic PDF extraction
pip install pypdf            # fallback PDF extraction (already in requirements.txt)
# pypdf is included by default; pymupdf is optional but strongly recommended

# Verify
python scripts/health_check.py
```

---

## Corpus strategy

This is the most important decision you will make.

**High-signal corpus:**
- Papers you have read and found significant — not your whole download folder
- Your own notes and annotations (even rough ones — your own thinking is the point)
- Lab notebooks and experimental write-ups
- Methods sections from papers you replicate or build on
- Grant proposals and your own previous writing
- Reviews and book chapters in your domain

**Low-signal corpus:**
- Your entire download folder unfiltered (too much noise dilutes signal)
- Papers you downloaded but never read
- Standard textbooks verbatim (Wikipedia-level generality)
- News and blog posts (ephemeral, low density)

A field of 5,000 deeply engaged papers will outperform 50,000 unread downloads
every time. The retrieval quality is determined by corpus quality, not size.

**Naming convention matters:**
Files become the `source` label in search results. Name them so results are readable:

```
smith_2023_crispr_offtarget.pdf      → source: smith_2023_crispr_offtarget
jones_2021_review_memory_consolidation.pdf
my_lab_notes_q3_2024.md
protocol_patch_clamp_v3.txt
```

---

## Quick start

### 1. Ingest a directory of papers

```bash
# Dry run first — always
python research/ingest_papers.py --dry-run --dir papers/

# Ingest with BibTeX metadata from Zotero/Mendeley
python research/ingest_papers.py --ingest --dir papers/ --bib library.bib

# Ingest without BibTeX
python research/ingest_papers.py --ingest --dir papers/
```

### 2. Fetch a paper directly from arXiv

```bash
# Downloads PDF, fetches metadata, ingests in one step
python research/ingest_papers.py --arxiv 2305.12345 --ingest

# Dry run — just download and preview without ingesting
python research/ingest_papers.py --arxiv 2305.12345 --dry-run
```

### 3. Write a note directly to memory

```bash
# Your observations go straight into the field
python research/ingest_papers.py --note "Smith 2023: off-target CRISPR edits in
  heterochromatin regions — worth following up with our CHiP-seq data" --source "my_notes"
```

### 4. Search

```bash
# Semantic search — finds by meaning, not exact words
curl -X POST http://127.0.0.1:8018/search \
     -H "Content-Type: application/json" \
     -d '{"query": "CRISPR off-target effects in heterochromatin", "k": 10}'

# Filter to a specific source
curl -X POST http://127.0.0.1:8018/search \
     -H "Content-Type: application/json" \
     -d '{"query": "patch clamp protocol", "k": 5, "where": "source = '\''my_lab_notes'\''"}'

# Filter by author tag
curl -X POST http://127.0.0.1:8018/search \
     -H "Content-Type: application/json" \
     -d '{"query": "memory consolidation sleep", "k": 10, "where": "tags LIKE '\''%author:Smith%'\''"}'
```

---

## BibTeX metadata integration

Export your reference library from Zotero or Mendeley as a `.bib` file.
The ingest script matches PDF filenames to BibTeX entries by cite-key or author+year,
then stores metadata in the `tags` field of every chunk.

Each result will include tags like:
```
author:Smith
year:2023
venue:Nature Neuroscience
doi:10.1038/s41593-023-01234-5
type:paper
```

The `where` clause in search supports SQL predicates, so you can filter by any tag.

**Zotero export:**
1. Select your collection → File → Export Library → BibTeX
2. Include Abstract field (important — abstract becomes a standalone chunk)

**Mendeley export:**
1. Tools → Options → BibTeX → Enable automatic BibTeX syncing
2. Or: select papers → Export → BibTeX

---

## Domain stacks for lab projects

Each research project can have its own isolated memory field —
same search interface, different corpus.

```bash
# Copy the domain template
cp lean/domain_lean.py.template lean/genomics_lean.py

# Edit: set DOMAIN_NAME="genomics", LANCE_DB_PATH="./lancedb_genomics", LEAN_PORT="18001"

# Start it
python lean/genomics_lean.py

# Ingest into the project-specific field
python research/ingest_papers.py --ingest --dir genomics_papers/ \
    --lean-url http://127.0.0.1:18001
```

Useful for:
- Separating active project literature from general reading
- Keeping a specific methodology corpus separate from a theoretical corpus
- Isolation between collaborators on the same machine (different ports, different fields)

---

## Embedding model for scientific text

The default model (nomic-embed-text-v1.5) is a strong general-purpose English embedding
model that performs well on scientific literature.

For domain-specific scientific retrieval, alternatives exist.
If you have a GPU and want higher accuracy on scientific text, set these in `.env`:

```bash
# nomic-embed-text-v1.5 (default — balanced, CPU-friendly)
EMBED_MODEL=nomic-embed-text-v1.5
EMBED_DIM=768

# mxbai-embed-large-v1 (higher accuracy, more RAM)
EMBED_MODEL=mxbai-embed-large-v1
EMBED_DIM=1024

# snowflake-arctic-embed-m (strong retrieval accuracy)
EMBED_MODEL=snowflake-arctic-embed-m
EMBED_DIM=768
```

All of these run via llama-server with `--embedding` flag.
Download the GGUF versions from HuggingFace.

**Important:** if you change `EMBED_DIM`, you cannot search across old and new vectors.
Start a new LanceDB path (`LANCE_DB_PATH=./lancedb_v2`) and re-ingest your corpus.

---

## Lab notebook ingestion

Jupyter notebooks (`.ipynb`) are supported. The ingest script extracts:
- All markdown cells (your narrative, observations, discussion)
- Text outputs from code cells (numerical results, printed summaries)
- Raw cells

Code itself is not ingested — only prose and outputs.
This means your analysis narrative and results go into the memory field,
not Python boilerplate.

```bash
python research/ingest_papers.py --ingest --dir notebooks/
```

---

## Recommended workflow

```
New paper arrives
       │
       ▼
Read it (actually read it)
       │
       ▼
Write your own 2–3 sentence summary → --note
       │
       ▼
Ingest the PDF → ingest_papers.py
       │
       ▼
Query your field: "what does this connect to?"
       │
       ▼
Write down the connections → --note
```

The notes you write are often more valuable than the papers themselves.
Your own synthesis, in your own words, is the highest-density signal you can put in.

---

## Limitations — be honest with yourself about these

- **No OCR.** Scanned PDFs with no text layer will extract as empty. Install Tesseract
  and the `pytesseract` package if your library contains scanned papers.

- **Equation extraction is imperfect.** Mathematical content in PDFs is stored as
  rendered glyphs, not LaTeX. Equations become symbol sequences that are partially
  searchable but not reliably so. Plain-text descriptions of methods search better
  than embedded equations.

- **Tables.** Simple tables extract reasonably well with pymupdf. Complex tables
  (merged cells, multi-page) do not. For critical tabular data, copy the relevant
  cells into a `.txt` file manually.

- **This does not replace reading.** Search finds what you put in. If you download
  papers without reading them, the retrieval will reflect that — technically correct,
  cognitively empty.

- **arXiv fetch requires internet.** The rest of the stack is fully offline.

---

## Getting help

Open a GitHub Discussion at https://github.com/02zerocool/mindfield/discussions

The right question is "I'm building a corpus from X, here's what I'm seeing" —
a concrete description of what you tried and what you observed.
That produces a real answer.
