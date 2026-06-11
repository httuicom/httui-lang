import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { GrammarConfig, CanonicalNode } from "./normalize.js";

const HERE = dirname(fileURLToPath(import.meta.url));

const NODE_RE =
  /^\s*\(([A-Za-z_][\w]*)\s+\[(\d+),\s*(\d+)\]\s+-\s+\[(\d+),\s*(\d+)\]/;

function rowColToOffset(input: string, row: number, col: number): number {
  let offset = 0;
  let line = 0;
  for (let i = 0; i < input.length && line < row; i++) {
    if (input[i] === "\n") line++;
    offset++;
  }
  return offset + col;
}

/**
 * Parses input with the grammar's canonical tree-sitter parser and
 * returns a normalized stream. The parser is loaded by shelling out to
 * the `tree-sitter` CLI, which already builds and caches parser.c on
 * demand — avoids depending on native node bindings or a WASM build step.
 */
export function parseTreeSitter(
  grammar: GrammarConfig,
  input: string,
): CanonicalNode[] {
  const grammarDir = resolve(HERE, grammar.grammarDir);
  const tmp = mkdtempSync(join(tmpdir(), "httui-cross-"));
  const file = join(tmp, "input.txt");
  writeFileSync(file, input, "utf8");
  let stdout: string;
  try {
    stdout = execFileSync("tree-sitter", ["parse", file], {
      cwd: grammarDir,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (e) {
    // The CLI exits non-zero when the tree contains ERROR/MISSING nodes,
    // but still prints the tree — exactly the error-recovery cases the
    // corpus needs to compare.
    const stdoutOnError = (e as { stdout?: unknown }).stdout;
    if (typeof stdoutOnError === "string" && stdoutOnError.length > 0) {
      stdout = stdoutOnError;
    } else {
      throw e;
    }
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }

  const out: CanonicalNode[] = [];
  for (const line of stdout.split("\n")) {
    const m = NODE_RE.exec(line);
    if (!m) continue;
    const name = m[1];
    const startRow = Number(m[2]);
    const startCol = Number(m[3]);
    const endRow = Number(m[4]);
    const endCol = Number(m[5]);
    const kind = grammar.mapTreeSitter(name);
    if (kind === null) continue;
    out.push({
      kind,
      from: rowColToOffset(input, startRow, startCol),
      to: rowColToOffset(input, endRow, endCol),
    });
  }
  return out;
}
