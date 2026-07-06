---
title: Computed values
slug: computed
sort: 4
refs: [computed]
---

`computed` derives a value from other reactive values and caches it. Unlike `observe`, which runs eagerly and produces side effects, `computed` is lazy: nothing runs until the returned getter is called, and the result is reused until a dependency changes.

::: story
Nice, the age updates automatically, Alice can grow older :-)
:::

```typescript
const alice = tilia({ birthYear: 1990 })
const age = computed(() => new Date().getFullYear() - alice.birthYear)

age() // computed once, cached until birthYear changes
```

```rescript
let alice = tilia({birthYear: 1990})
let age = computed(() => Date.now()->Date.getFullYear - alice.birthYear)

age() // computed once, cached until birthYear changes
```

### Chaining computeds

A computed can read another computed's getter, and the dependency chain works exactly like it does for plain properties — the outer computed recomputes when the inner one's cached value changes.

::: pro
The computed can be created anywhere but only becomes active inside a Tilia object or array.
:::

```typescript
const store = tilia({ trees: 120 })
const doubled = computed(() => store.trees * 2)
const label = computed(() => `${doubled()} trees (doubled)`)

label() // chains through doubled() to store.trees
```

```rescript
let store = tilia({trees: 120})
let doubled = computed(() => store.trees * 2)
let label = computed(() => `${doubled()->Int.toString} trees (doubled)`)

label() // chains through doubled() to store.trees
```
