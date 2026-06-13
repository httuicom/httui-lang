# Benchmark fixtures and harness

Synthetic vault fixtures used to validate the ADR-010 performance
budgets, generated deterministically by `gen_fixtures.py`:

- **medium.md**: ~500 lines, 10 executable blocks (5 HTTP + 5 SQL), ~30 refs.
- **large.md**: ~5000 lines, 50 blocks (mixed), ~190 refs.

Refs only point at blocks declared above (DAG by construction), so they
exercise real scope resolution. Regenerate with `python3 bench/gen_fixtures.py`.

## Harness

Two complementary benchmarks, both run by `make bench`:

- `bench_analysis.ml` — **in-process** analysis cost (no transport): scan,
  diagnostics, semantic tokens, completion, hover over each fixture. This
  isolates the pure-OCaml algorithm cost.
- `lsp_roundtrip.py` — **E2E over stdio**: spawn-to-initialize, request
  round-trip floor, and per-fixture `didChange→diagnostics` +
  `semanticTokens/full`. The gap between this and the in-process numbers
  is the LSP encoding + transport cost. No external dependencies.

```bash
make bench
# or individually:
python3 bench/gen_fixtures.py
dune exec bench/bench_analysis.exe -- bench/fixtures
python3 bench/lsp_roundtrip.py
```

Current numbers and the optimization conclusions they drive live in
[`BASELINE.md`](BASELINE.md).
