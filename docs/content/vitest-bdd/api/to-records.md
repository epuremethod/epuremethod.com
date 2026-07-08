---
name: toRecords
slug: to-records
kind: function
module: core
since: "0.6"
sort: 30
summary: Convert a Gherkin data table into records keyed by its header row.
signature:
  ts: "function toRecords(table: string[][]): Record<string, string>[]"
  res: "let toRecords: array<array<string>> => array<'a>"
tags: []
---

A data table reaches a step as raw rows of strings. `toRecords` reads the first row as field names and returns one record per remaining row — the shape assertions want when comparing against a list of domain objects. Values stay strings; parse them where the domain requires numbers or booleans. See also [toStrings](api.html#to-strings) and [toNumbers](api.html#to-numbers), and guide chapter [Tables and other tongues](docs.html#tables-and-other-tongues).

```typescript
import { Given, toRecords } from "vitest-bdd";

Given("I have a table", ({ When, Then }, data) => {
  const table = makeTable(toRecords(data));

  When("I sort by {string}", table.sort);
  Then("the table is", (expected) => {
    expect(table.list).toEqual(toRecords(expected));
  });
});
```

```rescript
open VitestBdd

given("I have a table", ({step}, data) => {
  let table = Table.make(toRecords(data))

  step("I sort by {string}", table.sort)
  step("the table is", expected => {
    expect(table.list).toEqual(toRecords(expected))
  })
})
```
