# `pnpm create epure` scaffolds a nine-day-old template

Filed 2026-09-03. Reproduced on pnpm 11.18.0, macOS, registry
`http://localhost:4873` (Verdaccio).

## Summary

`pnpm create epure` does not scaffold the newest `create-epure`. It
scaffolds the newest one that is more than 24 hours old. Today that is
`0.1.0-beta.17`, published 2026-08-25.

The template in `beta.17` is written against an older lapa. It does not
compile against the packages a fresh install pulls. Every project scaffolded
today has been dead on arrival for this reason.

The cause is pnpm 11's `minimumReleaseAge`, which defaults to 1440 minutes.
It is the same setting the template's own `pnpm-workspace.yaml` already
documents and works around. The workaround cannot cover `create-epure`
itself, because the file that holds it is written by the scaffold it is
meant to protect.

## What a person sees

```sh
pnpm create epure loby
cd loby && pnpm dev
```

The dev server starts and prints its link. The ReScript build then fails:

```
/loby/src/domain/api/service/Notes.res:1:6-14

  1 │ open Lapa.Data

  The module or file Lapa can't be found.
```

Vite serves nothing, because `src/view/Page.res.mjs` was never written. The
link opens an empty page. Nothing in the output names a version, so the
person has no reason to suspect the scaffolder.

## Root cause

`minimumReleaseAge` holds a newly published version back for a day and
resolves an older one instead, silently. It applies to the `create-epure`
download that `pnpm create` performs before any project directory exists.

The published history, and what each version is worth today:

| version | published | age at 18:50 UTC | template |
| ------- | --------- | ---------------- | -------- |
| 0.1.0-beta.17 | 2026-08-25 16:46 UTC | 9 days | old, does not compile |
| 0.1.0-beta.18 | 2026-09-03 06:40 UTC | 12.2 h | current |
| 0.1.0-beta.19 | 2026-09-03 06:58 UTC | 11.9 h | current |
| 0.1.0-beta.20 | 2026-09-03 17:58 UTC | 52 min | current |
| 0.1.0-beta.21 | 2026-09-03 18:43 UTC | 7 min | current |

`beta.17` is the newest version older than 24 hours. It is what the
resolver picks. The registry itself is correct — `dist-tags` gives
`latest` and `beta` as `0.1.0-beta.21`, and every tarball is intact.

### Why the template's exclude list does not help

`templates/pnpm-workspace.yaml` already carries the right idea:

```yaml
minimumReleaseAgeExclude:
  - "@epure/*"
  - "@lapa/*"
  - lapa
  - tilia
  - "@tilia/*"
```

That list works. It is why a scaffolded project installs `@lapa/db`
minutes after a beta lands. But it lives inside the scaffold. It is
copied into the project by the very `create-epure` whose own resolution
already happened. `create-epure` cannot exempt itself.

## What this is not

The `create-epure` in `~/Library/Caches/pnpm/dlx` was pinned at `beta.17`
and it was stale. That was a real second cache, and clearing it changed
nothing: a fresh resolve with an empty dlx cache picked `beta.17` again.
`minimumReleaseAge` is upstream of the cache and is the whole cause.

A third stale cache was also found and cleared — pnpm's packument cache
held `tilia@beta` three days behind the registry. Also not this bug.

## Resolution matrix, all tested

| command | resolves | template |
| ------- | -------- | -------- |
| `pnpm create epure` | 0.1.0-beta.17 | old, broken |
| `pnpm create epure@beta` | 0.1.0-beta.17 | old, broken |
| `pnpm create epure@0.1.0-beta.21` | 0.1.0-beta.21 | correct |
| `pnpm --config.minimumReleaseAge=0 create epure` | 0.1.0-beta.21 | correct |
| bare, with a global `minimumReleaseAgeExclude` | 0.1.0-beta.21 | correct |

A dist-tag does not escape the hold. Only an exact version does, or
turning the policy off, or naming `create-epure` in an exclude list that
exists before the command runs.

`beta.21` scaffolds and compiles clean: `Compiled 64 modules`, no errors
and no warnings.

## Workarounds today

Pin the version, and change the number on every release:

```sh
pnpm create epure@0.1.0-beta.21 myproject
```

Or exempt the families once, in the global pnpm config
(`~/Library/Preferences/pnpm/config.yaml` on macOS):

```yaml
minimumReleaseAgeExclude:
  - create-epure
  - "@epure/*"
  - "@lapa/*"
  - lapa
  - tilia
  - "@tilia/*"
```

This is applied on this machine already. `config.yaml.bak` holds what was
there before.

## What to fix

The install instruction cannot stay `pnpm create epure` while betas move
daily. Three directions, cheapest first.

1. **Make the scaffolder say its own age.** On start, `epure init` reads
   the registry's `latest` for `create-epure` and compares it to its own
   version. When it is behind, it stops and prints the exact-version
   command. This costs one request and turns a silent nine-day rollback
   into one line the person can act on. It also covers every future
   instance of this trap, not just today's.

2. **Document the global exclude** in the install page, beside the
   `pnpm create` line, with the reason. A person who scaffolds épure
   projects at all will want it once.

3. **Say the version in the scaffold's own output.** `epure init` already
   prints `<name> is ready`. Naming the version it scaffolded from would
   have made this fifteen minutes of work instead of an evening.

Worth deciding separately: whether `minimumReleaseAge` is wanted at all on
a machine whose whole job is moving betas the same day they publish, or
whether the exclude list is the right shape long term.

## Reproduce

```sh
rm -rf /tmp/epure-repro && mkdir -p /tmp/epure-repro && cd /tmp/epure-repro
pnpm create epure broken                 # -> beta.17, has src/service/Live.res
pnpm create epure@0.1.0-beta.21 fixed     # -> beta.21, no Live.res
grep -r "^open Lapa" broken/src | head -1 # open Lapa.App        (gone from lapa)
grep -r "^open Lapa" fixed/src  | head -1 # open LapaDb.App      (current)
```

`src/service/Live.res` is the quickest tell. It was removed in `beta.18`
when the binding moved to `@lapa/tilia`. A scaffold that has it is old.

## Environment

- pnpm 11.18.0, node 22.19.0, macOS (darwin 25.5.0)
- registry: Verdaccio at `http://localhost:4873`
- `create-epure` checkout at `0.1.0-beta.20` in `create/package.json`,
  with `0.1.0-beta.21` published
- the checkout's `templates/` matches published `beta.20` and `beta.21`
  byte for byte in `src/`
