# Benchmark fixtures and harness

Synthetic vault fixtures used to validate performance budgets:

- **Medium**: ~500 lines of markdown, 10 executable blocks (5 HTTP + 5 SQL),
  ~20 references.
- **Large**: ~5000 lines, 50 blocks, ~200 references.

Operations measured per fixture include incremental retokenize, semantic
tokens delta, completion popup latency, hover latency, diagnostic publish,
rename, find-all-references, format on save, and cancellation latency.

Cold-start metrics tracked separately: LSP spawn-to-ready, time-to-first-
completion after `didOpen`, first parse + semantic tokens, and schema cache
lookup. Memory budget (RSS) tracked on both medium and large fixtures.

Bench harness implementation pending.
