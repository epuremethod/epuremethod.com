open EpureVitest
open TestCli

// Dev.feature drives the real pair: `epure-dev` spawned over the shared
// scaffold, lapa reached only through vite's proxy, and death and stopping
// exercised on the real processes.

@val external later: (unit => unit, int) => unit = "setTimeout"
@val external encode: string => string = "encodeURIComponent"
@val external assign: (dict<string>, dict<string>) => dict<string> = "Object.assign"
@val @scope("process") external processEnv: dict<string> = "env"

type response = {status: int}
@send external text: response => promise<string> = "text"
type init = {@as("method") method_?: string, headers?: dict<string>, body?: string}
@val external fetch: (string, init) => promise<response> = "fetch"
@val external gets: string => promise<response> = "fetch"

type socket
@new external connect: string => socket = "WebSocket"
@set external whenOpen: (socket, unit => unit) => unit = "onopen"
@set external whenMessage: (socket, {"data": string} => unit) => unit = "onmessage"
@send external closes: socket => unit = "close"

let raise = message => JsError.throwWithMessage(message)

let settle = ms => Promise.make((resolve, _reject) => later(() => resolve(), ms))

let rec until = async (check, ~left=150) =>
  if !(await check()) {
    if left == 0 {
      raise("nothing answered in time")
    }
    await settle(100)
    await until(check, ~left=left - 1)
  }

let app = "http://127.0.0.1:8080"

let answers = async route =>
  switch await gets(app ++ route) {
  | response => Some(response)
  | exception JsExn(_) => None
  }

type served = {
  child: System.child,
  said: ref<string>,
  complained: ref<string>,
  session: ref<string>,
  code: ref<string>,
  gone: ref<bool>,
  exit: ref<int>,
}

let wordAfter = (words, name) =>
  words->Array.findMap(word =>
    word->String.startsWith(name ++ "=")
      ? Some(word->String.slice(~start=String.length(name) + 1))
      : None
  )

given("a project created by init that nothing serves", ({step}, context: testContext) => {
  let where = golden()
  let project = where.project
  let data = System.joined(project, ".data")
  System.forget(data)

  let current: ref<option<served>> = ref(None)
  let listening: ref<option<(socket, array<string>)>> = ref(None)
  let lastStatus = ref(0)
  let lastBody = ref("")

  let running = () =>
    switch current.contents {
    | Some(server) => server
    | None => raise("no dev was started")
    }

  context.onTestFinished(async _ => {
    listening.contents->Option.forEach(((socket, _)) => socket->closes)
    switch current.contents {
    | Some(server) if !server.gone.contents => {
        let quiet = Promise.make(
          (resolve, _reject) => server.child->System.whenGone(_ => resolve()),
        )
        server.child->System.signal("SIGTERM")->ignore
        await quiet
      }
    | _ => ()
    }
    System.forget(data)
  })

  let starts = async () => {
    let env = assign(Dict.make(), processEnv)
    env->Dict.set("EPURE_LAPA_BIN", where.lapa)
    let server = {
      child: System.run("node", [entry], {"cwd": project, "env": env}),
      said: ref(""),
      complained: ref(""),
      session: ref(""),
      code: ref(""),
      gone: ref(false),
      exit: ref(-1),
    }
    open System
    let hear = text => {
      server.said := server.said.contents ++ text
      server.said.contents
      ->String.split("\n")
      ->Array.find(line => line->String.startsWith("dev "))
      ->Option.forEach(line => {
        let words = line->String.trim->String.split(" ")
        wordAfter(words, "session")->Option.forEach(token => server.session := token)
        wordAfter(words, "code")->Option.forEach(code => server.code := code)
      })
    }
    server.child->out->reads("utf8")
    server.child->out->hears("data", hear)
    server.child->err->reads("utf8")
    server.child
    ->err
    ->hears("data", text => server.complained := server.complained.contents ++ text)
    server.child->whenGone(code => {
      server.gone := true
      server.exit := code->Nullable.getOr(-1)
    })
    current := Some(server)
    await until(async () => server.session.contents != "" || server.gone.contents)
    await until(async () => (await answers("/"))->Option.isSome || server.gone.contents)
    if server.gone.contents {
      raise("dev stopped early: " ++ server.complained.contents ++ server.said.contents)
    }
    server
  }

  let meta = name =>
    switch JSON.parseOrThrow(System.readFile(System.joined(data, "dev.json"), "utf8")) {
    | JSON.Object(fields) =>
      switch fields->Dict.get(name) {
      | Some(JSON.String(value)) => value
      | _ => raise(`dev.json names no ${name}`)
      }
    | _ => raise("dev.json is not an object")
    }

  let asks = async (route, ~method=?, ~token=?, ~sent=?) => {
    let headers = Dict.make()
    token->Option.forEach(token => headers->Dict.set("Authorization", token))
    switch await fetch(app ++ route, {method_: ?method, headers, body: ?sent}) {
    | response => {
        lastStatus := response.status
        lastBody := (await response->text)
      }
    | exception JsExn(_) => {
        lastStatus := 0
        lastBody := ""
      }
    }
  }

  let posts = async (route, ~token=?, message) =>
    await asks(route, ~method="POST", ~token?, ~sent=JSON.stringify(message))

  let calls = async (route, name, arguments) =>
    await posts(
      route,
      ~token=running().session.contents,
      JSON.Object(
        Dict.fromArray([
          ("jsonrpc", JSON.String("2.0")),
          ("id", JSON.Number(1.0)),
          ("method", JSON.String("tools/call")),
          (
            "params",
            JSON.Object(Dict.fromArray([("name", JSON.String(name)), ("arguments", arguments)])),
          ),
        ]),
      ),
    )

  step("Theo runs dev", async () => (await starts())->ignore)

  step("a running dev", async () => (await starts())->ignore)

  step("the app page answers on the app port", async () => {
    await asks("/")
    expect(lastStatus.contents).toBe(200)
    expect(lastBody.contents).toContain("adventure")
  })

  step("dev prints the code", () => {
    expect(running().code.contents->String.length > 0).toBe(true)
  })

  // ── the link ──────────────────────────────────────────────────────────

  // Dev writes the link only once the app answers, so it can arrive after
  // `starts` has returned. Vite prints an address of its own on the same
  // stream, so the session is what tells dev's line from it.
  let linesWithLink = () =>
    running().said.contents
    ->String.split("\n")
    ->Array.filter(line => line->String.includes("?lapa-session="))

  let awaitsLink = async () => {
    await until(async () => linesWithLink()->Array.length > 0)
    linesWithLink()->Array.getUnsafe(0)
  }

  let linkIn = line =>
    line
    ->String.trim
    ->String.split(" ")
    ->Array.find(word => word->String.startsWith("http://"))
    ->Option.getOrThrow

  let link = async () => linkIn(await awaitsLink())

  step("dev prints one link", async () => {
    let _ = await awaitsLink()
    expect(linesWithLink()->Array.length).toBe(1)
  })

  step("the link is the app page on the app port", async () => {
    let address = await link()
    expect(address->String.startsWith("http://localhost:8080/")).toBe(true)
  })

  step("the link carries the session as {string}", async (name: string) => {
    let address = await link()
    expect(address->String.includes(`?${name}=`)).toBe(true)
  })

  step("the link begins with {string}", async (scheme: string) =>
    expect((await link())->String.startsWith(scheme)).toBe(true)
  )

  step("the line holding the link names the project", async () => {
    let line = await awaitsLink()
    expect(line).toContain(System.named(golden().project))
  })

  step("fetching the link answers the app page", async () => {
    let address = await link()
    let answer = await gets(address)
    expect(answer.status).toBe(200)
    expect(await answer->text).toContain("adventure")
  })

  step("the link carries the session dev printed", async () => {
    let address = await link()
    expect(address).toContain(running().session.contents)
  })

  step("a client pulling with that session answers the boot's rows", async () => {
    let address = await link()
    let token =
      address
      ->String.split("lapa-session=")
      ->Array.getUnsafe(1)
      ->String.split("&")
      ->Array.getUnsafe(0)
    await asks(`/_lapa/query?under=${encode(meta("workspace"))}`, ~token)
  })

  step("a client pulls through {string} with the founder's session", async (prefix: string) =>
    await asks(
      `${prefix}query?under=${encode(meta("workspace"))}`,
      ~token=running().session.contents,
    )
  )

  step("the pull answers the boot's rows", () => {
    expect(lastStatus.contents).toBe(200)
    expect(lastBody.contents).toContain("entities")
  })

  step("the agent lists the tools at {string} with the founder's session", async (route: string) =>
    await posts(
      route,
      ~token=running().session.contents,
      JSON.Object(
        Dict.fromArray([
          ("jsonrpc", JSON.String("2.0")),
          ("id", JSON.Number(1.0)),
          ("method", JSON.String("tools/list")),
        ]),
      ),
    )
  )

  step("the desk's tools answer", () => {
    expect(lastStatus.contents).toBe(200)
    expect(lastBody.contents).toContain("define")
    expect(lastBody.contents).toContain("export")
  })

  step("the agent lists the tools at {string} with no session", async (route: string) =>
    await posts(
      route,
      JSON.Object(
        Dict.fromArray([
          ("jsonrpc", JSON.String("2.0")),
          ("id", JSON.Number(1.0)),
          ("method", JSON.String("tools/list")),
        ]),
      ),
    )
  )

  step("the answer is a refusal", () => expect(lastStatus.contents).toBe(403))

  step("a client listening through {string}", async (prefix: string) => {
    let heard: array<string> = []
    let socket = connect(`ws://127.0.0.1:8080${prefix}listen?session=${running().session.contents}`)
    let opened = ref(false)
    socket->whenOpen(() => opened := true)
    socket->whenMessage(message => heard->Array.push(message["data"]))
    listening := Some((socket, heard))
    await until(async () => opened.contents)
  })

  step("the agent makes an entity at {string}", async (route: string) => {
    await calls(
      route,
      "define",
      JSON.Object(
        Dict.fromArray([
          (
            "classes",
            JSON.Array([
              JSON.Object(
                Dict.fromArray([
                  ("title", JSON.String("Adventure")),
                  (
                    "fields",
                    JSON.Array([
                      JSON.Object(
                        Dict.fromArray([
                          ("title", JSON.String("price")),
                          ("kind", JSON.String("Number")),
                        ]),
                      ),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    )
    expect(lastStatus.contents).toBe(200)
    await calls(
      route,
      "make",
      JSON.Object(
        Dict.fromArray([
          ("class", JSON.String("Adventure")),
          ("title", JSON.String("Raft Run")),
          (
            "parts",
            JSON.Object(
              Dict.fromArray([
                (
                  "Adventure",
                  JSON.Object(
                    Dict.fromArray([
                      ("price", JSON.Object(Dict.fromArray([("n", JSON.Number(12.0))]))),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    )
    expect(lastStatus.contents).toBe(200)
  })

  step("the client hears a stamp", async () => {
    let (_, heard) = switch listening.contents {
    | Some(listener) => listener
    | None => raise("no client is listening")
    }
    await until(async () => heard->Array.length > 0)
  })

  step("the client's pull answers the entity", async () => {
    await asks(`/_lapa/query?under=${encode(meta("workspace"))}`, ~token=running().session.contents)
    expect(lastStatus.contents).toBe(200)
    expect(lastBody.contents).toContain("Raft Run")
  })

  step("Theo changes the page's text to {string}", (text: string) => {
    let page = System.joined(project, "src/view/Page.res")
    let original = System.readFile(page, "utf8")
    context.onTestFinished(async _ => System.writeFile(page, original))
    // The sentence the page says when it opens on no session: the one line
    // of its own text that a scaffold is born with.
    let said = "this page opens on a session"
    if !(original->String.includes(said)) {
      JsError.throwWithMessage(`the page no longer says "${said}"`)
    }
    System.writeFile(page, original->String.replace(said, text))
  })

  step("the served page script says {string}", async (wanted: string) =>
    await until(
      async () =>
        switch await answers("/src/view/Page.res.mjs") {
        | Some(response) if response.status == 200 =>
          (await response->text)->String.includes(wanted)
        | _ => false
        },
    )
  )

  step("Theo runs dev without a lapa binary", async () => {
    let env = assign(Dict.make(), processEnv)
    env->Dict.delete("EPURE_LAPA_BIN")
    let child = System.run("node", [entry], {"cwd": project, "env": env})
    let complained = ref("")
    open System
    child->err->reads("utf8")
    child->err->hears("data", text => complained := complained.contents ++ text)
    let exit = await Promise.make(
      (resolve, _reject) => child->whenGone(code => resolve(code->Nullable.getOr(-1))),
    )
    lastStatus := exit
    lastBody := complained.contents
  })

  step("dev exits and says lapa is missing", () => {
    expect(lastStatus.contents == 0).toBe(false)
    expect(lastBody.contents).toContain("lapa")
  })

  step("the compiler is not left running", () => {
    let built = System.runSync(
      System.joined(project, "node_modules/.bin/rescript"),
      ["build"],
      {"cwd": project, "stdio": "pipe", "encoding": "utf8"},
    )
    let status = Nullable.toOption(built["status"])->Option.getOr(-1)
    if status != 0 {
      Console.error(built["stdout"])
      Console.error(built["stderr"])
    }
    expect(status).toBe(0)
  })

  step("Theo sends SIGTERM to dev", async () => {
    let server = running()
    let quiet = Promise.make((resolve, _reject) => server.child->System.whenGone(_ => resolve()))
    server.child->System.signal("SIGTERM")->ignore
    await quiet
  })

  step("dev exits with {number}", (expected: float) => {
    expect(running().gone.contents).toBe(true)
    expect(running().exit.contents).toBe(expected->Float.toInt)
  })

  step("the app port no longer answers", async () =>
    await until(async () => (await answers("/"))->Option.isNone)
  )

  step("the data directory is free to serve again", async () => {
    let probe = System.run(where.lapa, ["dev", ".data", "--port", "0"], {"cwd": project})
    let said = ref("")
    open System
    probe->out->reads("utf8")
    probe->out->hears("data", text => said := said.contents ++ text)
    await until(async () => said.contents->String.includes("dev "))
    let quiet = Promise.make((resolve, _reject) => probe->whenGone(_ => resolve()))
    probe->signal("SIGTERM")->ignore
    await quiet
  })

  step("lapa dev dies", async () => {
    System.runSync("pkill", ["-9", "-f", "lapa.mjs dev .data"], {"stdio": "ignore"})->ignore
    let server = running()
    await until(async () => server.gone.contents)
  })

  step("dev exits and says lapa stopped", () => {
    expect(running().gone.contents).toBe(true)
    expect(running().exit.contents == 0).toBe(false)
    expect(running().complained.contents).toContain("lapa stopped")
  })
})
