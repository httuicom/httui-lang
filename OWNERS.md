# Grammar owners

This file declares the owner of each grammar maintained in this repository.
Owners are responsible for:

- Evaluating upstream releases and deciding when to bump (minimum cadence:
  quarterly, more often when security fixes are involved)
- Running the audit checklist on each bump (review of `grammar.js`,
  `refs.grammar`, and any `src/scanner.c`; sanitizers clean; corpus
  regression passes; downstream consumers re-validated; performance bench
  without regression)
- Monitoring upstream issue trackers for relevant fixes
- For httui-owned grammars: maintaining synchronization between the Lezer
  and tree-sitter versions

The audit checklist is in
[`.github/PULL_REQUEST_TEMPLATE.md`](./.github/PULL_REQUEST_TEMPLATE.md).
Every grammar-bump PR description must include the completed checklist.

## Current grammars

### httui-owned (paired Lezer + tree-sitter)

| Language | tree-sitter dir | Lezer dir | Owner | Cadence |
|---|---|---|---|---|
| refs | `lib/grammars/tree-sitter-httui-refs/` | `grammars-lezer/lezer-httui-refs/` | @gandarfh | quarterly |

### External (vendored or submodule)

| Grammar | Engine | Owner | Cadence | Upstream |
|---|---|---|---|---|
| _none yet — postgres / mysql / sqlite arrive later_ | — | — | — | — |

## Adding a new grammar

1. Open an issue describing the language and use case.
2. If httui-owned, both engines must be implemented in parallel. Add
   yourself to this file before opening the PR.
3. If external, the grammar is pinned to a specific commit SHA via
   submodule and goes through the audit checklist on the initial add.
