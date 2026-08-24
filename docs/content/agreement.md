# Contributing

This project is drawn before it is built — the
[épure](https://epuremethod.com) way of working together. This file is the
working agreement: copy it to the root of your project and keep it there
for the life of the project. It is addressed to everyone who will ever build
here — humans and AI assistants alike — so that the building stays convivial:
any mind, arriving at any moment, reads this page and knows how the work is
done. (A companion `AGENTS.md` holds one instruction — read this file — so
that assistant tooling lands here on its own.)

## Three promises

1. **The scenarios are the design.** Every want becomes a scenario — Given,
   When, Then, in the domain's own words — before it becomes code. The
   scenario files are the project's design contracts and its decision
   ledger: to know what the software does, read them; to change what it
   does, change them first. They cannot drift from the code, because they
   run against it. The vocabulary of the code is the vocabulary of the
   scenarios.

2. **Everything else is scaffolding.** Sketches, prose designs, prompts:
   useful while a want is being turned into scenarios, gone once it has
   been. The repo keeps no second description of behavior — nothing is ever
   kept in sync by hand, because nothing needs to be.

3. **Green is the handshake.** A feature is done when its scenarios pass,
   and it stays done because they keep passing while the project's standing
   check remains green. Trust lives in the suite, not in re-reading old
   code. And the steps that bind scenarios to code are code: reviewed like
   code, because a wrong step makes passing meaningless.

## The shape of the code

The code follows the diagonal architecture: layers ordered by dependency,
each independently testable, where a lower layer depends on higher layers
only. Nothing in `src/domain` touches an external library — tilia, the
state manager, is the one exception. The tools named here are the
reference stack — a project may swap them; the boundaries and the
promises stay.

- **croquis/** — the sketches of the croquis mode (see "Two modes"). It may
  use every layer below it, nothing ships depending on it, and git ignores
  everything in it except its `.gitkeep`.
- **design/** — the executable scenarios, their steps, and the test
  assembly. The steps that bind scenarios to code are code: reviewed like
  code, because a wrong step makes passing meaningless.
- **domain/api/** — the interfaces. `entity/` holds the types of the
  business objects — the vocabulary. `feature/` holds the contract each
  feature offers. `service/` holds every contract with the outside world —
  network, storage, audio, a socket, an rpc call. Whatever the app needs
  from the world is defined here and injected, so a test hands a feature
  fakes instead of the world.
- **domain/feature/** — the business behavior. One self-contained object
  per feature, built with tilia's `carve`: its state, its derived values,
  and its actions live together and speak the domain's words. The logic
  itself consists of ordinary pure functions — readable, testable in
  isolation, and handed over as a whole.
- **service/** — the connectors to the outside world (storage, network,
  clock, audio, translations). A service abstracts the technical details
  behind its interface; it holds no cache and no business logic.
- **view/** — the face. Views read features and render; they contain no
  business logic. The scenario suite never needs to know views exist. A
  server has **surfaces/** instead: one directory per surface, assembling
  the layers below it for the people or agents that reach it.

## The loop

want → scenario, agreed in the domain's words → build (pure functions,
carved features) → green → next want.

A bug is a missing scenario: write the scenario that fails, then fix the code.

## Two modes

A session works in one of two modes and names its mode in `SESSION.md`.

**Croquis** is finding out what to build, named for the quick freehand
sketch drawn before the épure. The agent defines the model at the desk, the
board shows it live, and the views are sketches in `src/croquis/` — no
scenarios, no stages, no stops. A sketch is cheap to make and cheap to
throw away. Two things survive a croquis: the model, which is data, and the
reasons worth keeping, which go to `DECISIONS.md`. Git never sees a sketch:
everything in `src/croquis/` is ignored except the `.gitkeep` that keeps
the folder.

**Build** is the loop above: a bounded want, its scenarios agreed first, a
stop after each stage, green as the handshake.

One rule joins the modes: the standing check stays green. A croquis adds
beside what is proven and never changes a behavior a scenario covers — to
change one, work in build. At a build session's close, `src/croquis/` is
empty.

## If you are an AI assistant

Before writing code against any library used here, read its version-matched
reference in `node_modules/<package>/llms.txt`. If something is not in the
reference, it does not exist — an unknown is a question to ask, never an
API to guess.

## What this file does not decide

Framework, bundler, storage, transport, styling, test runner adapters: those
are the project's choices, made when a scenario requires them. This file only
holds the method — the design stays executable, the domain stays in its own
words, the world stays injected.
