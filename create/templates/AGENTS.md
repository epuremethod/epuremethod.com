Read `CONTRIBUTING.md` before changing the project.

At session start, check whether the app already runs. If it does not, run it
with `pnpm dev`, in the background, and leave it running. It prints one link
with the session in the address. Give that link to the person to open: the app
opens only on a session. `.mcp.json` names the desk on the same session — the
install wrote it, dev keeps it — and the desk's tools answer while dev runs.

Say what you are doing while you do it. Write one short line before a step,
naming what you are about to do. Write one short line after it, naming what
came back. Reading documentation in silence leaves the person waiting with no
idea what is happening.

Hand things over early. Give the link as soon as dev prints it, and give a
finding as soon as you have it. Do not save either for the end of the work.
When something blocks you, say so at once, and say what you propose to do about
it.

Write plain, natural English:

- Use common words, short sentences, active voice, and concrete subjects.
- Put one claim or action in each sentence.
- Split anything that needs rereading.
- Keep the domain's exact vocabulary and meaning.
- Remove repetition and words that add no meaning.
- Avoid metaphors, idioms, clever phrasing, and compressed contrasts.
- Keep scenario steps to one action or assertion.

Use comments only for a domain rule, external quirk, or invariant that the code
and types cannot express. Keep them beside what they describe. Do not comment
fixtures or test data. Put lasting rationale in `DECISIONS.md`. Delete stale
comments after changing code.

The session works in one of three modes, named in `SESSION.md`: croquis,
cahier or build (`CONTRIBUTING.md`, "Three modes").

In build, stop after each session stage. Show the completed stage and wait for
agreement. Do not write steps or build before the feature is agreed.

In croquis, do not stop. Define the model at the desk and sketch views in
`src/croquis/`; write no scenarios. Never change a behavior a scenario covers —
to change one, work in build. The standing check stays green.

In cahier, write no code. Think in prose and diagrams in `docs/wip.md` —
what the thing is, what it promises, why it is shaped that way — and work it
through on real cases until the words are settled. Croquis and cahier are the
same stage: move between them freely. The scenarios are written from the
cahier, not from the sketch. Never write a sentence that promises behavior no
scenario proves: write the scenario, or cut the sentence.

Agents commit only when asked. Never run `git push`, `git merge`, `git rebase`,
or `git reset`. Otherwise leave changes in the working tree.
