import { describe, expect, it } from "vitest";
// @ts-expect-error — parser is generated at build time
import { parser } from "../src/parser.js";

/** Extract the list of top-level node names from a parse tree string.
 *
 * Lezer's `Tree.toString()` returns something like
 * "File(Text,Ref(RefBody(Identifier,DotPath(Dot,PathSegment(Identifier)))))".
 * We just want to know which constructs the parser recognized.
 */
function nodeNames(input: string): string[] {
  const tree = parser.parse(input);
  const names: string[] = [];
  tree.iterate({
    enter(node) {
      names.push(node.name);
    },
  });
  return names;
}

describe("lezer-httui-refs", () => {
  describe("ref forms", () => {
    it("parses {{alias}}", () => {
      const names = nodeNames("{{req1}}");
      expect(names).toContain("Ref");
      expect(names).toContain("RefBody");
      expect(names).toContain("Identifier");
    });

    it("parses {{alias.path}}", () => {
      const names = nodeNames("{{req1.body}}");
      expect(names).toContain("Ref");
      expect(names).toContain("DotPath");
      expect(names).toContain("PathSegment");
    });

    it("parses multi-segment path {{alias.a.b.c}}", () => {
      const names = nodeNames("{{req1.body.users.name}}");
      const pathSegments = names.filter((n) => n === "PathSegment");
      // alias is the leading Identifier, then 3 path segments
      expect(pathSegments.length).toBe(3);
    });

    it("parses array index {{alias.path[0]}}", () => {
      const names = nodeNames("{{req1.body.users[0]}}");
      expect(names).toContain("IndexAccess");
      expect(names).toContain("Number");
    });

    it("parses nested index path {{alias.a[0].b}}", () => {
      const names = nodeNames("{{req1.body.users[0].id}}");
      expect(names).toContain("IndexAccess");
      const pathSegments = names.filter((n) => n === "PathSegment");
      expect(pathSegments.length).toBeGreaterThanOrEqual(2);
    });

    it("parses {{ENV_VAR}} (uppercase identifier, no dot)", () => {
      const names = nodeNames("{{API_TOKEN}}");
      expect(names).toContain("Ref");
      // Env vars are syntactically identical to aliases at this layer;
      // disambiguation happens in the semantic walk (OCaml side).
    });
  });

  describe("text + refs interaction", () => {
    it("parses surrounding text", () => {
      const names = nodeNames("hello {{req1}} world");
      expect(names).toContain("Text");
      expect(names).toContain("Ref");
    });

    it("parses multiple refs in one document", () => {
      const names = nodeNames("a {{x}} b {{y.z}} c");
      const refs = names.filter((n) => n === "Ref");
      expect(refs.length).toBe(2);
    });

    it("treats single { as text (not delimiter)", () => {
      const names = nodeNames("a { b } c");
      expect(names).toContain("Text");
      // No Ref should appear — single brace doesn't open a ref.
      expect(names.filter((n) => n === "Ref").length).toBe(0);
    });

    it("handles empty document", () => {
      const names = nodeNames("");
      expect(names).toEqual(["File"]);
    });
  });

  describe("error recovery", () => {
    it("recovers from unclosed ref {{alias", () => {
      // Lezer should produce a tree even with syntax errors (recovery).
      const tree = parser.parse("text {{alias and more text");
      expect(tree).toBeDefined();
      // Error nodes are expected; we don't assert exact shape, just
      // that the parser doesn't throw.
    });

    it("recovers from empty ref {{}}", () => {
      const tree = parser.parse("{{}}");
      expect(tree).toBeDefined();
    });
  });
});
