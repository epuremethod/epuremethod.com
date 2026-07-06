import { highlightCode, toggleButton } from "./markdown.mjs";

const WORDMARK_SVG = `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
  <path d="M12 3C7.2 4.9 4.6 8.8 5.5 13.3 6.3 17 9 20.1 12 21c3-0.9 5.7-4 6.5-7.7C19.4 8.8 16.8 4.9 12 3Z"/>
  <path d="M12 7v10M12 11.5 9.2 9.7M12 11.5l2.8-1.8M12 15.5 8.8 13.4M12 15.5l3.2-2.1" stroke-width="1.1"/>
</svg>`;

// NOTE: pre-paint snippet default is "res" (see §7); the server-rendered
// data-lang attribute matches that default so there is no flash on load.
const PRE_PAINT_SCRIPT = `(() => {
  const q = new URLSearchParams(location.search).get("lang");
  const s = localStorage.getItem("lang");
  const v = q === "ts" || q === "res" ? q : s === "res" ? "res" : s === "ts" ? "ts" : "res";
  document.documentElement.dataset.lang = v;
})();`;

const TOGGLE_LISTENER_SCRIPT = `document.addEventListener("click", (e) => {
  if (!e.target.closest(".toggle")) return;
  const v = document.documentElement.dataset.lang === "ts" ? "res" : "ts";
  document.documentElement.dataset.lang = v;
  localStorage.setItem("lang", v);
});`;

function header(active) {
  return `<header class="top">
  <div class="wrap">
    <a class="wordmark" href="./index.html" aria-label="tilia — home">${WORDMARK_SVG}tilia</a>
    <nav class="nav" aria-label="Site">
      <a href="./index.html">Home</a>
      <a href="./docs.html"${active === "docs" ? ' aria-current="page"' : ""}>Docs</a>
      <a href="./api.html"${active === "api" ? ' aria-current="page"' : ""}>API</a>
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

export function shell({ title, description, active, main }) {
  return `<!doctype html>
<html data-lang="res">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="${description}">
<title>${title}</title>
<link rel="stylesheet" href="style.css">
<script>${PRE_PAINT_SCRIPT}</script>
</head>
<body>
<a class="skip-link" href="#main">Skip to content</a>
${header(active)}
<main id="main">
${main}
</main>
${footer()}
<script>${TOGGLE_LISTENER_SCRIPT}</script>
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
  return `<div class="example sig-wrap" data-pair>${toggleButton}${tsHtml}${resHtml}</div>`;
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
        g.entries.map((e) => `<a href="#${e.slug}">${e.name}</a>`).join("\n")
    )
    .join("\n");

  const articles = groups
    .map((g) => g.entries.map((e) => renderApiEntry(e, highlighter)).join("\n"))
    .join("\n");

  const main = `<div class="api-head">
  <div class="wrap">
    <p class="eyebrow">Reference<span class="sep">·</span>TypeScript &amp; ReScript signatures</p>
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
  });
}

function renderApiEntry(entry, highlighter) {
  const tags = [entry.module, ...entry.tags]
    .map((t, i) => `<span${i === 0 ? ` class="${entry.module}"` : ""}>${i === 0 ? MODULE_LABEL[entry.module] : t}</span>`)
    .join("");
  const sig = renderSignaturePair(highlighter, entry.signature.ts, entry.signature.res);
  return `<article class="entry" id="${entry.slug}">
  <header class="entry-head">
    <h2><a href="#${entry.slug}">${entry.name}</a></h2>
    <p class="tags">${tags}<span>Since ${entry.since}</span></p>
  </header>
  <p class="summary">${entry.summary}</p>
  ${sig}
  <div class="prose">${entry.bodyHtml}</div>
</article>`;
}

export function renderDocsPage({ chapters }) {
  const sorted = [...chapters].sort((a, b) => a.sort - b.sort);
  const toc = sorted
    .map((c, i) => `<a href="#${c.slug}"><span class="k">${String(i + 1).padStart(2, "0")}</span> ${c.title}</a>`)
    .join("\n");
  const body = sorted.map((c) => renderChapter(c)).join("\n");

  const main = `<div class="api-head">
  <div class="wrap">
    <p class="eyebrow">Guide</p>
    <h1>Docs</h1>
    <p class="sec-lead">A guided tour of tilia's mental model, from first render to reactive arrays.</p>
  </div>
</div>

<div class="wrap api-layout">
  <nav class="api-index" aria-label="Chapter index">
${toc}
  </nav>
  <div class="api-entries">
${body}
  </div>
</div>`;

  return shell({
    title: "Docs — tilia",
    description: "tilia guide — the mental model, getting started, and every reactive building block explained.",
    active: "docs",
    main,
  });
}

function renderChapter(chapter) {
  const refs =
    chapter.refs.length > 0
      ? `<p class="prose">Reference: ${chapter.refs
          .map((slug) => `<a href="api.html#${slug}">${slug}</a>`)
          .join(", ")}</p>`
      : "";
  return `<article class="entry" id="${chapter.slug}">
  <header class="entry-head">
    <h2>${chapter.title}</h2>
  </header>
  <div class="prose">${chapter.bodyHtml}</div>
  ${refs}
</article>`;
}
