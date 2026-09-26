open LapaDb.App
open LapaDb.Data

// `Notes.t` over a lapa client: `@lapa/tilia` reads and writes, and `make`
// drafts. This is the only file that knows both halves.
//
// A note is a plain `Record` with a title, so a scaffold shows something
// before it has a model of its own. `Record` below is what `lapa types` would
// write for that class, by hand. Once the generator has written classes of
// your own, this is the file that changes: one of them takes `Record`'s place,
// and `read` reads its own fields.

/** A `Record` as the binding hands it back: the bookkeeping part, the title
    every one carries, and `_rest` for what the model does not name, written
    back whole on a save. */
module Record = {
  type t = {
    entity: Lapa.Root.Entity.t,
    mutable titled: Lapa.Root.Titled.t,
    _rest: Lapa.rest,
  }

  let class_: Lapa.class_<t> = Lapa.class_("record.class")
  let all = Lapa.all(class_)
  let from = Lapa.from(class_)
  external record: t => Lapa.record = "%identity"

  let make = (~persona, ~under, ~titled): t => {
    entity: Lapa.entity(persona, class_, ~under),
    titled,
    _rest: Lapa.rest(),
  }
}

let read = (row: Record.t): Notes.note => {id: row.entity.id, title: row.titled.title}

/** The Personal node this session reaches: where a note the app makes
    hangs. The client pulls it on boot, so it is in the store by the time
    anything asks. */
let place = (client: Client.t) =>
  Promise.make((resolve, reject) => {
    let found = ref(None)
    client.store.seek(
      {field: Root.Entity.class_, test: Is(Relation(Root.personal))},
      {
        entry: id =>
          switch found.contents {
          | Some(_) => ()
          | None => found := Some(id)
          },
        ended: () =>
          switch found.contents {
          | Some(id) => resolve(id)
          | None => reject(JsError.make("this session reaches no Personal node"))
          },
        error: message => reject(JsError.make(message)),
      },
    )
  })

let over = async (~client: Client.t): Notes.t => {
  let personal = await place(client)
  // A conflict is told and nothing more: the merged row stays on screen as a
  // resolution draft, and what to do with one is the app's next decision.
  let db = LapaTilia.make(
    ~client,
    ~conflicts=(id, found) => Console.error2(`conflict on ${id}`, found),
    ~clock=SystemClock.make(),
  )
  // A class seek answers the class and everything below it, and the session's
  // own nodes — Personal, Inbox, the Authors and Domains — descend from
  // `Record` too. `from` keeps only what the app's model names, so the
  // untaught descendants drop out, exactly as they would through a generated
  // file.
  let rows = () =>
    switch db.array(Record.all) {
    | Loaded({data}) => data->Array.filterMap(row => Record.from(Record.record(row)))
    | _ => []
    }
  // The client answers `status()` as a plain value, and nothing on it fires
  // when a push lands. So it is read into a signal: on every write, and on
  // every delivery, because a landed push pulls.
  let (waiting, waits) = Tilia.signal(0)
  let asks = () =>
    waits(
      switch client.status() {
      | Pending => 1
      | Clear | Refused(_) => 0
      },
    )
  let _ = client.receives(_ => asks())
  {
    all: () => rows()->Array.map(read),
    ready: () =>
      switch db.array(Record.all) {
      | Loaded(_) => true
      | _ => false
      },
    saves: note =>
      rows()
      ->Array.find(row => row.entity.id == note.id)
      ->Option.forEach(row => {
        row.titled.title = note.title
        db.upsert(Record.record(row))
        asks()
      }),
    // A note is born with its place: `make` sets `addUnder`, and the save
    // stages the hang at `admin` and spends it.
    adds: title => {
      let note = Record.make(~persona=db.persona(), ~under=personal, ~titled={title: title})
      db.upsert(Record.record(note))
      asks()
    },
    waiting: () => waiting.value,
  }
}
