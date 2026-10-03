// Builds one scaffolded project for the whole run: `epure init` is slow
// because of its install, and every scenario reads the same result. The
// refusal scenario runs its own init; nothing else re-runs it.
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { links } from "./TestCli.mjs";

const create = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

export default function setup() {
  const root = mkdtempSync(join(tmpdir(), "epure-"));
  const ran = spawnSync(
    "node",
    [
      join(create, "bin/epure.mjs"),
      "init",
      "adventure",
      ...links,
    ],
    { cwd: root, stdio: "inherit" },
  );
  if (ran.status !== 0) throw new Error("the shared init did not pass");
  writeFileSync(
    join(tmpdir(), "epure-golden.json"),
    JSON.stringify({
      project: join(root, "adventure"),
      lapa: join(root, "adventure/node_modules/@lapa/server/bin/lapa.mjs"),
    }),
  );
  return () => rmSync(root, { recursive: true, force: true });
}
