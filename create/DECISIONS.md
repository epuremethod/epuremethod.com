# Decisions

Lasting reasons, appended when a session closes: date, decision, rejected
alternative, and cost. Not a work log.

## 2026-08-20 — The tool lives in `create/` of the method repo

The method's tool is package `@epure/create` — `epure` is taken on npm —
with bin `epure`, and `pnpm create @epure` reaches it by npm's create
convention. It lives in `create/` of the `epuremethod.com` repository,
which is one pnpm workspace: `docs/` the site, `create/` the tool. One
repo holds the method, the site and the tool, so the agreement template
`init` ships is single-sourced from `docs/content/agreement.md`, and one
pull brings everything to a box.

Refused: a repository of its own, `epuremethod/epure`. It would split the
method across two repos and duplicate the agreement template at HEAD.
Refused: `@epure/init` as the name; the same binary carries `dev`.

Costs the tool's method files living inside `create/`, not at the
repository root, which must not shadow the template the site publishes.

## 2026-08-20 — The scaffold is diagonal, and keep files carry the layers

`epure init` scaffolds the diagonal architecture: `domain/api/entity`,
`domain/api/feature`, `domain/api/service`, `domain/feature`, `service`,
`view`, and épure's `design` for scenarios and steps. `view/` holds the
app's face; a server has `surfaces/` instead, as lapa does. The
agreement's "shape of the code" section was rewritten to match; the
`repo/` floor is gone, persistence is a service. Each empty layer ships a
keep file, traveling as `gitkeep` and landing as `.gitkeep` — npm pack
mistreats dotfiles, the `gitignore` rule extended. The layout scenario
requires every layer to hold at least one file.

Refused: `init` creating the empty directories itself. Git carries no
empty directory, so Theo's first commit would drop the layers and a CI
checkout would no longer hold the source directories `rescript.json`
declares.

Costs five placeholder files in every new project, kept until a layer's
first real file lands.

## 2026-08-20 — The seam travels, not the app

The template ships `src/service/Live.res` — the binding where the lapa
client feeds @tilia/query, proven in the epure-template twin — and the
stack ranges that install it: tilia and `@tilia/react` at `^6.0.0-beta`,
`@tilia/query` at `^0.1.0-beta`. The worked example (`Note.res`,
`Notes.feature`, its steps) stays in the twin: the scaffold hands Theo a
seam, not an app to delete, and the example's steps need `@lapa/server`,
which is unpublished.

Refused: a seed scenario in the scaffold. Anything meaningful needs
`@lapa/server`; anything trivial is noise. The empty suite proves the
harness — rescript, vitest, @epure/vitest — so Theo's first scenario
fails on its content, never on wiring.

Costs a scaffold with no scenario over the binding until the alpha; the
twin carries the proof.

## 2026-08-20 — The golden init installs from npm

The shared init links only `lapa` from its checkout; tilia,
`@tilia/query` and `@tilia/react` install from the registry. Every test
run proves the published ranges resolve, compile, and bundle.

Refused: linking all four packages. It kept the suite hermetic and
proved nothing about what npm actually serves.

Costs a test suite that needs the registry.

## 2026-08-20 — Dev is two processes as one

`epure dev` spawns `lapa dev .data --port 8081` and vite, and stops them
together: either process dying takes the other down and dev exits
nonzero. Vite starts only once lapa has said `dev` — the data directory
is served before the app can answer. The ports and the `/_lapa/` proxy
live in the template's `vite.config.mjs`; dev itself only starts,
watches, and stops. The `lapa` binary comes from PATH, or from
`EPURE_LAPA_BIN` for a checkout while nothing is published.

Refused: dev owning the ports or the proxy. The template's vite config
is the app's own file, like the binding; dev reads nothing from it.

Costs a fixed inner port, 8081, until a need for choosing one appears.

## 2026-08-20 — Dev compiles, and the project owns its tool

`epure dev` runs `rescript watch` beside `lapa dev` and vite — three
processes as one. Without the compiler, dev served a page whose script
did not exist; the edit scenario now proves a source change reaches the
served script. After init, Theo types `pnpm dev`: the template's `dev`
script runs `epure dev`, and `@epure/create` sits in devDependencies like
vite and vitest. `pnpm create @epure` is the one global moment. The tool
pulls nothing: `rescript` and `vite` are peer dependencies at `*`, and
dev calls the stable commands from the project's own bin.

Refused: a dev script spawning the processes itself. Supervision code
would rot in every scaffolded app; a fix in the tool reaches every
project by a version bump.

Refused: a globally installed epure. A global tool drifts from the
project that scaffolded; the devDependency is version-locked in the
lockfile.

Costs a `--with` link for `@epure/create` until it publishes, and one
more directory in every project's node_modules.

## 2026-08-20 — The template approves its build scripts

pnpm blocks dependency build scripts and refuses the install until they
are approved. The template ships `pnpm-workspace.yaml` — the home of pnpm
settings — declaring `allowBuilds` with the scripts the stack needs:
today esbuild, vite's own transform engine. The list is the
explicit record of what may run at install; it grows deliberately, one
name at a time, when a dependency with a native piece joins the stack.
The `pnpm` field in package.json is no longer read.

Refused: dropping esbuild. It is vite's dependency, not the template's
choice; it leaves when vite replaces it.

Costs a pnpm-specific field in the scaffold's package.json.

## 2026-08-20 — A missing lapa is named, and dev leaves nothing behind

When a process of dev's cannot start, dev says which one and why, hints
the cure for lapa — install `@lapa/server`, or `EPURE_LAPA_BIN` for a
checkout — stops the others, and exits nonzero only after they have
closed. Exiting immediately orphaned the compiler's watcher, which then
blocked the next build with its lock.

Refused: letting the spawn error throw. An unhandled stack trace names
nothing and leaves the watcher running.

Costs an exit that waits for its children.
