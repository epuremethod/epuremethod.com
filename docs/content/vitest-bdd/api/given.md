---
name: Given
slug: given
kind: function
module: core
since: "0.1"
sort: 20
summary: Bind a Given pattern to a builder that creates the scenario's context and its steps.
signature:
  ts: "function Given(pattern: string, build: (steps: Context, ...params: Param[]) => void | Promise<void>): void"
  res: "let given: (string, (given, 'a) => unit) => unit"
tags: []
---

`Given` is the single entry point of a steps file. The pattern uses Cucumber expressions — `{string}` and `{number}` capture parameters — and the builder runs once per scenario, receiving the step-binding context first, then the captured parameters, then the Vitest `TestContext` last. Everything the scenario needs is created inside the builder, and every `When`/`Then` the builder registers closes over it — no world object, no shared state between scenarios. See [Step](api.html#step-type) for the context's shape, and guide chapter [Steps close over the world](docs.html#steps-close-over-the-world).

The builder may be `async`: the runner awaits it before executing steps. In ReScript, `given` captures at most one parameter — capture further values in a step or pass a table.

```typescript
import { expect } from "vitest";
import { Given } from "vitest-bdd";
import { makeCalculator } from "../feature/calculator";

Given("I have a {string} calculator", ({ When, Then }, name: string) => {
  const calculator = makeCalculator(name);

  When("I add {number} and {number}", calculator.add);
  Then("the result is {number}", (n: number) => {
    expect(calculator.result).toBe(n);
  });
});
```

```rescript
open VitestBdd

given("I have a {string} calculator", ({step}, name: string) => {
  let calculator = Calculator.make(name)

  step("I add {number} and {number}", calculator.add)
  step("the result is {number}", (n: float) => {
    expect(calculator.result).toBe(n)
  })
})
```
