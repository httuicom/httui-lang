# httui-lang

Language layer for [httui](https://httui.com). Provides parsing, semantic
analysis, type inference, and a Language Server (LSP) for httui blocks and
references.

## Layout

```
lib/                    OCaml library — semantics, type inference, completion,
                        diagnostics, codegen, formatter
lib/grammars/           tree-sitter grammars owned by this project
                        (canonical for semantic analysis)
grammars-lezer/         Lezer grammars for CodeMirror 6 first-paint rendering
                        (paired with tree-sitter for httui-owned languages)
grammars-external/      Upstream tree-sitter grammars vendored as submodules
                        (postgres, mysql, sqlite — arriving in later work)
bin/httui-lsp/          LSP server binary (pure OCaml) — an IO shell
                        around the library; storage reads only, never
                        touches the OS keychain
spec/                   Canonical specifications (token kinds vocabulary,
                        protocol notes)
bench/                  Benchmark fixtures and harness
OWNERS.md               Per-grammar ownership declarations
```

## Quick start

Prerequisites: OCaml 5.1+, Node 22+, tree-sitter CLI, opam, dune.

```bash
git clone git@github.com:httuicom/httui-lang.git
cd httui-lang
make install
make setup-hooks
make build
make test
```

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full development workflow,
commit style, and the grammar audit checklist.

## Quality gates

Every PR runs the following checks in CI before it can be merged:

| Check | Scope |
|---|---|
| OCaml build + tests (library + LSP binary) | Ubuntu and macOS |
| Lezer grammar build + corpus tests | `grammars-lezer/lezer-httui-refs` |
| Tree-sitter grammar generate + corpus tests | `lib/grammars/tree-sitter-httui-refs` |
| Tree-sitter sanitizers (ASan + UBSan) | scanner.c when present |
| Cross-grammar sync test | shared corpus for httui-owned grammars |
| Dependency audit | npm |

PRs that touch grammars also require the audit checklist from the PR
template to be completed.

## Documentation

- [`spec/token-kinds.md`](./spec/token-kinds.md) — canonical token kind
  vocabulary emitted by every grammar
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — development workflow, commit
  style, branch conventions
- [`OWNERS.md`](./OWNERS.md) — per-grammar ownership and review cadence
- [`SECURITY.md`](./SECURITY.md) — how to report issues
- [`CHANGELOG.md`](./CHANGELOG.md) — release history

## License

MIT. See [LICENSE](./LICENSE).
