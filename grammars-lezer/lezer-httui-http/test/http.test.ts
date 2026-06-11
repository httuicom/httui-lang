import { describe, expect, it } from "vitest";
// @ts-expect-error — parser is generated at build time
import { parser } from "../src/parser.js";

/** Extract the list of node names from a parse tree. */
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

describe("lezer-httui-http", () => {
  describe("request line", () => {
    it("specializes known methods", () => {
      expect(nodeNames("GET https://x.com")).toContain("GET");
      expect(nodeNames("POST /users")).toContain("POST");
      expect(nodeNames("DELETE /users/1")).toContain("DELETE");
    });

    it("keeps unknown uppercase methods generic", () => {
      const names = nodeNames("FOO https://x.com");
      expect(names).toContain("Method");
      expect(names).toContain("Url");
    });

    it("parses a method alone (mid-typing)", () => {
      const names = nodeNames("GET");
      expect(names).toContain("GET");
      expect(names).not.toContain("Url");
    });

    it("keeps the inline query inside the url token", () => {
      const names = nodeNames("GET https://x.com/users?page=1&limit=10");
      expect(names).toContain("Url");
      expect(names.filter((n) => n === "QueryLine").length).toBe(0);
    });
  });

  describe("query and header lines", () => {
    it("parses query continuations", () => {
      const names = nodeNames("GET /x\n?page=1\n&limit=10");
      expect(names.filter((n) => n === "QueryLine").length).toBe(2);
    });

    it("parses headers with colons in the value", () => {
      const names = nodeNames("GET /x\nOrigin: https://app.example.com");
      expect(names).toContain("HeaderName");
      expect(names).toContain("HeaderValue");
    });

    it("parses a header without value", () => {
      const names = nodeNames("GET /x\nX-Empty:");
      expect(names).toContain("HeaderName");
      expect(names).not.toContain("HeaderValue");
    });
  });

  describe("hash family", () => {
    it("distinguishes desc, disabled rows and comments", () => {
      const doc = [
        "GET /x",
        "# desc: token for staging",
        "Authorization: Bearer abc",
        "# X-Disabled: value",
        "# &limit=10",
        "# free-form note",
        "#bare",
      ].join("\n");
      const names = nodeNames(doc);
      expect(names.filter((n) => n === "DescLine").length).toBe(1);
      expect(names.filter((n) => n === "DisabledHeaderLine").length).toBe(1);
      expect(names.filter((n) => n === "DisabledQueryLine").length).toBe(1);
      expect(names.filter((n) => n === "CommentLine").length).toBe(2);
    });

    it("treats desc without trailing space as a disabled header", () => {
      const names = nodeNames("GET /x\n# desc:missing-space");
      expect(names).toContain("DisabledHeaderLine");
      expect(names).not.toContain("DescLine");
    });
  });

  describe("body", () => {
    it("starts after the first blank line and stays opaque", () => {
      const doc = [
        "POST /x",
        "Content-Type: application/json",
        "",
        "{",
        '  "note": "b: c",',
        "}",
      ].join("\n");
      const names = nodeNames(doc);
      expect(names).toContain("Body");
      expect(names.filter((n) => n === "BodyLine").length).toBe(3);
      // header-like body content must not lex as a header
      expect(names.filter((n) => n === "HeaderName").length).toBe(1);
    });

    it("keeps {{refs}} as plain body/url/header text", () => {
      const doc = "GET https://x.com/{{req1.body.id}}\nAuth: {{TOKEN}}";
      const names = nodeNames(doc);
      expect(names).toContain("Url");
      expect(names).toContain("HeaderValue");
    });

    it("tolerates blank lines inside the body", () => {
      const doc = "GET /x\n\nline1\n\n\nline2";
      const names = nodeNames(doc);
      expect(names.filter((n) => n === "BodyLine").length).toBe(2);
    });
  });

  describe("prelude and recovery", () => {
    it("skips leading blank lines and comments", () => {
      const names = nodeNames("\n# warm-up\nGET /x");
      expect(names).toContain("CommentLine");
      expect(names).toContain("GET");
    });

    it("handles an empty document", () => {
      expect(nodeNames("")).toEqual(["File"]);
    });

    it("handles no trailing newline", () => {
      const names = nodeNames("GET https://x.com/a");
      expect(names).toContain("Url");
    });

    it("recovers from a lowercase method", () => {
      const tree = parser.parse("get /x");
      expect(tree).toBeDefined();
    });

    it("recovers from a header missing its colon", () => {
      const names = nodeNames("GET /x\nnot-a-header\nB: c");
      // the following well-formed header still parses
      expect(names.filter((n) => n === "HeaderValue").length).toBeGreaterThan(
        0,
      );
    });
  });
});
