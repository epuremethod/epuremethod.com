# Agent Support Design — épure for AI coding assistants

Status: reviewed 2026-07-27. The `@epure/vitest` rename landed, all four
package references now exist and are live, and a shared documentation
generator — `@epure/minidoc` — now builds every site. What remains is
publication hygiene (one unpublished package, one reference missing from its
tarball, one stalled deployment) and the method playbooks, which are still
unwritten.

Scope: the documents and tools needed so that an AI coding assistant with no
prior knowledge of tilia, `@tilia/query`, or `@epure/vitest` can bootstrap an
épure project, align an existing project, and keep the method alive as the
project evolves.

This review used the complete local working trees for

* [épure](https://github.com/epuremethod/epuremethod.com)
* [Tilia](https://github.com/tiliajs/tilia)
* [@epure/vitest](https://github.com/epuremethod/vitest)
* [@epure/minidoc](https://github.com/epuremethod/minidoc)

together with the published npm packages and the live sites. All four working
trees are clean and level with `origin/main`, so local state and pushed state
no longer differ; published state is checked separately and is where the
remaining gaps are.

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
   [tiliajs.dev/react](https://tiliajs.dev/react),
   [epurejs.dev](https://epurejs.dev), and
   [epuremethod.com](https://epuremethod.com). All five answer, and each of the
   four tool sites serves its `llms.txt`.
3. **Consuming repositories** carry the project `CONTRIBUTING.md` template and
   a one-line `AGENTS.md` that sends assistants to it.
4. **Agent-native integrations** may wrap the same playbooks later. They must
   not become a second source of method content.

Ownership is resolved:

- [epuremethod/epuremethod.com](https://github.com/epuremethod/epuremethod.com)
  owns the method, P1–P4, the method site, and method-level agent discovery.
- [tiliajs/tilia](https://github.com/tiliajs/tilia) owns the `tilia`,
  `@tilia/react`, and `@tilia/query` contracts, package references,
  documentation, releases, and `tiliajs.dev`.
- [epuremethod/vitest](https://github.com/epuremethod/vitest) owns
  `@epure/vitest`, its references, documentation, release, and `epurejs.dev`.
  The transfer and the rename are done; the repository URL resolves and the
  package is on npm under its new name.
- [epuremethod/minidoc](https://github.com/epuremethod/minidoc) owns
  `@epure/minidoc`, the documentation generator that now builds all three
  sites. The repository is still private, so the link in `CLAUDE.md` does not
  resolve publicly.
- Starter, plugin, and lint implementations should use separate repositories
  when they become real distributable tools. Their method-level specifications
  remain here.

There is no longer a central tool-documentation pipeline in this repository.
Tool references are authored and shipped with the tool whose version they
describe. What *is* shared is the build machinery: `@epure/minidoc` renders
each site from its own `content/**/config.yaml`, so the three sites share a
generator without sharing content.

TypeScript and ReScript contracts are already separate source files. The
compact guides link both and include one example in each language. Separate
`llms-rescript*.txt` files are not required until mixed examples cause a
demonstrated problem or full references are introduced. Tilia additionally
ships `llms-typescript.md` and `llms-rescript.md` in its tarball; that split is
package-local and has not been generalized.

---

## 3. Current artifact status

Status meanings:

- **Done** — implemented, published, and verified where publication applies.
- **Prepared** — present and pushed, but not yet visible to a consumer.
- **Partial** — useful implementation exists, but the acceptance below is not
  met.
- **Pending** — no implementation exists.
- **Deferred** — no current consumer justifies the work.

### Foundation already present

- **Method site — partial.** `epuremethod.com` answers over HTTPS on its
  custom domain, so DNS, Pages, and the certificate are done. The live build
  predates the minidoc migration: `/agreement.html` and `/CONTRIBUTING.md`
  both return 404 although both are produced by the local build and their
  source is pushed. The deployment, not the content, is what is missing. One
  tool description still says the runner has “no translation layer.”
- **Tilia documentation — done for delivery, partial for content.**
  `tiliajs.dev` publishes the Tilia, Query, and React guides, API references,
  and `llms.txt` files. The remaining problems are content-level: the guides
  show `@epure/vitest` imports while every test in the repository still
  imports `vitest-bdd`, and one Query page still links `vitest-bdd.dev`.
- **`@epure/vitest` — done except for the stable release.** The repository
  transfer, the package rename, the in-memory translation, the docs migration
  to minidoc, `epurejs.dev`, and a packaged `llms.txt` are all in place, and
  the docs tests pass. Only beta versions are on npm, `vitest-bdd@latest` is
  still the pre-rename `1.0.1`, and the old name is not yet deprecated.
- **`@epure/minidoc` — new since the last review.** A ReScript documentation
  generator published as a beta and already building all three sites. It is
  tested through YAML scenarios run by `@epure/vitest`, which makes it the
  first tool in the ecosystem that dogfoods the method it supports.

### Catalog

| ID | Artifact | Status | Current evidence |
|---|---|---|---|
| R1 | Compact machine reference per package | Partial | `tilia`, `@tilia/query`, `@tilia/react`, and `@epure/vitest` each have an `llms.txt`, and all four are live; `@tilia/react` excludes its own file from the npm tarball, `@tilia/query` is not published at all, and `@epure/minidoc` has none |
| R2 | Explicit negative knowledge per package | Partial | `@epure/vitest` has the full three-section shape; the three Tilia references carry only scattered inline negatives |
| R3 | Documented exact package contracts | Partial | `tilia` and `@tilia/query` declarations are heavily documented; `@epure/vitest` defines its public surface and marks `load`/`loadYaml` `@internal`; `@tilia/react`'s 20-line declaration has only one-line comments |
| R4 | Guidance for this repository | Done | `CLAUDE.md` matches reality: the site is live, the vitest repository resolves, and the site folder is now `docs/`. Only the minidoc link is unresolvable, because that repository is private |
| P1 | `bootstrap.md` | Pending | No executable zero-to-running playbook exists |
| P2 | `align.md` | Pending | No audit and incremental-migration playbook exists |
| P3 | `evolve.md` | Pending | The site explains the development window, but no agent-executable protocol exists |
| P4 | Project `CONTRIBUTING.md` template | Partial | The 65-line template covers the promises, code shape, the loop, and package references, but not the signed-contract stop or the verification contract; the published page and raw download exist in the build but not yet on the live site |
| T1 | `create-epure` starter | Pending | Build after P1 and P4 stabilize |
| T2 | Agent skills/plugin | Deferred | Build only after the playbooks prove useful as plain markdown |
| T3 | Layering lint pack | Deferred | Build only when concrete recurring violations justify rules |
| T4 | `@epure/minidoc` generator | Partial | Published as a beta and building all three sites; it has no reference, no site, and no agent-facing documentation of its own |

### R1 — compact machine references

The acceptance is one compact `llms.txt` per package that:

1. states the mental model and critical rules;
2. includes the small R2 negative-knowledge section;
3. links the exact language contracts;
4. is included in the npm package and published at the tool's website; and
5. is checked during packaging or release.

Where each package stands against point 4, which is now the discriminating
one:

| Package | In the repository | On the site | In the tarball |
|---|---|---|---|
| `tilia` | yes | `tiliajs.dev/llms.txt` | yes, with `llms-typescript.md` and `llms-rescript.md` |
| `@tilia/query` | yes | `tiliajs.dev/query/llms.txt` | package not published |
| `@tilia/react` | yes | `tiliajs.dev/react/llms.txt` | **no** — `.npmignore` whitelists `dist/`, `src/*`, and `rescript.json`, and never re-includes `llms.txt` |
| `@epure/vitest` | yes | `epurejs.dev/llms.txt` | yes |
| `@epure/minidoc` | no | no site | n/a |

The `@tilia/react` gap matters more than it looks: the working agreement tells
assistants to read `node_modules/<package>/llms.txt`, so a project that
installs `@tilia/react` finds nothing where the agreement promises something.
Fixing it is one line in `.npmignore`, and it is the strongest argument for
acceptance point 5 — a packaging check, not a convention.

`llms-full.txt` and `api.json` remain deferred. The declarations and human API
pages already provide exhaustive detail, and no MCP or other consumer needs a
second exhaustive representation.

### R2 — negative knowledge

R2 is judgment, not generated API data. Each compact reference needs three
short sections: wrong analogies, semantic traps, and deliberate non-goals.

`@epure/vitest` now has exactly that shape in its 64-line `llms.txt`, and it
is the pattern the others should copy rather than reinvent. The three Tilia
references state their negatives inline instead — “no store, no selectors,” or
“an answer, not a progress state” — which is useful prose but is not findable
as a section and is easy to skim past.

Current Tilia seeds:

- There is no centralized store/dispatch/action/selectors architecture.
  Tilia does export a `store()` value constructor, so “there is no store” is
  false.
- There are no decorators or class observables.
- React's `useTilia()` takes no arguments and returns `void`; `leaf` is the
  preferred component wrapper, and there are no dependency arrays, selectors,
  or `memo` wrapper.

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

Vitest seeds are no longer a backlog item; they are shipped. The file names the
absent Cucumber World and hooks registry, the partial Cucumber Expressions
support, the in-memory translation with no generated file on disk, and the
requirement that operations follow `Given`.

### R3 — exact contracts

The useful requirement is that every public export has an accurate declaration
and enough documentation for an assistant to choose it correctly.

- `tilia` and `@tilia/query` ship TypeScript declarations and ReScript
  interfaces of comparable size (roughly 230–300 lines each), with behavioral
  JSDoc on public exports and `@internal` on the rest. They meet the
  requirement.
- `@tilia/react` is the outlier: a 20-line declaration with one-line comments
  and a ReScript interface that documents only `make`. Its surface is small,
  but `leaf`, `useTilia`, and `useComputed` are exactly the three calls an
  assistant gets wrong by analogy, so this is where prose pays.
- `@epure/vitest` improved with the rename. The public exports are deliberate,
  the options carry JSDoc, and `load` and `loadYaml` are marked `@internal`
  while `Runner` and `Operation` are no longer exported as named types. The
  declarations are generated at build time by tsup rather than committed,
  which is fine as long as the packaging check covers them.
- `@since` and automated equality between page summaries and JSDoc remain
  optional. Add them only if versioned references or repeated drift create a
  concrete need.

### R4 — repository guidance

`CLAUDE.md` is now accurate. It says tool documentation belongs in the tool
repositories, explains that `CONTRIBUTING.md` is a template, forbids a root
`AGENTS.md`, and identifies the site — which is live, at a link that resolves,
built from a folder that exists under its current name.

The two corrections carried by the previous review are closed: the site is
published, and `github.com/epuremethod/vitest` resolves. One new inaccuracy
takes their place — the minidoc link points at a private repository. Either
make the repository public with the first stable release or mark the link as
forthcoming.

---

## 4. Repository-local backlog

Only method content and method delivery belong here.

The site folder is now `docs/`, matching `docs/` in the tilia and vitest
repositories, and the workflow is `deploy-docs.yml` for the same reason. Paths
below use the new name.

### Finish publishing the method site

The infrastructure work from the last review is done: the Pages source, the
DNS records, the custom domain, and HTTPS all work. What is left is one
deployment and two content corrections.

1. Deploy the pushed build. The live site still serves the pre-minidoc
   version, so the agreement page and the `CONTRIBUTING.md` download 404. The
   workflow gained a build step in the same commit that introduced them, and
   its `pnpm/action-setup` step had no version source at the repository root;
   it now reads `docs/package.json`. Re-run it and confirm.
2. Verify `/agreement.html` and `/CONTRIBUTING.md` answer before describing
   the template as downloadable anywhere.
3. Replace “no translation layer” in the `@epure/vitest` card with the
   accurate distinction: Vite translates contracts in memory, but writes no
   generated test files.
4. Decide how to describe a tool that is published only as a beta. The card
   links `epurejs.dev`, which is live, but `npm install @epure/vitest` today
   resolves to a beta version.

### P3 — `docs/agents/evolve.md`

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

Keep the template short and method-level. Reconcile it with the site and P3:

- Add the signed-contract stop before implementation.
- Cover all four method principles: contracts, bounded floors, reactive state,
  and local-first/offline behavior.
- Name a project-defined standing verification command instead of hard-coding
  `tsc`, so the agreement also fits future non-JavaScript adapters.
- State that a failing scenario represents a contract violation; changing the
  contract requires validation, not a convenient test edit.
- Add a brief development-window section linking to P3.
- Keep the instruction to read each installed package's `llms.txt`; do not
  inline three large tool references into the template. The instruction is
  only as true as the packaging, which is why the `@tilia/react` gap above is
  a method problem and not only a Tilia problem.
- The template also assumes `.feature` files. `@epure/vitest` now accepts YAML
  contracts as well, and `@epure/minidoc` uses them exclusively, so the
  wording should name the contract rather than the extension.

Consuming projects pair the template with a one-line `AGENTS.md`. This
repository must not add one at its root because agent tooling would mistake the
template for this repository's own instructions.

### P1 — `docs/agents/bootstrap.md`

The first profile is JavaScript, but the method remains language-independent:

```text
features/   carved business objects, scenarios, and step bindings
repo/       persistence, one object per saved type
services/   deliberately few connectors to the outside world
views/      projections of state, without business logic
```

The playbook should install the released package names, copy P4, create the
one-line project `AGENTS.md`, build one minimal feature end to end, and define
the project's standing check. The exact install command still waits on two
releases: `@tilia/query` is unpublished, and `@epure/vitest` has only beta
versions.

### P2 — `docs/agents/align.md`

Provide:

1. a *relevé* of contracts, boundaries, state flow, and offline behavior;
2. evidence for each finding;
3. an incremental order: capture existing behavior as scenarios, extract
   business objects, isolate external services and persistence, then introduce
   reactive/query infrastructure where a scenario requires it; and
4. a green standing check after every reversible step.

### Method discovery

After P1–P3 exist:

- publish `docs/llms.txt` as a compact index of the method and playbooks;
- link `/agents/bootstrap.md`, `/agents/align.md`, and `/agents/evolve.md`;
- link the latest package references without copying their API content; and
- add human-facing links from the method site where they aid discovery.

`epuremethod.com/llms.txt` currently 404s, which is correct — it should not
exist until it can point at real playbooks.

---

## 5. Tool-repository backlog

### Tilia and `@tilia/query`

Already done:

- validated documentation infrastructure and human guides/API pages, now built
  by `@epure/minidoc`;
- compact `llms.txt` for `tilia`, `@tilia/query`, and `@tilia/react`, all three
  served from `tiliajs.dev`;
- exact TypeScript and ReScript contracts, well documented for the first two;
- `tilia` and `@tilia/react` published at 5.2.0; and
- GitHub Pages deployment.

Remaining:

1. publish `@tilia/query`; it is the only package in the ecosystem whose
   reference is live while the package it documents cannot be installed, and
   `bin/publish.sh` does not include it;
2. re-include `llms.txt` in the `@tilia/react` tarball and add a packaging
   check so the omission cannot recur;
3. give each compact guide an explicit, implementation-current R2 section on
   the `@epure/vitest` model;
4. expand the `@tilia/react` declarations where `leaf`, `useTilia`, and
   `useComputed` invite false analogies;
5. migrate the repository's own tests from `vitest-bdd` to `@epure/vitest`.
   Every package and sample app still imports the old name from a July beta
   while the published guides show the new one, so the documentation
   contradicts the code an assistant reads next to it; and
6. replace the remaining `vitest-bdd.dev` link in the Query guide.

Do not treat the untracked legacy site archive as current documentation.

### `@epure/vitest`

Already done:

- the repository transfer and the rename, with `vitest-bdd` retained
  deliberately as a compatibility shim that re-exports the canonical package;
- the working Vitest/Vite integration and in-memory translation with source
  maps;
- YAML contracts alongside Gherkin;
- closure-bound scenario operations;
- human API and guide source, migrated to `@epure/minidoc` and deployed to
  `epurejs.dev`, with green docs tests;
- a packaged `llms.txt` including a complete R2 section; and
- a defined public surface with internals marked `@internal`.

Remaining, and tracked in that repository's own `NEXT-STEPS.md`:

1. publish the stable `@epure/vitest` release; only betas exist today;
2. publish the `vitest-bdd` shim at the same version and deprecate the old
   name — `vitest-bdd@latest` is still the pre-rename `1.0.1`, so anyone
   installing it today gets the old package with no signal;
3. verify the tarball's ESM, CJS, types, ReScript sources, and `llms.txt`
   after publication; and
4. re-check the site and the released sources for stale strings before calling
   the migration complete.

### `@epure/minidoc`

Already done:

- a small ReScript generator with a three-function public interface — `run`,
  `nodeFs`, and `makeMemoryFileSystem` — and hand-written TypeScript
  declarations;
- YAML-configured builds driving all three sites from one beta version;
- scenario-first tests: eight YAML contracts run by `@epure/vitest` against an
  in-memory filesystem, plus a packaging smoke test; and
- a README covering the model, the variable kinds, and the build entries.

Remaining:

1. decide whether the repository becomes public, and fix or qualify the
   `CLAUDE.md` link accordingly;
2. publish a stable version once the three sites stop moving; and
3. write an `llms.txt` only when someone outside these four repositories
   builds a site with it. Until then the README and the declarations are
   enough, and a reference would be a fourth thing to keep in sync.

Its test suite is worth noting beyond this backlog: it is the first place where
the method is applied to an épure tool rather than described by one. If the
bootstrap playbook needs a worked example that is neither a toy nor a
framework, this is the closest candidate.

---

## 6. Deferred work

- **`llms-full.txt` and `api.json`:** wait for a consumer that cannot use the
  compact guide, declarations, and human API pages.
- **Versioned site references:** package-local files solve installed-version
  accuracy. Sites can remain latest-only until a breaking release creates a
  demonstrated need.
- **ReScript-specific machine exports:** exact `.resi` contracts already exist.
  Split the compact references only if mixed-language context proves harmful.
- **MCP documentation server:** packages and static references are sufficient
  today.
- **A reference for `@epure/minidoc`:** no external consumer yet.
- **T2 agent integrations:** wrap stable P1–P3 later; do not duplicate them.
- **T3 lint pack:** specify rules from observed recurring violations rather
  than hypothetical ones.

T1 is not deferred indefinitely: implement `create-epure` after P1 and P4 have
been exercised manually and their output is stable.

---

## 7. Sequence from the current state

The publication work and the playbook work are independent until bootstrap
needs final package names. Publication is now the shorter list, and it unblocks
the other.

1. Deploy and verify `epuremethod.com`, so the agreement page and its raw
   download exist.
2. Close the three publication gaps in the tool repositories: publish
   `@tilia/query`, ship `llms.txt` in the `@tilia/react` tarball, and release
   `@epure/vitest` with the `vitest-bdd` deprecation.
3. In the method repository, write P3, reconcile P4, then write P1 and P2. P1
   can name exact install commands as soon as step 2 lands.
4. Bring the Tilia repository's own tests onto `@epure/vitest` and add the R2
   sections its three references lack.
5. Publish the method `llms.txt` index once P1–P3 and the package URLs are
   stable.
6. Exercise P1 manually on a small project; then freeze its result as T1
   `create-epure`.
7. Build T2 or T3 only in response to demonstrated distribution or enforcement
   needs.

The old greenfield order—R2, generated R1, P4, P1, R4, P3, P2, R3, then
tooling—no longer reflects the repositories. R4, the references, the
documentation, the sites, and the template already exist; what is scarce now is
release discipline and the playbooks, not writing.
