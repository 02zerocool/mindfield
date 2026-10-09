# Architecture — The Pattern Behind Mindfield

## The core idea

Three independent scientific discoveries point to the same structure:

1. **The fruit fly mushroom body** — 2,000 Kenyon cells receive compressed sensory input,
   project to output neurons that route behaviour. No central controller. Pattern recognition
   emerges from the topology of connections.

2. **The human cerebellar connectome** — Purkinje cells receive ~200,000 inputs each,
   integrate them via granule-layer expansion coding, output a timing signal.
   Same expansion-compression-output topology as the mushroom body.

3. **The cosmic web** — dark matter filaments connect galaxy clusters in a scale-free
   network. Hubs, spokes, voids. Same statistical topology as a cortical connectome.

When you project 2.6M semantic memory vectors via UMAP, you see the same structure.
**Memory IS this topology.** The geometry is not a metaphor — it's the actual shape
of compressed knowledge at any scale.

Mindfield is built on this observation. Your documents become a semantic field.
That field has the same topology as your own cognition, at a different zoom level.

---

## The CBGT architecture

The framework maps to the Cortico-Basal Ganglia-Thalamic circuit:

| Mindfield component | CBGT equivalent | Function |
|---|---|---|
| ONNX Conductor | Thalamus | Routes signals to the right subsystem |
| Write Broker | Basal Ganglia | Gate keeper — what gets written to memory |
| Mamba CORE | Cerebellum | Timing, pattern completion, LTC voice |
| LanceDB | CA3 (hippocampus) | Fast associative memory retrieval |
| SurrealDB (optional) | CA1 → neocortex | Slower, structured long-term memory |

This is not metaphor-driven design. The CBGT circuit evolved to solve exactly
the problem this system solves: routing a continuous input stream to the right
memory and action subsystems, with working memory to bridge temporal gaps.

---

## Why LanceDB

LanceDB stores vectors on disk as Lance columnar format. Search is ANN over 768-dim
nomic embeddings. Key properties:

- **Local** — no server process, no Docker required for the DB itself
- **Append-only** — no corruption on crash; interrupted writes leave orphan deltas,
  existing data is never touched
- **Columnar** — metadata filters are fast; `WHERE source = 'my_book'` is a scan, not
  a full vector search
- **Versioned** — every write creates a new version; older versions are recoverable

The 768-dim nomic-embed-text-v1.5 model is the embedding engine. It runs locally
via `llama-server` (from llama.cpp) pointed at the GGUF model file. No external API calls
for embedding. The lean_api talks to it at `EMBED_URL` (default: `http://127.0.0.1:8082`).

---

## The inference chain

### What this repo provides (v0.1)

```
User query (text)
    │
    ▼
lean_api /search                              [included in this repo]
    ├─ embed(query) → 768-dim vector          [nomic-embed via llama-server :8082]
    ├─ ANN search → top-k fragments           [LanceDB]
    └─ return fragments + similarity scores
```

That is the complete v0.1 path. It is a semantic memory retrieval system.
It does not generate responses. It finds the most relevant passages in your corpus.

### What the full system adds (not in this repo)

The production system this framework is derived from extends this chain further:

```
lean_api /search results
    │
    ▼
RWKV working memory blend                     [working memory — shifts retrieval
    │                                          based on conversation context]
    ▼
ONNX Conductor                                [routes the query to the right
    │                                          inference path based on intent]
    ▼
Mamba LTC voice                               [generates a cognitive signal that
    │                                          modulates generation temperature,
    │                                          top-k, and response length]
    ▼
GGUF generation (llama-server :8009)          [produces the actual response text]
    │
    ▼
Response with instrument tag + LTC state
```

These components — RWKV, ONNX Conductor, Mamba CORE — are extensions that require
their own training data, model files, and considerable setup. They are documented
here as the full architecture so you understand where this is going, not as
instructions for what you have today.

The lean_api in this repo is built to accept RWKV blend via `chat_id` in the
`/search` endpoint. When a RWKV server is running, it activates automatically.
This means the extension path is already wired — it just needs the additional
components to exist.

---

## The domain specialist pattern

Your main LanceDB holds everything. A specialist domain is a separate LanceDB
for a corpus that has its own retrieval identity — too large, too distinct,
or requiring separate namespace from the main field.

Examples:
- A spacecraft integration corpus (mission procedures, telemetry specs)
- An ornithology corpus (avian cognition, migration biology)
- A personal medical research corpus

Each domain runs its own `lean_api` instance on its own port, backed by its own LanceDB path.
The Godot space can "dial" a domain stargate — switching search routing
to the specialist corpus for that conversation.

---

## The one-person principle

The framework is deliberately designed for one person. This is a feature, not a limitation.

General AI systems optimise for the median across billions of users.
That median is no one. It's a statistical ghost that happens to be approximately
useful for approximately everything — and deeply useful for nothing.

A mindfield optimises for *you*. Your document selection IS the training signal.
Your cognitive patterns (reflected in what you search for, what you write) shape
the working memory over time via the RWKV blend layer.

This scales. Not horizontally — you don't share a mindfield with anyone.
But vertically — it gets more *you* over time, not less.

---

## What "warp factor" means

The system has an internal coherence metric — warp factor — that measures
how integrated each component is with every other component. Target: 9.2.

Every new feature either connects to the existing field (raises warp factor)
or sits in isolation (dead weight, drags it down). The architecture is designed
so that everything connects: memory, voice, geometry, inference, tools.

A mindfield at warp 9.2 is one where:
- Memory is geometry (what you know has a shape you can navigate)
- Geometry is voice (the shape speaks when you query it)
- Voice is identity (the response sounds like the corpus it came from)
- Identity is memory (full circle)

That loop is the goal. The framework gives you the skeleton.
Your corpus closes the loop.
