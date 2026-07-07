import { highlightCode, toggleButton } from "./markdown.mjs";

const WORDMARK_SVG = `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
  <path d="M12 3C7.2 4.9 4.6 8.8 5.5 13.3 6.3 17 9 20.1 12 21c3-0.9 5.7-4 6.5-7.7C19.4 8.8 16.8 4.9 12 3Z"/>
  <path d="M12 7v10M12 11.5 9.2 9.7M12 11.5l2.8-1.8M12 15.5 8.8 13.4M12 15.5l3.2-2.1" stroke-width="1.1"/>
</svg>`;

const FAVICON_URL =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%232e7d3a' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 3C7.2 4.9 4.6 8.8 5.5 13.3 6.3 17 9 20.1 12 21c3-0.9 5.7-4 6.5-7.7C19.4 8.8 16.8 4.9 12 3Z'/%3E%3Cpath d='M12 7v10M12 11.5 9.2 9.7M12 11.5l2.8-1.8M12 15.5 8.8 13.4M12 15.5l3.2-2.1' stroke-width='1.1'/%3E%3C/svg%3E";

const PRE_PAINT_SCRIPT = `/* Language choice, resolved before first paint.
   Priority: ?lang= query param > localStorage > "ts". */
(function () {
  var q = new URLSearchParams(location.search).get("lang");
  var saved = null;
  try { saved = localStorage.getItem("tilia-lang"); } catch (e) {}
  var lang = (q === "ts" || q === "res") ? q : (saved === "res" ? "res" : "ts");
  document.documentElement.setAttribute("data-lang", lang);
})();`;

const TOGGLE_LISTENER_SCRIPT = `/* Language toggle: one delegated listener flips html[data-lang] and persists.
   The buttons carry no state — CSS renders them from the attribute. */
document.addEventListener("click", function (e) {
  if (!e.target.closest(".lang-toggle, .toggle")) return;
  var next = document.documentElement.getAttribute("data-lang") === "ts" ? "res" : "ts";
  document.documentElement.setAttribute("data-lang", next);
  try { localStorage.setItem("tilia-lang", next); } catch (err) {}
});`;

const DOCS_SCROLL_SPY_SCRIPT = `/* Scroll-spy: highlight the current chapter in the reading path. */
(function () {
  var links = {};
  document.querySelectorAll(".toc a[href^='#']").forEach(function (a) {
    links[a.hash.slice(1)] = a;
  });
  var spy = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (!en.isIntersecting) return;
      Object.keys(links).forEach(function (id) { links[id].removeAttribute("aria-current"); });
      links[en.target.id].setAttribute("aria-current", "true");
    });
  }, { rootMargin: "-10% 0px -75% 0px" });
  document.querySelectorAll(".chapter[id]").forEach(function (s) { spy.observe(s); });
})();`;

function header(active) {
  return `<header class="top">
  <div class="wrap">
    <a class="wordmark" href="./index.html" aria-label="tilia — home">${WORDMARK_SVG}tilia</a>
    <nav class="nav" aria-label="Site">
      <a href="./index.html">Home</a>
      <a href="./docs.html"${active === "docs" ? ' aria-current="page"' : ""}>Docs</a>
      <a href="./api.html"${active === "api" ? ' aria-current="page"' : ""}>API</a>
      <a href="#">Compare</a>
      <a href="https://github.com/tiliajs/tilia">GitHub</a>
    </nav>
  </div>
</header>`;
}

function footer() {
  return `<footer class="foot">
  <div class="wrap">
    <div class="fcell"><span class="lbl">Package</span><span class="val"><a href="https://www.npmjs.com/package/tilia">tilia on npm</a></span></div>
    <div class="fcell"><span class="lbl">Source</span><span class="val"><a href="https://github.com/tiliajs/tilia">github.com/tiliajs/tilia</a></span></div>
    <div class="fcell"><span class="lbl">License</span><span class="val">MIT</span></div>
    <div class="fcell"><span class="lbl">Method</span><span class="val"><a href="https://epure.dev">épure</a></span></div>
    <div class="fcell"><span class="lbl">Site</span><span class="val">tiliajs.com</span></div>
  </div>
</footer>`;
}

export function shell({
  title,
  description,
  active,
  main,
  scripts = [],
  includePrePaint = false,
  includeToggleScript = false,
  includeSkip = false,
  htmlAttrs = 'lang="en"',
  mainAttrs = "",
}) {
  const bundledScripts = includeToggleScript ? [TOGGLE_LISTENER_SCRIPT, ...scripts] : scripts;
  const allScripts = bundledScripts.map((code) => `<script>${code}</script>`).join("\n");
  const prePaint = includePrePaint ? `<script>${PRE_PAINT_SCRIPT}</script>` : "";
  const skip = includeSkip ? '<a class="skip" href="#content">Skip to content</a>' : "";
  return `<!doctype html>
<html ${htmlAttrs}>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="${description}">
<title>${title}</title>
<link rel="icon" href="${FAVICON_URL}">
<link rel="stylesheet" href="./style.css">
${prePaint}
</head>
<body>
${skip}
${header(active)}
<main${mainAttrs}>
${main}
</main>
${footer()}
${allScripts}
</body>
</html>
`;
}

const MODULE_LABEL = { core: "Core", react: "React" };
const MODULE_ORDER = ["core", "react"];

function renderSignaturePair(highlighter, ts, res) {
  const tsHtml = highlightCode(highlighter, ts, "typescript").replace(
    '<pre class="language-typescript">',
    '<pre class="sig language-typescript">'
  );
  const resHtml = highlightCode(highlighter, res, "rescript").replace(
    '<pre class="language-rescript">',
    '<pre class="sig language-rescript">'
  );
  return `<div class="sig-wrap" data-pair>${toggleButton}${tsHtml}${resHtml}</div>`;
}

function indexLabel(entry) {
  const m = entry.signature.ts.match(/^function\s+\w+(?:<[^>]+>)?\(([^)]*)\)/);
  if (!m) return entry.name;
  const raw = m[1].trim();
  if (raw === "") return `${entry.name}()`;
  const args = raw
    .split(",")
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => {
      const [name] = part.split(":");
      return name.trim();
    })
    .join(", ");
  return `${entry.name}(${args})`;
}

export function renderApiPage({ entries, highlighter }) {
  const groups = MODULE_ORDER.map((mod) => ({
    mod,
    entries: entries.filter((e) => e.module === mod).sort((a, b) => a.sort - b.sort),
  })).filter((g) => g.entries.length > 0);

  const index = groups
    .map(
      (g) =>
        `<p class="k idx-group">${MODULE_LABEL[g.mod]}</p>\n` +
        g.entries.map((e) => `<a href="#${e.slug}">${indexLabel(e)}</a>`).join("\n")
    )
    .join("\n");

  const articles = groups
    .map((g) => g.entries.map((e) => renderApiEntry(e, highlighter)).join("\n"))
    .join("\n");

  const main = `<div class="api-head">
  <div class="wrap">
    <p class="eyebrow">Reference<span class="sep">·</span>v1.x<span class="sep">·</span>TypeScript &amp; ReScript signatures</p>
    <h1>API Reference</h1>
    <p class="sec-lead">The public surface of tilia. Each entry gives the signature, behavior, and one minimal example.</p>
  </div>
</div>

<div class="wrap api-layout">
  <nav class="api-index" aria-label="API index">
${index}
  </nav>
  <div class="api-entries">
${articles}
  </div>
</div>`;

  return shell({
    title: "API Reference — tilia",
    description:
      "tilia API reference — the complete public surface of the tilia state management library for TypeScript and ReScript.",
    active: "api",
    main,
    includePrePaint: true,
    includeToggleScript: true,
    htmlAttrs: 'lang="en" data-lang="ts"',
  });
}

function renderApiEntry(entry, highlighter) {
  const tags = [entry.module, ...entry.tags]
    .map((t, i) => `<span${i === 0 ? ` class="${entry.module}"` : ""}>${i === 0 ? MODULE_LABEL[entry.module] : t}</span>`)
    .join("");
  const sig = renderSignaturePair(highlighter, entry.signature.ts, entry.signature.res);
  return `<article class="entry" id="${entry.slug}">
  <header class="entry-head">
    <h2><a href="#${entry.slug}">${indexLabel(entry)}</a></h2>
    <p class="tags">${tags}<span>Since ${entry.since}</span></p>
  </header>
  <p class="summary">${entry.summary}</p>
  ${sig}
  <div class="prose">${entry.bodyHtml}</div>
</article>`;
}

export function renderDocsPage({ chapters }) {
  const sorted = [...chapters].sort((a, b) => a.sort - b.sort);
  const toc = sorted.map((c) => `<li><a href="#${c.slug}">${c.title}</a></li>`).join("\n");
  const body = sorted.map((c, i) => renderChapter(c, i)).join("\n");

  const main = `<div class="docs-head">
  <div class="wrap">
    <p class="eyebrow">Docs<span class="sep">·</span>v1.x<span class="sep">·</span>Guided tour</p>
    <h1>The Guide</h1>
    <p class="standfirst">A reading path through tilia, in order: the mental model first, then tracking, computed values, observers, and React. Read it top to bottom once. When you need to look something up later, use the <a href="./api.html">API reference</a> instead — it is flat, complete, and made for that.</p>
  </div>
</div>

<div class="wrap docs-layout">
  <nav class="toc" aria-label="Chapters">
    <p class="k idx-group">Read in order</p>
    <ol>
${toc}
    </ol>
  </nav>
  <div class="chapters">
${body}
  </div>
</div>`;

  return shell({
    title: "The Guide — tilia",
    description:
      "The tilia guide — a reading path through the mental model, tracking, computed values, observers, and React integration.",
    active: "docs",
    main,
    includePrePaint: true,
    includeToggleScript: true,
    includeSkip: true,
    htmlAttrs: 'lang="en" data-lang="ts"',
    mainAttrs: ' id="content"',
    scripts: [DOCS_SCROLL_SPY_SCRIPT],
  });
}

function renderChapter(chapter, index) {
  const refs =
    chapter.refs.length > 0
      ? `<p class="xref">Reference: ${chapter.refs
        .map((slug) => `<a href="./api.html#${slug}">${slug}</a>`)
        .join(", ")} <span class="arrow">→</span></p>`
      : "";
  return `<section class="chapter" id="${chapter.slug}">
  <div class="ch-kicker"><span class="no">${String(index + 1).padStart(2, "0")}</span><span class="rule"></span></div>
  <h2><a href="#${chapter.slug}">${chapter.title}</a></h2>
  ${chapter.bodyHtml}
  ${refs}
</section>`;
}
