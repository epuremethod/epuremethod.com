// The app in a React context, and the hook that takes it out.
//
// `useApp` is an architectural suggestion rather than an api. One context for
// the whole app is enough because tilia tracks each read on its own: a view
// takes the feature it needs here and reads its values down in the JSX, so it
// repaints on those reads and on nothing else. Take the feature, not a deep
// value — destructuring everything at the top throws that away. A scenario
// provides an app of its own the same way.

let context = React.createContext((None: option<App.t>))

module Provider = {
  let make = React.Context.provider(context)
}

let useApp = () =>
  switch React.useContext(context) {
  | Some(app) => app
  | None => JsError.throwWithMessage("no app above this view")
  }
