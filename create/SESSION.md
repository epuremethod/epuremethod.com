# Session

One bounded goal per session: what will change, why, and who it serves,
then the feature, the approach, the steps, the build. Cleared when the
session closes; lasting reasons go to `DECISIONS.md`.

## Intention

**The scaffold opens a client and shows the board over the app it is
building, behind a toggle that exists only in dev.**

A scaffolded project has never opened a client. `src/Page.res` sets
`textContent` and says the app is running, and `Live.res` — the whole
`@tilia/query` binding the app owns — is wired to nothing. So the first
thing an agent makes has nowhere to appear, and the person beside the
agent has nothing to watch it appear in.

The board becomes an ordinary component of the app. It shares the app's
client, so what the agent makes shows in the app and on the board at the
same moment, off one store and one socket. The toggle is the template's
own: the app decides where the board sits and when, and it renders only
under `import.meta.env.DEV`, so a built app carries no board at all.

Who it serves: Theo, watching a model appear while the agent defines it;
and step 5 of sylva's bootstrap walk.

## Technical

Agreed 2026-08-22, written and not built. sylva's `SESSION.md` holds the same
decisions with the lapa and board halves; this is the template's.

**Amended 2026-08-23, and written; sylva's `SESSION.md` holds the full
handout, under "Step 5 — the board in an app, and the scaffold's hello
world".** The toggle moved into the board: `@lapa/board` draws its own icon at
the bottom right, keeps its open state in `localStorage`, and renders into a
shadow root. The template contributes one line, in `src/view/Page.res`:

```rescript
{Env.dev ? <LapaBoard.Mount client /> : React.null}
```

`@lapa/board` is a **dependency**, not a devDependency: the app compiles it
from ReScript sources, so `pnpm build` needs it present even though the DEV
flag keeps every byte of it out of the bundle — measured by *The board mounts
in the app, and only in dev*.

`<LapaBoard.Mount ...>` rather than the `<LapaBoard ...>` first written: the
board has to carry a ReScript namespace or its twenty module names collide
with the app's, and a collision silently drops the app's own file. Sylva's
handout holds the measurement and the two alternatives still open.

The scaffold also gains a hello world — `Notes.res`, `Hello.res`, `App.res`,
`AppView.res`, `HelloView.res`, `LiveNotes.res`, `Env.res`, `app.css` — so a
new project shows carving, service injection, `derived` and `computed` the
moment it runs, and so `Live.res` is finally wired to something. `Hello.res`
and `HelloView.res` say in their first lines that they are throwaway.

**The session arrives by a clickable link.** `epure dev` prints it once vite
is up and `lapa dev` has given up its session — `epure dev` is the only
process holding both halves, and it already parses that line:

```
adventure-parc  http://localhost:8080/?lapa-session=01a02af7ea697bda...
```

`http://` so the terminal linkifies it: one click, no paste. The app captures
`?lapa-session=`, keeps it in `localStorage`, and removes it from the address
with `history.replaceState`, so the token does not survive into bookmarks,
screenshots or shared links. The parameter is renamed from `?session=`
everywhere, the board's own page included: the address bar belongs to the
app, and lapa namespaces its parameter as `/_lapa/` namespaces its routes.
The port is 8080, fixed by `vite.config.mjs` with `strictPort`.

Rejected: `epure dev` serving the session at a dev-only route — new surface,
and it hands the founder's session to any page on that port. Rejected: the
app reading `.data/dev.json` — vite would have to serve a file outside the
app root, and it ties the app to lapa's on-disk layout.

Rejected: mounting the board in an iframe, in a second tab, or through a
browser extension. Each is a separate JavaScript realm, so the board would
open a client of its own — a second store, a second socket, and two views
that drift apart. Rejected: a vite plugin injecting the overlay. It would
work only under vite dev, it puts app behaviour in the build tool, and the
board would appear nowhere in the app's own source.

Measured before the design leaned on it: a `@lapa/board` reference behind
`import.meta.env.DEV` leaves no trace in `pnpm build`, and the bundle stays
1.17 kB. To be measured again against the real mount, which pulls a React
tree rather than one value.

**A wart to clear while there.** `templates/src/Page.res` is dead code.
`rescript.json` lists `src/domain`, `src/service`, `src/view` and
`src/design`, not `src/` itself, so only `src/view/Page.res` ever compiles.
The two files are byte-identical; the root one goes.

Not in this session: wiring `Live` to a query. `Live.make` needs a class, and
a fresh scaffold has none, so it stays a file the agent uses once a model
exists.

## Where this session stopped

`pnpm sync`, the create convention and `--registry` are built, green and
committed (`2e3e8b3`); their reasons are in `DECISIONS.md`. The suite is 29
scenarios across `Init.feature`, `Dev.feature` and `Sync.feature`.

`@epure/create` is published at `0.1.0-beta.4`, to sylva's local verdaccio
and nowhere else. `bin/publish.sh` raises the beta counter on every publish
and expects that registry at `localhost:4873`; sylva's `bin/registry.sh`
starts it. Run `pnpm sync` before publishing, and commit what it writes.

**Built on 2026-08-23, green: 34 scenarios.** `epure dev` prints one clickable
link once the app answers — it waits for the port rather than for a line vite
prints, so the address is true the moment it is written. Five scenarios in
`Dev.feature` cover it. `templates/src/service/Live.res` follows lapa's
`receives`: the engine attaches its own hook and answers `closes`, so nothing
hands a hook to a client before it exists. The dead `templates/src/Page.res` is
gone.

**Built on 2026-08-23, green: `Init.feature` 9/9.** The scaffold opens a
session, carves a hello world over a seam, and shows the board over the app it
is building. Both open questions are answered. The board reaches the app as
ReScript sources and is one module, so the template writes
`<LapaBoard client />` behind `Env.dev`. The toggle is proven nowhere on
purpose: open and shut is view state, and `src/view/` is rendering over
features with no business behaviour. What is proven is what the template owes —
*The board mounts in the app, and only in dev* reads the line out of the
created page and greps the built bundle, because what a dev flag guards has to
leave the build rather than merely go unrendered.

The scaffold ships scenarios now, which it could not before: it had no
`vitest.config.mjs`, so `vitest run --passWithNoTests` found nothing and
passed. `Hello.feature` is 18 scenarios over a `Notes.t` made of arrays, and
`--passWithNoTests` is gone, so *The project tests pass after initialization*
means a scaffolded project really ran them.

The dead `templates/src/Page.res` was back and shipping into every scaffold.
`Init.feature` asserts it stays gone, and that assertion is what caught it.

**Fixed on the way: `Dev.feature` had been failing 13 of 14.** vite 8 binds
`[::1]:8080` alone unless the host is named, and node's fetch resolves
`localhost` to 127.0.0.1: `ECONNREFUSED`. `fetch("http://[::1]:8080/")`
answered 200. `epure dev` waits for the app to answer before it prints the
link, so the wait never ended and every scenario needing a running app timed
out. The scaffold itself was healthy the whole time — 62 modules compiled,
`vite build` 305 kB, vite and `lapa dev` both fine by hand.

`templates/vite.config.mjs` names `host: "127.0.0.1"`, which is the address the
proxy target in that same file already used. 35/35.

## The dev server moved to its own package

Built on 2026-08-23, green: `create` 22/22, `dev` 14/14.

`@epure/dev` is the dev server, bin `epure-dev`, in `dev/` of this workspace.
`@epure/create` is the scaffolder alone. A project devDepends on the first and
runs the second once, through `pnpm create @epure`.

What forced it: `pnpm sync` reads the template's dependencies to ask the
registry for each version, and the template devDepended on `@epure/create` —
so sync asked about the package it was running from. It worked here only
because an earlier session had seeded the local registry. On a second machine,
against a registry that had never seen it, sync could not resolve at all. The
reasons and what was refused are in `DECISIONS.md`.

The publish order is now one way, and `docs/BOOTSTRAP.md` in sylva carries it:
sylva's three, then `@epure/dev`, then `pnpm sync`, then `@epure/create`.

Two things worth knowing. `epure dev` no longer runs — a first word that is not
a command is a project name, so without a guard the old command would have
scaffolded a project called "dev" and said nothing. It reports where dev went,
and *The old dev command says where dev went* proves it; the scenario was
checked against a reverted `Main.res` and fails there. And both `publish.sh`
scripts now find sylva at `../../sylva`, honour `SYLVA` and `EPURE_NPMRC`, and
say which file they wanted when it is missing — the old default was one
machine's `$HOME/work/sylva`.

## The database package is `@lapa/db`, and the registry is `127.0.0.1`

Both found on Anna's laptop on 2026-08-23, and both about reaching a package
rather than what it does. The reasons are in sylva's `SESSION.md` and
`docs/BOOTSTRAP.md`.

The template names `@lapa/db` now. npm routes registries by scope, and there is
no rule for a bare name, so an unscoped `lapa` always came from the default
registry — where an unrelated `lapa@1.1.2` lives. `TestCli.res` and `dev`'s
`setup.mjs` link it by the new name, and `Init.feature` and `Sync.feature` say
it in their tables.

Neither publish script names a registry now, and neither `package.json` carries
`publishConfig.registry`. They read `npm config get registry`, so the one lever
is `registry=http://localhost:4873` in `~/.npmrc`. The placeholder rule moved
into the scripts: they refuse to run against npmjs.org and say why. `pnpm sync`
and `pnpm create` take no flags either.

`epure-dev`'s wait asks both loopback families rather than only `localhost`,
because the word is not one address. The template still names
`host: "127.0.0.1"` for vite: its default is `localhost`, and everything that
has to reach the app — the wait, the scenarios, the proxy target — names an
address, so the app names one too.

One thing to know when scaffolding: ask for `pnpm create @epure@beta`, not a
version. Every publish passes `--tag beta`, and `--tag beta` never moves
`latest`, so a bare `pnpm create @epure` runs whatever the very first publish
set, forever. A partial version like `0.1.0-beta` is a range that matches
nothing published.

`create` 22/22, `dev` 14/14.

## The scaffold approves its own builds

`templates/pnpm-workspace.yaml` names `msgpackr-extract` beside `esbuild` under
`allowBuilds`. Without it pnpm stops at the end of the install and tells the
person to run `pnpm approve-builds` — from a directory they are not in, after
an install that scrolled past, and on some pnpm versions as
`ERR_PNPM_IGNORED_BUILDS` rather than a warning, which fails the init outright.

`msgpackr-extract` arrives through `@lapa/server` →
`@harperfast/rocksdb-js` → `msgpackr`. It is an optional native accelerator
with prebuilt binaries per platform, so allowing it costs an install script
rather than a compile, and msgpackr falls back to pure JS without it.

`Init.feature` asserts the created file carries `msgpackr-extract: true`, not
the install output. Once a build has run it is in the store and no later
install asks again, so the output only shows the problem on a machine that has
never built it — the assertion would pass everywhere it mattered least.

Two silent passes on the way to that, both caught by trying to make the
scenario fail. The first read `last`, which the opening scenario never sets
because it reads the shared scaffold rather than running its own init. The
second matched `"msgpackr-extract"` against the explanatory comment in the file
rather than the setting.
