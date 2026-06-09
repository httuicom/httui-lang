# Contributing to httui-lang

Thanks for your interest in contributing. This repository hosts the
language layer of the [httui](https://httui.com) product: tree-sitter and
Lezer grammars, the OCaml semantic library, and the LSP server binary.

## Getting started

### Prerequisites

- **OCaml 5.1+** and **dune** (install via opam)
- **Node.js 22+** (for grammar tooling: lezer-generator, tree-sitter CLI)
- **tree-sitter CLI** (`brew install tree-sitter` or via npm)

### Clone and install

```bash
git clone git@github.com:httuicom/httui-lang.git
cd httui-lang
make install
make setup-hooks    # installs commit-msg, pre-push, pre-commit hooks
```

### Build and test

```bash
make build          # OCaml lib + LSP binary + grammars
make test           # all tests across all languages
make lint           # formatters and linters
```

## Commit style

Subject-only conventional commits. No body. No emoji. No co-author tags.

Examples:

- `feat(refs): add support for nested index access`
- `fix(lsp): handle empty workspace folder gracefully`
- `chore: bump tree-sitter-postgres to 0.7.0`
- `docs(spec): clarify modifier composition rules`

The `commit-msg` hook rejects subjects that exceed 72 characters or
contain disallowed planning vocabulary (see
[CONVENTIONS.md](#public-vocabulary-discipline) below).

## Public vocabulary discipline

This is a real project, not a prototype. Internal planning artifacts
live in private notes outside this repository and **must not appear in
any public surface** — that includes branch names, commit messages, PR
titles, PR descriptions, code comments, identifiers, file names, error
messages, CHANGELOG entries, and issue titles.

If your branch name or commit subject contains identifiers like
`ADR-...`, `RFC-...`, `Slice ...`, `V1`, `Phase ...`, `vertical`,
`Story ...`, etc., rename it before pushing. Describe what the change
does, not which internal plan it implements.

The hooks installed by `make setup-hooks` enforce this on commit; the
`pre-push` hook runs the same checks against the full set of new
commits.

## Branches and pull requests

- Branch from `main` with a descriptive name (`feat/xxx`, `fix/yyy`,
  `chore/zzz`, `docs/aaa`).
- Open a PR against `main` once your change is ready for review. CI must
  pass before merge.
- Fill in the PR template completely. When your PR touches grammars
  (`grammar.js`, `refs.grammar`, `scanner.c`, or a submodule bump), the
  grammar audit checklist is mandatory.
- Keep PRs scoped. A grammar change, an LSP feature, and a CI tweak
  should be separate PRs.

## Adding a new grammar

Both engines are maintained in parallel for httui-owned languages:

- **tree-sitter** grammar lives in `lib/grammars/tree-sitter-<name>/`
- **Lezer** grammar lives in `grammars-lezer/lezer-<name>/`

Both engines must emit token kinds consistent with
[`spec/token-kinds.md`](./spec/token-kinds.md), and a cross-grammar sync
test must compare them on shared corpus inputs. Add yourself to
[`OWNERS.md`](./OWNERS.md) as the grammar owner.

## License

By submitting code to this repository, you agree that your contributions
are licensed under the MIT License (see [LICENSE](./LICENSE)).
