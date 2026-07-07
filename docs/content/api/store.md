---
name: store
slug: store
kind: function
module: core
since: "2.0"
sort: 80
summary: Define an inserted managed value from a setup function with setter.
signature:
  ts: "function store<T>(fn: (set: Setter<T>) => T): T"
  res: "let store: (('a => unit) => 'a) => 'a"
tags: []
---

`store` creates a dynamic inserted value from `fn(set)`. The setup returns the current value and receives `set` to update it later.

The setup runs on first access and can re-run when tracked dependencies used during setup change. This is suitable for finite-state values where transitions call `set`.

Use [source](api.html#source) when setup needs the previous value. See guide chapter [Letting the World In](docs.html#letting-the-world-in).

```typescript
import { store, tilia } from "tilia";

type Auth = { tag: "out"; login: () => void } | { tag: "in"; logout: () => void };
const app = tilia({
  auth: store<Auth>((set) => ({ tag: "out", login: () => set({ tag: "in", logout: () => set({ tag: "out", login: () => {} }) }) })),
});
```

```rescript
open Tilia

type auth = Out({login: unit => unit}) | In({logout: unit => unit})
let app = tilia({
  auth: store(set => Out({login: () => set(In({logout: () => set(Out({login: () => ()}))}))})),
})
```
