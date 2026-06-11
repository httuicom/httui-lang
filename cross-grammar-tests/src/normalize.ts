/**
 * Canonical node kinds for the refs grammar.
 *
 * Both engines (Lezer + tree-sitter) emit native node names; this module
 * folds them into a single vocabulary the sync test can compare. Names
 * follow the snake_case style used by the tree-sitter grammar and
 * spec/token-kinds.md. Engine-specific punctuation and roots are dropped
 * because they carry no semantic content for the sync contract.
 */
export type CanonicalKind =
  | "ref"
  | "ref_body"
  | "dot_path"
  | "path_segment"
  | "index_access"
  | "identifier"
  | "prev"
  | "number"
  | "text";

export interface CanonicalNode {
  kind: CanonicalKind;
  from: number;
  to: number;
}

const LEZER_TO_CANONICAL: Record<string, CanonicalKind | null> = {
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

const TREE_SITTER_TO_CANONICAL: Record<string, CanonicalKind | null> = {
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

export function mapLezer(name: string): CanonicalKind | null {
  if (name in LEZER_TO_CANONICAL) return LEZER_TO_CANONICAL[name];
  throw new Error(`Unknown Lezer node name: ${name}`);
}

export function mapTreeSitter(name: string): CanonicalKind | null {
  if (name in TREE_SITTER_TO_CANONICAL) return TREE_SITTER_TO_CANONICAL[name];
  throw new Error(`Unknown tree-sitter node name: ${name}`);
}

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
