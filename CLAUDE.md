# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The home of **épure** — a method and toolset for building software together, humans and AI assistants alike, with executable scenarios as the design. The method's site is epuremethod.com (not yet published; its draft lives here).

The tools and their documentation live elsewhere: tilia and @tilia/query (with the tiliajs.com docs site under `docs/`) at `~/git/tilia`; the test runner `@epure/vitest` (formerly vitest-bdd, with its own docs) at `~/git/vitest-bdd`. Edit guides and API docs in those repos, never here.

## Contents

- `CONTRIBUTING.md` — the épure working agreement **template**: the artifact consuming projects copy to their root (paired there with a one-line `AGENTS.md` pointing at it). It describes how *épure projects* work, **not** how this repo works — do not follow its promises (feature files, carve layout) here. Never create a root `AGENTS.md` in this repo: agent tooling auto-reads that filename and would be misdirected to the template.
- `agent-support-design.md` — live design doc for the agent-support surface: references (R1–R4), playbooks (P1–P3), the `CONTRIBUTING.md` template (P4), and tooling (T1–T3).
- `DESIGN/site/` — static prototype of the epuremethod.com landing page (plain HTML/CSS, no build step). The last remaining prototype: the tiliajs and vitest-bdd site prototypes, and a drafting copy of the docs pipeline, were consumed by the real repos and removed (recoverable from git history).
