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
const sylva = process.env.SYLVA ?? resolve(here, "../../sylva");

export default function setup() {
  const root = mkdtempSync(join(tmpdir(), "epure-dev-"));
  const ran = spawnSync(
    "node",
    [
      join(create, "bin/epure.mjs"),
      "init",
      "adventure",
      "--with", `lapa=link:${join(sylva, "packages/lapa")}`,
      "--with", `@lapa/db=link:${join(sylva, "packages/db")}`,
      "--with", `@lapa/tilia=link:${join(sylva, "packages/tilia")}`,
      "--with", `@lapa/server=link:${join(sylva, "packages/server")}`,
      "--with", `@lapa/board=link:${join(sylva, "packages/board")}`,
      "--with", `@epure/dev=link:${here}`,
    ],
    { cwd: root, stdio: "inherit" },
  );
  if (ran.status !== 0) throw new Error("the shared init did not pass");
  writeFileSync(
    join(tmpdir(), "epure-dev-golden.json"),
    JSON.stringify({
      project: join(root, "adventure"),
      lapa: join(sylva, "packages/server/bin/lapa.mjs"),
    }),
  );
  return () => rmSync(root, { recursive: true, force: true });
}
