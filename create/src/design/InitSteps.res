open EpureVitest
open TestCli

type file = {file: string}
type dependency = {dependency: string, \"type": string}
type layer = {directory: string}

@module("node:fs") external stat: string => {..} = "statSync"
@module("node:fs") external readDir: string => array<string> = "readdirSync"

// Enough of a document for the built page: the root element for the page
// itself, and what vite's module preload polyfill touches on load.
let ranPage: string => promise<string> = %raw(`async path => {
  const root = { textContent: "" };
  globalThis.document = {
    getElementById: id => (id === "root" ? root : null),
    createElement: () => ({ relList: { supports: () => false } }),
    querySelectorAll: () => [],
    head: { appendChild: () => {} },
    addEventListener: () => {},
  };
  globalThis.MutationObserver = class { observe() {} disconnect() {} };
  await import(path);
  delete globalThis.document;
  delete globalThis.MutationObserver;
  return root.textContent;
}`)

given("an empty working directory", ({step}, context: testContext) => {
  let scratch: ref<option<string>> = ref(None)
  let last: ref<option<ran>> = ref(None)

  context.onTestFinished(async _ => scratch.contents->Option.forEach(System.forget))

  let place = () =>
    switch scratch.contents {
    | Some(root) => root
    | None => {
        let root = System.scratch()
        scratch := Some(root)
        root
      }
    }

  let root = () =>
    switch scratch.contents {
    | Some(root) => root
    | None => System.parent(golden().project)
    }

  let at = path => System.joined(root(), path)

  let project = () => golden().project

  let manifest = () =>
    JSON.parseOrThrow(System.readFile(System.joined(project(), "package.json"), "utf8"))

  let section = name =>
    switch manifest() {
    | JSON.Object(fields) =>
      switch fields->Dict.get(name) {
      | Some(JSON.Object(deps)) => deps->Dict.keysToArray
      | _ => []
      }
    | _ => []
    }

  let runs = (script, ~name) => {
    let ran = System.runSync(
      "pnpm",
      [script],
      {"cwd": project(), "stdio": "pipe", "encoding": "utf8"},
    )
    let status = Nullable.toOption(ran["status"])->Option.getOr(-1)
    if status != 0 {
      Console.error(`${name} failed:`)
      Console.error(ran["stdout"])
      Console.error(ran["stderr"])
    }
    status
  }

  step("Theo initializes a project named {string}", async (name: string) =>
    switch scratch.contents {
    | Some(root) => last := Some(await TestCli.runs(["init", name], ~at=root))
    | None => ()
    }
  )

  step("Theo creates a project named {string} with no command", async (name: string) =>
    last := Some(await TestCli.runs([name]->Array.concat(TestCli.links), ~at=place()))
  )

  step("{string} names the project {string}", (path: string, name: string) =>
    switch JSON.parseOrThrow(System.readFile(at(path), "utf8")) {
    | JSON.Object(fields) => expect(fields->Dict.get("name")).toEqual(Some(JSON.String(name)))
    | _ => expect(path).toBe("an object")
    }
  )

  step(
    "Theo initializes a project named {string} against {string}",
    async (name: string, registry: string) =>
      last :=
        Some(
          await TestCli.runs(
            ["init", name, "--registry", registry]->Array.concat(TestCli.links),
            ~at=place(),
          ),
        ),
  )

  step("{string} does not exist", (path: string) =>
    expect((path, System.exists(at(path)))).toEqual((path, false))
  )

  step("{string} exists", (path: string) =>
    expect((path, System.exists(at(path)))).toEqual((path, true))
  )

  step("{string} contains the method files", (dir: string, table: array<array<string>>) =>
    toRecords(table)->Array.forEach(
      (row: file) =>
        expect((row.file, System.exists(at(System.joined(dir, row.file))))).toEqual((
          row.file,
          true,
        )),
    )
  )

  step("{string} contains the stack dependencies", (_: string, table: array<array<string>>) => {
    let held = (section("dependencies"), section("devDependencies"))
    toRecords(table)->Array.forEach(
      (row: dependency) => {
        let (dependencies, devDependencies) = held
        let where = row.\"type" == "dev dependency" ? devDependencies : dependencies
        expect((row.dependency, where->Array.includes(row.dependency))).toEqual((
          row.dependency,
          true,
        ))
      },
    )
  })

  step("{string} contains {string}", (path: string, text: string) =>
    expect(System.readFile(at(path), "utf8")).toContain(text)
  )

  // A layer must hold at least one file: git carries no empty directory,
  // and a fresh checkout must still build.
  step("{string} contains the diagonal layout", (dir: string, table: array<array<string>>) =>
    toRecords(table)->Array.forEach(
      (row: layer) => {
        let path = at(System.joined(dir, row.directory))
        let holds =
          System.exists(path) && stat(path)["isDirectory"]() && readDir(path)->Array.length > 0
        expect((row.directory, holds)).toEqual((row.directory, true))
      },
    )
  )

  step("the project dependencies are installed", () =>
    expect(System.exists(System.joined(project(), "node_modules"))).toBe(true)
  )

  step("the project builds successfully", () => expect(runs("build", ~name="build")).toBe(0))

  step("the project tests pass", () => expect(runs("test", ~name="test")).toBe(0))

  step("the built page says {string}", async (text: string) => {
    expect(runs("build", ~name="build")).toBe(0)
    let page = System.readFile(System.joined(project(), "dist/index.html"), "utf8")
    let asset = switch page->String.match(/\/assets\/[^\"]+\.js/) {
    | Some(result) => result->RegExp.Result.fullMatch
    | None => JsError.throwWithMessage("the built page names no script")
    }
    let said = await ranPage("file://" ++ System.joined(project(), "dist" ++ asset))
    expect(said).toContain(text)
  })

  step("the {string} directory contains a file", (name: string) => {
    let dir = System.joined(place(), name)
    System.mkdir(dir, {"recursive": true})
    System.writeFile(System.joined(dir, "kept.txt"), "kept")
  })

  step("init fails and reports {string}", (name: string) => {
    let ran = switch last.contents {
    | Some(ran) => ran
    | None => JsError.throwWithMessage("init did not run")
    }
    expect(ran.code == 0).toBe(false)
    expect(ran.complained).toContain(name)
  })
})
