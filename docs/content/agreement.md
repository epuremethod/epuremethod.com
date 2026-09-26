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

2. **Two things survive a want: the scenarios and the cahier.** The
   scenarios say what the software does; the cahier says what it is, how it
   is used, and why it is shaped that way. Everything else — sketches,
   prompts, plans, session notes — is scaffolding, gone once the want has
   landed. No sentence in the cahier promises behavior that no scenario
   proves: if it cannot be traced to a scenario, either write the scenario
   or cut the sentence. The repo keeps one description of behavior, and it
   runs.

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

- **croquis/** — the sketches of the croquis mode (see "Three modes"). It may
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

want → sketch and write until it holds → scenarios, agreed in the domain's
words → build (pure functions, carved features) → green → the cahier
finished against the suite → next want.

A bug is a missing scenario: write the scenario that fails, then fix the code.

## Three modes

A session works in one of three modes and names its mode in `SESSION.md`.
The three are ordered by the cost of being wrong: a sketch is wrong in
minutes, a paragraph in an hour, a signed scenario in a meeting, code in
the build. Be wrong where it is cheap — that is what drawing before
building means. Croquis and cahier are two activities of one stage, and a
session that names either may use the other: sketch, write, sketch again.
Build is on the other side of the line.

**Croquis** is finding out what to build, named for the quick freehand
sketch drawn before the épure. The agent defines the model at the desk, the
board shows it live, and the views are sketches in `src/croquis/` — no
scenarios, no stages, no stops. A sketch is cheap to make and cheap to
throw away. Two things survive a croquis: the model, which is data, and the
reasons worth keeping, which go to `DECISIONS.md`. Git never sees a sketch:
everything in `src/croquis/` is ignored except the `.gitkeep` that keeps
the folder. What a croquis finds is written into the cahier — while the
sketching goes on, or at its close.

**Cahier** is thinking in prose and diagrams — the notebook, and the head
of *cahier des charges*, the paper a contractor signs. A croquis shows
whether the thing can work; the cahier finds out whether it holds. It needs
no folder of its own: one working file in `docs/`, `wip.md`, saying what
the thing is, what it promises and why it is shaped that way, worked
through on real cases until the sentences stop contradicting each other and
the domain's words are settled. Prose is where a wrong idea breaks cheaply
and a missing word is obvious; a diagram is where a wrong shape does. A
cahier ends with a vocabulary and a list of promises, and the scenarios are
written from it, not from the sketch. Until it is signed it can be thrown
away whole, like the croquis it came from; signed, it is signed beside the
scenarios — a cahier des charges whose behavioral half runs. What it
settles becomes, once green, the page `docs/` publishes.

**Build** is the loop above: a bounded want, its scenarios agreed first, a
stop after each stage, green as the handshake. A build closes by finishing
the cahier against the green suite.

Two rules join the modes. The standing check stays green: a croquis adds
beside what is proven and never changes a behavior a scenario covers — to
change one, work in build — and at a build session's close, `src/croquis/`
is empty. And no writing promises what no scenario proves: the cahier
describes, explains and illustrates, and every behavior it states is one a
scenario already holds.

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
