# Grammar owners

This file declares the owner of each grammar maintained in this repository.
Owners are responsible for:

- Evaluating upstream releases and deciding when to bump (minimum cadence:
  quarterly, more often for security)
- Running the audit checklist on each bump (review of `grammar.js` and
  `src/scanner.c`; sanitizers clean; corpus regression passes; downstream
  type inference re-validated; performance bench without regression)
- Monitoring upstream issue trackers for security-related issues
- For httui-owned grammars: maintaining synchronization between the Lezer
  and tree-sitter versions

## Current grammars

| Grammar | Engine | Owner | Cadence |
|---|---|---|---|
| _none yet_ | — | — | — |

Grammars are added in subsequent work.

## Bump checklist

See the architecture documentation. Every grammar-bump PR description must
include the completed checklist.
