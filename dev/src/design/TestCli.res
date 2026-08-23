module System = {
  type child
  type stream

  @module("node:child_process") external run: (string, array<string>, 'a) => child = "spawn"
  @module("node:child_process") external runSync: (string, array<string>, 'a) => 'b = "spawnSync"
  @get external out: child => stream = "stdout"
  @get external err: child => stream = "stderr"
  @send external reads: (stream, string) => unit = "setEncoding"
  @send external hears: (stream, string, string => unit) => unit = "on"
  @send external whenGone: (child, @as("close") _, Nullable.t<int> => unit) => unit = "on"
  @send external signal: (child, string) => bool = "kill"

  @module("node:fs") external readFile: (string, string) => string = "readFileSync"
  @module("node:fs") external writeFile: (string, string) => unit = "writeFileSync"
  @module("node:fs")
  external removeDir: (string, {"recursive": bool, "force": bool}) => unit = "rmSync"
  @module("node:os") external tempRoot: unit => string = "tmpdir"
  @module("node:path") external joined: (string, string) => string = "join"
  @module("node:path") external resolved: (string, string) => string = "resolve"
  @module("node:path") external parent: string => string = "dirname"
  @module("node:path") external named: string => string = "basename"

  let forget = path => removeDir(path, {"recursive": true, "force": true})
}

@val external importUrl: string = "import.meta.url"
@module("node:url") external fileOf: string => string = "fileURLToPath"

let package = System.resolved(System.parent(fileOf(importUrl)), "../..")

/** The dev server's own bin. It takes no subcommand: the package is the
    command. */
let entry = System.joined(package, "bin/epure-dev.mjs")

type golden = {project: string, lapa: string}

/** The scaffold `setup.mjs` built once for the whole run, and the lapa binary
    it is served by. */
let golden = () =>
  switch JSON.parseOrThrow(
    System.readFile(System.joined(System.tempRoot(), "epure-dev-golden.json"), "utf8"),
  ) {
  | JSON.Object(fields) =>
    switch (fields->Dict.get("project"), fields->Dict.get("lapa")) {
    | (Some(JSON.String(project)), Some(JSON.String(lapa))) => {project, lapa}
    | _ => JsError.throwWithMessage("the shared init names no project")
    }
  | _ => JsError.throwWithMessage("no shared init was built")
  }
