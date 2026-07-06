---
title: Observing
slug: observing
sort: 5
refs: [observe]
---

`observe` is for effects that live outside a render: writing to `localStorage`, syncing to a server, logging, updating `document.title`. Call it once, anywhere, and it runs immediately and again on every relevant change.

The disposer returned by `observe` detaches the run permanently — no dependency it once tracked will trigger it again. Call it when the effect's owner is torn down, the same way you would clean up any other subscription.

### Effects that create effects

Nothing stops an `observe` callback from calling `observe` again to set up a nested effect, but it is rarely what you want: the outer run's re-execution will create a fresh inner effect each time without disposing the previous one. Prefer flattening related reads into a single `observe` call instead.
