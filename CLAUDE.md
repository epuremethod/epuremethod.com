# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository State

This repository is at the design/documentation stage. There is no source code, package manifest, build system, or test suite yet — so there are no build/lint/test commands to run. When code lands, update this file with the actual commands.

## What This Repo Contains

- `tilia-query-vision.md` — the product rationale for **TiliaQuery**: one shared lifecycle for remote collection data in Tilia apps (load, cache, background refresh, live-update merge, offline support).
- `tilia-query-technical.md` — the authoritative technical spec: full public API (in ReScript), internal model, data flows, adapter contracts, and known open problems. Read this before doing any TiliaQuery-related work.
- `claims-app-demo.css` / `claims-app-demo.jpg` — assets for a claims-adjuster demo app (Tailwind v4 `@theme` tokens, sync/write animations keyed by acting user) intended to showcase TiliaQuery's offline/sync behavior.

Note: the technical doc references paths like `query/src/TiliaQuery.res`, `query/test/TiliaQuery.feature`, and `tilia/TRADE_OFFS.md`. Those files belong to the TiliaQuery implementation repo, not this one — do not expect to find them here.

## TiliaQuery Architecture (from the spec)

TiliaQuery is an offline-first query-state layer written in ReScript (with a TypeScript `.d.ts` mirror), built on Tilia reactivity. Key concepts needed to reason about it:

- **Two connected caches:** an object cache by id, and a query-result cache (id lists) keyed by `Json.sortedStringify` of the filter. Views (`one`/`array`/`dict`) are memoized per query key and keep identity when the id list is unchanged, so no-op refetches don't re-render.
- **Two read tiers:** `local.fetch` always runs; `remote.fetch` only when `remote.online`. Remote is authoritative because its emit is expected to land after local's. Remote rows are written through to the local store.
- **Durable write outbox:** `upsert`/`remove` persist dirty rows/tombstones to the local store first, apply optimistically to memory, update query membership in place via `matches` (no refetch), then dispatch when online. Latest write per id wins. Boot replays `local.dirty()` through the same flow.
- **Channel-callback boundary:** adapters report outcomes via named callbacks (`emit`, `fail`, `covered`, `conflict`, `reject`, `offline`), never constructed variant values; ReScript variants never leak into compiled JS. Cancelled channels turn all callbacks into no-ops.
- **Scheduling is external:** the app calls `tick()`, which does the stale-refresh check (only while online) and idle-query GC using Tilia's observer graph (`_canopy`) for liveness.
- **Deliberate non-goals:** transport, storage schemas, domain query APIs, and scheduler ownership all live in per-feature adapters. `clear()` intentionally does not wipe the local database — that's the adapter's job on logout.

Semantic distinctions that are easy to get wrong:

- `sync(item)` is for inbound/live updates: memory cache + membership only; it never calls the remote or the local store.
- `covered()` means "a delta-sync engine owns this query — mark fresh without rows"; `fail(message)` is strictly a transport error and leaves freshness untouched so the next tick retries.
- `remote` must be a tilia object (reactive `online`); a plain record silently breaks reconnect replay.
- Local-tier fetch failures are ignored by design (adapter bug, not sync state).
