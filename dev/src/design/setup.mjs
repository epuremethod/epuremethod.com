// Builds one scaffolded project for the whole run: `epure init` is slow
// because of its install, and every scenario here reads the same result.
//
// The dev server is tested over a real scaffold, so this reaches for
// `create-epure` — a devDependency, never a runtime one. That direction is
// the whole point of the split: the scaffolder knows about the dev server
// because the template names it, and the dev server knows about the
// scaffolder only in its tests.
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const create = resolve(here, "../create");

// The lapa packages install from the registry at the template's `beta`, as a
// scaffold gets them: run sylva's bin/publish.sh before testing a change to
// them here. Linking a checkout instead brings its own copy of `tilia`, and
// ReScript refuses a package it finds twice.
export default function setup() {
  const root = mkdtempSync(join(tmpdir(), "epure-dev-"));
  const ran = spawnSync(
    "node",
    [
      join(create, "bin/epure.mjs"),
      "init",
      "adventure",
      "--with", `@epure/dev=link:${here}`,
    ],
    { cwd: root, stdio: "inherit" },
  );
  if (ran.status !== 0) throw new Error("the shared init did not pass");
  writeFileSync(
    join(tmpdir(), "epure-dev-golden.json"),
    JSON.stringify({
      project: join(root, "adventure"),
      lapa: join(root, "adventure/node_modules/@lapa/server/bin/lapa.mjs"),
    }),
  );
  return () => rmSync(root, { recursive: true, force: true });
}
