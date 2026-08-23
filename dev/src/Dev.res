// `epure-dev`: `rescript watch`, `lapa dev .data --port 8081` and vite,
// three processes as one. The template's vite.config.mjs holds the ports
// and the proxy; this file only starts, watches and stops. The `lapa`
// binary comes from PATH, or from EPURE_LAPA_BIN for a checkout
// (SESSION.md).
//
// This is its own package because a scaffolded app runs it every day and runs
// `epure init` never. Shipping the two together put the scaffolder in every
// app, and made the template depend on the tool that scaffolds it — a cycle
// `pnpm sync` walked into on any registry that had not already seen it.

open System

let lapaPort = "8081"
let appPort = "8080"

let stopping = ref(false)
let children: array<child> = []

let stopAll = () => {
  stopping := true
  children->Array.forEach(one => one->signal("SIGTERM")->ignore)
}

let watch = (name: string, one: child) => {
  children->Array.push(one)
  one->whenFailed(error =>
    if !stopping.contents {
      warn(`${name} could not start: ${error["message"]}\n`)
      if name == "lapa" {
        warn("install @lapa/server, or set EPURE_LAPA_BIN to a checkout's server/bin/lapa.mjs\n")
      }
      stopAll()
      failsWhenDone(1)
    }
  )
  one->whenGone(code =>
    if !stopping.contents {
      warn(`${name} stopped\n`)
      stopAll()
      let code = code->Nullable.getOr(1)
      exit(code == 0 ? 1 : code)
    }
  )
}

/** The session out of `lapa dev`'s first line: `dev <path> on <port>
    session=<token> code=<code>`. */
let sessionOf = line =>
  line
  ->String.split(" ")
  ->Array.findMap(word =>
    word->String.startsWith("session=")
      ? Some(word->String.slice(~start=String.length("session=")))
      : None
  )

let settle = ms => Promise.make((resolve, _) => later(() => resolve(), ms))

/** The desk's entry in the project's `.mcp.json`: the proxy's address with
    the session as its authorization, which is what the router takes. An
    agent started in the project reads the file and reaches the tools. Only
    the `desk` entry is dev's; the rest of the file is kept. The session is
    a credential, so the file is created owner-only, and the template
    gitignores it. */
let connect = token => {
  let path = joined(cwd(), ".mcp.json")
  let held = exists(path)
    ? switch readFile(path, "utf8")->JSON.parseOrThrow {
      | JSON.Object(fields) => Some(fields)
      | _ => None
      | exception _ => None
      }
    : Some(Dict.make())
  switch held {
  | None => warn(".mcp.json is not JSON; dev leaves it and writes no desk entry\n")
  | Some(fields) => {
      let servers = switch fields->Dict.get("mcpServers") {
      | Some(JSON.Object(servers)) => servers
      | _ => {
          let servers = Dict.make()
          fields->Dict.set("mcpServers", JSON.Object(servers))
          servers
        }
      }
      servers->Dict.set(
        "desk",
        JSON.Object(
          Dict.fromArray([
            ("type", JSON.String("http")),
            ("url", JSON.String(`http://localhost:${appPort}/_lapa/mcp`)),
            ("headers", JSON.Object(Dict.fromArray([("Authorization", JSON.String(token))]))),
          ]),
        ),
      )
      writeFile(path, JSON.stringify(JSON.Object(fields), ~space=2) ++ "\n", {"mode": 0o600})
    }
  }
}

/** The one line a person clicks. It waits for vite rather than for a line vite
    prints, so it is true the moment it is written: an address printed before
    the app answers would open on nothing. `http://` so a terminal linkifies
    it, and the session rides as `lapa-session` because the address bar belongs
    to the app. */
let announce = async token => {
  // The link says `localhost`, which is what vite prints and what a browser
  // opens. The probe asks both loopback families instead, because the word is
  // not one address: vite binds whichever `localhost` resolves to for it, and
  // node's own `fetch` can resolve it to the other one. Asking only `localhost`
  // waits forever on the half that disagrees.
  let address = `http://localhost:${appPort}/`
  let probes = [`http://127.0.0.1:${appPort}/`, `http://[::1]:${appPort}/`]
  let reached = async probe =>
    switch await answers(probe) {
    | _ => true
    | exception _ => false
    }
  let rec waits = async left =>
    if left > 0 {
      let answered = await probes->Array.reduce(Promise.resolve(false), async (found, probe) =>
        (await found) || (await reached(probe))
      )
      if answered {
        say(`\n${named(cwd())}  ${address}?lapa-session=${token}\n\n`)
      } else {
        await settle(100)
        await waits(left - 1)
      }
    }
  await waits(300)
}

/** `epure-dev prepare`: the desk file with no serving. It boots `lapa dev`
    once on an ephemeral port, writes `.mcp.json` from the line lapa
    prints, and stops it. The template's install runs this, so the file
    exists before any agent starts. A lapa that cannot start or answer —
    missing, or the store already held by a running dev — fails nothing
    here: the install stays whole, and a running dev writes the file
    itself. */
let prepare = () => {
  let lapa = env->Dict.get("EPURE_LAPA_BIN")->Option.getOr("lapa")
  let served = run(
    lapa,
    ["dev", ".data", "--port", "0"],
    {"cwd": cwd(), "stdio": ["ignore", "pipe", "pipe"]},
  )
  let seen = ref(false)
  let skip = message => {
    warn(`prepare skipped: ${message}\n`)
    exit(0)
  }
  served->whenFailed(_ => skip("lapa could not start"))
  served->whenGone(_ =>
    if !seen.contents {
      skip("lapa stopped before it spoke")
    }
  )
  served->out->reads("utf8")
  served
  ->out
  ->hears("data", text =>
    if !seen.contents {
      switch text->String.split("\n")->Array.find(line => line->String.startsWith("dev ")) {
      | Some(line) => {
          seen := true
          sessionOf(line)->Option.forEach(connect)
          say(".mcp.json holds the desk\n")
          served->signal("SIGTERM")->ignore
        }
      | None => ()
      }
    }
  )
  served->err->reads("utf8")
  served->err->hears("data", _ => ())
  delay(() =>
    if !seen.contents {
      served->signal("SIGTERM")->ignore
      skip("lapa said nothing")
    }
  , 30000)->unref
}

let serve = () => {
  let vite = joined(cwd(), "node_modules/.bin/vite")
  let rescript = joined(cwd(), "node_modules/.bin/rescript")
  if !exists(vite) || !exists(rescript) {
    warn("dev needs the project installed; run pnpm install\n")
    exit(1)
  }
  let lapa = env->Dict.get("EPURE_LAPA_BIN")->Option.getOr("lapa")

  whenSignalled("SIGTERM", () => stopAll())
  whenSignalled("SIGINT", () => stopAll())

  watch(
    "rescript",
    run(rescript, ["watch"], {"cwd": cwd(), "stdio": ["ignore", "inherit", "inherit"]}),
  )
  let served = run(
    lapa,
    ["dev", ".data", "--port", lapaPort],
    {"cwd": cwd(), "stdio": ["ignore", "pipe", "pipe"]},
  )
  let seen = ref(false)
  let hear = text => {
    say(text)
    if !seen.contents {
      switch text->String.split("\n")->Array.find(line => line->String.startsWith("dev ")) {
      | Some(line) =>
        seen := true
        watch("vite", run(vite, [], {"cwd": cwd(), "stdio": ["ignore", "inherit", "inherit"]}))
        sessionOf(line)->Option.forEach(token => {
          connect(token)
          announce(token)->Promise.ignore
        })
      | None => ()
      }
    }
  }
  served->out->reads("utf8")
  served->out->hears("data", hear)
  served->err->reads("utf8")
  served->err->hears("data", warn)
  watch("lapa", served)
}

let main = () => {
  if !exists(joined(cwd(), "package.json")) {
    warn("dev runs in a project; no package.json here\n")
    exit(1)
  }
  switch argv->Array.get(2) {
  | Some("prepare") => prepare()
  | Some(word) => {
      warn(`epure-dev knows no ${word}\n`)
      exit(1)
    }
  | None => serve()
  }
}
