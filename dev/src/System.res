// The node surface the dev server needs, and nothing beyond it. `create-epure`
// carries its own: two small lists of externals are cheaper to read than one
// shared package neither of them would own.

type child
type stream

@module("node:child_process") external run: (string, array<string>, 'a) => child = "spawn"
@get external out: child => stream = "stdout"
@get external err: child => stream = "stderr"
@send external reads: (stream, string) => unit = "setEncoding"
@send external hears: (stream, string, string => unit) => unit = "on"
@send external whenGone: (child, @as("close") _, Nullable.t<int> => unit) => unit = "on"
@send external whenFailed: (child, @as("error") _, {"message": string} => unit) => unit = "on"
@send external signal: (child, string) => bool = "kill"

@module("node:fs") external exists: string => bool = "existsSync"
@module("node:fs") external readFile: (string, string) => string = "readFileSync"
@module("node:fs") external writeFile: (string, string, {"mode": int}) => unit = "writeFileSync"
@module("node:path") external joined: (string, string) => string = "join"
@module("node:path") external named: string => string = "basename"

@val external answers: string => promise<'a> = "fetch"
@val external later: (unit => unit, int) => unit = "setTimeout"

type timer
@val external delay: (unit => unit, int) => timer = "setTimeout"
@send external unref: timer => unit = "unref"

@val external process: 'a = "process"
@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external cwd: unit => string = "cwd"
@val @scope("process") external exit: int => 'never = "exit"
// Sets the code and lets the process leave when its children have closed.
let failsWhenDone: int => unit = %raw(`code => { process.exitCode = code }`)
@val @scope("process") external env: dict<string> = "env"
@val @scope("process") external whenSignalled: (string, unit => unit) => unit = "on"
@val @scope(("process", "stdout")) external say: string => unit = "write"
@val @scope(("process", "stderr")) external warn: string => unit = "write"
