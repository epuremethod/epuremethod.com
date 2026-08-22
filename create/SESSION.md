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

`@lapa/board` is a devDependency and exposes one public module, so the app
writes `<LapaBoard client />`. The template renders the toggle, and the board
when the toggle is open — full page while nothing is defined, an overlay over
the app once something is. The toggle's open state lives in `localStorage`,
so it survives the reloads a dev session is made of, and the whole branch
sits under `import.meta.env.DEV`.

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

The template above is the next stage: the feature file first, then the build.
