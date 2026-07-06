---
title: Getting started
slug: getting-started
sort: 2
refs: [tilia]
---

Install the package with your package manager of choice:

```typescript
npm install tilia
```

```rescript
// bun add tilia
// or add "tilia" to bs-dependencies in rescript.json
```

Wrap any plain object with `tilia` to make it reactive, then read and write it like normal. The proxy tilia returns has the exact same shape and type as the value you passed in, so existing code that already works with plain objects keeps working unchanged.

### A minimal example

A forest with a tree count is enough to see the whole loop: create, read, write.
