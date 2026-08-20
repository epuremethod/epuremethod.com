# Conventions

What the code looks like. `CONTRIBUTING.md` holds the method and is shared
by every épure project; this file is this project's own and can be argued
with. A choice that turns out to matter gets a dated entry in
`DECISIONS.md`.

## Scenarios

**A scenario must be able to fail on the path it names.** A refusal that
would have happened anyway, for another reason, proves nothing.

**A `.feature` file carries section dividers and no prose comments.** What
a rule is for goes to `DECISIONS.md` or the method site.

## Naming

**One word where one word does.** camelCase when a second word is genuinely
needed. PascalCase for modules. Booleans read as a question. No
abbreviations except the ones that are already words here: `id`, `kv`.
