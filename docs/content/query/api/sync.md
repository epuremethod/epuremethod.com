---
name: .sync
slug: sync
kind: function
module: core
since: "0.1"
sort: 80
summary: Apply an inbound update to memory — cache and query membership only.
signature:
  ts: "collection.sync(value: T): void"
  res: "collection.sync: 'a => unit"
tags: []
---

`sync` is for changes that arrive from outside: a WebSocket push, a delta-sync batch. It updates the object cache and adjusts query membership via `matches` — and nothing else. No remote call (the change came from the remote), no local save (the engine that delivered it owns persistence).

Do not use [upsert](api.html#upsert) for inbound data: it would echo the change back to the server and dirty the local store on the way. `sync` is the inbound counterpart of the `covered()` callback on [FetchChannel](api.html#fetch-channel-type). See guide chapter [When the server disagrees](docs.html#when-the-server-disagrees).

```typescript
socket.on("card", (card: Card) => cards.sync(card));
```

```rescript
Socket.on(socket, "card", card => cards.sync(card))
```
