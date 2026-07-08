---
title: The channel boundary
slug: the-channel-boundary
sort: 6
refs: [remote-type, store-type, fetch-channel-type, write-channel-type]
---

Adapters are where your application's reality — its HTTP client, its IndexedDB wrapper, its sync engine — meets the lifecycle. The contract between the two sides is a handful of functions and the channels they answer through. This chapter builds a remote adapter and explains why the boundary is drawn exactly here.

### A remote adapter

The `remote` describes connectivity and three operations. Each receives a channel and reports its outcome by calling one named callback:

```typescript
import { tilia } from "tilia";
import type { Remote } from "@tilia/query";

const remote: Remote<Card, DeckQuery> = tilia({
  online: navigator.onLine,
  fetch(query, channel) {
    api.listCards(query.deck).then(
      (rows) => channel.emit(rows),
      (err) => channel.fail(err.message)
    );
  },
  upsert(card, channel) {
    api.saveCard(card).then(
      (saved) => channel.emit(saved),
      (err) =>
        err.status === 409
          ? channel.conflict(err.serverValue)
          : err.status === 403
            ? channel.reject(err.message)
            : channel.offline()
    );
  },
  remove(card, channel) {
    api.deleteCard(card.id).then(
      () => channel.emit(card),
      (err) => (err.status ? channel.reject(err.message) : channel.offline())
    );
  },
});

window.addEventListener("online", () => (remote.online = true));
window.addEventListener("offline", () => (remote.online = false));
```

```rescript
open Tilia

let remote: TiliaQuery.remote<card, deckQuery> = tilia({
  online: Navigator.onLine,
  fetch: (query, channel) =>
    Api.listCards(query.deck)
    ->Promise.thenResolve(rows => channel.emit(rows))
    ->Promise.catch(err => Promise.resolve(channel.fail(Error.message(err))))
    ->ignore,
  upsert: (card, channel) =>
    Api.saveCard(card)
    ->Promise.thenResolve(saved => channel.emit(saved))
    ->Promise.catch(err =>
      Promise.resolve(
        switch Api.status(err) {
        | 409 => channel.conflict(Api.serverValue(err))
        | 403 => channel.reject(Error.message(err))
        | _ => channel.offline()
        },
      )
    )
    ->ignore,
  remove: (card, channel) =>
    Api.deleteCard(card.id)
    ->Promise.thenResolve(() => channel.emit(card))
    ->Promise.catch(_ => Promise.resolve(channel.offline()))
    ->ignore,
})
```

The adapter's whole job is translation: your API's vocabulary of statuses and errors into the lifecycle's vocabulary of outcomes. It holds no state, retries nothing, caches nothing — all of that is the core's, which is why every collection behaves identically no matter what transport feeds it. (One deliberate exception: resolving an expected conflict — 3-way merge and retry, using an original value stored on the row — belongs in the adapter; the [previous chapter](#when-the-server-disagrees) shows the pattern.)

::: pro
`remote` must be a tilia object. The core *watches* `online` to drive reconnect replay — a plain record has nothing to watch, so offline writes could never replay. [make](api.html#make) enforces this: passing a plain record throws `make: remote is not a tilia proxy (reconnect could never replay writes)`.
:::

### Why callbacks, and why cancellation

Outcomes are reported by *calling a named function*, never by returning or constructing a result value. Two reasons. First, the boundary is bilingual: ReScript variants do not exist in compiled JavaScript, so a contract built on constructing them would be unwritable from TypeScript — named callbacks read identically in both languages. Second, a callback gives the core a place to stand between the adapter and the caches.

That place matters because of time. Answers arrive late: a fetch resolves after the query was refetched, an upsert confirms after a newer write to the same id took over. Every channel can be **cancelled** by the core, and a cancelled channel turns all of its callbacks into no-ops. The adapter never checks whether its answer is still wanted — it answers, and staleness is absorbed at the boundary. Race conditions become a property the core handles once, not a discipline every adapter must remember.

A `fetch` may also return a cleanup function. That is the live-subscription hook: subscribe to a feed, `emit` on every message, and the cleanup runs when the query is refetched or garbage-collected.

### The local store

The optional `local` adapter is the durable half — four functions over whatever storage you have:

- `fetch(query, channel)` — answer the query from disk, same channel contract as remote.
- `save(value, dirty)` — upsert a row; `dirty` marks it unsynced.
- `remove(value, dirty)` — `dirty` writes a delete tombstone; clean purges row and tombstone.
- `dirty()` — the previous session's unsynced writes, replayed at boot.

The `dirty` flag is the entire outbox persistence mechanism: the core tells the store *what to remember about sync state*, the store just remembers it. Note what is absent — no migrations, no schemas, no query planner. If your local store is a full sync engine instead of a passive cache, it still fits: answer fetches from its database, report `covered()`, and deliver inbound changes via [`sync`](#when-the-server-disagrees).

::: story
Alice notices none of this, which is the review the adapter author wanted.
:::

One piece of the lifecycle is still unclaimed: nothing has said *when* stale queries refresh or old ones are evicted. That timing belongs to the application — and to the next chapter.
