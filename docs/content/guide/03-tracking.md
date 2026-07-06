---
title: Tracking
slug: tracking
sort: 3
refs: [observe]
---

Every read of a reactive property, inside an `observe` run, is recorded against that run. When you later write to the same property, every run that read it is scheduled to re-execute. This is per-property, not per-object: reading `forest.trees` does not create a dependency on `forest.health`.

Tracking is also re-computed on every run, not fixed at creation time. If a run takes a branch this time that skips reading a property it read last time, that dependency is dropped — the next write to that property will not trigger a re-run until the branch reads it again.

### Batching

Multiple writes made synchronously in the same tick are coalesced: an observer that depends on three properties you just set in a row re-runs once, not three times.
