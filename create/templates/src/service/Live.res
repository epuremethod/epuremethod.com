// Live queries: @tilia/query fed by the lapa client. Lapa owns the
// database — the front, the push, the pull, the refusal. The engine owns
// the read model: what a view asks stays live as writes land and pulls
// arrive. They meet in this file and nowhere else: lapa runs with any
// state management, and this binding is the template's own, to keep or
// replace like any other file here.

/** How the app's rows ride on entities of one class. */
type rows<'query, 'row> = {
  /** The class whose entities are rows. */
  class: Id.t,
  /** The row an entity carries, or None for one the read model ignores. */
  row: Entity.t => option<'row>,
  /** The entity behind a row, written whole on an edit. */
  entity: 'row => Entity.t,
  /** The row's id: the `Entity.id` of its entity. */
  id: 'row => string,
  /** Whether a row answers a query. */
  matches: ('query, 'row) => bool,
  /** A stable key for a query. */
  key: 'query => string,
}

type t<'query, 'row> = {
  /** The engine: `one`, `array`, `upsert`, `status`, `tick`. */
  query: TiliaQuery.t<'query, 'row>,
  /** Wire this into the client config's `received`. */
  received: array<(Id.t, Entity.t)> => unit,
}

let make = (~client: Client.t<'a>, ~rows: rows<'query, 'row>): t<'query, 'row> => {
  // The engine's remote is the client, and the client always answers:
  // its front holds what the wire cannot take yet. Connectivity is the
  // client's business, so the engine never goes offline.
  let (online, _) = Tilia.signal(true)
  let engine = TiliaQuery.make({
    id: rows.id,
    matches: rows.matches,
    key: rows.key,
    remote: {
      online,
      // Every row of the class the store holds, filtered by the query.
      // `live`: received deliveries keep the result fresh, so the engine
      // schedules no periodic refresh.
      fetch: (query, channel) => {
        let ids = []
        client.store.seek(
          {field: Root.Entity.class, test: Is(Value.Ref(rows.class))},
          {
            entry: id => ids->Array.push(id),
            ended: () => {
              let values = []
              let rec read = i =>
                switch ids->Array.get(i) {
                | Some(id) =>
                  client.store.get(
                    id,
                    {
                      found: entity => {
                        rows.row(entity)->Option.forEach(row =>
                          if rows.matches(query, row) {
                            values->Array.push(row)
                          }
                        )
                        read(i + 1)
                      },
                      missing: () => read(i + 1),
                      error: message => channel.fail(message),
                    },
                  )
                | None => channel.live(values)
                }
              read(0)
            },
            error: message => channel.fail(message),
          },
        )
      },
      // In order, one save each: through the front, so an edit made
      // offline pushes when the client is back. The first refusal fails
      // the batch whole and the engine reverts it.
      push: (ops, channel) => {
        let rec run = i =>
          switch ops->Array.get(i) {
          | Some(TiliaQuery.Upsert({value})) =>
            client.store.save(
              [rows.entity(value)],
              {
                ok: () => {
                  channel.set(value)
                  run(i + 1)
                },
                error: message => channel.fail(message),
              },
            )
          | Some(Remove(_)) =>
            // A row leaves by its edge, and edges are the gate's.
            channel.fail("remove goes through gate.cut, not the engine")
          | None => ()
          }
        run(0)
      },
    },
  })
  let received = pairs => {
    let changed =
      pairs->Array.filterMap(((class, entity)) => class == rows.class ? rows.row(entity) : None)
    if changed->Array.length > 0 {
      engine.receive.changed(changed)
    }
  }
  {query: engine, received}
}
