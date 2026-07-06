---
title: The mental model
slug: mental-model
sort: 1
refs: [tilia]
---

tilia turns a plain object into a reactive one without changing its shape. There is no store class, no action creators, no selectors — you read and write properties exactly as you would on any JavaScript object, and tilia tracks who read what.

The library has two halves that work together: a way to make data reactive (`tilia`), and a way to react to it (`observe`, `computed`, and `useTilia` for React). Everything else in the API is built from those primitives.

### Why not a state management framework

Most state libraries ask you to describe *how* data changes: actions, reducers, dispatch. tilia instead asks you to describe *what* depends on what, and lets ordinary property access do the rest. The domain model you already have — plain objects, arrays, nested records — becomes the state layer.
