---
name: Store
slug: store-type
kind: type
module: core
since: "0.1"
sort: 230
summary: Local store adapter — offline reads and the durable write outbox.
signature:
  ts: |-
    interface Store<T, Q> {
      fetch(query: Q, channel: FetchChannel<T>): void | (() => void),
      save(value: T, dirty: boolean): void,
      remove(value: T, dirty: boolean): void,
      dirty(): Promise<Write<T>[]>
    }
  res: |-
    type store<'a, 'query> = {
      fetch: ('query, Channel.fetch<'a>) => option<unit => unit>,
      save: ('a, bool) => unit,
      remove: ('a, bool) => unit,
      dirty: unit => promise<array<write<'a>>>,
    }
tags: []
---

The optional local store is the durable half of the lifecycle: it answers every query offline and persists the write outbox. `fetch` uses the same [FetchChannel](api.html#fetch-channel-type) contract as the remote — its failures are ignored by design (an adapter bug, not a sync state).

The `dirty` flag on `save` and `remove` is the entire outbox mechanism: `save(value, true)` marks a row unsynced, `remove(value, true)` writes a delete tombstone, and the clean calls settle them once the remote confirms (`remove(value, false)` purges row and tombstone). `dirty()` returns the previous session's unsynced writes — each a `Write` carrying the `value` and a `deleted` flag — replayed at boot through the normal flow.

A full sync engine also fits this contract: answer fetches from its database, report `covered()`, and deliver inbound changes via [sync](api.html#sync). See guide chapter [The channel boundary](docs.html#the-channel-boundary).

```typescript
const local: Store<Card, DeckQuery> = {
  fetch: (q, channel) => void db.query(q).then(channel.emit),
  save: (card, dirty) => db.put({ ...card, dirty }),
  remove: (card, dirty) =>
    dirty ? db.put({ ...card, dirty, deleted: true }) : db.delete(card.id),
  dirty: () => db.unsynced(),
};
```

```rescript
let local: TiliaQuery.store<card, deckQuery> = {
  fetch: (q, channel) => Db.query(q)->Promise.thenResolve(channel.emit)->ignore->None,
  save: (card, dirty) => Db.put(card, ~dirty),
  remove: (card, dirty) => dirty ? Db.tombstone(card) : Db.delete(card.id),
  dirty: () => Db.unsynced(),
}
```
