import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import {
  GRAMMARS,
  coalesceText,
  formatStream,
  type CanonicalNode,
} from "./normalize.js";
import { parseLezer } from "./lezer-runner.js";
import { parseTreeSitter } from "./tree-sitter-runner.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const CORPUS_DIR = resolve(HERE, "../corpus");

interface Case {
  name: string;
  input: string;
  divergenceAllowed: boolean;
}

function loadCorpus(grammarName: string): Case[] {
  const dir = join(CORPUS_DIR, grammarName);
  return readdirSync(dir)
    .filter((f) => f.endsWith(".input"))
    .sort()
    .map((file) => ({
      name: file.replace(/\.input$/, ""),
      input: readFileSync(join(dir, file), "utf8"),
      divergenceAllowed: file.includes(".diverges."),
    }));
}

for (const grammar of GRAMMARS) {
  describe(`cross-grammar sync (${grammar.name})`, () => {
    const cases = loadCorpus(grammar.name);

    for (const c of cases) {
      if (c.divergenceAllowed) {
        it(`${c.name}: both grammars parse without throwing`, () => {
          expect(() => parseLezer(grammar, c.input)).not.toThrow();
          expect(() => parseTreeSitter(grammar, c.input)).not.toThrow();
        });
      } else {
        it(`${c.name}: lezer stream is a coarsening of tree-sitter`, () => {
          const lezer = coalesceText(parseLezer(grammar, c.input));
          const ts = coalesceText(parseTreeSitter(grammar, c.input));

          // Contract: tree-sitter is canonical; Lezer is rendering-only
          // and may emit LESS structure, never DIFFERENT structure.
          // Every Lezer node must exist in the tree-sitter stream with
          // the same span and canonical kind.
          const tsKeys = new Set(
            ts.map((n) => `${n.kind}@${n.from}..${n.to}`),
          );
          const missing = lezer.filter(
            (n) => !tsKeys.has(`${n.kind}@${n.from}..${n.to}`),
          );
          expect(
            formatStream(missing),
            "lezer nodes absent from the tree-sitter stream",
          ).toBe("");

          // Anchor kinds must match exactly in both directions — guards
          // against a degenerate Lezer that emits nothing and trivially
          // passes the subset check above.
          const anchorsOf = (nodes: CanonicalNode[]) =>
            formatStream(
              nodes.filter((n) => grammar.anchorKinds.includes(n.kind)),
            );
          expect(anchorsOf(lezer)).toBe(anchorsOf(ts));
        });
      }
    }
  });
}
