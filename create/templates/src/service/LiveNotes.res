open LapaDb.App
open LapaDb.Data

// `Notes.t` over a lapa client: `@lapa/tilia` reads, the client writes. This
// is the only file that knows both halves.
//
// A note is a plain `Record` with a title, so a scaffold shows something
// before it has a model of its own. `LapaStore.Record` is the root class as
// `lapa types` writes it. Once the generator has written classes of your own,
// this is the file that changes: one of them takes `Record`'s place, and
// `read` reads its own fields.

module Record = LapaStore.Record

let read = (row: Record.t): Notes.note => {
  id: row.entity.id,
  title: row.titled->Option.mapOr("", titled => titled.title),
}

/** The Personal node this session reaches: where a note the app makes is
    placed. The Account has an edge to it, and the client pulls both on
    boot, so they are in the store by the time anything asks. */
let place = (client: Client.t) =>
  Promise.make((resolve, reject) => {
    let cancel = ref(() => ())
    let answered = ref(false)
    let answers = result => {
      answered := true
      cancel.contents()
      switch result {
      | Ok(personal) => resolve(personal)
      | Error(message) => reject(JsError.make(message))
      }
    }
    cancel :=
      client.edges(
        From(client.actor),
        {
          changed: edges => {
            let rec next = index =>
              switch edges->Array.get(index) {
              | None => answers(Error("this session reaches no Personal node"))
              | Some(edge: Edge.t) =>
                client.get(
                  edge.to,
                  {
                    found: row =>
                      switch LapaStore.Personal.from(row) {
                      | Some(_) => answers(Ok(edge.to))
                      | None => next(index + 1)
                      },
                    missing: () => next(index + 1),
                    error: message => answers(Error(message)),
                  },
                )
              }
            if !answered.contents {
              next(0)
            }
          },
          error: message => answers(Error(message)),
        },
      )
    if answered.contents {
      cancel.contents()
    }
  })

let over = async (~client: Client.t, ~engine: LapaTilia.t): Notes.t => {
  let personal = await place(client)
  let notes = Lapa.under(Record.klass)(personal)
  // The place head answers every row under the node whose class descends
  // from `Record`, and an App is one. A note is a `Record` itself.
  let rows = () =>
    switch engine.load(notes) {
    | Loaded({data}) => data->Array.filter(row => row.entity.class == Lapa.Root.record)
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
  let writes = row => {
    client.upsert([Record.record(row)], {ok: asks, error: message => Console.error(message)})
    asks()
  }
  {
    all: () => rows()->Array.map(read),
    ready: () =>
      switch engine.load(notes) {
      | Loaded(_) => true
      | _ => false
      },
    saves: note =>
      rows()
      ->Array.find(row => row.entity.id == note.id)
      ->Option.forEach(row => {
        row.titled = Some({title: note.title})
        writes(row)
      }),
    // A note is made with its parent: the save adds the edge from the
    // Personal node at `admin`.
    adds: title => writes(Record.make(client.context, ~under=personal, ~titled={title: title})),
    waiting: () => waiting.value,
  }
}
