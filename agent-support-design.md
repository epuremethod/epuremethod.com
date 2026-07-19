# Agent Support Design — épure for AI coding assistants

Status: design, nothing built yet.
Scope: the documents, web pages, and tools needed so that an AI coding assistant with **no prior knowledge** of tilia, @tilia/query, or vitest-bdd can (1) bootstrap an épure project, (2) align an existing project, and (3) keep the method alive as the project evolves — without ever hallucinating the APIs.

Companion docs: `tilia-query-vision.md`, `tilia-query-technical.md`, `site/index.html` (method canon).

---

## 1. The problem, stated precisely

The three tools are small, recent, and absent from (or barely present in) model training data. When an agent meets an unknown reactive-state or query library, it does not say "I don't know" — it **completes by analogy**: tilia becomes MobX or Zustand, @tilia/query becomes react-query, vitest-bdd becomes cucumber-js. The hallucinations are systematic and predictable: `useQuery(...)`, `createStore(...)`, `dispatch(...)`, `defineFeature(...)`, world objects, decorators. Each one type-checks in the agent's head and fails in the build — or worse, the agent "fixes" it by writing a wrapper that reimplements the library badly.

"Never hallucinate" is not achievable by documentation quality alone. It is achievable as a **system property** when three layers reinforce each other:

| Layer | Mechanism | Failure it prevents |
|---|---|---|
| **Knowledge** | The exact, version-matched API is *in the agent's context* before it writes code, in the language the project uses | Completion by analogy |
| **Verification** | `tsc --noEmit` against shipped `.d.ts` + the vitest-bdd feature suite; the agent is instructed to run both after every change | Hallucination that slips through anyway |
| **Process** | The method itself (feature file signed → implement → suite green) encoded as an executable protocol, not prose | Drift over the project's life |

Everything in this document is one of these three layers, and every knowledge artifact is **generated from an already-validated single source** — never hand-written twice — so the docs a human reads and the reference an agent loads cannot disagree.

### 1.1 Negative knowledge prevents false analogies

For a niche library, saying what exists is half the job. The other half is pre-empting the analogy: an explicit, machine-loadable list of **what does not exist and what is easy to get wrong**. Seeds (to be completed per tool):

**tilia**
- There is no store, no dispatch, no action creators, no selectors. State is a plain object passed to `tilia()`; views observe it directly.
- No decorators, no class observables, no `makeAutoObservable`.
- `useTilia()` takes no arguments and returns nothing useful to destructure — it registers the component as an observer.

**@tilia/query**
- There is no `useQuery` hook and no query-key array API. Queries are plain filter objects; views are `one` / `array` / `dict`.
- `sync(item)` is called after an external sync engine has reconciled the eventual local database. It then aligns the memory cache and query membership without writing locally again or echoing the inbound change back to the remote.
- `covered()` ≠ `fail(message)`: `covered` means "a delta-sync engine owns this query — mark fresh without rows"; `fail` is strictly a transport error and leaves freshness untouched so the next `tick()` retries.
- `clear()` deliberately does not wipe the local database — that is the adapter's job on logout.
- `remote` must be a tilia object (reactive `online`); a plain record silently breaks reconnect replay.
- Adapters report outcomes via named callbacks (`emit`, `fail`, `covered`, `conflict`, `reject`, `offline`) — never constructed variant values.
- Nothing schedules itself: the app calls `tick()`. There is no polling interval option to configure.

**vitest-bdd**
- There is no world object, no `Before`/`After` hooks registry, no step-definition files scanned by glob, no regex steps, no cucumber.js compatibility layer.
- `Given` is the single entry point of a steps file; every `When`/`Then` closes over the context created inside its builder. Patterns are Cucumber *expressions* (`{string}`, `{number}`), not regexes.
- The `.feature` file **is** the Vitest suite — there is no generated test file and no translation step.

This list lives once (§3, artifact **R2**) and is embedded into every agent-facing reference.

---

## 2. Delivery architecture (recommendation)

Four delivery channels, ordered by authority. A project consuming épure touches them in reverse order (template first, packages last), but truth flows downward from the packages.

```
┌──────────────────────────────────────────────────────────────┐
│ 1. npm packages          tilia / @tilia/query / vitest-bdd    │
│    llms.txt + .d.ts      version-matched, arrives with        │
│                          `npm install` — AUTHORITATIVE        │
├──────────────────────────────────────────────────────────────┤
│ 2. websites              tiliajs.com · vitest-bdd.dev ·       │
│    llms.txt, llms-full   epuremethod.com — discoverable,      │
│    playbook pages        linkable, latest version             │
├──────────────────────────────────────────────────────────────┤
│ 3. the project           AGENTS.md template, create-epure —   │
│    templates             the method wired into the repo the   │
│                          agent works in                       │
├──────────────────────────────────────────────────────────────┤
│ 4. agent-native          Claude Code plugin /epure:* skills — │
│    conveniences          thin wrappers over layer 3 playbooks │
└──────────────────────────────────────────────────────────────┘
```

**Why the package is the authority.** A website reference always documents *latest*; the project may have installed anything. A reference shipped inside the npm package can never be the wrong version, needs no network, and sits where agents already look (`node_modules/<pkg>/`). The project `AGENTS.md` template (layer 3) tells the agent explicitly: *before using tilia, @tilia/query, or vitest-bdd, read `node_modules/<pkg>/llms.txt` — it matches the installed version.* The `.d.ts` files then make the compiler enforce what the reference said.

**Why the websites still matter.** Discovery (an agent researching "what is tilia" lands on tiliajs.com and finds `/llms.txt` per the emerging convention), alignment of *existing* projects (no template was ever installed), and the method playbooks, which are not tied to any package version.

**Why templates and skills are thin.** All process content lives in markdown playbooks (layer 2/3) that any agent — Claude Code, Cursor, Copilot, a bare API loop — can follow. The Claude Code plugin only packages those playbooks as slash commands; it adds distribution, not content. This keeps the method agent-tool-agnostic.

**Language separation (decided).** TypeScript and ReScript material are **separate artifacts**, never interleaved: an agent that sees dual signatures will blend them. TS ships first (`llms.txt`, `llms-full.txt`); ReScript follows later as parallel files (`llms-rescript.txt`, `llms-rescript-full.txt`). The docs *website* keeps its human-facing TS/ReScript toggle; only the agent-facing exports are split.

---

## 3. Artifact catalog

Prioritized in three tiers. IDs (`R*` references, `P*` playbooks, `T*` tooling) are used in §4.

### Tier 1 — machine references (foundation, build first)

| ID | Artifact | Source of truth | Published at |
|---|---|---|---|
| R1 | `llms.txt`, `llms-full.txt`, `api.json` per tool, TS variant | `docs/content/<tool>/{api,guide}/*.md` via a new emitter in `docs/src/` | `docs/dist/<tool>/` → site root of each domain; copied into each npm package |
| R2 | "Not in this library" negative-knowledge blocks, per tool | Hand-curated markdown in `docs/content/<tool>/` (new file), validated + embedded by the emitter | Inside R1 outputs |
| R3 | Fully doc-commented `.d.ts` per package | The tool implementation repos (`github.com/tiliajs/*`) | npm packages |
| R4 | Rewritten root `CLAUDE.md` for *this* repo | — (housekeeping: current one predates the entire `docs/` build) | this repo |

### Tier 2 — method playbooks + project template

| ID | Artifact | Purpose |
|---|---|---|
| P1 | `bootstrap.md` | Zero → running épure project: layout, installs, config, first feature |
| P2 | `align.md` | Audit + incremental migration of an existing codebase |
| P3 | `evolve.md` | The development window as an agent-executable protocol |
| P4 | Project `CONTRIBUTING.md` template | The four principles as enforceable rules, dropped into every épure project; a one-line `AGENTS.md` points agent tooling at it |

All four are plain markdown, authored in `docs/content/epure/` (new), published on epuremethod.com (e.g. `/agents/bootstrap.md` and linked from `/llms.txt`), and vendored verbatim into the starter template (T1).

### Tier 3 — tooling (specified now, built later)

| ID | Artifact | Notes |
|---|---|---|
| T1 | `create-epure` starter template | `npm create epure` → the P1 layout pre-wired, P4 already in place |
| T2 | Claude Code plugin: `/epure:bootstrap`, `/epure:align`, `/epure:window` | Skills wrapping P1–P3 |
| T3 | Enforcement lint pack | e.g. "no fetch outside `services/`", "no logic in `views/`" — makes P-2 machine-checkable |

---

## 4. Per-artifact outlines

### R1 — generated references (`llms.txt` / `llms-full.txt` / `api.json`)

**Audience:** agents. **Source:** the docs build already parses and cross-validates everything needed — API frontmatter (`name`, `slug`, `kind`, `module`, `since`, `sort`, `summary`, `signature.ts`, `signature.res` — see `docs/src/schema.mjs`) and guide `refs[]` checked against API slugs. 27 tilia + 20 query + 14 vitest-bdd entries exist today. The emitter adds **zero new authoring work** for the API surface.

**The emitter** (new module in `docs/src/`, invoked from `build.mjs` after page rendering):

- Input: the same parsed entries/chapters the HTML templates receive.
- Language filtering: markdown bodies contain *paired* TS/ReScript fences (the build already pairs adjacent fences for the toggle — `docs/src/markdown.mjs`). The TS emitter keeps `typescript` and `gherkin` fences, drops `rescript` fences, and strips ReScript-only prose sentences where flagged (convention to define: a `:::res-only` container or a per-paragraph marker; first pass can simply drop `rescript` fences, since the prose is already TS-led).
- Link rewriting: `api.html#slug` / `docs.html#slug` anchors become in-document anchors in `llms-full.txt`.
- Output per tool, written to `docs/dist/<tool>/`:
  - **`llms.txt`** — the index, per the llms.txt convention: one-paragraph tool description, the negative-knowledge block (R2) inline (it is short and must never be skipped), then a linked list of every API entry (`name — summary`, with `since`) and guide chapter.
  - **`llms-full.txt`** — full text: every guide chapter, then every API entry (name, kind, module, since, TS signature, body). Ordered guide-first: the guides teach the *shape* of correct usage, which is what suppresses analogy.
  - **`api.json`** — the raw frontmatter array (TS signature only) for programmatic use: `[{ name, slug, kind, module, since, summary, signature, tags }]`. This is what a future MCP server or doc-lookup tool would serve.
- Config: a `pages.llms` section per `config.yaml` (inherits through the existing `base:` mechanism, so it is defined once in `tilia/config.yaml`).
- Validation: the emitter fails the build if an R2 file is missing or if any entry lacks a TS signature — same fail-loud posture as the existing schema checks.

**Size check:** 61 entries × ~40 lines + guides ≈ agents can load `llms-full.txt` for one tool whole (~2–4k lines); `llms.txt` stays under ~150 lines. Both fit comfortably in a context window; no chunking needed.

### R2 — negative knowledge ("not in this library")

**Audience:** agents, embedded everywhere. One markdown file per tool, e.g. `docs/content/<tool>/agents/not-in-this-library.md`, hand-curated (this is judgment, not derivable from frontmatter). Content = §1.1 expanded, in three sections per tool:

1. **Wrong analogies** — "if you are reaching for react-query/redux/cucumber-js idioms, stop; here is the épure equivalent" (each item pairs the hallucination with the real API by slug).
2. **Semantic traps** — correct-looking calls with wrong meaning (`sync` vs `upsert`, `covered` vs `fail`, plain-record `remote`, local-tier fetch failures ignored by design). Source: `tilia-query-technical.md` and the guides.
3. **Deliberate non-goals** — transport, storage schemas, scheduler ownership, `clear()` vs logout wipe — so the agent builds the adapter instead of "fixing" the library.

Kept short (≤ 60 lines per tool) so it can be embedded verbatim in `llms.txt`, the package reference, and P4.

### R3 — doc-commented `.d.ts`

**Audience:** the TypeScript compiler + agents reading types. Lives in the tool implementation repos, so here it is a **requirements spec to hand over**: every exported symbol carries a JSDoc block whose first sentence equals the docs `summary` (generated or CI-checked against `api.json` to prevent drift), plus `@since`. The `.d.ts` is the verification layer: once the agent's context and the compiler agree, hallucination cannot survive `tsc --noEmit`. Each package also copies its `llms.txt` (R1) and declares it in `package.json` `files`.

### R4 — this repo's `CLAUDE.md`

Housekeeping, small but real: the current file says the repo has no build system and describes only the TiliaQuery spec era. Rewrite to cover the `docs/` pipeline (build/dev/check commands), content conventions (frontmatter rules, filename = slug, `NN-` = `sort`), the `site/` + `tiliajs/` + `vitest-bdd/` prototypes, and this design doc.

### P1 — `bootstrap.md`

**Audience:** an agent (or human) starting a project from nothing. Written as a protocol the agent executes top to bottom, each step ending in a check:

1. **Layout** — the three floors plus the contracts:
   ```
   features/     *.feature files — the signed contracts
   src/business/ pure functions, no imports from services or views
   src/services/ named, deliberately few (auth, storage, transport…)
   src/views/    projections of state, no logic
   ```
2. **Install** — `tilia @tilia/react @tilia/query vitest-bdd vitest typescript` (exact package names and the vitest config wiring for `.feature` files).
3. **Drop in P4** as the project's `CONTRIBUTING.md`, and write the one-line `AGENTS.md` pointing at it ("Read `CONTRIBUTING.md` — it is addressed to you too."), which agent tooling reads on its own.
4. **First feature end-to-end** — write one `.feature`, one steps file, one business module, one tilia state object, one view; suite green. This worked example is the single most anti-hallucination artifact in the whole plan: it shows the *shape* once, correctly, in the project itself.
5. **Verification loop** — `tsc --noEmit && vitest run` defined as the project's standing check; the agent is told to run it after every change.

### P2 — `align.md`

**Audience:** an agent auditing an existing codebase. Two parts:

1. **Audit** — one concrete inspection per principle: P-1 do behaviors have feature files, and do they run? P-2 grep-level checks (network calls outside services, logic in components, business importing UI). P-3 how does state reach the screen — props-drilling/stores vs observation? P-4 what happens offline? Output: a written findings sheet (the *relevé* — measure the existing building before drawing).
2. **Migration order** — smallest reversible steps: contracts first (write `.feature` files for existing behavior — instant regression suite, no code moved), then extract business functions, then introduce tilia state at the leaves, then @tilia/query at the data boundary. Never a big-bang rewrite; each step ends suite-green.

### P3 — `evolve.md`

**Audience:** an agent working inside a live project — the continuity answer. The development window (method §02) rewritten as an executable protocol with hard gates:

- A window opens on a stated need; the agent's first output is a **`.feature` diff, nothing else**. No implementation until the contract diff is validated by a human ("signed").
- During build: contracts anchor every prompt; the agent re-reads the relevant `.feature` before touching code; every change ends with the verification loop green.
- Scope discipline: anything outside the signed scenarios is logged for the next window, not done.
- Window close: all scenarios green, human demo, then stability — the agent refuses "quick patches" between windows and says why, citing the method.

P4 references this protocol so it survives in every project, not just on the website.

### P4 — project `CONTRIBUTING.md` template

**Audience:** everyone who builds in an épure project — agents land on it through the one-line `AGENTS.md`. One file, ≤ 120 lines, four sections:

1. **Rules** — the four principles as imperatives ("every behavior change starts as a `.feature` diff and stops there until signed", "no network access outside `src/services/`", "views render state, never compute it", "reads answer from local first; writes go through the outbox").
2. **Read before coding** — `node_modules/tilia/llms.txt`, `node_modules/@tilia/query/llms.txt`, `node_modules/vitest-bdd/llms.txt` (version-matched), with the R2 negative-knowledge blocks inlined as a fallback for offline/partial installs.
3. **Verification loop** — the standing command, and the instruction that a failing scenario is a contract violation, never a test to edit.
4. **The window** — three-line summary + link to P3.

### Tier 3 sketches

- **T1 `create-epure`:** a template repo consumed by `npm create` — P1's result frozen: layout, configs, P4, one worked example feature. Spec after P1 stabilizes; the template is P1 made instant.
- **T2 Claude Code plugin:** skills = the playbooks with argument plumbing (`/epure:window "the need"` opens a window: drafts the `.feature` diff and stops for signature). No content of its own.
- **T3 lint pack:** eslint rules enforcing P-2 layering mechanically, so alignment (P2) and continuity (P3) get compiler-grade backing beyond types.

---

## 5. Sequencing and open questions

**Build order:** R2 (curation, unblocks everything) → R1 emitter → P4 + P1 (bootstrap is the highest-value playbook) → R4 → P3 → P2 → hand off R3 spec to the tool repos → T1 → T2/T3.

**Open questions**

1. **Version pinning of web references.** Package copies solve versioning for installed projects; do the websites also serve per-version references (`/llms/0.9/llms-full.txt`) or latest-only? Proposal: latest-only until a breaking major exists; the `since:` fields already mark late additions.
2. **Consumption by the tool repos.** R1/R3 outputs are generated *here* but shipped *there* (github.com/tiliajs/*). Options: publish `api.json` and let each repo's CI pull it; or move `docs/content/<tool>/api/` into each tool repo eventually and make this site aggregate. Needs a decision before R3.
3. **Deploy automation.** Nothing exists (no workflows, no CNAME). llms.txt only helps if it is actually at the domain roots; a minimal Pages/static deploy per domain is a prerequisite for layer 2.
4. **ReScript variant timing.** Separate `llms-rescript*.txt` emit is mechanical once the TS emitter exists (the paired-fence structure already isolates the languages); gate it on demand.
5. **Discovery beyond llms.txt.** Do we want an MCP server serving `api.json` lookups? Deferred — packages-in-context should be sufficient, and an MCP server adds an operational surface the method doesn't need yet.
