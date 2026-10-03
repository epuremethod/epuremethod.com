open Tilia

// The app: one carve, and every feature hangs off it. A view takes the
// feature it needs out of the context and reads it where it draws — one
// context for the whole app works because tilia tracks each read on its own,
// so a view repaints on what it read and on nothing else.
//
// The world arrives injected. `make` names services, never a client: the
// mount builds them over radif, and a scenario builds them out of arrays.

type t = {
  hello: Hello.t,
  /** Whether anything the app wrote is still on its way to the server. */
  saving: bool,
}

let make = (~notes: Notes.t): t =>
  carve(_ => {
    hello: Hello.make(~notes),
    saving: computed(() => notes.waiting() > 0),
  })
