open TiliaReact

// THROWAWAY, with `Hello.res`. Delete both once the app has a model and
// views of its own.
//
// `leaf` is what makes a view reactive: tilia watches the reads made while it
// renders, so this repaints exactly when one of them changes. No dependency
// array, no selector, no memo. Every rule lives in `Hello`; a click here
// calls one of its actions and draws what it answers.

let text = React.string

let box = "w-full rounded-md border border-line bg-raised px-3 py-2 text-sm \
  outline-none placeholder:text-quiet focus:border-ink/30"

let value = event => (event->ReactEvent.Form.target)["value"]

module Row = {
  @react.component
  let make = leaf((~note: Notes.note) => {
    let {hello} = AppView.useApp()
    let open_ = hello.chosen == Some(note.id)

    <li className="border-t border-line first:border-t-0">
      <button
        type_="button"
        className="flex w-full items-baseline gap-3 px-1 py-2 text-left"
        onClick={_ => hello.opens(note.id)}>
        <span className="text-quiet text-xs"> {text(open_ ? "▾" : "▸")} </span>
        <span className="grow"> {text(note.title)} </span>
      </button>
      {open_
        ? <div className="flex gap-2 px-1 pb-3 pl-7">
            <input
              className=box
              value={hello.draft}
              autoFocus=true
              onChange={event => hello.draft = value(event)}
              onKeyDown={event => event->ReactEvent.Keyboard.key == "Enter" ? hello.renames() : ()}
            />
            <button
              type_="button"
              className="rounded-md border border-line px-3 py-2 text-sm whitespace-nowrap"
              onClick={_ => hello.renames()}>
              {text("save")}
            </button>
          </div>
        : React.null}
    </li>
  })
}

@react.component
let make = leaf(() => {
  let app = AppView.useApp()
  let hello = app.hello

  <main className="mx-auto max-w-2xl px-6 py-14">
    <header className="flex items-baseline justify-between gap-4">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight"> {text("Hello")} </h1>
        <p className="mt-1 text-sm text-quiet">
          {text("Notes, kept by radif. Ask the agent for a model of your own.")}
        </p>
      </div>
      {app.saving ? <span className="text-xs text-quiet"> {text("saving…")} </span> : React.null}
    </header>
    <div className="mt-8 flex gap-2">
      <input
        className=box
        placeholder="new note"
        value={hello.entry}
        onChange={event => hello.entry = value(event)}
        onKeyDown={event => event->ReactEvent.Keyboard.key == "Enter" ? hello.adds() : ()}
      />
      <button
        type_="button"
        className="rounded-md border border-line px-4 py-2 text-sm whitespace-nowrap"
        onClick={_ => hello.adds()}>
        {text("add")}
      </button>
    </div>
    <input
      className={box ++ " mt-3"}
      placeholder="filter"
      value={hello.filter}
      onChange={event => hello.filter = value(event)}
    />
    <ul className="mt-6 rounded-md border border-line bg-raised">
      {hello.shown->Array.length == 0
        ? <li className="px-3 py-6 text-sm text-quiet italic">
            {text(
              !hello.ready
                ? "reading…"
                : hello.counted == 0
                ? "no notes yet — add one above"
                : "no note matches the filter",
            )}
          </li>
        : React.array(hello.shown->Array.map(note => <Row note key={note.id} />))}
    </ul>
    <p className="mt-3 text-xs text-quiet">
      {text(
        `${hello.shown->Array.length->Int.toString} of ${hello.counted->Int.toString} shown`,
      )}
    </p>
  </main>
})
