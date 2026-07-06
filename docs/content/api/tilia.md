---
name: tilia
slug: tilia
kind: function
module: core
since: "1.0"
sort: 1
summary: Create a reactive object from a plain object.
signature:
  ts: "function tilia<T>(value: T): T"
  res: "let tilia: 'a => 'a"
tags: []
---

Returns a reactive proxy of `value` with the same type and the same shape. Reads and writes go through ordinary property access; there is no wrapper API to learn and nothing to unwrap. Nested objects become reactive on first access, so a whole domain model can be made observable with a single call at its root.

::: pro
Call `tilia` once at the root of a domain object. Nested plain objects and arrays assigned later are wrapped lazily the first time they are read, so you never need to call it again as the tree grows.
:::

```typescript
const forest = tilia({
  trees: 120,
  health: 'good'
})

forest.trees += 1 // observers of `trees` re-run
```

```rescript
let forest = tilia({
  trees: 120,
  health: "good",
})

forest.trees = forest.trees + 1 // observers of `trees` re-run
```
