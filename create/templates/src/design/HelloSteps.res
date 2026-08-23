open EpureVitest

// Steps for Hello.feature. No server, no client, no browser: `Notes.t` is a
// record of closures, so the world here is three signals and the app's rules
// run straight against them.
//
// The one thing a hand-made `Notes.t` must get right is that `all`, `ready`
// and `waiting` answer reactively — the carve derives from them, and a plain
// `ref` would leave every derived value stale after a write. `Tilia.signal`
// is the cheapest way to say so.

let raise = message => JsError.throwWithMessage(message)

let listed = (text: string) =>
  text->String.trim == "" ? [] : text->String.split(",")->Array.map(one => one->String.trim)

let titles = (notes: array<Notes.note>) => notes->Array.map(one => one.title)->Array.join(", ")

given("the notes {string}", ({step}, given: string) => {
  let (held, holds) = Tilia.signal(
    listed(given)->Array.mapWithIndex((title, at) => {
      Notes.id: `note-${at->Int.toString}`,
      title,
      entity: Dict.make(),
    }),
  )
  let (answered, answers) = Tilia.signal(true)
  let (flying, flies) = Tilia.signal(0)
  let saved = []
  let added = []

  let notes: Notes.t = {
    all: () => held.value,
    ready: () => answered.value,
    saves: note => {
      saved->Array.push(note.title)
      holds(held.value->Array.map(one => one.Notes.id == note.id ? note : one))
    },
    adds: title => added->Array.push(title),
    waiting: () => flying.value,
  }

  let app = App.make(~notes)
  let hello = app.hello

  let named = title =>
    switch held.value->Array.find(one => one.title == title) {
    | Some(note) => note
    | None => raise(`no note titled ${title}`)
    }

  // ── reading ──────────────────────────────────────────────────────────

  step("the notes have not answered", () => answers(false))

  step("the app shows {string}", (wanted: string) => expect(titles(hello.shown)).toEqual(wanted))

  step("the app counts {number} notes", (wanted: float) =>
    expect(hello.counted).toEqual(wanted->Float.toInt)
  )

  step("the filter is {string}", (text: string) => hello.filter = text)

  step("the app is not ready", () => expect(hello.ready).toBe(false))

  // ── opening ──────────────────────────────────────────────────────────

  step("{string} is opened", (title: string) => hello.opens(named(title).id))

  step("the note open is {string}", (title: string) =>
    expect(hello.opened->Option.map(one => one.Notes.title)).toEqual(Some(title))
  )

  step("no note is open", () => expect(hello.opened->Option.isNone).toBe(true))

  step("the draft is {string}", (text: string) => hello.draft = text)

  step("the draft says {string}", (text: string) => expect(hello.draft).toEqual(text))

  // ── renaming ─────────────────────────────────────────────────────────

  step("the rename is saved", () => hello.renames())

  step("{string} was saved", (title: string) => expect(saved).toEqual([title]))

  step("nothing was saved", () => expect(saved).toEqual([]))

  // ── adding ───────────────────────────────────────────────────────────

  step("the add box holds {string}", (text: string) => hello.entry = text)

  step("the note is added", () => hello.adds())

  step("{string} was added", (title: string) => expect(added).toEqual([title]))

  step("nothing was added", () => expect(added).toEqual([]))

  step("the add box is empty", () => expect(hello.entry).toEqual(""))

  // ── waiting ──────────────────────────────────────────────────────────

  step("{number} writes are on their way", (count: float) => flies(count->Float.toInt))

  step("the app is saving", () => expect(app.saving).toBe(true))

  step("the app is not saving", () => expect(app.saving).toBe(false))
})
