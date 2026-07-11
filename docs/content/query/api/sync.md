---
name: .sync
slug: sync
kind: function
module: core
since: "0.1"
sort: 80
summary: Apply an inbound update — cache, query membership, and a clean local save.
signature:
  ts: "collection.sync(value: T): void"
  res: "collection.sync: 'a => unit"
tags: []
---

`sync` is for changes that arrive from outside: a WebSocket push, a delta-sync batch. It updates the object cache, adjusts query membership via `matches`, and saves the value clean to the local store — so a pushed change survives an offline restart. No remote call: the change came from the remote. If the id has a pending optimistic write, `sync` is a no-op — the local write wins until it settles. An engine that already wrote its own database can still call `sync`; the extra clean save is idempotent.

Do not use [upsert](api.html#upsert) for inbound data: it would echo the change back to the server and dirty the local store on the way. `sync` is the inbound counterpart of the `covered()` callback on [FetchChannel](api.html#fetch-channel-type); [syncRemove](api.html#sync-remove) is its delete twin. See guide chapter [When the server disagrees](docs.html#when-the-server-disagrees).

```typescript
socket.on("card", (card: Card) => cards.sync(card));
```

```rescript
Socket.on(socket, "card", card => cards.sync(card))
```
