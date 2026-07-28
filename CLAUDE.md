# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The home of **épure** — a method and toolset for building software together, humans and AI assistants alike, with executable scenarios as the design. The method's site is published at epuremethod.com from `docs/`.

The tools and their documentation live elsewhere: [tilia and @tilia/query](https://github.com/tiliajs/tilia); the test runner [@epure/vitest](https://github.com/epuremethod/vitest). Edit guides and API docs in those repositories, never here.

## Contents

- `docs/content/agreement.md` — the épure working agreement **template**: the artifact consuming projects copy to their root as `CONTRIBUTING.md` (paired there with a one-line `AGENTS.md` pointing at it). It describes how *épure projects* work, **not** how this repo works — do not follow its promises (feature files, carve layout) here. It is the single source for the published page and the raw download, so edit it and nothing else. Never create a root `AGENTS.md` or `CONTRIBUTING.md` in this repo: agent tooling and GitHub auto-read those filenames and would mistake the template for this repository's own instructions.
- `agent-support-design.md` — live design doc for the agent-support surface: references (R1–R4), playbooks (P1–P3), the working agreement template (P4), and tooling (T1–T3).
- `docs/` — epuremethod.com, built by [minidoc](https://github.com/epuremethod/minidoc) and deployed by GitHub Actions. `content/config.yaml` declares the shared shell and every output; `content/` holds the page bodies, `assets/` the stylesheet and fonts. `pnpm build` writes `docs/dist`, which is what Pages serves. The folder is named `docs/` to match tilia and `@epure/vitest`.
