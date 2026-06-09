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

## Harness

- `lsp_roundtrip.py` — transport baseline against the built `httui-lsp`
  binary: spawn-to-initialize, request round-trip (framing + JSON +
  dispatch), and didChange ingestion. No external dependencies.

```bash
dune build
make bench          # or: python3 bench/lsp_roundtrip.py
```

Feature-level operations (hover, completion, semantic tokens,
diagnostics) gain sections here as the server implements them; the
fixtures above become their inputs.
