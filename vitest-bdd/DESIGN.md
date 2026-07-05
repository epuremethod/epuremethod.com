# vitest-bdd.dev — design blueprint

Static prototype: `index.html` plus its own `style.css` and self-hosted IBM Plex fonts. No build step, no framework; deploys as-is (GitHub Pages or any static host). The only JavaScript is the `feature | steps` pane toggle on the code figure. Light theme only.

## Standing in the family

vitest-bdd is **independent of tilia** — it binds Gherkin to Vitest and works in any Vitest project. Its family resemblance runs through **épure** (it is sheet `A-03 · PROOF` of the method), not through tiliajs.com: same IBM Plex type system, hairline rules, 1.5px ink borders on the few objects that matter, small-caps mono labels, the dictionary-definition card, registration crosshairs on the épure bridge. No tilia leaf appears anywhere — the linden is tilia's brand.

## The four-stock paper family

Temperature is the family axis: the warmer the stock, the closer to the living wood; the cooler, the closer to the bench where work is checked.

| stock | value | site | temperament |
|---|---|---|---|
| warm ivory | `#fbf6e9` | tilia landing | the living wood |
| warm cream | `#faf8f2` | tilia API | the workshop shelf |
| gray-cream | `#f7f5f1` | épure | the drawing office |
| cool stone | `#f2f1ec` | vitest-bdd | the proof bench |

vitest-bdd is the coolest of the three tools — stone with a faint olive undertone. No warm-cream (`#fbf6e9`-family) value appears anywhere on this site.

## Color tokens

```css
/* stone bones */
--paper: #f2f1ec;   /* stone — cooler than épure, faint olive undertone */
--card:  #faf9f5;   /* code card, feature examples */
--shade: #e6e4dc;   /* recessed panels — reads recessed, not highlighted */
--line:  #d9d7cd;   /* hairlines cooled to sit on stone */
--ink:   #1d1a14;   --muted: #5c5544;   --faint: #8d8371;

/* clay system — near-achromatic */
--clay:      #5a554c;  /* body — buttons, tag grounds, dictionary rule. white label 7.4:1 */
--clay-deep: #3f3b34;  /* hover / active */
--clay-soft: #eeebe2;  /* slip — tint fills. Lifted from the spec'd #e9e6de: at spec it
                          collided with --shade on the stone paper (Δ ≈ 1 lightness step);
                          at #eeebe2 the ladder card > paper > clay-soft > shade reads. */
--clay-ink:  #47433c;  /* text on --clay-soft fills; code values */
--mark:      #b0402a;  /* sanguine — the checker's pencil. ANNOTATION ONLY, see rules.
                          5.2:1 on paper — holds for thin strokes without darkening. */

--steel:     #4a463c;  /* code keywords */
```

## Affordance rules

The clay system is near-achromatic, so color cannot signal function. These rules are structural, not stylistic:

1. Clay lives in AREAS only: solid buttons, tint fills, tag grounds, the dictionary block's rule. Never in thin elements — no clay-colored link text, no 1px clay accents expected to read as "accent".
2. Every link is underlined, always. No color-only links anywhere on this site.
3. Hover states change lightness AND form: button darkens to --clay-deep; links thicken the underline or gain a --clay-soft fill behind the text. A lightness shift alone is not a hover state here.
4. --mark (sanguine) is annotation, never state and never interactive: the logo crosshair, the PROOF stamp border, the active-nav tick. It must never color links, buttons, hovers, or pass/fail indicators. If the site ever shows failing tests, failure gets its own hotter token — the brand mark does not moonlight as an error color.

(One deliberate reading of rule 2: the header wordmark — ink text plus the sanguine crosshair — is an identity mark, not a prose link, and carries no underline. Every textual link on the page is underlined.)

## Identity

- **Wordmark / favicon**: a small registration crosshair (vertical + horizontal line through a thin circle, single-weight strokes, ~19px) in `--mark` — vitest-bdd's own mark.
- **Metaphor**: compas — the divider. Steps the drawing off against the work. (Replaces the earlier équerre entry: the divider carries the dynamic the static square lacked, and the definition inverts the équerre's line — the square checked the work against the drawing; the divider steps the drawing off against the work.) The copy runs on measuring and rules ("expected 3, measured 1002"); the épure card's phrase "Contracts That Run" is the headline.
- **PROOF stamp**: a small chip — sanguine border, clay-ink small-caps text — before the hero eyebrow, echoed on the bridge label (`SHEET A-03 · PROOF`).
- **Signature illustration**: a wing compass mid-measure (pivot knob, spread legs, slotted wing with its thumbscrew) standing behind the code card's lower-right corner — one leg passes behind the sheet and its point emerges below the corner; the other scribes a dotted arc on the paper. Clay strokes at 35%, hidden below 920px and in print.
- **Code panes**: near-achromatic — keywords in `--steel` at regular weight, strings/measured values in `--clay-ink` at weight 500 (hierarchy by weight and darkness, not hue), comments faint italic.

## Page pattern

Same grammar as the épure-family landings: header → hero (stamp + eyebrow, text, équerre defcard | code figure) → three value props in a hairline grid → épure bridge (`SHEET A-03 · PROOF` stamp, registration crosshairs) → title-block footer (Package / Source / License / Method / Site). The code figure is captioned `THE CONTRACT` and its toggle is `feature | steps` — the same contract seen from the Gherkin side and the typed-bindings side.

Projection/print: the clay/stone fills are low-contrast by design; readability is carried entirely by ink (`#1d1a14`) on paper text contrast, which is untouched. Print styles drop the compass and toggles.

## Placeholders to resolve before publishing

- `Docs` nav link points to `#`; "Get Started" points to `#`.
- `github.com/tiliajs/vitest-bdd` is a guess — épure's card only links npm. Swap in the real repo.
- The épure link uses `https://epure.dev` — swap in the real domain.
