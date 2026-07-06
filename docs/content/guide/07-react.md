---
title: Using tilia with React
slug: react
sort: 7
refs: [use-tilia]
---

`useTilia` makes a component's render function behave like an `observe` run: every reactive property read during render is tracked, and the component re-renders when one of them changes. Call it once, at the top of the component body, before any reads of reactive state.

Because tracking happens through ordinary property access, there are no selectors to write and no context providers to set up. A component reads exactly the slice of the domain it needs, and only that slice drives its re-renders.

### Lists of components

Each list item component should call `useTilia` itself rather than relying on the parent's subscription — that way, updating one item's properties re-renders only that item, not the whole list.
