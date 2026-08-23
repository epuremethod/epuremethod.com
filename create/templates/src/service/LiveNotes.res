open Lapa.App
open Lapa.Data

// `Notes.t` over a lapa client: the engine reads, the client's front writes,
// and the gate makes. This is the only file that knows both halves.
//
// A note is a plain `Record` with a title, so a scaffold shows something
// before it has a model of its own. Once `lapa types` has written classes of
// your own, this is the file that changes: `class` names one of them and
// `read` becomes its generated guard.

/** The engine's queries. One for now: every note. The filtering the app
    does is over the answer, not over the wire. */
type query = All

let field = (entity: Entity.t, facet, field) =>
  entity->Dict.get(facet)->Option.flatMap(part => part->Dict.get(field))

let read = (entity: Entity.t) =>
  switch (
    field(entity, Root.entity, Root.Entity.id),
    field(entity, Root.titled, Root.Titled.title),
  ) {
  | (Some(Value.String(id)), Some(Value.String(title))) => Some({Notes.id, title, entity})
  | _ => None
  }

// The copy goes one facet deep: the titled part is the only one written, and
// everything else the server sent rides back untouched.
let entity = (note: Notes.note) => {
  let next = note.entity->Dict.toArray->Dict.fromArray
  let part = switch note.entity->Dict.get(Root.titled) {
  | Some(part) => part->Dict.toArray->Dict.fromArray
  | None => Dict.make()
  }
  part->Dict.set(Root.Titled.title, Value.String(note.title))
  next->Dict.set(Root.titled, part)
  next
}

/** The Personal node this session reaches: where a note the app makes
    hangs. The client pulls it on boot, so it is in the store by the time
    anything asks. */
let place = (client: Client.t) =>
  Promise.make((resolve, reject) => {
    let found = ref(None)
    client.store.seek(
      {field: Root.Entity.class, test: Is(Value.Ref(Root.personal))},
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
  let live = Live.make(
    ~client,
    ~rows={
      class: Root.record,
      row: read,
      entity,
      id: (note: Notes.note) => note.id,
      matches: (_, _) => true,
      key: _ => "all",
    },
  )
  {
    all: () =>
      switch live.query.array(All) {
      | Loaded({data}) => data
      | _ => []
      },
    ready: () =>
      switch live.query.array(All) {
      | Loaded(_) => true
      | _ => false
      },
    saves: note => live.query.upsert(note),
    // A note is born with its place and its access, so making one is the
    // gate's business and not the engine's. The engine hears it arrive on
    // the pull that follows the push.
    adds: title =>
      client.gate.create(
        ~actor=client.actor,
        [{GateType.class: Root.record, title, parts: [], hangs: [(personal, Access.admin)]}],
        {ok: _ => (), error: message => Console.error(message)},
      ),
    waiting: () => live.query.status.pending,
  }
}
