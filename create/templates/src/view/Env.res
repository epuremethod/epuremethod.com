// `import.meta.env` is vite's, and ReScript has no syntax for `import.meta`,
// so it is bound once here. `dev` is statically false in a build, which is
// what keeps the board out of one.

type meta = {env: {"DEV": bool}}
@val external meta: meta = "import.meta"

let dev = meta.env["DEV"]
