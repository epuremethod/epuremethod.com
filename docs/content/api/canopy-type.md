---
name: Canopy
slug: canopy-type
kind: type
module: core
since: "5.2"
sort: 280
summary: Developer-inspection shape listing live and idle observed keys.
signature:
  ts: "type Canopy = { live: Set<string>; idle: Set<string> }"
  res: "type canopy = {live: Set.t<string>, idle: Set.t<string>}"
tags: []
---

`Canopy`/`canopy` is the shape used for observer-inspection results, with `live` and `idle` key sets.

`live` contains currently observed keys. `idle` contains current keys without active observers.

This type is part of the developer helper surface.

```typescript
import type { Canopy } from "tilia";

const c: Canopy = { live: new Set(["name"]), idle: new Set(["age"]) };
void c;
```

```rescript
open Tilia

let c: canopy = {live: Set.make()->Set.add("name"), idle: Set.make()->Set.add("age")}
ignore(c)
```
