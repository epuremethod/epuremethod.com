open TestCli

// A real browser, for the one question no fetch can answer: does the page
// draw anything.
//
// Dev's other scenarios read what the server sends — the page's html, the
// script's text, the wire's answers — and every one of them passes while the
// app renders nothing at all. The app mounts from a promise: a session, a
// store, a client over the wire, then React. A promise that never settles
// leaves `#root` empty, the console silent and every server-side assertion
// green. That gap is what this file closes.
//
// Chrome over the devtools protocol, and no dependency: node speaks
// WebSocket since 22, which is the whole of what the protocol needs. A
// machine with no Chrome is named rather than skipped past — a browser test
// that quietly does not run is the gap again, one layer up.

@val external later: (unit => unit, int) => unit = "setTimeout"
@val @scope("process") external environment: dict<string> = "env"

type answer
@send external json: answer => promise<JSON.t> = "json"
@val external fetch: string => promise<answer> = "fetch"

type socket
@new external connect: string => socket = "WebSocket"
@set external whenOpen: (socket, unit => unit) => unit = "onopen"
@set external whenMessage: (socket, {"data": string} => unit) => unit = "onmessage"
@send external sends: (socket, string) => unit = "send"
@send external closes: socket => unit = "close"

@module("node:fs") external exists: string => bool = "existsSync"
@module("node:fs") external tempDir: string => string = "mkdtempSync"

let raise = message => JsError.throwWithMessage(message)
let settle = ms => Promise.make((resolve, _reject) => later(() => resolve(), ms))

/** Where a browser is. `CHROME` names one on a machine that keeps it
    elsewhere; the paths below are where the three platforms put it. */
let binary = () => {
  let named = switch environment->Dict.get("CHROME") {
  | Some(path) if path != "" => [path]
  | _ => []
  }
  let known = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  ]
  switch named->Array.concat(known)->Array.find(exists) {
  | Some(path) => path
  | None =>
    raise(
      "these scenarios need a browser, and none was found. " ++
      "Install Chrome, or name one in CHROME.",
    )
  }
}

// ── the protocol ───────────────────────────────────────────────────────

type t = {
  child: System.child,
  socket: socket,
  /** Every console error, page error and thrown exception, in order. */
  complaints: array<string>,
  /** Every socket the page opened: what the protocol calls it, the address,
      and whether the server answered its handshake. */
  sockets: array<(string, string, ref<bool>)>,
  ask: (string, JSON.t) => promise<JSON.t>,
}

let field = (json, name) =>
  switch json {
  | JSON.Object(fields) => fields->Dict.get(name)
  | _ => None
  }

let text = json =>
  switch json {
  | Some(JSON.String(value)) => value
  | _ => ""
  }

/** The line chrome writes to stderr when it is ready, and the address in it.
    The port is asked for as 0, so what it chose is only knowable this way. */
let listening = (said: string) =>
  said
  ->String.split("\n")
  ->Array.findMap(line =>
    switch line->String.indexOfOpt("ws://") {
    | Some(at) => Some(line->String.slice(~start=at)->String.trim)
    | None => None
    }
  )

let rec waitsFor = async (check, ~every=100, ~left=100) =>
  switch await check() {
  | Some(found) => found
  | None =>
    if left == 0 {
      raise("the browser did not answer in time")
    }
    await settle(every)
    await waitsFor(check, ~every, ~left=left - 1)
  }

/** Open a browser, and a page in it. Nothing is navigated yet: a caller
    that wants what the page said from its first line must hear before it
    goes anywhere. */
let opens = async () => {
  let profile = tempDir(System.joined(System.tempRoot(), "epure-browser-"))
  let child = System.run(
    binary(),
    [
      "--headless=new",
      "--disable-gpu",
      "--no-sandbox",
      "--no-first-run",
      "--disable-extensions",
      "--remote-debugging-port=0",
      `--user-data-dir=${profile}`,
      "about:blank",
    ],
    {"cwd": System.tempRoot()},
  )
  let said = ref("")
  child->System.err->System.reads("utf8")
  child->System.err->System.hears("data", line => said := said.contents ++ line)

  let endpoint = await waitsFor(async () => listening(said.contents))
  // The browser endpoint names the port; the page is asked for over http,
  // which is the one route the protocol offers to find a target.
  let port =
    endpoint
    ->String.split("/")
    ->Array.get(2)
    ->Option.getOr("")
    ->String.split(":")
    ->Array.get(1)
    ->Option.getOr("")
  let target = await waitsFor(async () =>
    switch await fetch(`http://127.0.0.1:${port}/json/list`) {
    | answer =>
      switch await answer->json {
      | JSON.Array(list) => list->Array.find(one => one->field("type")->text == "page")
      | _ => None
      }
    | exception JsExn(_) => None
    }
  )

  let socket = connect(target->field("webSocketDebuggerUrl")->text)
  let complaints = []
  let sockets = []
  let waiting: dict<JSON.t => unit> = Dict.make()
  let counter = ref(0)

  socket->whenMessage(message => {
    let json = JSON.parseOrThrow(message["data"])
    switch json->field("id") {
    | Some(JSON.Number(id)) =>
      switch waiting->Dict.get(Float.toString(id)) {
      | Some(answer) => {
          waiting->Dict.delete(Float.toString(id))
          answer(json->field("result")->Option.getOr(JSON.Null))
        }
      | None => ()
      }
    | _ => {
        let params = json->field("params")->Option.getOr(JSON.Null)
        switch json->field("method")->text {
        | "Runtime.consoleAPICalled" =>
          if params->field("type")->text == "error" {
            complaints->Array.push("console: " ++ JSON.stringify(params))
          }
        | "Runtime.exceptionThrown" =>
          complaints->Array.push(
            "thrown: " ++
            params
            ->field("exceptionDetails")
            ->Option.flatMap(one => one->field("text"))
            ->text,
          )
        | "Log.entryAdded" =>
          let entry = params->field("entry")->Option.getOr(JSON.Null)
          if entry->field("level")->text == "error" {
            complaints->Array.push("log: " ++ entry->field("text")->text)
          }
        | "Network.webSocketCreated" =>
          sockets->Array.push((
            params->field("requestId")->text,
            params->field("url")->text,
            ref(false),
          ))
        | "Network.webSocketHandshakeResponseReceived" =>
          // By request, not by count: vite opens a socket of its own on the
          // same page, and one answering says nothing about the other.
          sockets->Array.forEach(((id, _, answered)) =>
            if id == params->field("requestId")->text {
              answered := true
            }
          )
        | _ => ()
        }
      }
    }
  })
  await Promise.make((resolve, _reject) => socket->whenOpen(() => resolve()))

  let ask = (method_, params) => {
    counter := counter.contents + 1
    let id = counter.contents
    let answer = Promise.make((resolve, _reject) =>
      waiting->Dict.set(Int.toString(id), resolve)
    )
    socket->sends(
      JSON.stringify(
        JSON.Object(
          Dict.fromArray([
            ("id", JSON.Number(Int.toFloat(id))),
            ("method", JSON.String(method_)),
            ("params", params),
          ]),
        ),
      ),
    )
    answer
  }

  let page = {child, socket, complaints, sockets, ask}
  let none = JSON.Object(Dict.make())
  let _ = await page.ask("Runtime.enable", none)
  let _ = await page.ask("Log.enable", none)
  let _ = await page.ask("Network.enable", none)
  let _ = await page.ask("Page.enable", none)
  page
}

let goes = async (page, ~to as address) => {
  let _ = await page.ask(
    "Page.navigate",
    JSON.Object(Dict.fromArray([("url", JSON.String(address))])),
  )
}

/** What an expression answers, as a string. */
let reads = async (page, expression) => {
  let answer = await page.ask(
    "Runtime.evaluate",
    JSON.Object(
      Dict.fromArray([
        ("expression", JSON.String(expression)),
        ("returnByValue", JSON.Boolean(true)),
        ("awaitPromise", JSON.Boolean(true)),
      ]),
    ),
  )
  answer->field("result")->Option.flatMap(one => one->field("value"))->text
}

/** What the app drew, once it has drawn anything. An app that never draws
    is what these scenarios are here to catch, so this waits rather than
    reading once, and says so plainly when nothing comes. */
let drew = async (page, ~within=15000) => {
  let tries = within / 250
  let rec look = async left =>
    switch await reads(page, "document.getElementById('root').innerHTML") {
    | "" =>
      if left == 0 {
        ""
      } else {
        await settle(250)
        await look(left - 1)
      }
    | drawn => drawn
    }
  await look(tries)
}

let shuts = page => {
  page.socket->closes
  page.child->System.signal("SIGKILL")->ignore
}
