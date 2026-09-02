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

## 2026-08-23 — `dev` is its own package, `@epure/dev`

The tool is two packages, split by how long each lives. `@epure/create`
scaffolds: a project runs it once, through `pnpm create @epure`, and never
installs it. `@epure/dev` runs the dev server: a project devDepends on it and
runs it every day. The bin is `epure-dev`, and the template's `dev` script
calls it.

One package put the scaffolder in every app that would never run it again, and
the maintainer's `sync` with it. Worse, it made the template depend on the tool
that writes the template. `pnpm sync` reads the template's dependencies to ask
the registry what version each is at, so it asked about `@epure/create` — the
package it was running from — and failed on any registry that had not already
published it. It worked here only because an earlier session had seeded the
local one. A second machine found it in a minute.

The split points the arrow one way. `@epure/create` names `@epure/dev` in the
template it writes. `@epure/dev` names `@epure/create` only in its own
scenarios, which need a scaffold to run against, and a devDependency is not a
cycle. The publish order follows: `@epure/dev`, then `sync`, then
`@epure/create`.

Refused: leaving it and special-casing `@epure/create` inside `sync`. It would
hide the cycle rather than remove it, and leave every app carrying a scaffolder
and a maintainer tool. Refused: dropping the dependency by inlining the three
processes in the template's `dev` script — that copies fourteen scenarios'
worth of supervision into every scaffold, where no fix would ever reach it.

Costs a second package to version and publish, and they move together for now.
`epure dev` no longer runs; it says where `dev` went, because a first word that
is not a command would otherwise scaffold a project named "dev".

## 2026-08-23 — While in beta, the template names tags

`pnpm sync` writes `beta` for a dependency published as a prerelease, and a
caret over the version for a released line. The ranges it wrote before —
`^0.1.0-beta` — met pnpm 11's `minimumReleaseAge`: pnpm holds a version back
for a day after it is published (default 1440 minutes) and quietly resolves
an older one meanwhile, and under that gate the range fell back to the
*oldest* beta on the line. A scaffold made minutes after a publish installed
beta.2 while the registry said beta.6.

The tag alone is not enough — the gate holds tags back too — so the
template's `pnpm-workspace.yaml` lists `@epure/*`, `@lapa/*`, `tilia` and
`@tilia/*` under `minimumReleaseAgeExclude`. The publishing machine goes
further in `~/.config/pnpm/config.yaml`: `minimumReleaseAge: 0` and
`dlxCacheMaxAge: 0`, because `pnpm create @epure` resolves through dlx,
which honors the gate but not the exclusions, and its cache would serve
yesterday's create for a day after a publish.

Refused: keeping the ranges and clearing caches — the gate is policy, not
staleness, and no cache clearing moves it.

Costs a scaffold whose beta versions are resolved at install rather than
fixed by the template, and a spec that never leaves the beta line by itself:
when a line releases, the template is hand-edited to a release spec and the
exclusions are removed. Both costs end with the betas.

## 2026-08-24 — The desk file is minted at install, and dev keeps it

The desk at `/_lapa/mcp` takes the founder's session in the
`Authorization` header, and an MCP client that arrives without it falls
into an OAuth flow the server does not have. An agent reads `.mcp.json`
when it starts, so the file must exist before the agent does — and the
first agent of a project starts right after the install. The template's
`postinstall` runs `epure-dev prepare`: lapa boots once on an ephemeral
port, founds itself if the store is new, the session lands in
`.mcp.json` as the desk's authorization, and the boot stops. Dev writes
the same file on every serve, so a wiped `.data` heals on the next run.
A prepare that cannot boot lapa — missing, or the store held by a
running dev — warns and exits zero: the install stays whole, and the
running dev maintains the file itself. The desk entry is dev's alone:
other entries in the file are kept, and a file that does not parse is
left with a warning. The file carries a credential and differs in every
checkout, so it is created owner-only, the template gitignores it, and
init does not ship it as a file of its own. The template's `AGENTS.md`
tells an agent the loop: run `pnpm dev` in the background, give the
printed link to the person, and reach the desk through `.mcp.json`.

Refused: shipping the entry without the session, as the template did. A
client reads it, is refused, and tries dynamic client registration,
which answers 404. Refused: writing the file only when dev first
serves. The agent usually starts before `pnpm dev`, and asking it to
reconnect proved one step too many. Refused: an environment variable in
the entry — nothing sets it in the client's shell. Refused: a stdio
proxy reading `dev.json` — a second process for what one header does.

Costs an install that boots lapa once, and a `.data` store that exists
before dev has ever served.

## 2026-08-24 — The package is `create-epure`

`@epure/create` becomes `create-epure`, the unscoped package pnpm maps
`pnpm create epure` to — the short form is what a person types from
memory. The trap the scope guarded against does not apply: during
development every install routes to the local registry, whatever the
name's scope, and the registry forwards what it does not hold — no
install falls through to npmjs by accident. The bin stays `epure`.
`create-epure` is free on npmjs (checked 2026-08-24) and publishes the
day epure publishes for real.

Refused: keeping `@epure/create`. The scope bought no safety and cost
the short form.

Costs a rename in every script and paper that named the package, and an
unscoped entry in the local registry's package rules so the name never
proxies to a stranger's future package.

## 2026-08-24 — Sketches compile from `src/croquis`, a dev source

The template's `rescript.json` names `src/croquis` beside `src/design`,
`type: "dev"`, subdirs on. A sketch is an ordinary module: a view mounts
it behind `Env.dev`, like the board, and the flag drops it from a build.
Measured in a scaffold before wiring: the mount compiles from `src/view`
— the compiler does not stop a project's own sources from reaching a dev
module — and the built bundle carries no trace of the sketch. Empty, the
folder costs nothing: the `.gitkeep` holds the directory `rescript.json`
names, and the standing check stays green.

Refused: a plain source block. `type: "dev"` states what the mode
promises — nothing ships depending on a sketch — and keeps sketches out
of any consumer's compile.

Costs a mount line the croquis adds in `src/view` and removes at its
close: a compiled reference cannot outlive the module it names.

## 2026-09-02 — The binding is lapa's; the template ships the seam

`Live.res` is gone. The scaffold depends on `lapa`, `@lapa/db` and
`@lapa/tilia`, and `LiveNotes.res` fills `Notes.t` over `LapaTilia.make`.
`Notes.note` is an id and a title: the record's `_rest` writes the server's
other parts back, so the seam carries no entity. `@tilia/query` stays a
dependency, because the app matches `Loaded` on the loadable the binding
answers and ReScript sees only what a project names. This supersedes the
2026-08-20 rule above: the seam still travels, the binding no longer does.

Refused: a `waiting` that counts writes. The client keeps no count, and the
engine's `status.pending` went with the engine/store split; `LiveNotes` reads
the client's status into a signal on every write and every delivery.

Costs the golden init linking `lapa` and `@lapa/tilia` beside the three it
linked, from `packages/`, and one hand-written `Record` module in
`LiveNotes.res` standing in for a generated file until a model exists.
