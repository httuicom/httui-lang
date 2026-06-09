import { parser } from "@httui/lezer-refs";
import { mapLezer, type CanonicalNode } from "./normalize.js";

/** Parses input with the Lezer grammar and returns a normalized stream. */
export function parseLezer(input: string): CanonicalNode[] {
  const tree = parser.parse(input);
  const out: CanonicalNode[] = [];
  tree.iterate({
    enter(node) {
      const kind = mapLezer(node.name);
      if (kind !== null) {
        out.push({ kind, from: node.from, to: node.to });
      }
    },
  });
  return out;
}
