open EpureVitest
open TestCli

// A registry of our own. The feature is about which line sync follows and
// what range it writes, so the answers are served here: no network, and a
// scenario can say "not published" without unpublishing anything.

type dependency = {dependency: string, \"type": string}

@module("semver") external satisfies: (string, string) => bool = "satisfies"

type request = {url: string}
type reply
type server
@module("node:http") external serve: ((request, reply) => unit) => server = "createServer"
@send external listens: (server, int, string, unit => unit) => unit = "listen"
@send external shuts: (server, unit => unit) => unit = "close"
@send external at: server => {"port": int} = "address"
@send external heads: (reply, int, dict<string>) => unit = "writeHead"
@send external ends: (reply, string) => unit = "end"
@val external decode: string => string = "decodeURIComponent"

let raise = message => JsError.throwWithMessage(message)

let sections = ["dependencies", "devDependencies"]

let specs = (file): dict<string> => {
  let found = Dict.make()
  switch JSON.parseOrThrow(System.readFile(file, "utf8")) {
  | JSON.Object(fields) =>
    sections->Array.forEach(section =>
      switch fields->Dict.get(section) {
      | Some(JSON.Object(deps)) =>
        deps
        ->Dict.toArray
        ->Array.forEach(((package, spec)) =>
          switch spec {
          | JSON.String(spec) => found->Dict.set(package, spec)
          | _ => ()
          }
        )
      | _ => ()
      }
    )
  | _ => ()
  }
  found
}

let named = (file, package) =>
  switch specs(file)->Dict.get(package) {
  | Some(spec) => spec
  | None => raise(`the template names no ${package}`)
  }

given("a registry answering for the template's dependencies", ({step, test: context}) => {
  let scratch = System.scratch()
  let template = System.joined(scratch, "package.json")
  System.writeFile(
    template,
    System.readFile(System.joined(package, "templates/package.json"), "utf8"),
  )
  let before = System.readFile(template, "utf8")

  // package -> tag -> version. A package absent from this answers 404.
  let published: dict<dict<string>> = Dict.make()
  specs(template)
  ->Dict.keysToArray
  ->Array.forEach(name =>
    published->Dict.set(name, Dict.fromArray([("latest", "1.2.3"), ("beta", "1.2.3-beta.4")]))
  )

  let answering = ref(true)
  let listener = serve((request, reply) => {
    let name = decode(request.url)->String.slice(~start=1)
    switch published->Dict.get(name) {
    | Some(tags) => {
        reply->heads(200, Dict.fromArray([("content-type", "application/json")]))
        reply->ends(
          JSON.stringify(
            JSON.Object(
              Dict.fromArray([
                ("name", JSON.String(name)),
                (
                  "dist-tags",
                  JSON.Object(
                    tags
                    ->Dict.toArray
                    ->Array.map(((tag, version)) => (tag, JSON.String(version)))
                    ->Dict.fromArray,
                  ),
                ),
              ]),
            ),
          ),
        )
      }
    | None => {
        reply->heads(404, Dict.fromArray([("content-type", "application/json")]))
        reply->ends("{}")
      }
    }
  })

  let port = ref(0)
  let listening = Promise.make((resolve, _reject) =>
    listener->listens(0, "127.0.0.1", () => {
      port := (listener->at)["port"]
      resolve()
    })
  )

  let ran = ref({said: "", complained: "", code: 0})

  context.onTestFinished(async _ => {
    if answering.contents {
      await Promise.make((resolve, _reject) => listener->shuts(() => resolve()))
    }
    System.forget(scratch)
  })

  let sets = (package, tag, version) =>
    switch published->Dict.get(package) {
    | Some(tags) => tags->Dict.set(tag, version)
    | None => published->Dict.set(package, Dict.fromArray([(tag, version)]))
    }

  let served = package =>
    switch published->Dict.get(package) {
    | Some(tags) =>
      switch (tags->Dict.get("latest"), tags->Dict.get("beta")) {
      | (Some(version), _) => version
      | (None, Some(version)) => version
      | _ => raise(`nothing is published for ${package}`)
      }
    | None => raise(`nothing is published for ${package}`)
    }

  step("{string} is published at {string}", (package: string, version: string) => {
    sets(package, "latest", version)
    sets(package, "beta", version)
  })

  step(
    "{string} is published at {string} as {string}",
    (package: string, version: string, tag: string) => sets(package, tag, version),
  )

  step(
    "{string} is published at {string} as {string} only",
    (package: string, version: string, tag: string) =>
      published->Dict.set(package, Dict.fromArray([(tag, version)])),
  )

  step("{string} is not published", (package: string) => published->Dict.delete(package))

  step("the registry does not answer", async () => {
    await listening
    await Promise.make((resolve, _reject) => listener->shuts(() => resolve()))
    answering := false
  })

  step("the template already names {string} at {string}", (package: string, spec: string) => {
    let json = JSON.parseOrThrow(System.readFile(template, "utf8"))
    switch json {
    | JSON.Object(fields) =>
      sections->Array.forEach(section =>
        switch fields->Dict.get(section) {
        | Some(JSON.Object(deps)) if deps->Dict.get(package)->Option.isSome =>
          deps->Dict.set(package, JSON.String(spec))
        | _ => ()
        }
      )
    | _ => ()
    }
    System.writeFile(template, JSON.stringify(json, ~space=2) ++ "\n")
  })

  step("the template is synced", async () => {
    await listening
    ran :=
      (
        await runs(
          [
            "--registry",
            `http://127.0.0.1:${port.contents->Int.toString}`,
            "--template",
            template,
          ],
          ~at=scratch,
          ~entry=System.joined(package, "bin/sync.mjs"),
        )
      )
  })

  step("the template names {string} at {string}", (name: string, spec: string) =>
    expect(named(template, name)).toBe(spec)
  )

  step("the template names each dependency at a published version", (table: array<array<string>>) =>
    toRecords(table)->Array.forEach((row: dependency) => {
      let spec = named(template, row.dependency)
      let tagged = switch published->Dict.get(row.dependency) {
      | Some(tags) => tags->Dict.get(spec)->Option.isSome
      | None => false
      }
      expect((row.dependency, tagged || satisfies(served(row.dependency), spec))).toEqual((
        row.dependency,
        true,
      ))
    })
  )

  step("the template still names the project {string}", (name: string) =>
    switch JSON.parseOrThrow(System.readFile(template, "utf8")) {
    | JSON.Object(fields) => expect(fields->Dict.get("name")).toEqual(Some(JSON.String(name)))
    | _ => raise("the template is not an object")
    }
  )

  step("the template still holds its scripts", () =>
    switch JSON.parseOrThrow(System.readFile(template, "utf8")) {
    | JSON.Object(fields) =>
      switch fields->Dict.get("scripts") {
      | Some(JSON.Object(scripts)) => expect(scripts->Dict.get("dev")->Option.isSome).toBe(true)
      | _ => raise("the template holds no scripts")
      }
    | _ => raise("the template is not an object")
    }
  )

  step("sync fails and reports {string}", (text: string) => {
    expect(ran.contents.code == 0).toBe(false)
    expect(ran.contents.complained).toContain(text)
  })

  step("sync fails and reports the registry", () => {
    expect(ran.contents.code == 0).toBe(false)
    expect(ran.contents.complained).toContain("127.0.0.1")
  })

  step("the template is unchanged", () =>
    expect(System.readFile(template, "utf8")).toBe(before)
  )
})
