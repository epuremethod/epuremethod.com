import { epureVitest } from "@epure/vitest";
import { defineConfig } from "vitest/config";

// Scenarios are the tests: every `.feature` under `src/design/` runs, with
// its steps in the `Steps.res` beside it.
export default defineConfig({
  plugins: [epureVitest()],
  test: {
    include: ["src/design/**/*.feature"],
  },
});
