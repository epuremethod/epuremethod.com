import { readFile, readdir, mkdir, writeFile, copyFile, cp } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseApiEntry, parseGuideChapter } from "./schema.mjs";
import { createPrismHighlighter, createMarkdown, renderBody } from "./markdown.mjs";
import { renderApiPage, renderDocsPage } from "./templates.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const apiDir = path.join(root, "content/api");
const guideDir = path.join(root, "content/guide");
const distDir = path.join(root, "dist");

export async function copyAssets() {
  await mkdir(distDir, { recursive: true });
  await copyFile(path.join(root, "assets/style.css"), path.join(distDir, "style.css"));
  // Keep font paths in style.css valid in dist output.
  await cp(path.join(root, "assets/fonts"), path.join(distDir, "fonts"), { recursive: true });
  console.log("Copied assets to dist/");
}

async function collect(dir) {
  const files = (await readdir(dir)).filter((f) => f.endsWith(".md")).sort();
  const out = [];
  for (const file of files) {
    const raw = await readFile(path.join(dir, file), "utf8");
    out.push({ file, raw });
  }
  return out;
}

function collectApiEntries(files, errors) {
  const entries = [];
  for (const { file, raw } of files) {
    try {
      const entry = parseApiEntry(`content/api/${file}`, raw);
      const expectedSlug = file.replace(/\.md$/, "");
      if (entry.slug !== expectedSlug) {
        errors.push(
          `content/api/${file}: slug "${entry.slug}" must equal filename "${expectedSlug}"`
        );
      }
      entries.push({ ...entry, file });
    } catch (err) {
      errors.push(err.message);
    }
  }
  return entries;
}

function collectGuideChapters(files, errors) {
  const chapters = [];
  for (const { file, raw } of files) {
    try {
      const chapter = parseGuideChapter(`content/guide/${file}`, raw);
      const m = file.match(/^(\d+)-(.+)\.md$/);
      if (!m) {
        errors.push(`content/guide/${file}: filename must match "NN-slug.md"`);
      } else {
        const [, prefix, slugPart] = m;
        if (chapter.slug !== slugPart) {
          errors.push(
            `content/guide/${file}: slug "${chapter.slug}" must equal filename slug "${slugPart}"`
          );
        }
        if (chapter.sort !== Number(prefix)) {
          errors.push(
            `content/guide/${file}: sort ${chapter.sort} must equal filename prefix ${Number(prefix)}`
          );
        }
      }
      chapters.push({ ...chapter, file });
    } catch (err) {
      errors.push(err.message);
    }
  }
  return chapters;
}

function crossValidate(entries, chapters, errors) {
  const slugs = new Set();
  for (const e of entries) {
    if (slugs.has(e.slug)) errors.push(`content/api/${e.file}: duplicate slug "${e.slug}"`);
    slugs.add(e.slug);
  }
  const names = new Set();
  for (const e of entries) {
    if (names.has(e.name)) errors.push(`content/api/${e.file}: duplicate name "${e.name}"`);
    names.add(e.name);
  }
  const chapterSlugs = new Set();
  for (const c of chapters) {
    if (chapterSlugs.has(c.slug)) errors.push(`content/guide/${c.file}: duplicate slug "${c.slug}"`);
    chapterSlugs.add(c.slug);
  }
  const chapterSorts = new Set();
  for (const c of chapters) {
    if (chapterSorts.has(c.sort)) errors.push(`content/guide/${c.file}: duplicate sort ${c.sort}`);
    chapterSorts.add(c.sort);
  }
  for (const c of chapters) {
    for (const ref of c.refs) {
      if (!slugs.has(ref)) {
        errors.push(`content/guide/${c.file}: refs entry "${ref}" does not match any API slug`);
      }
    }
  }
}

function renderBodies(md, entries, chapters, errors) {
  for (const e of entries) {
    try {
      e.bodyHtml = renderBody(md, `content/api/${e.file}`, e.body, {
        allowHeadings: false,
        page: "api",
      });
    } catch (err) {
      errors.push(err.message);
    }
  }
  for (const c of chapters) {
    try {
      c.bodyHtml = renderBody(md, `content/guide/${c.file}`, c.body, {
        allowHeadings: true,
        page: "docs",
      });
    } catch (err) {
      errors.push(err.message);
    }
  }
}

export async function runBuild() {
  const errors = [];

  const [apiFiles, guideFiles] = await Promise.all([collect(apiDir), collect(guideDir)]);
  const entries = collectApiEntries(apiFiles, errors);
  const chapters = collectGuideChapters(guideFiles, errors);
  crossValidate(entries, chapters, errors);

  const highlighter = await createPrismHighlighter();
  const md = createMarkdown(highlighter);
  renderBodies(md, entries, chapters, errors);

  if (errors.length > 0) {
    console.error(`Build failed with ${errors.length} error(s):\n`);
    for (const e of errors) console.error(`  - ${e}`);
    return { ok: false };
  }

  const apiHtml = renderApiPage({ entries, highlighter });
  const docsHtml = renderDocsPage({ chapters });

  await mkdir(distDir, { recursive: true });
  await writeFile(path.join(distDir, "api.html"), apiHtml);
  await writeFile(path.join(distDir, "docs.html"), docsHtml);
  await copyAssets();

  const bytes = Buffer.byteLength(apiHtml) + Buffer.byteLength(docsHtml);
  console.log(
    `Built ${entries.length} API entries, ${chapters.length} guide chapters — ${bytes} bytes written to dist/`
  );
  return { ok: true };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const { ok } = await runBuild();
  if (!ok) process.exit(1);
}
