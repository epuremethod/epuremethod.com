// `epure init <name>`: the scaffold, then `pnpm install`. `--with a=b`
// overrides a dependency before the install, for the checkouts the alpha
// still links (SESSION.md).

open System

@val external importUrl: string = "import.meta.url"
@module("node:url") external fileOf: string => string = "fileURLToPath"
@module("node:path") external parent: string => string = "dirname"

let templates = () => joined(parent(parent(fileOf(importUrl))), "templates")

let rec files = dir =>
  readDir(dir)->Array.flatMap(name => {
    let path = joined(dir, name)
    stat(path)["isDirectory"]() ? files(path)->Array.map(rest => joined(name, rest)) : [name]
  })

// Dotfiles ship undotted: npm pack mistreats .gitignore, and the keep
// files follow the same rule. A keep file makes git carry an empty layer,
// so a fresh CI checkout still holds every declared source directory.
let landed = name =>
  switch name {
  | "gitignore" => ".gitignore"
  | _ => name->String.endsWith("gitkeep") ? name->String.replace("gitkeep", ".gitkeep") : name
  }


let overrides = (raw: string, withs: array<(string, string)>) => {
  let json = JSON.parseOrThrow(raw)
  switch json {
  | JSON.Object(fields) => {
      let set = (section, package, spec) =>
        switch fields->Dict.get(section) {
        | Some(JSON.Object(deps)) if deps->Dict.get(package)->Option.isSome => {
            deps->Dict.set(package, JSON.String(spec))
            true
          }
        | _ => false
        }
      withs->Array.forEach(((package, spec)) =>
        if !set("dependencies", package, spec) && !set("devDependencies", package, spec) {
          switch fields->Dict.get("dependencies") {
          | Some(JSON.Object(deps)) => deps->Dict.set(package, JSON.String(spec))
          | _ => ()
          }
        }
      )
      JSON.stringify(json, ~space=2) ++ "\n"
    }
  | _ => raw
  }
}

let run = (name: string, withs: array<(string, string)>) => {
  let dir = resolved(cwd(), name)
  if exists(dir) && readDir(dir)->Array.length > 0 {
    warn(`init refuses: ${name} already holds files\n`)
    exit(1)
  }
  let from = templates()
  files(from)->Array.forEach(file => {
    let text = readFile(joined(from, file), "utf8")->String.replaceAll("{{name}}", name)
    let text = file == "package.json" ? overrides(text, withs) : text
    let target = joined(dir, landed(file))
    mkdir(parent(target), {"recursive": true})
    writeFile(target, text)
  })
  let installed = runSync("pnpm", ["install"], {"cwd": dir, "stdio": "inherit"})
  if Nullable.toOption(installed["status"]) != Some(0) {
    warn(`init could not install in ${name}\n`)
    exit(1)
  }
  say(`${name} is ready\n`)
}
