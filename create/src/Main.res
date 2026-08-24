open System

let usage = "epure init <name> [--registry <url>] [--with package=spec]\n"

// `dev` moved to its own package, and a person who types the old command must
// be told rather than handed a project named "dev". `names` still refuses the
// word for that reason.
let moved = "dev moved to @epure/dev. Run `pnpm dev` in a project, or `epure-dev` by hand.\n"

// `pnpm create epure <name>` runs the bin as `epure <name>`: npm's create
// convention passes no subcommand. A first word that is neither a command nor
// a flag is the project's name.
let names = (word: string) => word != "init" && word != "dev" && !(word->String.startsWith("-"))

let flagged = (args: array<string>, name) => {
  let rec walk = index =>
    switch (args->Array.get(index), args->Array.get(index + 1)) {
    | (Some(found), Some(value)) if found == name => Some(value)
    | (Some(_), _) => walk(index + 1)
    | (None, _) => None
    }
  walk(0)
}

let withsOf = (args: array<string>) => {
  let withs: array<(string, string)> = []
  let rec walk = index =>
    switch (args->Array.get(index), args->Array.get(index + 1)) {
    | (Some("--with"), Some(pair)) => {
        switch pair->String.indexOfOpt("=") {
        | Some(at) =>
          withs->Array.push((
            pair->String.slice(~start=0, ~end=at),
            pair->String.slice(~start=at + 1),
          ))
        | None => ()
        }
        walk(index + 2)
      }
    | (Some(_), _) => walk(index + 1)
    | (None, _) => ()
    }
  walk(0)
  withs
}

let main = () => {
  let args = argv->Array.slice(~start=2)
  switch (args->Array.get(0), args->Array.get(1)) {
  | (Some("init"), Some(name)) if !(name->String.startsWith("-")) =>
    Init.run(name, withsOf(args), ~registry=?flagged(args, "--registry"))
  | (Some("dev"), _) => {
      warn(moved)
      exit(1)
    }
  | (Some(name), _) if names(name) =>
    Init.run(name, withsOf(args), ~registry=?flagged(args, "--registry"))
  | _ => {
      warn(usage)
      exit(1)
    }
  }
}
