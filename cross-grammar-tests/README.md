# cross-grammar-tests

Asserts that the Lezer (`grammars-lezer/lezer-httui-refs`) and tree-sitter
(`lib/grammars/tree-sitter-httui-refs`) grammars produce equivalent
normalized token streams for the same inputs.

The two engines emit different native node names; `src/normalize.ts`
folds both into a small canonical vocabulary aligned with
`spec/token-kinds.md`. The test then compares the pre-order traversals
node by node.

## Running

```bash
make tree-sitter-generate           # ensure parser.c is up to date
cd grammars-lezer/lezer-httui-refs && npm ci && npm run build:parser
cd cross-grammar-tests && npm ci && npm test
```

Tree-sitter is invoked via the `tree-sitter` CLI (already a peer of the
canonical grammar package); install it once with `npm install -g
tree-sitter-cli` if it is not on PATH.

## Adding a case

Drop a file in `corpus/` with a `.input` suffix. The filename (minus the
suffix) becomes the test name. The file content is fed verbatim to both
parsers.

If the case is error-recovery only (the two engines may produce slightly
different error trees), name the file `*.diverges.input`. The test then
only asserts that both parsers complete without throwing.
