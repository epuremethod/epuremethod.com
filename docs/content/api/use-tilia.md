---
name: useTilia
slug: use-tilia
kind: hook
module: react
since: "1.0"
sort: 1
summary: Subscribe a React component to the reactive values it reads during render.
signature:
  ts: "function useTilia(): void"
  res: "let useTilia: unit => unit"
tags: []
---

Call it once at the top of a component. The render is tracked like an `observe` run: the component re-renders exactly when a property it read changes, and never otherwise. No selectors, no context providers, no memoization to get right — components read the domain directly.

```typescript
function Forest() {
  useTilia()
  return <p>{forest.trees} trees</p>
}
```

```rescript
@react.component
let make = () => {
  useTilia()
  <p> {React.int(forest.trees)} </p>
}
```
