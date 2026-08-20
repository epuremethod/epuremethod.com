Read `CONTRIBUTING.md` before changing the project.

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

Stop after each session stage. Show the completed stage and wait for agreement.
Do not write steps or build before the feature is agreed.

Agents commit only when asked. Never run `git push`, `git merge`,
`git rebase`, or `git reset`. Otherwise leave changes in the working tree.