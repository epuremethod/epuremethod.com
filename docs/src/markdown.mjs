import MarkdownIt from "markdown-it";
import container from "markdown-it-container";
import { createHighlighter } from "shiki";
import { readFile } from "node:fs/promises";

const THEME = "github-light";
const ALLOWED_LANGS = ["typescript", "rescript"];

export async function createShikiHighlighter(grammarPath) {
  const grammar = JSON.parse(await readFile(grammarPath, "utf8"));
  grammar.name = "rescript";
  return createHighlighter({
    themes: [THEME],
    langs: ["typescript", grammar],
  });
}

export function highlightCode(highlighter, code, lang) {
  const raw = highlighter.codeToHtml(code, { lang, theme: THEME });
  return raw.replace(/^<pre[^>]*>/, `<pre class="language-${lang}">`);
}

export const toggleButton =
  '<button class="toggle" type="button" aria-label="Switch example language"><span class="ts">ts</span> | <span class="res">res</span></button>';

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
    const lang = t.info.trim();
    const next = tokens[i + 1];
    if (
      lang === "typescript" &&
      next &&
      next.type === "fence" &&
      next.info.trim() === "rescript"
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
      return tokens[idx].nesting === 1 ? '<aside class="story">\n' : "</aside>\n";
    },
  });
  md.use(container, "pro", {
    render(tokens, idx) {
      return tokens[idx].nesting === 1
        ? '<aside class="pro"><p class="k pro-label">Pro tip</p>\n'
        : "</aside>\n";
    },
  });

  md.renderer.rules.fence = (tokens, idx, options, env) => {
    const token = tokens[idx];
    const lang = token.info.trim();
    if (!ALLOWED_LANGS.includes(lang)) {
      throw new Error(
        `${env.file}: code fence uses unsupported language "${lang}" (only "typescript" or "rescript" allowed)`
      );
    }
    const codeHtml = highlightCode(highlighter, token.content.replace(/\n$/, ""), lang);
    const pair = token.meta && token.meta.pair;
    let out = "";
    if (pair === "start") out += `<div class="example" data-pair>${toggleButton}`;
    else if (!pair) out += `<div class="example">`;
    out += codeHtml;
    if (pair === "end" || !pair) out += `</div>`;
    return out;
  };

  return md;
}

export function renderBody(md, file, body, { allowHeadings }) {
  markCallouts(file, body);
  const env = { file };
  const tokens = md.parse(body, env);
  if (!allowHeadings) assertNoHeadings(file, tokens);
  markFencePairs(tokens);
  return md.renderer.render(tokens, md.options, env);
}
