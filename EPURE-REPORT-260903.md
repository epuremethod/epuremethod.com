# épure + lapa — report from a first agent session

**Date:** 2026-09-03
**Project:** `flood`, scaffolded from the épure template, empty apart from the
scaffold.
**Task given:** "I want to build a family todo app."
**Worked in:** croquis, then build.
**Result:** a working app — `Member` and `Task` defined at the desk, one carve
of rules, 35 scenarios green, the scaffold deleted.

I was dropped into this project with no prior knowledge of épure, lapa or
tilia. Everything below is what actually happened, in order, including the
places I guessed and the two places I guessed wrong.

Sections 1 and 2 evaluate the method and the tooling. Section 3 records **how
I actually worked with lapa** — the order of the calls, and the findings that
only became visible from inside that loop. Section 4 reads **the generated
types** closely, since that file is the join between the desk and the app and
carries most of lapa's naming decisions. Section 5 does the same for tilia and
the query engine. Section 6 states what went untested, so the rest is not read
as broader than it is.

---

## 1. What works

### 1.1 `llms.txt` per package is the single best thing here

Ten packages ship one. `CONTRIBUTING.md` makes reading them a rule, and adds
the clause that does the real work:

> If something is not in the reference, it does not exist — an unknown is a
> question to ask, never an API to guess.

Each file then names its own authority: *"These files are authoritative. If
prose differs, follow the contracts."* That three-layer arrangement —
rule → summary → `.resi` — meant I could go from never having seen lapa to
writing a correct client binding without one API guess. `LiveChores.res`
compiled essentially first try.

This convention should be the headline of the whole project. It is more
valuable than any individual API decision in it.

### 1.2 The scaffold is a worked example, not a placeholder

`Hello.res`, `HelloSteps.res`, `Notes.res` and `LiveNotes.res` are a complete
vertical slice of every layer, each marked `THROWAWAY` with a note saying what
to delete it for. They taught the idioms by demonstration, and the comments
taught the *reasons*:

> `derived` reads the carve itself, `computed` reads only what it closes over.

> The one thing a hand-made `Notes.t` must get right is that `all`, `ready`
> and `waiting` answer reactively — a plain `ref` would leave every derived
> value stale after a write.

That second comment saved me from a real bug. I would have written a `ref`.

Building `LiveChores` from `LiveNotes` and `FamilySteps` from `HelloSteps` was
close to mechanical. Deleting the scaffold at the end felt like the intended
arc rather than cleanup.

### 1.3 Croquis mode earns its place

Croquis got a real app in front of the person in one pass — real rows, real
counts, real day standings — and their answer came back as *"the simple app
works, you can build."* That is one round trip to a settled scope. Writing
scenarios first for a want nobody had seen yet would have cost far more and
produced worse scenarios, because I did not yet know that "whose is it"
mattered more than "when is it due".

The two modes are the correct decomposition of a problem most methods get
wrong by pretending only one of them exists.

### 1.4 desk → `lapa types` → typed ReScript is genuinely excellent

One `define` call with two classes and six fields, and
`src/domain/api/entity/Flood.res` appeared with typed records, class handles
and field handles. No command run by hand, no codegen step to remember, no
schema file to keep in sync. `desk://roots` answered the one design question
I actually had (Record vs Through) in the length of a paragraph.

This is the strongest part of lapa's developer surface.

### 1.5 Scenarios as the design contract did the thing it claims

Writing `Family.feature` before any code forced five decisions into the open
that I would otherwise have silently baked into the implementation:

- the sort order, and that a title breaks a same-day tie
- that "soon" means inside seven days
- that done is hidden by default
- that the owed count ignores the hide-done filter
- that a task can be owed by nobody

The person could have vetoed any of the five before a line existed. That is
the method working exactly as advertised, and it is worth the ceremony.

### 1.6 The seam makes the domain testable with nothing

`Chores.t` is a record of closures. The steps build one over three
`Tilia.signal`s and three arrays. No mocking library, no DI container, no test
double framework, no browser, no server — 35 scenarios in 126 ms. The
architecture's promise ("a test hands a feature fakes instead of the world")
is not aspirational; it is just true.

### 1.7 Smaller things that are right

- **`conflicts` is a required argument** to `LapaTilia.make`, with the reason
  stated: *"a conflict is the one thing lapa's own surface does not say, so no
  view may open without a place for it to go."* Forcing the decision at the
  type level is correct.
- **`AGENTS.md` holds one instruction** — read `CONTRIBUTING.md`. It worked; I
  landed on the working agreement immediately.
- **Every file opens with a comment saying what layer it is and what it may
  not touch.** Navigating an unfamiliar codebase was nearly free.
- **`Access` refuses to expose its integers** ("the integers have holes and
  are not stable"). Good.

---

## 2. What is confusing, or broken

Ordered by how much damage each one does to a first session.

### 2.1 The desk cannot connect on a cold session — HIGH

The desk lives at `http://localhost:8080/_lapa/mcp` and **only answers while
`pnpm dev` runs**. `.mcp.json` names it. But an MCP client establishes its
connections at session start, and `AGENTS.md` instructs the agent to start dev
*after* the session has begun:

> At session start, check whether the app already runs. If it does not, run it
> with `pnpm dev`.

So on any cold start the ordering is guaranteed to fail:

```
session starts → MCP tries to connect to desk → nothing is listening → fails
             → agent reads AGENTS.md → starts dev → desk is now up
             → but the MCP client will not retry
```

I had no desk tools for the entire session. I drove it over `curl` instead,
reading the token straight out of `.mcp.json`, which worked fine — but it is a
hole that every first session falls into, and an agent that does not think to
build the curl fallback is simply stuck.

`@epure/dev/llms.txt` half-sees this — *"An agent holding a stale token must be
restarted so its MCP client re-reads the file"* — but that is about a *stale*
token, not about the server not existing yet.

**Fix, in order of preference:**
1. Let the desk outlive `pnpm dev` — `epure-dev prepare` already boots
   `lapa dev` once at install; leave a desk listening, or start one on demand.
2. Failing that, say plainly in `AGENTS.md`: *"the desk answers only while dev
   runs, so on a cold session it will not be connected. Start dev, then ask
   the person to reconnect it, or reach it over HTTP —* `.mcp.json` *has the
   url and the header."*

### 2.2 A stale browser IndexedDB breaks boot with an unactionable error — HIGH

The first thing I saw, before writing any code:

```
Error: ..Meta.......... does not include all ancestors of its super
```

thrown inside `Client.make`, caught by `Page.res`, shown to the person as
*"this app could not open — the console says why"*.

The server's definitions were fine. I checked `Meta`, `Node` and `Entity` at
the desk and all three satisfy the rule the error names. The cause is that the
browser's IndexedDB — hardcoded to the name `"app"` — held definitions from a
**previous `.data` store**, and merging those with the current ones produces
an inconsistency. A fresh Chrome profile booted perfectly.

Three things are wrong here:

- **The error names an internal root class.** `..Meta..........` is a dotted
  sixteen-byte id. Nothing tells the reader this is about their browser cache.
- **The cure is undiscoverable.** Nothing in the message, in `Page.res`, or in
  the épure docs says "clear site data". `@epure/dev/llms.txt` covers the
  agent's stale token but never the browser's stale store.
- **It is self-inflicted and self-healable.** The client knows the store it is
  talking to; it could refuse to merge across a re-founding.

**Fix:** name the IndexedDB after the store's founding key or the session, so
a re-founded `.data` gets a fresh browser database automatically. Failing
that, detect the ancestor mismatch at boot and wipe the local kv rather than
throwing. Failing *that*, at minimum make `Page.res` say *"this app could not
open — if you re-founded `.data`, clear this site's data."*

### 2.3 Running `rescript` by hand silently kills the dev server — MEDIUM

I ran `npx rescript build` to check for compile errors while `pnpm dev` was
running. The watcher died with a Rust panic (`exit code 101`) and, because
*"one child dying takes dev down"*, took the whole dev server with it —
vite, the store, and the desk. I did not notice until a background task
notification arrived several steps later.

Checking whether the code compiles is about the most ordinary thing an agent
does. That it destroys the environment, in the background, with a Rust
backtrace, is a bad failure mode.

**Fix:** say it explicitly in `@epure/dev/llms.txt` and `AGENTS.md` — *"never
run `rescript` while dev runs; the watcher holds the lock. Read
`lib/bs/.compiler.log` instead."* Better: have `epure-dev` detect a second
`rescript` and refuse it with that sentence rather than panicking.

### 2.4 `type: "dev"` does not enforce "nothing ships depending on it" — MEDIUM

`CONTRIBUTING.md` says of `croquis/`:

> It may use every layer below it, **nothing ships depending on it**, and git
> ignores everything in it except its `.gitkeep`.

I assumed `rescript.json`'s `"type": "dev"` enforced this, and built the
croquis its own entry point (`src/croquis/Sketch.res`) with `index.html`
repointed at it, specifically to avoid making `Page.res` depend on a sketch.

**That workaround was unnecessary, and I only found out by testing it at the
end of the session.** A shipping module may import a croquis module freely:

```
src/view/ProbeShip.res      →  let borrowed = ProbeDev.hello
src/croquis/ProbeDev.res    →  let hello = "from a dev source"
```

This compiles under `pnpm dev`, compiles under `pnpm build`, and — once the
import is reachable from the entry rather than dead code — the string lands in
the production bundle. Verified:

```
$ grep -o "from a dev source" dist/assets/*.js
from a dev source
```

So the third promise of the croquis is a convention the tooling does not
check. A sketch pointed at from `Page.res` will ship, silently, and git will
not even show you the file that did it, because `src/croquis/*` is ignored.
That combination — unenforced *and* invisible to review — is the worrying
part.

**Fix:** either enforce it (a build step that fails when a non-dev source
imports `src/croquis/`), or drop the claim from `CONTRIBUTING.md` and say
instead: *"nothing that ships should depend on it, and nothing checks that for
you."* The current wording reads as a guarantee.

Two related gaps, both of which cost me time:

- Nothing documents **how a croquis is meant to be seen at all.** The sketch
  needs an entry point; `index.html` names `src/view/Page.res.mjs`. Neither
  `CONTRIBUTING.md` nor `README.md` says whether to repoint `index.html`, edit
  `Page.res`, or something else. Ship a `src/croquis/Sketch.res` placeholder
  in the template and say which.
- `AGENTS.md` says *"at a build session's close, `src/croquis/` is empty"* but
  nothing says who restores `index.html`.

### 2.5 One class has two different, unequally-typed write paths — MEDIUM

To **edit** a task, I mutate the generated record and hand it over:

```rescript
row.task.done = done
db.upsert(Flood.Task.record(row))
```

Fully typed. To **create** one, I build an untyped dictionary:

```rescript
let part = Dict.make()
part->Dict.set(Lapa.fieldId(Flood.Task.done), Lapa.Value.Bool(false))
assignee->Option.forEach(id =>
  part->Dict.set(Lapa.fieldId(Flood.Task.assignee), Lapa.Value.Ref(id)))

client.ops.create(~actor, [{
  OperationsType.class: Lapa.classId(Flood.Task.class),
  title, parts: [(Lapa.classId(Flood.Task.class), part)],
  hangs: [(personal, Lapa.Access.admin)],
}], reply)
```

Nothing checks that `Task.done` is a `bool`, that `done` is required and must
be present, or that `assignee` must be a `Ref` to a `Member`. A wrong
`Lapa.Value` constructor compiles and is refused at runtime by the server.
This is the sharpest edge in the whole API, and it sits on the one operation a
new app must get right immediately.

The reason is understandable — creation composes offline, and the composer
cannot know the id the mint has not handed out yet (`OperationsType.self`
exists for exactly this). But the generator already knows the class, the field
ids and their kinds.

**Fix:** have `lapa types` emit a constructor per class:

```rescript
Flood.Task.creation(~title, ~done=false, ~assignee?, ~hangs=[(personal, admin)])
```

returning an `OperationsType.creation`. Required fields become required
arguments; kinds are checked. This would remove the only place in the app
where I had to hand-marshal values.

### 2.6 `Lapa.id` is sixteen raw bytes, and nothing warns the app author — MEDIUM

`lapa/llms.txt` explains this well from the store's side:

> Sixteen bytes, and the width is load-bearing... Held as a string because
> ReScript strings are byte sequences and the store speaks bytes.

What it never says is the consequence for anyone writing a **view**: an id may
contain a NUL and must never go into a DOM attribute, a URL, a query string,
`JSON.stringify`, or anything else that round-trips through a text channel.

My first instinct was the obvious one — `<option value={member.id}>` — which
would have been a latent, hard-to-reproduce bug. I avoided it by reasoning
about the byte-string claim, not because anything told me to. Both member
pickers now speak positions in the `members` array and convert back to ids in
the handler, which works but couples the picker to array order.

The desk already knows this matters: *"Every id crosses the desk as base64."*
The client surface does not extend the courtesy.

**Fix:** one sentence in `lapa/llms.txt` — *"an id is raw bytes: never put one
in the DOM, a URL or JSON. Spell it first."* Better: ship `Lapa.spell` /
`Lapa.parse` (the base64 the desk already uses) as public API so views have a
sanctioned way to do this.

### 2.7 Data tables and step placeholders are underdocumented — MEDIUM

`@epure/vitest/llms.txt` mentions `toRecords`, `toStrings` and `toNumbers`
convert Gherkin tables, and the `.resi` types `toRecords` as
`array<array<string>> => array<'a>`. Nothing anywhere says:

- what a table step's **text** must be (does it include the trailing colon?)
- how the table **reaches** the step function, or in which argument position
- that a table step therefore takes exactly one argument when it has no
  placeholder captures

I guessed `step("the tasks:", (table: array<array<string>>) => ...)` and it
worked. But guessing is precisely what the working agreement forbids, and here
the reference could not answer the question.

Two traps worth documenting alongside it:

- **A column named `for` cannot work.** `toRecords` produces a record, and
  `for` is a ReScript keyword. My table originally used `| task | for | done |
  due |`; I renamed the column to `whose`. Anyone modelling assignment will hit
  this immediately.
- **Only `{string}` and `{number}` exist.** The prose hedges — *"placeholders
  such as `{string}` and `{number}`"* — and "such as" implies more. There are
  not; the plugin's own bundle contains exactly those two. Say "only".
  Consequences: every count arrives as `float` and needs `->Float.toInt`, and
  there is no `{int}` or `{word}`.

### 2.8 Singular and plural step text need separate registrations — LOW

`"Juno" owes 1 task` and `"Ada" owes 2 tasks` are different patterns, so I
registered both with identical bodies. Readable Gherkin and DRY steps are in
direct tension. An optional-suffix form (`owes {number} task(s)`) would fix
it; Cucumber has one.

### 2.9 `EpureVitest` exports a module named `Todo` — LOW

ReScript's module namespace is flat, and a steps file opens `EpureVitest`. My
feature was naturally called `Todo` — in a *todo app* — and `Todo.t` inside
the steps would have resolved to `EpureVitest.Todo` (the `describe.todo`
bindings). I renamed the feature to `Family` before writing code, but only
because I had read the whole `.resi` first.

**Fix:** nest the mode modules — `EpureVitest.Mode.Todo`, `Mode.Skip`,
`Mode.Only` — or rename to `Pending`. `Todo`, `Skip` and `Only` are all words
a domain might want.

### 2.10 desk `make` and app `create` hang instances in different places — LOW

`make` hangs a test instance under **the workspace**; `client.ops.create`
(following the scaffold) hangs under **Personal**. Both are reachable, so the
app sees both and nothing breaks. But rows that look identical in the UI live
in different parts of the graph, which makes `look {under: id}` misleading and
would matter the moment anything is scoped by walking. Worth one sentence in
the `make` description.

---

### 2.11 `indexed` must be decided before you can know if you need it — LOW

`define` asks for `indexed` per field, at the moment the class is born. I
marked `Task.done`, `Task.assignee` and `Task.due` as indexed because it
sounded prudent, and then **never issued a single field seek.** `Lapa.equals`,
`above`, `below`, `between` and `contains` all went unused. `Family.res`
filters and sorts the whole array in memory, because the client already holds
everything the session reaches.

For an app this size that is the right implementation and the wrong schema. I
only noticed after the fact.

What is missing is a sentence, in `lapa/llms.txt` or in the `define` tool's
description, saying which side of the line an app is on: *the client holds
every row it reaches, so an app filters in memory until it does not fit;
`indexed` is for seeks, and a seek is for what the client should not hold.*
Without it, "should this be indexed?" has no answerable form at define time,
and the honest default — index nothing until a seek needs it — never occurs
to you, because `indexed` reads like a performance hint rather than a
statement about reach.

Related: `Field.indexed` **cannot be changed later** — `Store.res` refuses it
with `changedIndexed`. So the guess is permanent, which raises the cost of not
documenting how to make it.

---

## 3. How I worked with lapa: the actual loop

Recorded because the sequence mattered more than any individual call, and
because two of the findings above only became visible from inside it.

### 3.1 Reading before touching anything

`CONTRIBUTING.md` makes this a rule, so the order was references first, code
second: `lapa/llms.txt`, then `@lapa/server/llms.txt` and `@epure/dev/llms.txt`
to understand the desk and the dev process, then `@lapa/db/llms.txt` and
`@lapa/tilia/llms.txt` at the point of writing against them. Where the prose
ran out I dropped to the file each one names as authoritative — `Lapa.resi`
for `Value.t`, the class and field handles and `classId`/`fieldId`;
`LapaTilia.resi` for the view type; `OperationsType.res` for the `creation`
record.

Roughly seven hundred lines of reading before the first line of code, and it
paid: **no guessed lapa API in the whole session.** The one place I had to
guess anything was `@epure/vitest`'s table steps (§2.7), where the reference
could not answer.

### 3.2 Driving the desk over HTTP

Since MCP never attached (§2.1), the desk was reached with a four-line shell
helper that reads the token out of `.mcp.json` and posts JSON-RPC 2.0:

```
POST http://localhost:8080/_lapa/mcp
Authorization: <session from .mcp.json>
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{...}}
```

This worked for every tool and for `resources/read`. Worth documenting as the
sanctioned fallback — it needs nothing but curl, and the file that makes it
possible is already written on every serve.

The order of calls was:

1. `resources/read desk://roots` — the one design question I had was Record vs
   Through, and this answered it in a paragraph.
2. `look {pull: 0}` — because the `define` tool's own description says *"read
   the definitions before you define"*.
3. `define` — two classes, six fields, one push.
4. `make` × 11 — three members and eight tasks, so the croquis had something
   real to draw.

### 3.3 Reading the definitions first changed the model

This is the strongest argument for step 2 above, and it is worth making
concrete. `look {pull: 0}` showed that `Titled`, `Described`, `Dated` and
`Owned` already exist as root facets. So `Member` and `Task` both take
`requires: ["Titled"]` and **neither defines a name of its own** — the title
*is* the person's name and *is* what the job is.

Left to guess I would have written `Member.name` and `Task.what`, duplicating
a root facet and producing two places where a name could live. Nothing but
reading the store first prevents that, which is exactly why the tool
description says to.

### 3.4 The two modelling decisions worth recording

**`Task.assignee` is a `ref` field, not a `Through`.** Through is *"one edge,
one payload… a fact about that pair"* that can never happen twice between the
same two nodes. An assignment changes constantly — a task moves from Malik to
Juno and back — so it is a mutable field on the task, not an edge payload.
`desk://roots` made this decidable in one read; it is the kind of choice that
is very expensive to get wrong, since a class never moves after birth.

**Both classes descend from `Record` and hang under `Personal`.** Record
because there are many of them and they have a place in the tree; Personal
because that is where the scaffold hangs its rows and this session has one
person. The rejected `Family` node is recorded in `DECISIONS.md`.

### 3.5 What the generator gave back

*(read closely in §4; what follows is only what it looked like in the flow.)*

`lapa dev --types` had already rewritten `src/domain/api/entity/Flood.res` by
the time I looked — `Lapa.app([...])` teaching the model at boot, plus a
module per class with a typed record, `class`, `all`, `from`, a field handle
per field, and the `record` widening. I never edited it.

One detail worth praising: **nullability falls straight out of required-ness.**
`Member`'s part is generated as `Nullable.t<part>` because every field on it is
optional, while `Task`'s `task` part is non-null because `done` is required.
The schema decision shows up in the ReScript type without anyone restating it.

### 3.6 The binding has three distinct jobs

`LiveChores.res` is the only file that knows both halves, and it splits
cleanly:

- **Reading** — `db.array(Flood.Task.all)`, match `Loaded({data})`, map down
  to the plain `Chores.task` the domain speaks. The domain never sees a
  generated record.
- **Editing** — mutate the watched row, then hand it over:
  `row.task.done = done; db.upsert(Flood.Task.record(row))`.
- **Creating** — an entirely different shape: `client.ops.create` with a
  hand-built `dict<Lapa.Value.t>` keyed by `Lapa.fieldId`. This is the part
  that required reading `OperationsType.res` and `Lapa.resi` line by line, and
  the only place nothing type-checked me (§2.5).

Plus two pieces of plumbing taken from the scaffold, both of which I would not
have known to write: `place(client)`, which seeks
`Root.Entity.class Is Ref(Root.personal)` to find where a new task hangs; and
reading `client.status()` into a `Tilia.signal`, because it answers a plain
value and nothing on it fires when a push lands.

### 3.7 `look` was also the debugger

The one unplanned use. When the client threw `..Meta.......... does not
include all ancestors of its super`, `look {pull: 0}` let me hand-check the
invariant the error names — `Meta`'s super is `Node`, `Node`'s ancestors are
`[Entity]`, so `Meta`'s must be `[Entity, Node]`, and they were. That is how I
concluded the server was consistent and the browser was stale (§2.2), rather
than guessing.

A desk that can answer "is the store actually self-consistent?" is worth more
than it probably looks, and it is not advertised as a diagnostic.

### 3.8 The half of lapa I never touched

Everything above is the write path and the read-everything path. I never used
a **seek**. `Lapa.equals`, `above`, `below`, `between` and `contains` went
entirely unexercised, because the client holds every row the session reaches
and the domain filters in memory.

That is correct for a family's worth of tasks and wrong as a schema (§2.11),
and I did not notice the tension until writing this report — which is itself
the finding: nothing in the flow prompts you to ask whether you are building
for reach or for scale, at the one moment the answer is permanent.

---

## 4. The generated types

`lapa dev --types` rewrote `src/domain/api/entity/Flood.res` after every
`define`, with no command run by hand. I never edited it. This is
simultaneously the strongest part of lapa's developer surface (§1.4) and the
place where three separate naming vocabularies meet without a map.

### 4.1 What it produces

For two classes and six fields, one file: a teaching call, then a module per
class.

```rescript
Lapa.app([
  ("AaBoqKfGcXqpw3GJSuqDYg==", "member", [(..., "colour", "text")], [...]),
  ("AaBoqKfGcRa+VckOGxCGPQ==", "task",   [(..., "assignee", "relation"),
                                          (..., "done", "bool"),
                                          (..., "due", "time")], [...]),
])

module Task = {
  type part = {
    mutable assignee: Nullable.t<Lapa.id>,
    mutable done: bool,
    mutable due: Nullable.t<float>,
  }
  type t = {
    entity: Lapa.Root.Entity.t,
    mutable task: part,
    mutable titled: Lapa.Root.Titled.t,
    mutable dated: Nullable.t<Lapa.Root.Dated.t>,
    mutable described: Nullable.t<Lapa.Root.Described.t>,
    mutable owned: Nullable.t<Lapa.Root.Owned.t>,
    _rest: Lapa.rest,
  }
  let class: Lapa.class<t> = Lapa.class("task.class")
  let assignee = Lapa.relation("task.assignee")
  let done = Lapa.bool("task.done")
  let due = Lapa.time("task.due")
  let all = Lapa.all(class)
  let from = Lapa.from(class)
  external record: t => Lapa.record = "%identity"
}
```

Worth noting that `Lapa.app([...])` is a **top-level side effect**: the model
is taught when the module is imported, so it is taught only if something
imports the generated file. In this app `LiveChores.res` references
`Flood.Task.all`, so it happens. Nothing says what the failure looks like in
an app where it does not, and the failure would be at runtime.

### 4.2 Nullability is derived from the model, and that is excellent

The single best property of the output. Every distinction in the schema shows
up in the ReScript type without anyone restating it:

| in the model | in the generated type |
|---|---|
| `requires: ["Titled"]` | `titled: Lapa.Root.Titled.t` — non-null |
| root facets not required | `dated`, `described`, `owned` — `Nullable.t<…>` |
| `done` required | `done: bool` — non-null |
| `assignee`, `due` optional | `Nullable.t<…>` |

`Guard`/`Nullable` discipline is stated once in `lapa/llms.txt` — *"what may
be absent is `Nullable`, never `option`"* — and the generator holds to it
exactly.

### 4.3 …but "every field optional" makes the whole part nullable, silently

The one place that derivation surprised me. Compare:

```rescript
mutable member: Nullable.t<part>,   // Member — every field on it is optional
mutable task: part,                 // Task   — `done` is required
```

Because `colour` is `Member`'s only field and it is optional, the **entire
part** becomes nullable, and reading a colour is a double unwrap:

```rescript
colour: switch row.member->Nullable.toOption {
| Some(part) => part.colour->Nullable.toOption->Option.getOr(plain)
| None => plain
}
```

against `Task`'s flat `row.task.done`.

This is correct — a part with no required field genuinely need not be present
— but the coupling is invisible. **Marking any one field on a class required
changes how every other field on that class is read.** A schema decision about
field A silently determines the ergonomics of field B. I would not have
predicted it, and nothing documents it.

**Fix:** say it in the generator's own reference, or generate a reader per
field (`Task.colourOf(row)`) so the part's nullability stops leaking into
every call site.

### 4.4 Three vocabularies for one set of kinds

The sharpest finding in this section, and I crossed all three in one session
without anything telling me they were the same thing.

| the concept | desk `define` | generated file / `Lapa` handles | `Lapa.Value.t` |
|---|---|---|---|
| text | `string` | `text` | `String` |
| a number | `number` | `number` | `Number` |
| a moment | `time` | `time` | `Time` |
| yes/no | `bool` | `bool` | `Bool` |
| a level | `access` | `access` | `Access` |
| **one reference** | **`ref`** | **`relation`** | **`Ref`** |
| **several references** | **`refs`** | **`relations`** | **`Refs`** |

So in one afternoon I wrote `"kind": "ref"` at the desk, got back
`Lapa.relation("task.assignee")` in the generated file, and then had to write
`Lapa.Value.Ref(id)` to create a row. Three names, one concept, no mapping
table anywhere.

`string` → `text` is the same problem in milder form.

**Fix:** either align the desk's `define` to lapa's own names (`text`,
`relation`, `relations`), or put this table in `lapa/llms.txt`. The former is
better — the desk is the newer surface and the one with a schema string that
could simply be changed.

### 4.5 The same name means two different things in one file

`Flood.Task.done` and `row.task.done` are both spelled `done`, in the same
generated module, and they are not the same kind of thing:

- `Task.done` is a `field<bool, direct>` **handle** — what `Lapa.fieldId` and
  the seeks take.
- `row.task.done` is the **value** on a decoded record.

`LiveChores.res` uses both, six lines apart:

```rescript
part->Dict.set(Lapa.fieldId(Flood.Task.done), Lapa.Value.Bool(false))  // handle
row.task.done = done                                                    // value
```

`Lapa.resi` does explain the design — *"a handle names the path the record
holds — `todo.done` — and never the module, whose name is a different function
of the title"* — but it explains it from the library's side, not from the
point of view of someone reading a generated file for the first time. The
collision is deliberate and defensible; it is also real conceptual load that
nothing warns you about.

### 4.6 The header spells the app id in a way nothing else does

```
// lapa types — flood — \x01\xa0h\xa1\"Y}\xc9\x99\x11\xd2\xa4\xe8^\xf7\x0e
```

Those are the sixteen bytes the desk spells `AaBooSJZfcmZEdKk6F73Dg==`
everywhere else, escaped raw into a comment — unreadable, and containing an
escaped double quote for good measure.

This is not cosmetic. The header is **load-bearing for ownership**: *"the
generator owns the files carrying that header and nothing else."* So the line
that decides whether a file may be overwritten is the least legible line in
the file, and a human cannot match it against the id the desk just handed
them.

**Fix:** write the base64. The desk already established that spelling as the
one ids cross surfaces in.

### 4.7 What it does not generate

- **No constructor.** The gap behind §2.5 — the generator knows the class id,
  the field ids and their kinds, which is everything a typed
  `OperationsType.creation` needs, and emits none of it.
- **No `.resi`.** Everything is public, including the `%identity` widening,
  which is machinery rather than API.
- **No seek helpers beyond `all`.** `equals`/`above`/`below`/`between` must be
  assembled by hand from the field handles. Fine, but combined with §2.11 it
  means the indexed flags produce nothing visible in the generated output —
  there is no sign in `Flood.res` that `done` is indexed and `colour` is not.
- **Two name derivations from one title, undocumented at the edges.** A class
  title becomes both a part name (`"task"`) and a module name (`Task`) by
  *different* functions. What either does with a multi-word title —
  `Shopping list` — is not stated, and I did not test it.

### 4.8 Small things that are right

- **Fields are emitted alphabetically** (`assignee, done, due`), not in
  definition order. Deterministic output means clean diffs when the model
  changes.
- **`_rest` is abstract** and carries what the app's model does not name,
  written back whole by `pack`. Two apps over one store can coexist without
  either knowing the other's fields — a genuinely good decision.
- **`record` is `%identity`** — the widening costs nothing at runtime.
- **Rewritten after every definition change**, with no command to remember and
  no drift possible.
- **"Nobody edits the generated files"** is stated plainly in three separate
  references, and the header makes the claim checkable.

---

## 5. Technical note: how I used tilia, `@tilia/query` and `@lapa/tilia`

Requested, and worth writing down because my usage was uneven — some of it
confident, some of it cargo-culted from the scaffold, and one part of the
stack I never touched at all.

### 5.1 `carve` — used for both features, confidently

`Family` and `App` are both `carve`. The mental model I formed, and which held
up: **the record literal you pass to `carve` is the state, and `derived` /
`computed` are markers that turn individual fields into reactive derivations
of the rest.** No store, no reducer, no selector — the shape of the object is
the shape of the feature.

The distinction I worked from is the scaffold's comment, which is the clearest
statement of it anywhere in the docs:

> `derived` reads the carve itself, `computed` reads only what it closes over.

So I used:

- **`derived`** for anything reading `self` — `shown` and `owed` (they read
  `self.whose` and `self.hidesDone`), `chooses`, and `adds` (reads
  `self.entry`, writes it back).
- **`computed`** for anything reading only the injected `chores` — `members`,
  `loose`, `ready`.
- **plain fields** for actions that read neither — `ticks`, `assigns`,
  `stands`.

That last category is a judgement call I am **not confident about**. `ticks:
task => chores.ticks(task, !task.done)` is a plain function on the carve
rather than a `derived` one, because it needs nothing from `self`. It works.
Whether it is idiomatic, or whether everything callable should be `derived`
for consistency, I could not determine from the docs.

### 5.2 A pattern I invented, and my main open question about tilia

Three fields are **`computed` values that are themselves functions**:

```rescript
named: computed(() => {
  let members = chores.members()
  id => members->Array.find(one => one.id == id)->Option.mapOr("someone", one => one.name)
}),
owedBy: computed(() => {
  let tasks = chores.tasks()
  id => tasks->Array.filter(task => !task.done && task.assignee == Some(id))->Array.length
}),
```

The intent: the closure is rebuilt when `members` or `tasks` change, so a view
calling `family.owedBy(id)` repaints correctly. It works.

**But it is coarse, and I think it is wrong.** `owedBy` is one reactive node
for the whole family, so ticking *any* task rebuilds it and repaints *every*
member chip — exactly the fine-grained-tracking property tilia sells. The
right shape is presumably one `computed` per member, but a carve is a record
literal with fixed fields and the member list is dynamic. I found no
documented way to build a keyed collection of derivations, and
`tilia/llms.txt` (128 lines) does not cover it.

**This is the single thing I would most want answered**, and I suspect it is a
common shape: *"a derived value per row of a list whose length comes from
data."* If tilia has an answer, it belongs in `llms.txt`; if it does not, that
is worth knowing too.

### 5.3 `@tilia/query` — I barely used it, and did not read it

Honest accounting: **I never opened `@tilia/query/llms.txt`** (182 lines, the
longest reference in the tree). I used the engine only through what
`@lapa/tilia` exposes, and only one call:

```rescript
switch db.array(Flood.Task.all) {
| Loaded({data}) => data
| _ => []
}
```

So of the documented surface I used `array` and nothing else. I never used
`one`. I never called `tick()`. I never called `dispose()`. I never passed
`expiry`.

Two of those are gaps I cannot resolve from the references:

- **`tick()` is described as "the engine's heartbeat: refresh, aging,
  eviction"** — but nothing says *who drives it*. The scaffold never calls it.
  Neither does my app. Is something else driving it? Is it optional for lapa
  because *"lapa needs none of it and answers the store's half with nothing"*?
  That sentence exists but stops short of "so you never need to call it",
  which is what a reader needs.
- **`dispose()` is never called anywhere.** `LapaTilia.make` is called once at
  boot in a page that never unmounts, so it did not matter here. But no
  example shows the lifecycle, and *"the engine closes with the last view
  open"* implies it matters in an app that opens more than one.

### 5.4 The staleness model, which my app entirely ignores

`@lapa/tilia/llms.txt` describes a genuinely thoughtful model: a query claims
`live` while the client is in step; a socket drop ages the claim to `Local` at
the refresh interval and holds the refresh so *"the data stays on screen at
`Local`"*; a query first asked out of step answers `fresh` from the store.

**My app throws all of it away.** I collapse every non-`Loaded` state to `[]`
and expose a single `ready: bool`. A family app on phones around a house is
exactly the case that model was designed for — someone in the garden goes
offline, ticks a job, comes back — and I built none of it, because the
scaffold does not, and because the constructor names for the other states are
not in `llms.txt` (they are presumably in `TiliaQuery.loadable`, which I would
have had to go read).

**Suggestion:** the reference explains the model well but gives no code. One
worked `switch` over every `loadable` state, with the recommended UI treatment
of each, would move this from "documented" to "usable".

### 5.5 `@lapa/tilia` — the mutate-then-`upsert` pattern

```rescript
row.task.done = done
db.upsert(Flood.Task.record(row))
```

You mutate the object the engine is watching, then tell the engine. Coming
from immutable-state habits this read as wrong, and I would not have trusted
it without this line:

> A row is one object: what a query lists is the object the app is watching,
> and an arrival is folded into it.

That sentence is load-bearing and well placed. The `Flood.Task.record(row)`
widening (`external record: t => Lapa.record = "%identity"`) is also cleanly
explained by *"the app widens through its generated file"*.

`conflicts` being a **required** argument, with the reason given, is the best
API decision I met in lapa. My handler is nonetheless a stub — I copied the
scaffold's `Console.error2` — which means the app has a place for conflicts to
go and no behaviour when one arrives. That is a real limitation of what I
built, not of the library.

### 5.6 `@tilia/react` — `leaf` worked exactly as advertised

Every component is wrapped in `leaf`. No dependency arrays, no selectors, no
`memo`, no re-render debugging. The guidance to *"read the feature from a
React context and the fields where they are used"* is concrete and I followed
it: `AppView.useApp().family`, then read fields down in the JSX.

One thing I did not do and probably should have: **`useComputed`**. The docs
recommend it *"for a conclusion (`selected`, `due`) instead of the values
behind it"*, which is precisely what `family.stands(task)` is in every row. I
read the advice and did not apply it, because the scaffold has no example and
the payoff was not obvious at eight tasks.

### 5.7 Where the layering held, and the one place it strained

The diagonal architecture held cleanly. `Family.res` imports nothing but
`Tilia` and `Chores`. The one strain: **the domain touches `lapa`.**
`Chores.member` and `Chores.task` both carry `Lapa.id`, so
`src/domain/api/service/` depends on an external package. `CONTRIBUTING.md`
says *"nothing in `src/domain` touches an external library — tilia is the one
exception."*

In practice this is fine — `lapa` is a types-only package, the generated
entities live under `src/domain/api/entity/` by design, and the scaffold's own
`Notes.res` does the same thing. But the sentence as written has two
exceptions and admits one. Worth amending to *"tilia and lapa are the
exceptions: one is the state manager, the other is the vocabulary."*

---

## 6. What I did not exercise

So the report is not read as broader than it is:

- **No view is tested.** By design — *"the scenario suite never needs to know
  views exist"* — but it means `FamilyView.res` is verified only by compiling
  and by my having watched the croquis version run.
- **No offline, no reconnection, no conflict.** Single session, single
  browser, server always up.
- **No `migrate`, no `rebase`, no `export`.** I defined the model once and
  never changed it, so I never met lapa's migration story, which its own docs
  flag as the sharp part (*"nothing repairs by itself"*).
- **No invitations, accounts, or multi-user anything.** The app deliberately
  models family members as rows rather than Accounts, so the entire access
  and edge model went untouched.
- **No seek.** `Lapa.equals`, `above`, `below`, `between` and `contains` were
  never used; the client holds everything the session reaches and the domain
  filters in memory. So half of lapa's query surface is unassessed here, and
  the `indexed` flags in this app's model are untested guesses (§2.11, §3.8).
- **One `.data` store, one Domain, one Personal node.**

---

## 7. Ranked recommendations

| # | Fix | Why |
|---|-----|-----|
| 1 | Make the desk reachable on a cold session, or document the HTTP fallback | Every first agent session loses the desk entirely |
| 2 | Namespace the browser IndexedDB per store, or self-heal the ancestor mismatch | An unactionable error is the first thing a new project shows |
| 3 | Generate a typed `creation` constructor per class | Removes the only hand-marshalled, unchecked write path |
| 4 | Warn that `Lapa.id` must never enter the DOM, a URL or JSON; expose `spell`/`parse` | A latent bug the docs currently let you walk into |
| 5 | Align the kind vocabulary, or publish the mapping | `ref` / `relation` / `Ref` is one concept under three names, crossed in one session |
| 6 | Enforce the croquis boundary, or stop claiming it | An unenforced *and* gitignored rule is worse than no rule |
| 7 | Document table steps, and that placeholders are **only** `{string}` / `{number}` | The one place the "never guess" rule could not be obeyed |
| 8 | Say that `rescript` must not be run while dev runs | An ordinary action destroys the environment, silently |
| 9 | Document that an all-optional class makes its whole part `Nullable` | One field's required-ness silently changes how every other field is read |
| 10 | Answer "a derived value per row of a dynamic list" for tilia | The one modelling question I could not resolve |
| 11 | Show a worked `switch` over every `loadable` state | The staleness model is documented but unusable as written |
| 12 | Write the app id as base64 in the generated header | The line that decides file ownership is the least legible line in the file |
| 13 | Nest `EpureVitest`'s `Todo`/`Skip`/`Only` under `Mode` | Collides with ordinary domain words |
| 14 | Say when a field wants `indexed` — reach vs scale — at `define` time | The flag is permanent, and the question has no answerable form today |

---

## 8. Overall

The method worked. A first-time agent with no knowledge of any of these three
libraries produced a working, tested, documented application in one session,
made five design decisions explicitly instead of silently, and threw away its
own exploratory work on purpose at the end.

Almost everything that cost me time was **environmental rather than
conceptual** — the desk not being connected, a stale browser database, a
watcher that dies when you compile. The ideas are in better shape than the
edges around them, which is the right way round, and most of the list above is
a day of work rather than a redesign.

The two things I would change first are not code at all. Make the desk
reachable when an agent actually needs it, and either enforce the croquis
boundary or stop promising it.
