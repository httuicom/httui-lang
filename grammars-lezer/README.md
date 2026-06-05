# Lezer grammars

This directory hosts [Lezer](https://lezer.codemirror.net/) grammars used by
the CodeMirror 6 client for fast lexical first-paint highlighting.

Tree-sitter grammars (canonical, used by the OCaml semantic layer and the
TUI client) live in `../lib/` for httui-owned grammars and in
`../grammars-external/` for upstream ones.

Each httui-owned language has a paired Lezer and tree-sitter grammar.
Synchronization between them is enforced via cross-grammar corpus tests in
CI.
