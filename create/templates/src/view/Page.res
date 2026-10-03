open LapaDb.App
open LapaDb.Data

// The app's one entry, and the only file that knows how the world is made:
// the session, the client over it, the services over the client, and the app
// they carve. Everything below takes what it needs as an argument, so a
// scenario builds the same app over services of its own.
//
// The session arrives in the address — `?lapa-session=…` — put there by
// `epure dev`. It is kept for the next visit and taken out of the address at
// once, so it does not survive into bookmarks, screenshots or shared links.

type element

@val @scope("document") external byId: string => Nullable.t<element> = "getElementById"
@set external writes: (element, string) => unit = "textContent"
@set external classed: (element, string) => unit = "className"

@val @scope(("window", "location")) external search: string = "search"
@val @scope(("window", "location")) external here: string = "pathname"
@val @scope(("window", "localStorage")) external keep: (string, string) => unit = "setItem"
@val @scope(("window", "localStorage")) external kept: string => Nullable.t<string> = "getItem"
@val @scope(("window", "history"))
external replaces: (Nullable.t<string>, string, string) => unit = "replaceState"

type params
@new external params: string => params = "URLSearchParams"
@send external asked: (params, string) => Nullable.t<string> = "get"

let sessionKey = "lapa:session"

let session = () =>
  switch params(search)->asked("lapa-session")->Nullable.toOption {
  | Some(token) => {
      keep(sessionKey, token)
      replaces(Nullable.null, "", here)
      Some(token)
    }
  | None => kept(sessionKey)->Nullable.toOption
  }

let outcome = (run: Reply.outcome<'a> => unit): promise<'a> =>
  Promise.make((resolve, reject) =>
    run({ok: resolve, error: message => reject(JsError.make(message))})
  )

// One sentence, and no app under it: this runs where there is nothing to
// render yet, so it writes rather than mounting React.
let tells = message =>
  byId("root")
  ->Nullable.toOption
  ->Option.forEach(root => {
    root->classed("mx-auto max-w-2xl px-6 py-14 text-sm text-quiet")
    root->writes(message)
  })

let shows = element =>
  ReactDOM.querySelector("#root")->Option.forEach(root =>
    ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(element)
  )

// The board is an ordinary component over the app's own client and engine:
// one store, one socket, and what the agent makes shows in both at the same
// moment. It
// renders only under `import.meta.env.DEV`, so a built app carries none of
// it — the whole package drops out of the bundle.
let opens = async token => {
  let indexed = await outcome(reply => IndexedDbKv.make(~name="app", reply))
  let client = await Client.make({base: "/_lapa", token, kv: indexed.kv})
  // One engine per client, shared by the app and the board. Its tick ages
  // the claim and evicts the plans nobody reads.
  let engine = LapaTilia.make(~client, ~clock=SystemClock.make())
  setInterval(engine.tick, 10000)->ignore
  let notes = await LiveNotes.over(~client, ~engine)
  shows(
    <AppView.Provider value={Some(App.make(~notes))}>
      <HelloView />
      {Env.dev ? <LapaBoard client engine /> : React.null}
    </AppView.Provider>,
  )
}

switch session() {
| Some(token) =>
  opens(token)
  ->Promise.catch(error => {
    Console.error(error)
    tells("this app could not open — the console says why")
    Promise.resolve()
  })
  ->Promise.ignore
| None => tells("this page opens on a session — start it with `pnpm dev`")
}
