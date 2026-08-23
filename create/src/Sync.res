// `pnpm sync`: what the template's dependencies are published as, written
// into `templates/package.json`. A released line is fixed by a caret over
// the tested version. A line still in beta is named by its tag: the line
// moves daily and only its newest build is kept working, so a scaffold
// must take what the tag names at install.

open System

@val external fetch: (string, 'a) => promise<'b> = "fetch"

let flagged = (args: array<string>, name) => {
  let rec walk = index =>
    switch (args->Array.get(index), args->Array.get(index + 1)) {
    | (Some(found), Some(value)) if found == name => Some(value)
    | (Some(_), _) => walk(index + 1)
    | (None, _) => None
    }
  walk(0)
}

let registry = (args: array<string>) => {
  let url = switch flagged(args, "--registry") {
  | Some(url) => url
  | None =>
    switch env->Dict.get("npm_config_registry") {
    | Some(url) if url != "" => url
    | _ => "https://registry.npmjs.org"
    }
  }
  url->String.endsWith("/") ? url->String.slice(~start=0, ~end=String.length(url) - 1) : url
}

/** The parts of a version, before any prerelease and after it. */
let split = (version: string) =>
  switch version->String.indexOfOpt("-") {
  | Some(at) => (
      version->String.slice(~start=0, ~end=at),
      Some(version->String.slice(~start=at + 1)),
    )
  | None => (version, None)
  }

/** `19.2.3` becomes `^19.2.3`, and `0.1.0-beta.6` becomes `beta`: a
    prerelease is named by its tag, so a scaffold takes the newest beta the
    registry holds when it installs. */
let named = (version: string) =>
  switch split(version) {
  | (_, None) => `^${version}`
  | (_, Some(pre)) => pre->String.split(".")->Array.get(0)->Option.getOr("beta")
  }

/** A spec that is a tag asks for it, and a spec on a prerelease line asks for
    its tag; anything else asks for the release. Leaving a beta line is a hand
    edit to the template, and sync must not undo it by preferring whichever
    version is newest. */
let wanted = (spec: string) => {
  let bare = spec->String.replace("^", "")
  switch bare->String.slice(~start=0, ~end=1)->Int.fromString {
  | None => bare
  | Some(_) =>
    switch split(bare) {
    | (_, Some(pre)) => pre->String.split(".")->Array.get(0)->Option.getOr("latest")
    | (_, None) => "latest"
    }
  }
}

let asked = async (~registry, ~package) => {
  let url = `${registry}/${package->String.replaceAll("/", "%2f")}`
  let answer = try await fetch(url, {"headers": {"accept": "application/json"}}) catch {
  | JsExn(error) =>
    JsError.throwWithMessage(
      `sync cannot reach ${registry}: ${error->JsExn.message->Option.getOr("no answer")}`,
    )
  }
  if !(answer["ok"]) {
    JsError.throwWithMessage(`sync found no ${package} on ${registry}`)
  }
  await answer["json"]()
}

/** The version the tag names, falling back to the other line when the one
    the template is on holds nothing yet. */
let taken = (packument, ~package, ~tag) => {
  let tags = switch packument {
  | JSON.Object(fields) =>
    switch fields->Dict.get("dist-tags") {
    | Some(JSON.Object(tags)) => tags
    | _ => Dict.make()
    }
  | _ => Dict.make()
  }
  let at = name =>
    switch tags->Dict.get(name) {
    | Some(JSON.String(version)) => Some(version)
    | _ => None
    }
  switch at(tag) {
  | Some(version) => version
  | None =>
    switch at(tag == "latest" ? "beta" : "latest") {
    | Some(version) => version
    | None => JsError.throwWithMessage(`sync found no ${package} on any line`)
    }
  }
}

let sections = ["dependencies", "devDependencies"]

let main = async () => {
  let args = argv->Array.slice(~start=2)
  let registry = registry(args)
  let file = switch flagged(args, "--template") {
  | Some(path) => path
  | None => joined(Init.templates(), "package.json")
  }
  let raw = readFile(file, "utf8")
  let json = JSON.parseOrThrow(raw)
  switch json {
  | JSON.Object(fields) => {
      let specs: array<(dict<JSON.t>, string, string)> = []
      sections->Array.forEach(section =>
        switch fields->Dict.get(section) {
        | Some(JSON.Object(deps)) =>
          deps
          ->Dict.toArray
          ->Array.forEach(((package, spec)) =>
            switch spec {
            | JSON.String(spec) => specs->Array.push((deps, package, spec))
            | _ => ()
            }
          )
        | _ => ()
        }
      )
      // Every version is resolved before one is written: a template half
      // moved to a new line is worse than one that never moved.
      let found = try await Promise.all(
        specs->Array.map(async ((deps, package, spec)) => {
          let tag = wanted(spec)
          let packument = await asked(~registry, ~package)
          (deps, package, spec, named(taken(packument, ~package, ~tag)))
        }),
      ) catch {
      | JsExn(error) => {
          warn(`${error->JsExn.message->Option.getOr("sync failed")}\n`)
          exit(1)
        }
      }
      found->Array.forEach(((deps, package, spec, range)) => {
        if spec != range {
          say(`${package} ${spec} -> ${range}\n`)
        }
        deps->Dict.set(package, JSON.String(range))
      })
      writeFile(file, JSON.stringify(json, ~space=2) ++ "\n")
      say(`the template is synced with ${registry}\n`)
    }
  | _ => {
      warn("sync found no template package.json\n")
      exit(1)
    }
  }
}
