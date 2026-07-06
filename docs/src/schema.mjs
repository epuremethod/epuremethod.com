import * as S from "sury";
import matter from "gray-matter";

const slugPattern = /^[a-z0-9-]+$/;

const apiEntrySchema = S.schema({
  name: S.string,
  slug: S.string.with(S.pattern, slugPattern),
  kind: S.union(["function", "type", "hook"]),
  module: S.union(["core", "react"]),
  since: S.string,
  sort: S.int32,
  summary: S.string,
  signature: S.schema({
    ts: S.min(S.string, 1),
    res: S.min(S.string, 1),
  }),
  tags: S.optional(S.array(S.string), []),
});

const guideChapterSchema = S.schema({
  title: S.string,
  slug: S.string.with(S.pattern, slugPattern),
  sort: S.int32,
  refs: S.optional(S.array(S.string), []),
});

function parseEntry(file, raw, schema) {
  const { data, content } = matter(raw);
  try {
    const frontmatter = S.parser(schema)(data);
    return { ...frontmatter, body: content };
  } catch (err) {
    throw new Error(`${file}: ${err.message}`);
  }
}

export function parseApiEntry(file, raw) {
  return parseEntry(file, raw, apiEntrySchema);
}

export function parseGuideChapter(file, raw) {
  return parseEntry(file, raw, guideChapterSchema);
}
