---
name: observe
slug: observe
kind: function
module: core
since: "1.0"
sort: 2
summary: Run a function now, and re-run it whenever the reactive values it reads change.
signature:
  ts: "function observe(fn: () => void): () => void"
  res: "let observe: (unit => unit) => unit => unit"
tags: []
---

tilia records which properties `fn` reads during each run and re-runs it when any of them is written. Tracking is per-property and re-computed on every run, so branches that stop reading a value stop depending on it. `observe` returns a disposer that stops the tracking; call it to detach the effect.

Use `observe` for effects that live outside a view: logging, persistence, derived state kept in the domain.

::: story
Nice, the age updates automatically, Alice can grow older :-)
:::

```typescript
const stop = observe(() => {
  document.title = `${forest.trees} trees`
})

// later, if the effect is no longer needed
stop()
```

```rescript
let stop = observe(() => {
  Document.setTitle(`${forest.trees->Int.toString} trees`)
})

// later, if the effect is no longer needed
stop()
```
