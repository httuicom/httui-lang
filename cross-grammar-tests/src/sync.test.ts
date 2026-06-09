import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { coalesceText, formatStream, type CanonicalNode } from "./normalize.js";
import { parseLezer } from "./lezer-runner.js";
import { parseTreeSitter } from "./tree-sitter-runner.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const CORPUS_DIR = resolve(HERE, "../corpus");

interface Case {
  name: string;
  input: string;
  divergenceAllowed: boolean;
}

function loadCorpus(): Case[] {
  return readdirSync(CORPUS_DIR)
    .filter((f) => f.endsWith(".input"))
    .sort()
    .map((file) => ({
      name: file.replace(/\.input$/, ""),
      input: readFileSync(join(CORPUS_DIR, file), "utf8"),
      divergenceAllowed: file.includes(".diverges."),
    }));
}

describe("cross-grammar sync (refs)", () => {
  const cases = loadCorpus();

  for (const c of cases) {
    if (c.divergenceAllowed) {
      it(`${c.name}: both grammars parse without throwing`, () => {
        expect(() => parseLezer(c.input)).not.toThrow();
        expect(() => parseTreeSitter(c.input)).not.toThrow();
      });
    } else {
      it(`${c.name}: lezer stream is a coarsening of tree-sitter`, () => {
        const lezer = coalesceText(parseLezer(c.input));
        const ts = coalesceText(parseTreeSitter(c.input));

        // Contract: tree-sitter is canonical; Lezer is rendering-only and
        // may emit LESS structure, never DIFFERENT structure. Every Lezer
        // node must exist in the tree-sitter stream with the same span
        // and canonical kind.
        const tsKeys = new Set(ts.map((n) => `${n.kind}@${n.from}..${n.to}`));
        const missing = lezer.filter(
          (n) => !tsKeys.has(`${n.kind}@${n.from}..${n.to}`),
        );
        expect(
          formatStream(missing),
          "lezer nodes absent from the tree-sitter stream",
        ).toBe("");

        // Ref anchors must match exactly in both directions — guards
        // against a degenerate Lezer that emits nothing and trivially
        // passes the subset check above.
        const refsOf = (nodes: CanonicalNode[]) =>
          formatStream(nodes.filter((n) => n.kind === "ref"));
        expect(refsOf(lezer)).toBe(refsOf(ts));
      });
    }
  }
});
