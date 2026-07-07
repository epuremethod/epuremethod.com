import MarkdownIt from "markdown-it";
import container from "markdown-it-container";
import Prism from "prismjs";
import "prismjs/components/prism-typescript.js";
import "prismjs/components/prism-rescript.js";

const ALLOWED_LANGS = ["typescript", "rescript", "res"];

export async function createPrismHighlighter() {
  return Prism;
}

function normalizeLang(lang) {
  if (lang === "res") return "rescript";
  return lang;
}

export function highlightCode(highlighter, code, lang) {
  const prism = highlighter || Prism;
  const prismLang = normalizeLang(lang);
  const grammar = prism.languages[prismLang];
  if (!grammar) {
    throw new Error(`Unsupported Prism language "${prismLang}"`);
  }
  const html = prism.highlight(code, grammar, prismLang);
  return `<pre class="language-${lang}"><code>${html}</code></pre>`;
}

export const toggleButton =
  '<button class="lang-toggle" type="button" aria-label="Switch example language"><span class="lt lt-ts">TS</span><span class="lt lt-res">RES</span></button>';

function markCallouts(file, body) {
  const re = /^:::[ \t]*(\S*)$/gm;
  let m;
  while ((m = re.exec(body))) {
    const name = m[1];
    if (!name) continue; // bare ":::" is a closing marker
    if (name !== "story" && name !== "pro") {
      throw new Error(
        `${file}: unknown callout container ":::${name}" (expected "story" or "pro")`
      );
    }
  }
}

function markFencePairs(tokens) {
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    if (t.type !== "fence") continue;
    const lang = normalizeLang(t.info.trim());
    const next = tokens[i + 1];
    if (
      lang === "typescript" &&
      next &&
      next.type === "fence" &&
      normalizeLang(next.info.trim()) === "rescript"
    ) {
      t.meta = { pair: "start" };
      next.meta = { pair: "end" };
      i++;
    }
  }
}

function assertNoHeadings(file, tokens) {
  for (const t of tokens) {
    if (t.type === "heading_open") {
      throw new Error(
        `${file}: API entry body must not contain headings (found <${t.tag}>) — the heading comes from "name"`
      );
    }
  }
}

export function createMarkdown(highlighter) {
  const md = new MarkdownIt({ html: false });

  md.use(container, "story", {
    render(tokens, idx) {
      return tokens[idx].nesting === 1 ? '<div class="story">\n<span class="k">Story</span>\n' : "</div>\n";
    },
  });
  md.use(container, "pro", {
    render(tokens, idx) {
      return tokens[idx].nesting === 1
        ? '<div class="pro">\n<span class="k">Pro tip</span>\n'
        : "</div>\n";
    },
  });

  md.renderer.rules.fence = (tokens, idx, options, env) => {
    const token = tokens[idx];
    const lang = normalizeLang(token.info.trim());
    if (!ALLOWED_LANGS.includes(lang)) {
      throw new Error(
        `${env.file}: code fence uses unsupported language "${lang}" (only "typescript", "rescript", or "res" allowed)`
      );
    }
    const codeHtml = highlightCode(highlighter, token.content.replace(/\n$/, ""), lang);
    const pair = token.meta && token.meta.pair;
    let out = "";
    if (env.page === "docs") {
      if (pair === "start") {
        out += `<figure class="example" data-pair><figcaption class="exbar"><span class="k">Example</span>${toggleButton}</figcaption>`;
      } else if (!pair) {
        out += `<figure class="example"><figcaption class="exbar"><span class="k">Example</span></figcaption>`;
      }
      out += codeHtml;
      if (pair === "end" || !pair) out += `</figure>`;
      return out;
    }
    if (env.page === "api") {
      if (pair === "start") {
        out += `<figure class="ex" data-pair><figcaption class="exbar"><span class="k">Example</span></figcaption>`;
        out += codeHtml;
        return out;
      }
      if (pair === "end") {
        out += codeHtml;
        out += `</figure>`;
        return out;
      }
      const plain = codeHtml.replace(/^<pre class="language-[^"]+">/, '<pre class="code">');
      out += `<figure class="ex"><figcaption class="k">Example</figcaption>${plain}</figure>`;
      return out;
    }
    if (pair === "start") out += `<div class="example" data-pair>${toggleButton}`;
    else if (!pair) out += `<div class="example">`;
    out += codeHtml;
    if (pair === "end" || !pair) out += `</div>`;
    return out;
  };

  return md;
}

export function renderBody(md, file, body, { allowHeadings, page = "api" }) {
  markCallouts(file, body);
  const env = { file, page };
  const tokens = md.parse(body, env);
  if (!allowHeadings) assertNoHeadings(file, tokens);
  markFencePairs(tokens);
  return md.renderer.render(tokens, md.options, env);
}
