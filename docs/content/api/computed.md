---
name: computed
slug: computed
kind: function
module: core
since: "1.0"
sort: 3
summary: Derive a memoized value that recomputes only when the reactive values it reads change.
signature:
  ts: "function computed<T>(fn: () => T): () => T"
  res: "let computed: (unit => 'a) => unit => 'a"
tags: []
---

`computed` wraps `fn` in the same dependency tracking as `observe`, but instead of running eagerly it returns a getter. The first call to the getter runs `fn` and caches the result; later calls return the cached value until one of the properties read by `fn` changes, at which point the next call recomputes it.

The computation can be created anywhere but only becomes active — that is, only starts tracking — once its getter is called from inside a tilia object or array, or from an `observe` run.

::: pro
The computed can be created anywhere but only becomes active inside a Tilia object or array.
:::

```typescript
const canGrow = computed(() => forest.health === 'good')

canGrow() // reads forest.health, caches the result
```

```rescript
let canGrow = computed(() => forest.health === "good")

canGrow() // reads forest.health, caches the result
```
