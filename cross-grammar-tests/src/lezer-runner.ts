import { parser as refsParser } from "@httui/lezer-refs";
import { parser as httpParser } from "@httui/lezer-http";
import type { GrammarConfig, CanonicalNode } from "./normalize.js";

const PARSERS: Record<string, typeof refsParser> = {
  "@httui/lezer-refs": refsParser,
  "@httui/lezer-http": httpParser,
};

/** Parses input with the grammar's Lezer parser and returns a
 * normalized stream. */
export function parseLezer(
  grammar: GrammarConfig,
  input: string,
): CanonicalNode[] {
  const parser = PARSERS[grammar.lezerPackage];
  if (!parser) throw new Error(`No Lezer parser for ${grammar.lezerPackage}`);
  const tree = parser.parse(input);
  const out: CanonicalNode[] = [];
  tree.iterate({
    enter(node) {
      const kind = grammar.mapLezer(node.name);
      if (kind !== null) {
        out.push({ kind, from: node.from, to: node.to });
      }
    },
  });
  return out;
}
