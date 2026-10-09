# Mindfield

**A framework for building a personal cognitive externalisation.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.11%2B-blue)](https://python.org)
[![LanceDB](https://img.shields.io/badge/Memory-LanceDB-orange)](https://lancedb.com)
[![Godot](https://img.shields.io/badge/Visualisation-Godot_4-blue)](https://godotengine.org)

---

> *"When a system offloads genuine cognitive work and a person relies on it as they rely on memory,
> it IS part of their cognitive system."*
>
> — Andy Clark & David Chalmers, *The Extended Mind* (1998)

---

## What this is — and what it is not

**v0.1 delivers:** a working local semantic memory API + ingest pipeline.
You can store your documents, search them by meaning, and retrieve the most relevant passages for any query. That is real and it works.

**v0.1 does not deliver:** a conversational AI, a chatbot, or anything that generates responses.
There is no web UI in this release. There is no GGUF inference included.
The gap between "memory API" and a fully integrated personal AI is significant and honest work remains to close it.

This framework was derived from a production personal AI system with 2.6 million memory records, trained local models, and years of accumulated corpus work. That system took years to build. This repo gives you the foundation — the memory layer — which is the hardest and most important part. The rest can be layered on top.

Set your expectations clearly: after following the quick start, you will have a semantic search engine over your own documents. It will be fast, local, and accurate. It will not talk back. Not yet.

---

## What this is — the philosophy

Mindfield is not a chatbot framework. It is not a RAG wrapper. It is not another way to talk to a language model.

It is a framework for building a **semantic memory field** — a local, offline system that grows from *your* knowledge, reflects *your* thinking, and serves *you alone*.

The difference matters:

- A general AI averages across humanity. You get the statistical median of eight billion people's training data — useful for everything, intimate with nothing.
- A mindfield averages across *you*. You get yourself, made searchable, queryable, and spatial.

The corpus you bring is the mind. The framework is the skeleton.

---

## The science behind the architecture

This project was built on an observation that emerged from building a personal memory system and watching what happened when it grew large enough to visualise.

When you project a semantic memory field of sufficient size (hundreds of thousands of records) through UMAP dimensionality reduction, the resulting geometry is not random. It has **hubs, filaments, and voids** — a scale-free topology with self-similar structure at every zoom level.

This is the same topology as:

- **The fruit fly mushroom body** — 2,000 Kenyon cells receive compressed sensory projections, forming the insect's associative memory centre
- **The human cerebellar connectome** — Purkinje cells integrating ~200,000 inputs each through granule-layer expansion coding
- **The cosmic web** — dark matter filaments connecting galaxy clusters across hundreds of megaparsecs

Three independent systems, three orders of magnitude apart in scale, same statistical topology. This is not coincidence. It is the shape that compressed knowledge takes — at any scale, in any substrate.

The architecture of Mindfield is grounded in this observation. The memory is not just stored — it has a geometry. That geometry is navigable, visualisable, and alive.

The full architectural rationale is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## What you get

| Component | Included | What it does |
|---|---|---|
| **LanceDB memory** | ✅ v0.1 | Your documents as 768-dim semantic vectors — fast, local, fully offline |
| **Lean API** | ✅ v0.1 | Search, write, embed — the memory access layer |
| **Ingest pipeline** | ✅ v0.1 | Drop `.txt`, `.md`, `.pdf` files → chunked → embedded → searchable |
| **Domain stacks** | ✅ v0.1 | Specialist sub-corpora on separate ports for distinct knowledge areas |
| **Godot visualisation** | ✅ script only | The burst engine GDScript — requires your own Godot 4 project + scene |
| **Docker / NSSM** | ✅ v0.1 | Portable Linux stack or native Windows services |
| **Web frontend (Voyager CC)** | 🔜 v0.2 | Search and chat UI — not yet included, tracked in issues |
| **GGUF inference** | 🔜 bring your own | Plug in any llama-server compatible GGUF model |

---

## Quick start

**What you will have at the end of this:** a running local memory API you can search with any HTTP client.

```bash
# 1. Clone
git clone https://github.com/yourname/mindfield
cd mindfield

# 2. Setup — creates dirs, installs deps
python setup.py

# 3. Download the embedding model (~300MB, one-time)
#    Place it in models/
wget -P models/ https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf

# 4. Start the embedding server
#    (keep this running in a separate terminal)
llama-server --model models/nomic-embed-text-v1.5.Q8_0.gguf \
             --port 8082 --host 127.0.0.1 --embedding

# 5. Start the memory API
#    (keep this running in a separate terminal)
python lean/lean_api.py

# 6. Drop your documents and ingest
cp your_notes/*.md  ingest/ingest_queue/
python ingest/ingest_bulk_memory.py --dry-run    # preview
python ingest/ingest_bulk_memory.py --ingest     # write

# 7. Search
curl -X POST http://127.0.0.1:8018/search \
     -H "Content-Type: application/json" \
     -d '{"query": "your question here", "k": 10}'

# Or verify the stack
python scripts/health_check.py
```

**Docker alternative (steps 4–5):**
```bash
docker-compose up nomic-embed lean
```
Note: run `nomic-embed lean` specifically — not `up -d` (which includes services not yet in this repo).

---

## The fill path

Your corpus is the most important decision you will make in this entire project. The framework is infrastructure. The knowledge is yours.

**What makes a strong personal corpus:**

- Books you have read and found meaningful — especially your own annotations and highlights
- Your own writing: notes, journals, essays, observations accumulated over years
- Research papers in domains you actually think about
- Conversations worth preserving
- Primary sources in areas that matter to you

**What makes a weak corpus:**

- Wikipedia dumps — too broad, too shallow, no personal signal
- News articles — ephemeral, low density
- Anything you have not actually read

A field of 10,000 deeply personal records will outperform 1,000,000 generic ones for your purposes. The goal is not size. The goal is signal density.

Supported ingest formats: `.txt`, `.md`, `.rst`, `.pdf`

---

## Adding a specialist domain

A specialist domain is a separate LanceDB for a corpus too large or too distinct to sit in your main memory — a technical reference corpus, a domain research collection, a project archive.

```bash
cp lean/domain_lean.py.template lean/my_domain_lean.py
# Edit: set DOMAIN_NAME, LANCE_DB_PATH, LEAN_PORT
python lean/my_domain_lean.py
```

Each domain runs its own `lean_api` instance on its own port, with its own LanceDB. In the Godot space, you can dial a domain stargate to route search through the specialist corpus for a session.

---

## Hardware requirements

| Component | Minimum | Recommended |
|---|---|---|
| RAM | 8 GB | 16–32 GB |
| Storage | 10 GB | 100 GB+ (for large corpora) |
| GPU | Not required | Any CUDA GPU for GGUF inference |
| OS | Linux / macOS / Windows | Windows 10+ or Ubuntu 22.04+ |

The embedding server (nomic-embed-text-v1.5) runs well on CPU. GGUF inference benefits from a GPU but is not required — the system has a pure-retrieval path that skips generation entirely.

---

## Project structure

```
mindfield/
├── README.md
├── docs/
│   └── ARCHITECTURE.md          ← the pattern, the science, the rationale
├── lean/
│   ├── lean_api.py              ← memory access layer (search/write/embed)
│   ├── requirements.txt
│   ├── Dockerfile
│   └── domain_lean.py.template  ← copy to add specialist domains
├── ingest/
│   ├── ingest_bulk_memory.py    ← fill your memory from files
│   └── ingest_queue/            ← drop files here
├── godot/
│   ├── MemoryGenesis.gd         ← 3D memory burst engine (Godot 4)
│   └── README.md
├── services/
│   └── install.ps1              ← Windows NSSM service installer
├── scripts/
│   └── health_check.py          ← verify your stack
├── docker-compose.yml
├── setup.py
├── .env.example
└── .gitignore
```

---

## Built with

This project was built with and alongside:

- **[Anthropic / Claude](https://anthropic.com)** — Claude was the reasoning partner throughout the entire design and build of the system that this framework is derived from. The architecture was iterated through real working sessions with Claude Code. Anthropic's work on safe, capable AI made a collaborator like this possible. This is acknowledged genuinely, not as a disclaimer.

- **[LanceDB](https://lancedb.com)** — The memory substrate. A columnar vector database that treats vectors as first-class citizens and runs entirely on local disk. Without LanceDB's append-only architecture, the safety of a personal memory system would have been much harder to guarantee.

- **[nomic-embed-text-v1.5](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF)** by [Nomic AI](https://nomic.ai) — The 768-dimensional embedding model that turns text into the geometric field. Accurate, open-weight, and runnable on CPU via llama.cpp.

- **[llama.cpp](https://github.com/ggerganov/llama.cpp)** by [Georgi Gerganov](https://github.com/ggerganov) — The inference engine for both embedding and optional GGUF generation. The entire local AI ecosystem owes a significant debt to this project.

- **[Godot Engine](https://godotengine.org)** — The 3D visualisation layer. A genuinely free and open engine that made building a spatial memory interface possible without commercial dependency.

- **[FastAPI](https://fastapi.tiangolo.com)** by [Sebastián Ramírez](https://github.com/tiangolo) — The API layer that makes every service in this stack simple to build, document, and run.

---

## Philosophical foundations

This work draws on:

- **Andy Clark & David Chalmers** — *The Extended Mind* (1998). The philosophical case that cognitive systems extend beyond the skull when external components meet the right functional criteria. This is the intellectual foundation for the entire project.

- **The FlyWire Consortium** — The complete connectome of *Drosophila melanogaster*, which provided the empirical reference for the mushroom body topology observation.

- **The Cerebellum Connectome Project** — Purkinje cell integration architecture that mirrors the same expansion-compression pattern.

- **The cosmic web survey community** — For making it undeniable that this topology appears at every scale.

---

## A note on personal AI

This framework emerged from building a system for one specific person — not as a product, not for a market, but as a genuine cognitive tool for one human being.

The insight that drove it was simple: the right benchmark for AI is not performance on standardised tests. It is whether the system makes the human it serves **more fully themselves** — more capable of their own thinking, more connected to their own knowledge, more able to think at the scale their questions deserve.

General AI systems cannot do this by design. They are built to be useful to everyone, which means they are optimised for the average of everyone — and the average of everyone is no one in particular.

A personal memory field is different. It knows exactly one person's reading history, one person's thinking patterns, one person's years of hand-picked knowledge. It gets more specific over time, not less.

This framework is a skeleton. It is not the mind. You are the mind. The corpus you build is the only thing that gives this meaning.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

The most valuable contributions are:
- Documentation improvements and translations
- Alternative ingest format support (EPUB, HTML, Obsidian vault, etc.)
- Docker improvements for wider hardware compatibility
- Reports of what works, what doesn't, and what your corpus taught you

---

## Licence

MIT. Build your own mind. Keep it yours.

---

*"The Question lives in the human. The computation lives in the stack. Together they are one extended system — the thing Deep Thought could not be alone."*
