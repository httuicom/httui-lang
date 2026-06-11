/**
 * Canonical node kinds per grammar.
 *
 * Both engines (Lezer + tree-sitter) emit native node names; this module
 * folds them into a single vocabulary the sync test can compare. Names
 * follow the snake_case style used by the tree-sitter grammars and
 * spec/token-kinds.md. Engine-specific punctuation and roots are dropped
 * because they carry no semantic content for the sync contract.
 */

export interface CanonicalNode {
  kind: string;
  from: number;
  to: number;
}

export interface GrammarConfig {
  /** Display name and corpus subdirectory. */
  name: string;
  /** Directory of the canonical tree-sitter grammar (repo-relative). */
  grammarDir: string;
  /** npm package exposing the Lezer parser. */
  lezerPackage: string;
  mapLezer: (name: string) => string | null;
  mapTreeSitter: (name: string) => string | null;
  /** Kinds that must match exactly in both directions — guards against
   * a degenerate Lezer stream that trivially passes the subset check. */
  anchorKinds: string[];
}

function mapper(
  table: Record<string, string | null>,
  engine: string,
): (name: string) => string | null {
  return (name) => {
    if (name in table) return table[name] as string | null;
    throw new Error(`Unknown ${engine} node name: ${name}`);
  };
}

const LEZER_REFS: Record<string, string | null> = {
  Ref: "ref",
  RefBody: "ref_body",
  DotPath: "dot_path",
  PathSegment: "path_segment",
  IndexAccess: "index_access",
  Identifier: "identifier",
  Prev: "prev",
  Number: "number",
  Text: "text",
  File: null,
  LBrace: null,
  RBrace: null,
  Dot: null,
  LBracket: null,
  RBracket: null,
  "⚠": null,
};

const TREE_SITTER_REFS: Record<string, string | null> = {
  ref: "ref",
  ref_body: "ref_body",
  dot_path: "dot_path",
  path_segment: "path_segment",
  index_access: "index_access",
  identifier: "identifier",
  prev: "prev",
  number: "number",
  text: "text",
  source_file: null,
  ERROR: null,
  MISSING: null,
};

const LEZER_HTTP: Record<string, string | null> = {
  RequestLine: "request_line",
  GET: "method",
  POST: "method",
  PUT: "method",
  PATCH: "method",
  DELETE: "method",
  HEAD: "method",
  OPTIONS: "method",
  Method: "method",
  Url: "url",
  QueryLine: "query_line",
  HeaderLine: "header_line",
  HeaderName: "header_name",
  HeaderValue: "header_value",
  DescLine: "desc_line",
  CommentLine: "comment_line",
  DisabledQueryLine: "disabled_query_line",
  DisabledHeaderLine: "disabled_header_line",
  Body: "body",
  BodyLine: "body_line",
  File: null,
  Colon: null,
  "⚠": null,
};

const TREE_SITTER_HTTP: Record<string, string | null> = {
  request_line: "request_line",
  method: "method",
  url: "url",
  query_line: "query_line",
  header_line: "header_line",
  header_name: "header_name",
  header_value: "header_value",
  desc_line: "desc_line",
  comment_line: "comment_line",
  disabled_query_line: "disabled_query_line",
  disabled_header_line: "disabled_header_line",
  body: "body",
  body_line: "body_line",
  source_file: null,
  ERROR: null,
  MISSING: null,
};

export const GRAMMARS: GrammarConfig[] = [
  {
    name: "refs",
    grammarDir: "../../lib/grammars/tree-sitter-httui-refs",
    lezerPackage: "@httui/lezer-refs",
    mapLezer: mapper(LEZER_REFS, "Lezer"),
    mapTreeSitter: mapper(TREE_SITTER_REFS, "tree-sitter"),
    anchorKinds: ["ref"],
  },
  {
    name: "http",
    grammarDir: "../../lib/grammars/tree-sitter-httui-http",
    lezerPackage: "@httui/lezer-http",
    mapLezer: mapper(LEZER_HTTP, "Lezer"),
    mapTreeSitter: mapper(TREE_SITTER_HTTP, "tree-sitter"),
    anchorKinds: ["request_line", "header_line"],
  },
];

export function formatStream(nodes: CanonicalNode[]): string {
  return nodes.map((n) => `${n.kind}@${n.from}..${n.to}`).join("\n");
}

/**
 * Merges contiguous `text` nodes. The engines segment plain-text runs
 * differently (Lezer splits around characters like a lone `{`), and the
 * segmentation carries no rendering meaning — the sync contract compares
 * text by coverage, not by how it was chunked.
 */
export function coalesceText(nodes: CanonicalNode[]): CanonicalNode[] {
  const out: CanonicalNode[] = [];
  for (const n of nodes) {
    const prev = out[out.length - 1];
    if (n.kind === "text" && prev?.kind === "text" && prev.to === n.from) {
      prev.to = n.to;
    } else {
      out.push({ ...n });
    }
  }
  return out;
}
