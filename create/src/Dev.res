// `epure dev`: `rescript watch`, `lapa dev .data --port 8081` and vite,
// three processes as one. The template's vite.config.mjs holds the ports
// and the proxy; this file only starts, watches and stops. The `lapa`
// binary comes from PATH, or from EPURE_LAPA_BIN for a checkout
// (SESSION.md).

open System

let lapaPort = "8081"

let stopping = ref(false)
let children: array<child> = []

let stopAll = () => {
  stopping := true
  children->Array.forEach(one => one->signal("SIGTERM")->ignore)
}

let watch = (name: string, one: child) => {
  children->Array.push(one)
  one->whenFailed(error =>
    if !stopping.contents {
      warn(`${name} could not start: ${error["message"]}\n`)
      if name == "lapa" {
        warn("install @lapa/server, or set EPURE_LAPA_BIN to a checkout's server/bin/lapa.mjs\n")
      }
      stopAll()
      failsWhenDone(1)
    }
  )
  one->whenGone(code =>
    if !stopping.contents {
      warn(`${name} stopped\n`)
      stopAll()
      let code = code->Nullable.getOr(1)
      exit(code == 0 ? 1 : code)
    }
  )
}

let main = () => {
  if !exists(joined(cwd(), "package.json")) {
    warn("dev runs in a project; no package.json here\n")
    exit(1)
  }
  let vite = joined(cwd(), "node_modules/.bin/vite")
  let rescript = joined(cwd(), "node_modules/.bin/rescript")
  if !exists(vite) || !exists(rescript) {
    warn("dev needs the project installed; run pnpm install\n")
    exit(1)
  }
  let lapa = env->Dict.get("EPURE_LAPA_BIN")->Option.getOr("lapa")

  whenSignalled("SIGTERM", () => stopAll())
  whenSignalled("SIGINT", () => stopAll())

  watch(
    "rescript",
    run(rescript, ["watch"], {"cwd": cwd(), "stdio": ["ignore", "inherit", "inherit"]}),
  )
  let served = run(
    lapa,
    ["dev", ".data", "--port", lapaPort],
    {"cwd": cwd(), "stdio": ["ignore", "pipe", "pipe"]},
  )
  let seen = ref(false)
  let hear = text => {
    say(text)
    if (
      !seen.contents &&
      text->String.split("\n")->Array.some(line => line->String.startsWith("dev "))
    ) {
      seen := true
      watch("vite", run(vite, [], {"cwd": cwd(), "stdio": ["ignore", "inherit", "inherit"]}))
    }
  }
  served->out->reads("utf8")
  served->out->hears("data", hear)
  served->err->reads("utf8")
  served->err->hears("data", warn)
  watch("lapa", served)
}
