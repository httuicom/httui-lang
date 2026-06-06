# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Canonical token kinds vocabulary at `spec/token-kinds.md`
- Lezer grammar for httui reference syntax at
  `grammars-lezer/lezer-httui-refs/` (corpus tests cover alias forms,
  dot navigation, array index, env vars, surrounding text, and error
  recovery)
- Tree-sitter grammar for httui reference syntax at
  `lib/grammars/tree-sitter-httui-refs/` (canonical for semantic
  analysis; corpus tests mirror the Lezer counterpart)
- Initial repository skeleton: dune workspace, OCaml library placeholder,
  Rust LSP binary placeholder, grammars directories, OWNERS file,
  benchmark fixtures directory
- CI workflow covering OCaml (Ubuntu + macOS), Rust (httui-lsp), Lezer
  grammar build and tests, tree-sitter grammar build and tests
- Repository governance: PR template with grammar audit checklist,
  SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md, dependabot config,
  issue templates, Makefile, pre-commit hooks setup

## [0.1.0] — unreleased

First public version. Tracked here once the language layer reaches
feature parity with the in-product reference resolution.
