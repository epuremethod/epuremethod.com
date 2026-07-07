---
name: Changes
slug: changes-type
kind: type
module: core
since: "5.2"
sort: 260
summary: Batched write payload containing upserted rows and removed keys.
signature:
  ts: |-
    type Changes<T> {
      upsert: T[];
      remove: string[]
    }
  res: |-
    type changes<'a> = {
      upsert: array<'a>,
      remove: array<string>
    }
tags: [deprecated]
---

`Changes<T>`/`changes<'a>` is deprecated with [changing](api.html#changing). Prefer feature-level mutate actions and `tilia/query` flows.

`Changes<T>`/`changes<'a>` is the payload produced by `changing().changes()` and delivered through [watch](api.html#watch).

`upsert` carries row objects captured at write time. `remove` carries deleted keys.

See [changing](api.html#changing) and [Changing](api.html#changing-type).

```typescript
import type { Changes } from "tilia";

const c: Changes<{ qty: number }> = { upsert: [{ qty: 1 }], remove: ["old"] };
void c;
```

```rescript
open Tilia

let c: changes<{qty: int}> = {upsert: [{qty: 1}], remove: ["old"]}
ignore(c)
```
