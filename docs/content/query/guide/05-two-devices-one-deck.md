---
title: Two devices, one deck
slug: two-devices-one-deck
sort: 5
refs: []
---

Changing devices is where hand-rolled sync layers usually crack, so it is worth saying plainly: in this design, "continue on your phone" is not a feature anyone built. It is what remains when two rules are kept honestly — the server is authoritative, and every cache admits it is a cache.

### The meeting point

By the time Alice's train reaches the station, the laptop's outbox has drained through the gaps between tunnels. Every review she made, every card she reworded, is on the server — not because some export ran, but because that is where writes were always headed. Closing the laptop loses nothing, because the laptop was never the owner of anything.

The phone, meanwhile, has its own local store, holding whatever it saw last. At the station it gets one bar of signal and a minute of attention: the queries Alice opens answer instantly from the phone's local copy, refresh from the server, and — because remote results are written through — the phone's store now carries the deck as the laptop left it. Then the bus turns into the hills and the signal dies, and none of that matters anymore.

Multi-device support, offline support, and plain cache correctness turn out to be the same discipline. There is one truth, at the meeting point; everything else is a device remembering.

### When the server speaks first

So far the remote only ever answered questions. Real backends also *volunteer* facts — a websocket delivery, a sync engine's notification. Those enter through `receive`:

```typescript
socket.on("cards.changed", cards.receive.changed); // values that changed
socket.on("cards.removed", cards.receive.removed); // ids that were deleted
```

```rescript
Socket.on(socket, "cards.changed", cards.receive.changed) // values that changed
Socket.on(socket, "cards.removed", cards.receive.removed) // ids that were deleted
```

Deliveries are past tense on purpose: facts about the server, not commands to it. A changed value is offered to every in-memory query through `matches` — it joins the results it now belongs to and leaves the ones it no longer does, the same membership logic writes use. A removed id leaves every result. And a delivery that lands on a row with an unconfirmed local edit goes through the same merge machinery as any other remote arrival, so a pending write is never silently clobbered by an incoming one — [chapter 7](#when-the-world-returns) owns that story.

### Queries that stay fresh on their own

When a source pushes complete results — a server subscription per query — the adaptor answers through `channel.live` instead of `channel.set`, calling it again on every update, and registers its cleanup with `channel.finally`:

```typescript
fetch: (query, channel) => {
  const sub = socket.subscribe(deckTopic(query), channel.live);
  channel.finally(() => sub.close());
},
```

```rescript
fetch: (query, channel) => {
  let sub = Socket.subscribe(socket, deckTopic(query), channel.live)
  channel.finally(() => sub->Subscription.close)
},
```

`live` tells the engine the source keeps this result fresh, so the periodic refresh skips it. `finally` hands the engine the teardown, and the engine runs it exactly once, when the fetch closes — superseded, retired from memory, or disposed. Late replies on a closed fetch are ignored wholesale; the adaptor never guards against its own stragglers.

::: story
Alice buys a terrible coffee, thumbs the phone awake in the bus queue, and the deck is already mid-thought — the queue starts where the laptop stopped, the card she reworded in the last tunnel reads the new way. The bus climbs; the bars vanish; the deck doesn't flinch.
:::

::: pro
Keep your protocol past tense too. A message named `cardChanged` carries a fact and can be replayed, reordered, or ignored safely; a message named `changeCard` is a command wearing a fact's clothes.
:::

The phone now holds everything it needs. It will have to, because where the bus is going there is no third answer coming — for a week.
