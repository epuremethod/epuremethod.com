open Tilia

// THROWAWAY. The scaffold's hello world, here so a new project shows
// something the moment it runs. Delete this file and `HelloView.res` once
// the app has a model of its own; nothing else depends on them.
//
// It is written the way the rest should be: the state is a carve, every
// value the views read derives from it, and the world arrives as `Notes.t`
// rather than as a client.

type t = {
  /** What the filter box holds. */
  mutable filter: string,
  /** What the add box holds. */
  mutable entry: string,
  /** The title being edited, before it is saved. */
  mutable draft: string,
  /** The note the person opened, by id. */
  mutable chosen: option<Radif.id>,
  /** That note, or None while none is open. */
  opened: option<Notes.note>,
  /** The notes the filter leaves. */
  shown: array<Notes.note>,
  /** How many notes there are in all. */
  counted: int,
  /** Whether the first answer has come back. */
  ready: bool,
  /** Open a note, or shut the one already open. */
  opens: Radif.id => unit,
  /** Save the draft into the note that is open. */
  renames: unit => unit,
  /** Add the entry as a note, and clear the box. */
  adds: unit => unit,
}

let matches = (~filter, one: Notes.note) =>
  switch filter->String.trim->String.toLowerCase {
  | "" => true
  | wanted => one.title->String.toLowerCase->String.includes(wanted)
  }

let make = (~notes: Notes.t): t =>
  carve(({derived}) => {
    filter: "",
    entry: "",
    draft: "",
    chosen: None,
    // `derived` reads the carve itself, `computed` reads only what it
    // closes over. Both run again when what they read changes, and only
    // then — a view that draws the count repaints when a note is added and
    // not when the filter is typed in.
    opened: derived((self: t) =>
      self.chosen->Option.flatMap(id => notes.all()->Array.find(one => one.id == id))
    ),
    shown: derived((self: t) =>
      notes.all()->Array.filter(one => matches(~filter=self.filter, one))
    ),
    counted: computed(() => notes.all()->Array.length),
    ready: computed(() => notes.ready()),
    opens: derived((self: t) =>
      id =>
        if self.chosen == Some(id) {
          self.chosen = None
        } else {
          self.chosen = Some(id)
          self.draft =
            notes.all()->Array.find(one => one.id == id)->Option.mapOr("", one => one.title)
        }
    ),
    renames: derived((self: t) =>
      () =>
        switch (self.opened, self.draft->String.trim) {
        | (Some(note), title) if title != "" && title != note.title => notes.saves({...note, title})
        | _ => ()
        }
    ),
    adds: derived((self: t) =>
      () =>
        switch self.entry->String.trim {
        | "" => ()
        | title => {
            notes.adds(title)
            self.entry = ""
          }
        }
    ),
  })
