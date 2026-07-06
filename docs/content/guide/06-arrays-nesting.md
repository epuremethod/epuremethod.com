---
title: Arrays and nesting
slug: arrays-nesting
sort: 6
refs: [tilia]
---

Arrays passed to `tilia`, or assigned into a reactive object later, become reactive the same way plain objects do. Reading `list.length`, iterating with `map` or `forEach`, and indexing by position are all tracked individually, so an observer that only reads `list[0]` does not re-run when you push a new item at the end.

Nesting works the same way at any depth: a reactive object's nested objects and arrays are wrapped lazily on first access, not eagerly at creation. This keeps `tilia(value)` cheap even for large trees, since only the parts you actually read pay the proxy cost.

### Replacing vs. mutating

Both `list.push(item)` and `list = [...list, item]` notify observers of `list`, but only the first also preserves identity for anything holding a reference to the array itself. Prefer in-place mutation when other code depends on referential stability of the array.
