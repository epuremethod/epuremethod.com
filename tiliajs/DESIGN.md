# tiliajs.com — design blueprint

Static prototype: `index.html` (tilia landing), `query.html` (@tilia/query landing), `api.html` (reference template, three entries), one shared `style.css`. No build step, no framework; deploys as-is to GitHub Pages. The only JavaScript is the `ts | res` toggle on the landing code figures. Light theme only (per brief).

(vitest-bdd is independent of tilia and lives at vitest-bdd.dev — its blueprint is the sibling `vitest-bdd/` directory, which derives from this design system via épure. It is not a tiliajs.com page.)

## One temperature: tilia's own

The whole site runs at tilia's temperature: warm ivory stock, no grid underlay, green in the primary role (buttons, active nav, marks), and none of épure's citation grammar (no FIG. numbers, no numbered section kickers, no solid-ink buttons). The family resemblance to épure is carried by the type system, the hairline-and-ink-border discipline, the small-caps label grammar, and the dictionary/title-block/crosshair motifs — not by sharing épure's paper. The signature leaf illustration remains landing-only: identity surfaces get the pivot object, utility surfaces (API, later Docs/Compare) get the same temperature without decoration.

## Family resemblance to épure

tilia is the tool; épure is the method. The two sites share bones and differ in skin.

**Shared (taken from the épure stylesheet):**

- Type system: IBM Plex Sans (400/500/600) for headings and body, IBM Plex Mono (400/500) for code, labels, metadata. Fonts self-hosted in `fonts/` (copied from `site/fonts/`); system stacks as fallback — no CDN required to render.
- The `.k` small-caps mono label: 11px, `0.14em` tracking, uppercase. Used for nav, section tags, figure captions, index groups, footer labels.
- The dictionary-definition card (`.defcard`): same structure as épure's, with the linden entry in the hero.
- Section kicker: mono number + hairline rule + small-caps tag (`01 —— THE CASE, IN THREE LINES`).
- Hairline rules (`--line`), 1.5px ink borders on the *few* elements that matter (code figure, bridge block, footer top rule, buttons). épure's grid-paper underlay is not used — plain ivory ground site-wide.
- Registration crosshairs (`.reg`) on the bridge block corners — a literal stitch to épure's sheet corners.
- The footer is a lightened title-block: label/value cells in mono (Package / Source / License / Method / Site).
- The bridge block carries `SHEET A-01 · FOUNDATION`, matching how the épure page lists tilia.

**tilia's own skin (where it departs):**

- No sheet frame around the whole page, no desk background — content sits directly on warm ivory paper. Airier section padding. The primary button is linden green, not épure's solid ink.
- Two accents instead of épure's blue: linden green (the working accent — links, labels, glyphs, hover states) and honey (rare second voice — code strings/literals, the React tag, the active `res` toggle). Flat color only; no gradients anywhere.
- Value-prop glyphs are line-drawn SVG strokes in `currentColor` (muted at rest, leaf on hover) — no emoji, no filled icons.

## Color tokens

```css
/* shared bones, inherited from épure (shifted to warm ivory) */
--paper: #fbf6e9;   /* page — épure uses #f7f5f1; a different stock from the same mill */
--card:  #fffdf4;   /* raised surfaces: code figure, defcard, tags */
--ink:   #1d1a14;   /* text, strong borders */
--muted: #5c5544;   /* secondary text — 7.3:1 on paper */
--faint: #8d8371;   /* decorative labels only, never load-bearing text */
--line:  #e8e1cc;   /* hairlines */
--shade: #f4eedc;   /* inline code, signature blocks */

/* tilia's own skin — brand green, fixed on every page */
--leaf:      #2e7d3a;  /* wordmark leaf */
--leaf-ink:  #25612f;  /* code keywords (.tk) */
--honey:     #a3691a;  /* borders, decor */
--honey-ink: #8a5410;  /* honey for text (code strings) — AA on paper */
--honey-soft:#f5ecd9;

/* accent role — everything interactive or marked: buttons, nav
   hover/current, defcard rule, pids, glyph hover, bridge label,
   footer links, sig borders, selection, focus rings */
--accent:      #2e7d3a;  /* fill — 4.9:1 vs --btn-label, AA */
--accent-ink:  #25612f;  /* text/links — 7.2:1 on paper */
--accent-soft: #e5efe0;  /* flat tint, never a gradient */
--accent-deep: #1e5227;  /* button active */
--btn-label:   #fdfbf4;
```

Package pages re-ink the accent role without touching anything else. The
family: each tool takes its accent from what it is to the tree.

| page | body class | metaphor | accent | ink |
|---|---|---|---|---|
| tilia | — | the wood | `#2e7d3a` linden | `#25612f` |
| @tilia/query | `.query` | sève, the sap | `#2c6d9e` river | `#245a84` |

(each with its own `--accent-soft` tint and `--accent-deep` active shade; all
fills ≥ 4.9:1 against `--btn-label`, all inks ≥ 6.8:1 on paper. The sibling
vitest-bdd.dev site extends the same family with brass — équerre, the measure —
but as its own site, not a body class here.)

Brand green never re-inks: the wordmark leaf and code keywords stay
`--leaf`/`--leaf-ink` on every page, so every package screen still reads as
tilia.

Rule of application: green takes the primary role (buttons, active nav underline, defcard rule, footer links, sidebar hovers); ink does structure, not emphasis — the solid-ink button, épure's most recognizable atom, does not appear on this site. Honey appears at most once per viewport. If a screen has more honey than leaf, something is wrong.

## Type scale

| Role | Face | Size | Weight | Notes |
|---|---|---|---|---|
| Hero H1 | Sans | clamp(34–52px) | 600 | −0.02em, line-height 1.06 |
| Page H1 (API) | Sans | clamp(28–40px) | 600 | −0.015em |
| Section H2 | Sans | clamp(23–30px) | 600 | −0.01em |
| Entry H2 (API) | Mono | clamp(19–23px) | 500 | function name as heading |
| Card H3 | Sans | 17.5px | 600 | |
| Lead | Sans | 17px | 400 | muted |
| Body | Sans | 16px / 1.55 | 400 | |
| Card / prose small | Sans | 14.5–15px | 400 | muted, max ~46–66ch |
| Code | Mono | 13.5px / 1.65 | 400 | scrolls horizontally < 380px |
| Label `.k` | Mono | 11px | 400–500 | 0.14em tracking, uppercase |
| Micro label | Mono | 9–10px | 400 | footer labels, tags |

## Spacing rhythm

- Container: max-width 1080px, inline padding `clamp(20px, 4vw, 36px)`.
- Sections: vertical `clamp(52px, 8vw, 88px)`, separated by hairlines (not ink — ink borders are reserved for objects, not seams).
- Cards: 26px padding; code blocks: 20–22px.
- Grid-of-hairlines pattern (props, footer) uses shared 1px `--line` borders, épure-style.

## Page patterns

- **Landing**: header → hero (text + defcard | code figure with ts/res toggle and `npm install` footer line) → three value props in a hairline grid → épure bridge block → title-block footer. The code figure caption is plain `REACTIVE STATE` (FIG. numbering is the method's citation style, not the tool's), and section heads are just the title over the section hairline — no number, no running title. A large hand-drawn linden leaf (inline SVG, single-weight strokes, ink at 8% opacity) sits behind the code card's lower-right corner with only the tip and lower veins emerging; it hides below 920px and in print.
- **Package landing** (`query.html`, the pattern for future tilia packages): identical structure to the tilia landing — same hero grammar, its own dictionary entry (sève, matching the épure tool card verbatim), its own accent via `body.query`, and its own bridge sheet number (`SHEET A-02 · DATA`). The signature leaf recurs with the metaphor re-lit: `.leaf-mark.sap` fades the wood to 7% and strokes the vein network in river blue — query is what moves through the wood. Copy leads with fluidity (instant reads, quiet sync, no spinners); offline is a supporting card, not the headline.
- **API reference**: page head (eyebrow, H1, lead) → sticky grouped sidebar (`CORE`, `REACT`, …) + entry column. Each entry: mono name heading (self-anchoring), tag chips, one-line summary, signature block (shade + leaf left rule), one prose paragraph, one captioned example. Entries repeat with hairline separators — 30 entries is the same markup 30 times; new groups are one more `idx-group` label in the sidebar. Below 820px the sidebar becomes a wrapping top index.

## Placeholders to resolve before publishing

- `Docs` and `Compare` nav links point to `#`.
- The épure link uses `https://epure.dev` — swap in the real domain.
- API signatures/prose are set for layout, not verified against the tilia repo (see the HTML comment in `api.html`).
- GitHub/npm URLs assume `github.com/tiliajs/tilia` and the `tilia` / `@tilia/query` package names.
- `query.html` is not linked from the nav (reachable from épure's sheet A-02 and npm); decide its nav slot when Docs/Compare land.

## Explicitly avoided (per brief)

Vaporwave gradients, sparkle/rainbow emoji in chrome, self-deprecating copy. Playfulness lives inside the examples (`sky.color = 'pink'`), never in the frame.
