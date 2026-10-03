// What the app asks of the world, and the whole seam between a feature and
// the machinery: no client, no store and no wire reach past this file. The
// mount injects one made over a radif client; a scenario hands one made of
// arrays, and the feature cannot tell the difference.

/** A note: a `Record` entity read down to what the app draws. */
type note = {
  id: Radif.id,
  title: string,
}

type t = {
  /** Every note the client holds. Reading this inside a carve or a view
      runs again when a pull lands or an edit is saved. */
  all: unit => array<note>,
  /** Whether the first answer has come back. Before it has, the app has
      nothing to say rather than nothing to show. */
  ready: unit => bool,
  /** Write a note back under the title it now carries. */
  saves: note => unit,
  /** Make a note under this title. */
  adds: string => unit,
  /** How many writes have not reached the server yet. */
  waiting: unit => int,
}
