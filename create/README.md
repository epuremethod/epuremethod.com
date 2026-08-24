# create-epure

The method's scaffolder: `epure init` creates a project on the method's
files and the reference stack. `pnpm create epure` reaches it by npm's
create convention; the bin is `epure`.

This package is an épure project of its own: its scenarios live in
`src/design/`, its working files (`CONTRIBUTING.md`, `SESSION.md`,
`DECISIONS.md`) beside them — inside this folder, never at the repository
root, because the root must not shadow the agreement template the site
publishes.
