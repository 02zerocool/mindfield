# Godot — 3D Memory Visualisation (optional)

The Godot integration renders your memory field as a living 3D geometry —
knowledge domains as glowing particle clusters, autonomous thought bursts
that erupt from whichever domain you're querying.

This is optional. The core stack (lean + voyager) works without it.
The Godot space adds a spatial, embodied interface to the same memory.

## What's here

- `MemoryGenesis.gd` — autonomous memory burst engine. Queries your LanceDB
  every N seconds, spawns particle bursts at the corresponding domain cluster.
  The geometry makes your corpus visible as a living field.

## Requirements

- Godot 4.3+
- Your lean_api running at :8018 (or update the URL constant in MemoryGenesis.gd)
- The `star_point.gdshader` from the main project (or substitute your own)

## Setup

1. Open your Godot 4 project
2. Add `MemoryGenesis.gd` as a child Node3D in your scene
3. Set `enabled = true` to start autonomous memory bursts
4. Update `LEAN_URL` (line 21 of MemoryGenesis.gd) to point at your lean_api

## Customising domains

Edit the `DOMAINS` dictionary to match your corpus structure.
The positions and colours define where each domain cluster appears in 3D space.

The `THOUGHT_SEQUENCE` array defines what queries fire during autonomous mode.
Replace these with queries that reflect your corpus.

## The architecture connection

When your memory field projects to UMAP, it shows the same topology as:
- The fruit fly mushroom body
- The human cerebellar connectome  
- The cosmic web

The Godot space makes this visible. Your knowledge has a shape. This is it.

See `docs/ARCHITECTURE.md` for the full explanation.
