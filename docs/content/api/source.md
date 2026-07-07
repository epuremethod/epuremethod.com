---
name: source
slug: source
kind: function
module: core
since: "2.0"
sort: 70
summary: Define an inserted value managed by previous-plus-set setup logic.
signature:
  ts: "function source<T>(initialValue: T, fn: (previous: T, set: Setter<T>) => unknown): T"
  res: "let source: ('a, ('a, 'a => unit) => 'ignored) => 'a"
tags: []
---

`source` creates a dynamic value for insertion in a reactive object. It starts from `initialValue`, then executes `fn(previous, set)` on first read and whenever tracked dependencies in `fn` change.

`previous` is the latest value held by the source, and `set` updates it. If `fn` does asynchronous work, dependencies must still be read synchronously before awaiting; only synchronous reads are tracked.

If dependencies change, the current value stays available until `set` is called again. See [store](api.html#store), [carve](api.html#carve), and guide chapter [Letting the World In](docs.html#letting-the-world-in).

```typescript
import { signal, source, tilia } from "tilia";

const [url, setUrl] = signal("helena");
const app = tilia({
  name: source("Medea", (previous, set) => {
    set(url.value === "helena" ? `${previous}+Helena` : `${previous}+Other`);
  }),
});

setUrl("other");
app.name;
```

```rescript
open Tilia

let (url, setUrl) = signal("helena")
let app = tilia({
  name: source("Medea", (previous, set) => {
    set(url.value === "helena" ? `${previous}+Helena` : `${previous}+Other`)
  }),
})

setUrl("other")
ignore(app.name)
```
