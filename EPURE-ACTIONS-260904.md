# épure — actions from the flood session

**Date:** 2026-09-04
**Sources:** `EPURE-REPORT-260903.md`, the flood code at `~/tmp/flood`, this
repository, and `~/git/epuremethod.com`.

Every claim in the report was checked against the code. Almost all of them
hold. This file says which do not, adds what the report missed, and turns the
whole into concrete actions. Each action names the repository it lands in.

---

## 1. Feedback on the report

### 1.1 What holds, verified

- The three kind vocabularies are real. The desk speaks `ref`/`refs`
  (`packages/server/src/surfaces/desk/Tools.res:843`), the generator emits
  `relation`/`relations` (`Typing.res`, `kinded`), and the app writes
  `Lapa.Value.Ref` (`Lapa.resi`). The stored `Field.kind` value is the
  desk's spelling. Nothing runs the db yet, so this is a clean rename with
  no migration (§3, A5).
- The desk cannot answer a cold session. `epure-dev prepare` boots `lapa dev`
  only long enough to write `.mcp.json`, then kills it (`dev/src/Dev.res`,
  `prepare`). Nothing leaves a desk listening. The report's first finding is
  structural, not a documentation gap.
- The browser database name is the literal `"app"` for every scaffolded
  project (`create/templates/src/view/Page.res:67`). The boot error it causes
  is `Errors.invalidAncestors`, raised with a raw id.
- The croquis boundary is a convention only. `"type": "dev"` in
  `rescript.json` does not stop a shipping import, and the probe pair that
  proved it still sits in flood's `lib/bs/`. The blessed mechanism — a mount
  line in `src/view`, added and removed by hand — is recorded only in
  `create/DECISIONS.md`, which no scaffolded project receives.
- Creation is the one untyped write path. `LapaTilia` has `upsert` and no
  `create`, so every app drops to `client.ops.create` with a hand-built
  `dict<Lapa.Value.t>`.

### 1.2 Where the report overstates

- **"No id ever crosses into the DOM" is not quite what the code does.**
  `FamilyView.res` passes raw ids as React `key` in three places. A `key`
  never round-trips through a text channel, so the latent bug the decision
  guards against is absent — but a NUL-carrying byte string as a
  reconciliation key is its own risk, and the decision does not cover it.
  The `Chip` picker also passes ids directly in closures; only the two
  `<select>`s pay the position-coupling cost.
- **The fake ids cannot catch the byte-string bug.** The steps mint
  `"member-0"`, printable ASCII. The one decision the agent reasoned its way
  to has zero executable coverage. This is an argument for `Lapa.spell`
  (§3, A4), not against the report.
- **The croquis workaround was not pure waste.** `Sketch.res` duplicated 80
  lines of `Page.res` session plumbing. The cost of the missing documentation
  was duplication and a manual restore, not just a detour.

### 1.3 What the report missed — found in the code

- **The fake is more expressive than the real service.** `Chores.waiting`
  is asserted at `2` in two scenarios, but `LiveChores` maps
  `client.status()` to `0` or `1` and can never answer `2`. The scenarios
  pass against behavior the live service cannot produce. This is a
  method-level hazard, not a flood bug: nothing in the agreement says a fake
  may only show states its live service can reach (§6, W1).
- **A refused write silently reads as saved.** `Refused(_)` maps to
  `waiting: 0`. `BEFORE-BETA.md` already flags this for the scaffold; flood
  reproduced it independently, which confirms the scaffold teaches it.
- **`ready` checks only tasks.** `Flood.Member.all` is never awaited, so the
  chip row can render empty while the list claims ready.
- **The unsubscribe handle is discarded** — `let _ = client.receives(...)`.
  Harmless in a page that never unmounts, and copied from the scaffold, so
  every app will do it.
- **`pnpm test` may kill `pnpm dev`.** The template's `pretest` runs
  `rescript` — the same by-hand build the report shows killing the watcher.
  The method's core loop (run the scenarios while dev serves) collides with
  itself. Needs verification, then a fix either way (§4, E4).
- **The domain touches `lapa` in flood exactly as the report's §5.7 says**,
  and the agreement's "tilia is the one exception" sentence is wrong as
  written. The amendment the report proposes is right (§6, W2).

The report itself is the strongest artifact of the session. §7 turns that
into a workflow action (§6, W4).

---

## 2. Creation joins the class module (sylva) — the decision

The generated file gains a constructor per class. In flood's vocabulary:

```rescript
let task = Flood.Task.make(
  ~title="Dishes",
  ~task={done: false, assignee: Nullable.null, due: Nullable.null},
  ~hangs=[(personal, Lapa.Access.admin)],
)
client.ops.create(~actor, [task], reply)
```

No `~entity`: the entity core is minted, and the title is the call's, exactly
as `Operations.create` already works. The arguments mirror the row:

- `~title: string` — required, because `Titled` is.
- The class's own part, by its row name — `~task: part`. Required when the
  row holds it non-null, optional (`~member: part=?`) when the row holds it
  `Nullable`, so required-ness falls out of the model the same way the record
  types do.
- One optional argument per carriable facet: `~dated: Lapa.Root.Dated.t=?`,
  `~described=?`, `~owned=?`, and the app's own facets.
- `~hangs=?` and `~holds=?` pass through. The place decision stays explicit
  and stays out of the generator.

A required field cannot be omitted — it is a non-null record field. A wrong
kind cannot compile. The `for`-keyword and naming rules are already the
generator's. This removes the only place in an app where nothing type-checks
the write.

**Rejected: flat labeled arguments per field**
(`Task.make(~title, ~done, ~assignee=?, ~due=?)`). Reads better at the call
site, but field names collide across parts (`task.done` and another part's
`done` are legal together), the generator would need a new refusal family,
and creating and editing would speak different shapes. With part records,
what you create is what you read back. Cost of the chosen shape: an absent
optional field is spelled `Nullable.null` in the literal, because a part
record names every field.

### Implementation notes

1. **`creation` and `self` move to `lapa`.** They are pure vocabulary — a
   class id, a title, parts, hangs, holds. Nothing runs the db yet, so they
   move outright and the call sites follow; no alias. This respects "lapa
   depends on nothing" and lets the generated file stay written against
   `Lapa` alone.
2. **`Lapa` gains the part encoder.** The taught model already maps
   `"task.done"` to its id and kind, and `pack` already encodes root facets.
   A `Lapa.part: (string, 'a) => parted` (abstract result, name resolved
   through the taught tables, `Nullable.null` fields left out) is all the
   generated `make` needs. The unchecked `'a` is the same trust the
   `%identity` widening already carries: the generated signature constrains
   every caller.
3. **The generator emits `make`** beside `class`, `all`, `from`, `record`.
   `make` joins the `reserved` list so a field cannot shadow it.
4. **Scenarios first**: extend `Types.feature`/`Merge.feature` territory with
   a creating scenario over `TypesHelper`, and `Typing.feature`'s golden file
   `packages/server/src/design/entity/Adventures.res` — then copy it over
   `packages/tilia/src/design/entity/Adventures.res` as `CODEMAP.md` requires.
5. **Follow-up, separate session:** `LapaTilia` could gain
   `create: Lapa.creation => unit` that fills the actor and answers through
   the engine, so an app never touches `client.ops` for the ordinary case.
   Decide after the constructor lands; `upsert`'s `Refused` story applies.
6. **Follow-up, separate decision:** the client could expose the session's
   Personal node, so apps stop hand-seeking it (flood's `place(client)` is
   23 lines every app will rewrite). The server knows it at admission.

---

## 3. Other actions in sylva

Ranked. Each is one session or less unless marked.

- **A1 — Self-heal the stale browser store.** On boot, the client writes a
  founding mark (the store's app id) into its kv. When the mark and the
  server disagree, forget the local database and pull fresh instead of
  merging. An offline edit against a re-founded store is meaningless, so
  nothing of value is lost. This fixes the report's §2.2 at the root;
  the template rename (E2) only narrows it. Ties into `BEFORE-BETA.md`'s
  "a scenario over `IndexedDbKv`".
- **A2 — Name the actionable cure in the error path.** Until A1 lands,
  `invalidAncestors` reaching a client boot should say what to do:
  "the browser holds definitions from another store — clear this site's
  data." Cheap, and worth keeping even after A1 as the last-resort message.
- **A3 — Write the header id as base64.** `Typing.res` `header` uses
  `escaped(app)`; use `btoa(app)` like every id in the teaching call. No
  standing files to keep owning: `wrote` checks the one spelling. The line
  that decides file ownership becomes legible.
- **A4 — Ship `Lapa.spell` and `Lapa.parse`.** The base64 pass the desk
  already uses, as public API. One paragraph in `packages/lapa/llms.txt`:
  an id is raw bytes; never put one in the DOM, a URL, JSON, or a React
  `key`; spell it first. Rejected on merits, not on compatibility: making
  `Lapa.id` abstract — an id is a dict key throughout the API, and dict
  keys are strings.
- **A5 — One kind vocabulary everywhere: `text`, `number`, `time`, `bool`,
  `access`, `relation`, `relations`.** Nothing runs the db, so rename
  outright, no dual read and no mapping table. The desk's `define` schema
  and `scalars` say the new words; `kindOf` reads only them; dev stores are
  re-founded. Go the whole way while renaming is free: `Lapa.Value` and
  `Value.kind` constructors become `Text`, `Relation`, `Relations` too, so
  the desk, the stored field, the handle and the value constructor spell
  one concept one way. `String`/`Ref`/`Refs` disappear.
- **A6 — Say where instances hang.** One sentence in the desk `make` tool
  description: an app's own create usually hangs under Personal, so rows
  made here live in a different part of the graph than rows the app makes.
- **A7 — Answer `indexed` at define time.** In the `define` tool's field
  schema and in `packages/lapa/llms.txt`: the client holds every row it
  reaches, so an app filters in memory until it does not fit; `indexed` is
  for seeks, and a seek is for what the client should not hold; the honest
  default is to index nothing. Say plainly that the flag cannot change later
  (`changedIndexed`), and open a `docs/NEXT.md` line for making it
  changeable, which is a reindex sweep and its own session.
- **A8 — A worked `loadable` switch.** In `packages/tilia/llms.txt`: one
  `switch` over every state with the recommended treatment of each, and one
  sentence each on `tick` ("lapa answers the store's half with nothing, so
  an app over lapa never calls it" — if that is true; verify) and `dispose`
  (when it matters). The staleness model is documented but not usable from
  the reference alone.
- **A9 — Document the nullable-part rule.** Where the generator is
  described (`packages/server/llms.txt`, type-generation block): a class
  whose fields are all optional has a `Nullable` part, so marking any one
  field required changes how every other field on the class is read.

---

## 4. Actions in epuremethod.com

- **E1 — The cold desk, in two steps.**
  *Now:* a paragraph in `create/templates/AGENTS.md`: on a cold session the
  desk MCP is not connected, because the desk answers only while dev runs.
  Start dev, then ask the person to reconnect the MCP client. Until it is
  connected, the desk answers plain HTTP JSON-RPC — `.mcp.json` holds the
  url and the header. Bless the curl fallback the flood agent invented.
  *Later, design needed:* a desk that outlives `pnpm dev` — `epure-dev`
  adopting an already-running `lapa dev` instead of always spawning one,
  with the `.data` lock as the guard. Costs a process that outlives the
  terminal and a stop story; decide only if cold sessions stay painful
  after the documentation lands.
- **E2 — Name the browser database after the project.** `{{name}}` instead
  of `"app"` in `create/templates/src/view/Page.res:67`, and improve the
  `Page.res` failure text: "if you re-founded `.data`, clear this site's
  data." Narrows §2.2 until sylva's A1 removes it.
- **E3 — Enforce the croquis boundary at build.** A small vite plugin in
  the template: `pnpm build` fails when a module under `src/croquis/` is
  reached from the entry. `pnpm dev` stays permissive — the blessed mount
  line works while sketching, and a forgotten one fails the build loudly
  instead of shipping silently. Then document the mount-line convention
  where a scaffolded project can see it (`templates/README.md`, "Two
  modes"), including that nobody repoints `index.html`. Today the
  convention lives only in `create/DECISIONS.md`.
- **E4 — Stop `pnpm test` and by-hand `rescript` from killing dev.**
  Verify the collision first: `pretest` runs `rescript` while the watcher
  holds the build. Then either have `pretest` skip the build when the
  watcher runs (the watcher keeps `lib/bs` current), or have `epure-dev`
  refuse a second compiler with one clear sentence instead of dying on a
  Rust panic. Say it in `dev/llms.txt` and `templates/AGENTS.md` either
  way: read `lib/bs/.compiler.log` to check compilation while dev runs.
- **E5 — Show the refused state in the scaffold.** `LiveNotes` collapses
  `Refused` into "not saving", and flood copied that faithfully. One member
  of `Notes.t` carries it, one line of `HelloView` shows it. The scaffold is
  the teacher; this is where the lesson lands. (Sylva's `BEFORE-BETA.md`
  already lists it; it is the template half of that item.)
- **E6 — The stale-template install.** Already filed as `EPURE_BUG.md`:
  `epure init` checks the registry's `latest` for `create-epure` and stops
  with the exact-version command when it is behind; print the scaffolded
  version either way. Keeping it here so the list is complete.

---

## 5. Actions in other repositories

**`@epure/vitest`** (separate repo; the template pins a beta tarball):

- **V1 — Document tables and placeholders exactly.** The step text includes
  the trailing colon; the table arrives as the step's single argument as
  `array<array<string>>`; `toRecords` field names must be valid ReScript
  record fields, so a column named `for` cannot work. Replace "such as
  `{string}` and `{number}`" with "only". Every `{number}` arrives as
  `float`.
- **V2 — Consider an optional-suffix form** (`task(s)`) — and say in the
  reference, until it exists, that singular and plural are two
  registrations. Note from flood: `"{number} task is loose"` vs
  `"{number} tasks are loose"` differ by the verb too, so a suffix matcher
  alone does not close the gap; weigh that before building it.
- **V3 — Nest `Todo`/`Skip`/`Only` under `Mode`** (or rename `Todo`).
  The package is itself a beta with the template as its consumer, so nest
  now rather than waiting for a major.

**tilia** (checkout beside this repo):

- **T1 — Answer "a derived value per row of a dynamic list".** The report's
  single open modelling question (§5.2), and a common shape. If tilia has an
  idiom, it belongs in `tilia/llms.txt` with a worked example; if not, that
  is a real gap worth an issue. The flood pattern — a `computed` returning a
  closure — works but repaints every row.

---

## 6. Method and workflow changes

- **W1 — A fake may only show states its live service can produce.** New
  sentence for the agreement (`docs/content/agreement.md`, promise 3
  territory): when a live service replaces a fake, every state a scenario
  asserts must be one the live service can reach. Flood's `waiting: 2`
  scenarios pass against a service that can only answer `0` or `1`, and
  nothing in the method catches it. This is the one finding that touches
  the method itself rather than its edges.
- **W2 — Fix the domain-exception sentence.** The agreement says "tilia is
  the one exception" while every generated entity file and the seam types
  name `Lapa.id`. Amend to the report's wording: tilia and lapa are the
  exceptions — one is the state manager, the other is the vocabulary.
- **W3 — Say who restores what at a croquis close.** The agreement says
  "at a build session's close, `src/croquis/` is empty"; add the other
  half: the mount line the croquis added is removed by the same close, and
  E3's build check is what verifies it.
- **W4 — Keep the report ritual.** The report was worth more than the app.
  One line in the template's `AGENTS.md`: on a first session with a new
  stack, or when asked, close by writing what confused, what was guessed,
  and what was never exercised, as `EPURE-REPORT-<date>.md`. The "what I
  did not exercise" section (§6 of the report) is the part to insist on —
  it is what kept the report honest.
- **W5 — Decide what `CONVENTIONS.md` is for.** Flood never filled its
  stub, and nothing prompted it to. Either the template's session order
  names the moment a convention is recorded, or the stub is dropped.

---

## 7. Map from the report's ranked recommendations

| Report | Action here |
|---|---|
| 1 desk on a cold session | E1 |
| 2 stale IndexedDB | A1, A2, E2 |
| 3 typed creation constructor | §2 (the decision) |
| 4 id hygiene, `spell`/`parse` | A4 |
| 5 kind vocabulary | A5 |
| 6 croquis boundary | E3, W3 |
| 7 table steps, placeholders | V1 |
| 8 `rescript` vs dev | E4 |
| 9 all-optional part is `Nullable` | A9 |
| 10 derived value per row | T1 |
| 11 worked `loadable` switch | A8 |
| 12 header id as base64 | A3 |
| 13 `Todo`/`Skip`/`Only` | V3 |
| 14 `indexed` at define time | A7 |

Beyond the report: W1 (fake expressiveness), E5 (refused reads as saved),
E4's `pretest` half, E6 (stale template), W4, W5, and §2's follow-ups (a
binding-level `create`, the client's Personal node).
