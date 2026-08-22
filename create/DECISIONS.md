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

## 2026-08-22 — The template's versions are fixed when the tool publishes

`pnpm sync` resolves every dependency the template names against the
registry in front of it and writes what it found. A template is worth
what its versions were installed, built and tested at together, so they
are fixed here and never resolved when a project is scaffolded. The four
steps are sync, commit, test, publish, in that order: sync is its own
step so the bump lands in the history as a readable change, and what was
tested is what was committed.

Sync follows the line the template is already on. A prerelease spec asks
for that tag, anything else asks for the release, and either falls back
to the other when the line it wants is empty. The range written is a
caret over the base version, keeping the first prerelease identifier:
`0.1.0-beta.3` becomes `^0.1.0-beta`, `19.2.3` becomes `^19.2.3`.

Refused: taking the newest version regardless of line. `tilia` is
`5.2.0` on latest and 6 on beta, and the scaffold's `Live.res` is
written against 6 — sync would have downgraded it and broken the build.
Leaving a beta line stays a hand edit, which sync then respects.

Refused: a curated list of packages to pin. The range style follows from
what the registry answers, so `react` and `lapa` go through one path.

A beta range floats on purpose. `^0.1.0-beta` matches every later beta
of that line and then the release that ends it, which is what a beta is
for. It does not reach the next line, so moving from `^0.1.0-beta` to
`^0.2.0-beta` is a sync and a commit that someone reads.

Costs a step before every publish, and a refusal when a dependency is
not published — sync writes nothing rather than moving the template half
way.

## 2026-08-22 — `pnpm create @epure <name>` names the project directly

npm's create convention runs the bin as `epure <name>`, with no
subcommand, and the tool answered its usage line instead. A first word
that is neither a command nor a flag is the project's name. `epure init
<name>` still works and is what the scenarios drive.

Costs a rule that a future subcommand must be added to.

## 2026-08-22 — `--registry` hands the registry to the project

pnpm reads `.npmrc` from the project directory and does not walk up, so
a registry configured where the command was typed does not reach the
install `init` runs one level down. `epure init <name> --registry <url>`
writes `.npmrc` into the scaffold, so the first install and every later
one find it. With no flag no file is written.

Refused: restricting the flag to prerelease versions. Where packages
come from and what versions they are are unrelated, and a mirror, an
offline install or a CI cache are ordinary reasons to point elsewhere.
The guard against publishing in the wrong place is
`publishConfig.registry`, which is a different thing.

Refused: redirecting `registry.npmjs.org` in `/etc/hosts`. It is
machine-global and invisible, and it fails on TLS against a local
registry serving http.

Costs an `.npmrc` in a scaffold whose maker asked for one.
