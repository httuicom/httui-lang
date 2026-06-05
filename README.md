# httui-lang

Language layer for [httui](https://httui.com). Provides parsing, semantic
analysis, type inference, and a Language Server (LSP) for httui blocks and
references.

## Layout

```
lib/                    OCaml library — semantics, type inference, completion,
                        diagnostics, codegen, formatter
grammars-lezer/         Lezer grammars for CodeMirror 6 first-paint rendering
grammars-external/      Tree-sitter grammars from upstream (postgres, mysql, ...)
                        as git submodules pinned to specific SHAs
bin/httui-lsp/          Rust binary that wraps the OCaml library via FFI
                        and depends on httui-core for storage and execution
bench/                  Benchmark fixtures and harness
OWNERS.md               Per-grammar ownership declarations
```

## Build

OCaml lib:

```bash
opam install . --deps-only --with-test
dune build
dune runtest
```

LSP binary:

```bash
cd bin/httui-lsp
cargo build
```

## License

MIT. See [LICENSE](./LICENSE).
