# Agent Support Design — épure for AI coding assistants

Status: reviewed 2026-07-22. The method site, repository guidance, Tilia
documentation pipeline, and the first compact package references exist. The
published content and project template are partial; the method playbooks and
most `@epure/vitest` agent support remain to be built.

Scope: the documents and tools needed so that an AI coding assistant with no
prior knowledge of tilia, `@tilia/query`, or `@epure/vitest` can bootstrap an
épure project, align an existing project, and keep the method alive as the
project evolves.

This review used the complete local working trees for
[épure](https://github.com/epuremethod/epuremethod.com),
[Tilia](https://github.com/tiliajs/tilia), and the repository that is becoming
[`@epure/vitest`](https://github.com/epuremethod/vitest). Local staged and
uncommitted work counts as prepared, not published.

---

## 1. Outcome and constraints

The tools are small and recent enough that an assistant may complete an unknown
API by analogy: Tilia becomes Redux or MobX, `@tilia/query` becomes TanStack
Query, and `@epure/vitest` becomes Cucumber.js. Good agent support should reduce
those guesses and make remaining mistakes fail quickly. It cannot guarantee
that an assistant never hallucinates or that semantically wrong code always
fails.

Three layers reinforce each other:

| Layer | Mechanism | Purpose |
|---|---|---|
| Knowledge | A compact guide plus the exact contract for the installed package | Teach the API's shape and pre-empt false analogies |
| Verification | The project's typecheck and executable scenarios | Catch invalid calls and violated behavior |
| Process | Scenario-first playbooks and a repository working agreement | Keep the method intact as the project changes |

The sources of truth are deliberately narrow:

- Public API contracts and tests live with each implementation package.
- A package's `llms.txt` explains its mental model, critical rules, and traps,
  then points to its exact TypeScript and ReScript contracts. It should not
  reproduce every signature.
- Method playbooks and the consuming-project `CONTRIBUTING.md` template live in
  this repository.
- Content is reused verbatim when it must appear in several places. Generation
  is useful only when there is an existing structured source; it is not a goal
  by itself.

---

## 2. Delivery and ownership

Four delivery channels remain useful:

1. **Installed packages** provide version-matched `llms.txt` and declarations
   without requiring network access.
2. **Websites** provide discovery and the latest human and machine references:
   [tiliajs.dev](https://tiliajs.dev),
   [tiliajs.dev/query](https://tiliajs.dev/query),
   [epurejs.dev](https://epurejs.dev), and
   [epuremethod.com](https://epuremethod.com).
3. **Consuming repositories** carry the project `CONTRIBUTING.md` template and
   a one-line `AGENTS.md` that sends assistants to it.
4. **Agent-native integrations** may wrap the same playbooks later. They must
   not become a second source of method content.

Ownership is now resolved:

- [epuremethod/epuremethod.com](https://github.com/epuremethod/epuremethod.com)
  owns the method, P1–P4, the method website, and method-level agent discovery.
- [tiliajs/tilia](https://github.com/tiliajs/tilia) owns the `tilia`,
  `@tilia/react`, and `@tilia/query` contracts, package references,
  documentation, releases, and `tiliajs.dev`.
- [epuremethod/vitest](https://github.com/epuremethod/vitest) will own
  `@epure/vitest`, its references, documentation, release, and `epurejs.dev`.
  The local repository and package are still named `vitest-bdd`; the transfer
  and rename are pending.
- Starter, plugin, and lint implementations should use separate repositories
  when they become real distributable tools. Their method-level specifications
  remain here.

There is no longer a central tool-documentation pipeline in this repository.
Tool references are authored and shipped with the tool whose version they
describe.

TypeScript and ReScript contracts are already separate source files. The
current compact Tilia guide links both and includes one example in each
language. Separate `llms-rescript*.txt` files are not required until mixed
examples cause a demonstrated problem or full references are introduced.

---

## 3. Current artifact status

Status meanings:

- **Done** — implemented in the owning local repository.
- **Prepared** — present locally but not yet committed, pushed, or deployed.
- **Partial** — useful implementation exists, but the acceptance below is not
  met.
- **Pending** — no implementation exists.
- **Deferred** — no current consumer justifies the work.

### Foundation already present

- **Method website — prepared.** The complete static site is under `website/`.
  Its move from `DESIGN/site/`, Pages workflow, custom-domain file, and final
  domain correction are local changes. They are not yet committed or deployed;
  DNS still needs to point `epuremethod.com` at GitHub Pages. One tool
  description still incorrectly says that the runner has no translation layer.
- **Tilia documentation — partial.** A validated static build and GitHub Pages
  workflow publish the Tilia and Query guides and API references to
  `tiliajs.dev`. Some guide content anticipates the unpublished
  `@epure/vitest`, while one Query page still links the old runner domain.
- **Vitest integration and human documentation — partial.** The runner,
  fourteen API pages, and eight guide chapters exist. Documentation updates are
  staged locally, but the package, links, site label, and generated imports
  still use `vitest-bdd`. The documentation tests also retain assumptions about
  content that moved to the Tilia repository.

### Catalog

| ID | Artifact | Status | Current evidence |
|---|---|---|---|
| R1 | Compact machine reference per package | Partial | `tilia/llms.txt` and `query/llms.txt` exist locally and on the website; `@tilia/react` and `@epure/vitest` have none |
| R2 | Explicit negative knowledge per package | Partial | Useful rules exist in Tilia compact guides and Vitest human prose, but none has a complete analogy/traps/non-goals section |
| R3 | Documented exact package contracts | Partial | Tilia and Query declarations are substantially documented; Vitest declarations are generated but undocumented |
| R4 | Guidance for this repository | Prepared | `CLAUDE.md` describes intended ownership, but its site and Vitest links anticipate work not yet published |
| P1 | `bootstrap.md` | Pending | No executable zero-to-running playbook exists |
| P2 | `align.md` | Pending | No audit and incremental-migration playbook exists |
| P3 | `evolve.md` | Pending | The website explains the development window, but no agent-executable protocol exists |
| P4 | Project `CONTRIBUTING.md` template | Partial | The 65-line template covers scenarios, code shape, the loop, and package references, but not the complete window and verification contract |
| T1 | `create-epure` starter | Pending | Build after P1 and P4 stabilize |
| T2 | Agent skills/plugin | Deferred | Build only after the playbooks prove useful as plain markdown |
| T3 | Layering lint pack | Deferred | Build only when concrete recurring violations justify rules |

### R1 — compact machine references

The immediate acceptance is one compact `llms.txt` per package that:

1. states the mental model and critical rules;
2. includes the small R2 negative-knowledge section;
3. links the exact language contracts;
4. is included in the npm package and published at the tool's website; and
5. is checked during packaging or release.

Tilia and Query meet most of this. Their compact files link the exact
TypeScript and ReScript contracts and are copied to `/llms.txt` and
`/query/llms.txt`. Tilia packaging explicitly preserves its file. Query
packaging includes the file but currently includes unrelated repository files
as well, so package curation remains.

`@tilia/react` has exact TypeScript and ReScript contracts and is summarized by
the core Tilia guide, but an independently installed package has no local
machine entry point. A short package-local `llms.txt` should point to the core
guide, explain `leaf`, `useTilia`, and `useComputed`, and link its own exact
contracts without duplicating the core reference.

`@epure/vitest` has no machine reference or package inclusion yet.

`llms-full.txt` and `api.json` are deferred. The declarations and human API
pages already provide exhaustive detail, and no MCP or other consumer currently
needs a second exhaustive representation.

### R2 — negative knowledge

R2 is judgment, not generated API data. Each compact reference needs three
short sections: wrong analogies, semantic traps, and deliberate non-goals.
Current facts must be taken from the implementation contracts, not the old
draft in this document.

Current Tilia seeds:

- There is no centralized store/dispatch/action/selectors architecture.
  Tilia does export a `store()` value constructor, so “there is no store” is
  false.
- There are no decorators or class observables.
- React's `useTilia()` takes no arguments and returns `void`; `leaf` is the
  preferred component wrapper.

Current Query seeds:

- There is no `useQuery` hook or query-key array. Queries are plain values and
  reads are `one(query)` and `array(query)`.
- Remote connectivity is a Tilia `Signal<boolean>`. Fetch answers use
  `set`, `live`, `fail`, `end`, and `finally`; writes use
  `set`, `removed`, `retry`, and `fail`.
- Inbound server facts arrive through `receive.changed(values)` and
  `receive.removed(ids)`.
- The engine owns no timers; the application calls `tick()`.
- There is no `dict`, `sync`, `covered`, or `clear` API in the current
  contract.

Current Vitest seeds:

- There is no Cucumber World or Cucumber hooks registry. Vitest lifecycle hooks
  remain available.
- `Given` registers the scenario builder; scenario operations close over the
  context created by that builder.
- Step matching supports the runner's own normalized placeholders such as
  `{string}` and `{number}`; it is not a complete Cucumber Expressions
  implementation.
- Vite translates a feature or Markdown contract to Vitest JavaScript in
  memory. There is no generated test file on disk, but there is a translation
  step.

### R3 — exact contracts

The useful requirement is that every public export has an accurate declaration
and enough documentation for an assistant to choose it correctly.

- Tilia and Query ship separate TypeScript declarations and ReScript
  interfaces. Most public TypeScript exports have useful JSDoc. Missing public
  comments should be filled, and internal exports should remain clearly marked.
- `@since` and automated equality between page summaries and JSDoc are
  optional improvements, not blockers. Add them only if versioned references
  or repeated drift create a concrete need.
- Vitest's generated declaration has no JSDoc and exposes internal
  `load`, `Runner`, and `Operation` symbols. The rename is the right time to
  define and document the intended public surface.

### R4 — repository guidance

`CLAUDE.md` now correctly says that tool documentation belongs in the tool
repositories, explains that `CONTRIBUTING.md` is a template, forbids a root
`AGENTS.md`, and identifies the static website.

Two repository-local corrections remain:

- Until the first successful deployment, change “is published at” to “will be
  published at,” or update the sentence only after deployment is verified.
- The intended `epuremethod/vitest` link is not live yet. Keep the public target
  link, but identify the repository transfer as pending until the URL resolves.

---

## 4. Repository-local backlog

Only method content and method delivery belong here.

### Publish the method site

1. Replace “no translation layer” with the accurate distinction: Vite
   translates contracts in memory, but writes no generated test files.
2. Verify that the advertised `@epure/vitest` name and `epurejs.dev` destination
   are ready, or label the tool as forthcoming until its release.
3. Commit and push the prepared `website/`, workflow, `CNAME`, `CLAUDE.md`, and
   domain-link changes.
4. Select GitHub Actions as the Pages source.
5. Point `epuremethod.com` DNS at GitHub Pages.
6. Verify the custom domain and HTTPS.
7. Only then describe the site as published.

### P3 — `website/agents/evolve.md`

Turn the development window into a short protocol with hard gates:

1. Open on a named need, scope, people, and end date.
2. Draft the `.feature` contract before implementation.
3. Stop until the people who own the need validate the contract.
4. Build against the signed scenarios and run the project's standing check
   after each change.
5. Keep work outside the signed scenarios for a later window.
6. Close only when scenarios are green, the result is demonstrated, and the
   bounded diff has passed its required review and audit.

The protocol should not claim that every project forbids all maintenance
between windows; it should define how urgent maintenance opens a bounded
window.

### P4 — `CONTRIBUTING.md`

Keep the template short and method-level. Reconcile it with the website and P3:

- Add the signed-contract stop before implementation.
- Cover all four method principles: contracts, bounded floors, reactive state,
  and local-first/offline behavior.
- Name a project-defined standing verification command instead of hard-coding
  `tsc`, so the agreement also fits future non-JavaScript adapters.
- State that a failing scenario represents a contract violation; changing the
  contract requires validation, not a convenient test edit.
- Add a brief development-window section linking to P3.
- Keep the instruction to read each installed package's `llms.txt`; do not
  inline three large tool references into the template.

Consuming projects pair the template with a one-line `AGENTS.md`. This
repository must not add one at its root because agent tooling would mistake the
template for this repository's own instructions.

### P1 — `website/agents/bootstrap.md`

The first profile is JavaScript, but the method remains language-independent:

```text
features/   carved business objects, scenarios, and step bindings
repo/       persistence, one object per saved type
services/   deliberately few connectors to the outside world
views/      projections of state, without business logic
```

The playbook should install the released package names, copy P4, create the
one-line project `AGENTS.md`, build one minimal feature end to end, and define
the project's standing check. Do not publish an exact install command until
`@epure/vitest` and `@tilia/query` are available under their intended names.

### P2 — `website/agents/align.md`

Provide:

1. a *relevé* of contracts, boundaries, state flow, and offline behavior;
2. evidence for each finding;
3. an incremental order: capture existing behavior as scenarios, extract
   business objects, isolate external services and persistence, then introduce
   reactive/query infrastructure where a scenario requires it; and
4. a green standing check after every reversible step.

### Method discovery

After P1–P3 exist:

- publish `website/llms.txt` as a compact index of the method and playbooks;
- link `/agents/bootstrap.md`, `/agents/align.md`, and `/agents/evolve.md`;
- link the latest package references without copying their API content; and
- add human-facing links from the method site where they aid discovery.

---

## 5. Tool-repository backlog

### Tilia and `@tilia/query`

Already done:

- validated documentation infrastructure and human guides/API pages;
- compact `llms.txt` files for both tools;
- exact TypeScript and ReScript contracts;
- Tilia package inclusion and website publication; and
- GitHub Pages deployment.

Remaining:

1. strengthen each compact guide with an explicit, implementation-current R2
   section;
2. add a short package-local reference for `@tilia/react`;
3. replace the premature `@epure/vitest` package claims and the remaining
   `vitest-bdd.dev` link when the renamed package is available;
4. curate the Query npm package contents and publish `@tilia/query`;
5. verify package inclusion of all machine guides during release; and
6. fill the remaining public declaration comments where an export is not
   self-explanatory.

Do not treat the untracked legacy website archive as current documentation.

### `@epure/vitest`

Already done:

- the working Vitest/Vite integration;
- in-memory feature-to-test translation with source maps;
- closure-bound scenario operations;
- human API and guide source; and
- generated TypeScript declarations.

Remaining, in dependency order:

1. transfer and rename the repository, package, generated runtime import,
   plugin metadata, ReScript bindings, documentation, and links from
   `vitest-bdd` to `@epure/vitest`;
2. change the documentation target from `vitest-bdd.dev` to `epurejs.dev`;
3. remove the old Tilia/Query assumptions from the documentation tests and
   make the staged docs build green;
4. define the intended public exports and add useful declaration
   documentation;
5. author and package `llms.txt`, including the current Vitest R2 section;
6. add website deployment and custom-domain configuration; and
7. publish and verify the package before P1 uses its final install command.

---

## 6. Deferred work

- **`llms-full.txt` and `api.json`:** wait for a consumer that cannot use the
  compact guide, declarations, and human API pages.
- **Versioned website references:** package-local files solve installed-version
  accuracy. Websites can remain latest-only until a breaking release creates a
  demonstrated need.
- **ReScript-specific machine exports:** exact `.resi` contracts already exist.
  Split the compact references only if mixed-language context proves harmful.
- **MCP documentation server:** packages and static references are sufficient
  today.
- **T2 agent integrations:** wrap stable P1–P3 later; do not duplicate them.
- **T3 lint pack:** specify rules from observed recurring violations rather
  than hypothetical ones.

T1 is not deferred indefinitely: implement `create-epure` after P1 and P4 have
been exercised manually and their output is stable.

---

## 7. Sequence from the current state

Two tracks can proceed independently until bootstrap needs final package names:

1. Publish and verify `epuremethod.com`.
2. In the method repository, write P3, reconcile P4, then write P1 and P2.
3. In the tool repositories, complete current R2/R3 gaps and finish the
   `@epure/vitest` rename, reference, package, and website release.
4. Publish the method `llms.txt` index once P1–P3 and the package URLs are
   stable.
5. Exercise P1 manually on a small project; then freeze its result as T1
   `create-epure`.
6. Build T2 or T3 only in response to demonstrated distribution or enforcement
   needs.

The old greenfield order—R2, generated R1, P4, P1, R4, P3, P2, R3, then
tooling—no longer reflects the repositories. R4 and substantial reference,
documentation, website, and template work already exist; generated exhaustive
references are no longer a prerequisite.
