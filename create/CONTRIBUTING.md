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

Four floors, each independently testable. The tools named here are the reference
stack — a project may swap them; the boundaries and the promises stay.

- **features/** — the business logic. One self-contained object per feature,
  built with tilia's `carve`: its state, its derived values, and its actions
  live together and speak the domain's words. Alongside each feature are its
  scenarios and its steps file. The logic itself consists of ordinary
  pure functions — readable, testable in isolation, and handed over as a whole.
- **repo/** — persistence. One self-contained object per data type that is
  saved.
- **services/** — connectors to the outside world (storage, network, clock,
  audio, translations). Features and repos never reach for the world; the
  world arrives **injected**, so every feature runs unchanged in a test.
- **views/** — the face. Views read features and render; they contain no
  business logic. The scenario suite never needs to know views exist.

## The loop

want → scenario, agreed in the domain's words → build (pure functions,
carved features) → green → next want.

A bug is a missing scenario: write the scenario that fails, then fix the code.

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
