---
name: .syncRemove
slug: sync-remove
kind: function
module: core
since: "0.1"
sort: 85
summary: Apply an inbound delete — evict everywhere, purge the clean local row.
signature:
  ts: "collection.syncRemove(value: T): void"
  res: "collection.syncRemove: 'a => unit"
tags: []
---

`syncRemove` is the delete twin of [sync](api.html#sync), for deletions that arrive from outside: it evicts the id from the object cache and every query id list, purges the clean row from the local store, and drops the id from persisted query records. Without the purge, a delete pushed over a socket would vanish from the screen but linger on disk — and reappear as a ghost on the next offline start.

No remote call, and no tombstone: the server already knows. If the id has a pending optimistic write, `syncRemove` is a no-op — the local write wins until it settles. Dirty rows and tombstones are never touched. See guide chapter [When the server disagrees](docs.html#when-the-server-disagrees).

```typescript
socket.on("cardDeleted", (card: Card) => cards.syncRemove(card));
```

```rescript
Socket.on(socket, "cardDeleted", card => cards.syncRemove(card))
```
