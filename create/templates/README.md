# {{name}}

This project is drawn before it is built — the
[épure](https://epuremethod.com) way of working beside an AI agent.
`CONTRIBUTING.md` is the working agreement; this file says how to run the
project and where things live.

## Run it

```sh
pnpm dev
```

Once the app answers, the command prints one link. Open that link: the app
opens only on a session, and the link carries it. The agent's desk answers
on the same session — the install wrote `.mcp.json`, and dev keeps it.

## The board

The running app shows the board behind an icon at the bottom right, in dev
only. The board reads the same client as the app, so what the agent defines
appears in both at the same moment. A build carries no board.

## Three modes

Every session works in one mode, named in `SESSION.md`. They are ordered by
the cost of being wrong — a sketch is wrong in minutes, a paragraph in an
hour, a signed scenario in a meeting, code in the build:

- **Croquis** — finding out what to build. The agent defines the model at
  the desk and sketches views in `src/croquis/`. No scenarios, no stops.
  Git never sees a sketch. Two things survive a croquis: the model, and the
  reasons worth keeping, which go to `DECISIONS.md`.
- **Cahier** — finding out whether it holds. The thing is thought through
  in prose and diagrams in `docs/wip.md` until the words are settled, and
  the scenarios are written from it. No code. Croquis and cahier are the
  same stage: move between them freely.
- **Build** — a bounded want, its scenarios agreed first, a stop after each
  stage, green as the handshake.

In all three the standing check stays green. `CONTRIBUTING.md`, "Three
modes", holds the rule.

## The shape

- `src/croquis/` — a croquis's throwaway views. Git never sees them.
- `src/design/` — the scenarios and their steps: the executable design.
- `src/domain/` — the model and the features, in the domain's own words.
  `domain/api/` holds what the server generates from the model.
- `src/service/` — connectors to the outside world. Features never reach
  for the world; it arrives injected.
- `src/view/` — the face. Views read features and render; they hold no
  business logic.

## The commands

| Command | What it does |
| ------- | ------------ |
| `pnpm dev` | the app, the data server, and the desk, on one session |
| `pnpm test` | the standing check — every scenario |
| `pnpm build` | the production bundle, in `dist/` |
| `pnpm format` | formats the ReScript sources |
