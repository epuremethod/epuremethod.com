import { epureVitest } from "@epure/vitest";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [epureVitest({ concurrent: false })],
  test: {
    include: ["src/design/**/*.feature"],
    globalSetup: ["src/design/setup.mjs"],
    fileParallelism: false,
    testTimeout: 300000,
    hookTimeout: 300000,
  },
});
