# Performance baseline — Slice 2.5

Measured on the canonical ADR-010 fixtures (`bench/fixtures/`, generated
by `gen_fixtures.py`): **medium** (466 lines, 10 blocks, ~30 refs) and
**large** (5226 lines, 50 blocks, ~190 refs). Reproduce with `make bench`.

Machine: darwin/arm64 (dev). Numbers are indicative, not absolute — the
gates that matter are the ADR-010 budgets and regression between runs.

## Analysis path — in-process (`bench_analysis.ml`)

Pure OCaml, no transport. p95 on the **large** fixture:

| Operation | p50 | p95 |
|---|---|---|
| `Fence_scanner.scan` | 0.21ms | 0.23ms |
| `Analyze.diagnostics` | 0.62ms | 0.70ms |
| `Semantic_tokens.of_blocks` | 0.79ms | 0.83ms |
| `Analyze.completion_at` | ~0ms | ~0ms |
| `Analyze.hover_at` | ~0ms | ~0ms |
| didChange (scan + diagnostics) | 0.89ms | 0.92ms |

The whole analysis is **sub-millisecond on 50 blocks** — two orders of
magnitude under the ADR-010 diagnostics budget (<100ms p95). The
suspected hot spots (the O(n²) `aliases_above`, re-parsing every block's
tree-sitter tree per edit) cost <1ms combined. **The analysis is not a
bottleneck.**

## Transport path — E2E over stdio (`lsp_roundtrip.py`)

| Operation | p50 | p95 | ADR-010 p95 budget |
|---|---|---|---|
| request round-trip floor | 0.011ms | 0.015ms | — |
| didChange→diagnostics [medium 12KB] | 0.21ms | 0.35ms | <100ms |
| didChange→diagnostics [large 147KB] | 1.83ms | 1.89ms | <100ms |
| semanticTokens/full [medium] | 1.27ms | 1.34ms | <80ms |
| **semanticTokens/full [large]** | **67.8ms** | **69.7ms** | **<80ms** |

`didChange→diagnostics` on the large doc is **1.9ms** end to end —
excellent. The one number near a budget is **`semanticTokens/full` on
the large doc: ~70ms p95**. Note `Semantic_tokens.of_blocks` itself is
0.83ms — so the other ~67ms is **LSP delta-position encoding + JSON
serialization of the large token array, plus stdio transfer**, not the
token computation. This is exactly what `semanticTokens/full/delta`
targets (send the diff, not the whole array).

## Frontend path — per-keystroke (`httui-desktop`, vitest bench, jsdom)

One keystroke = insert + delete (two `view.dispatch` calls):

| Fixture | mean | p99 |
|---|---|---|
| medium (10 blocks) | 0.59ms | 1.04ms |
| large (50 blocks) | 6.18ms | 6.89ms |

**10.5x medium→large.** That linear-with-doc-size scaling is the
signature of the full-document scanners (`createFencedBlockExtension`
`findBlocks`, `cm-tables`, `cm-merge-conflict`) that re-walk every line
on every `docChanged`. The viewport-scoped `referenceHighlight` would be
roughly constant. jsdom caveat: `visibleRanges` covers the whole doc, so
this is a worst-case upper bound for the viewport plugins and excludes
browser layout/paint.

## Conclusions (what the data says to optimize)

1. **LSP analysis (planned Fase 2: memo + subtree cache) — not justified
   by the bench.** Everything is sub-ms; optimizing it would tune work
   already 100x under budget (the ADR-010 anti-pattern: don't optimize
   what the bench doesn't flag).
2. **Semantic tokens encoding (Fase 3 delta) — justified**, but as the
   one transport hot spot (~70ms on large) and a future token-consuming
   client concern. The desktop does not consume server semantic tokens
   today (Lezer first-paint), so it pays 0ms of this now.
3. **Frontend full-doc scanners (Fase 4) — the real desktop win.** They
   scale linearly with doc size and dominate the keystroke cost. Early-out
   by sentinel + incrementalizing the fence scanner cut this directly.
