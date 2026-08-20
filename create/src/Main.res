open System

let usage = "epure <init|dev>\n  init <name> [--with package=spec]\n  dev\n"

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
    Init.run(name, withsOf(args))
  | (Some("dev"), _) => Dev.main()
  | _ => {
      warn(usage)
      exit(1)
    }
  }
}
