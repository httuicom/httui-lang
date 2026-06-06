# @httui/lezer-refs

[Lezer](https://lezer.codemirror.net/) grammar for httui reference syntax —
`{{alias.path[0].nested}}` forms embedded in markdown and string literals.

This grammar is consumed by the CodeMirror 6 client in the httui desktop
app for fast lexical first-paint highlighting. Semantic enrichment
(resolved vs unresolved, types) comes from the LSP server, which uses the
canonical [tree-sitter-httui-refs](../../lib/grammars/tree-sitter-httui-refs)
grammar.

## Grammar coverage

| Form | Example |
|---|---|
| Alias only | `{{req1}}` |
| Alias + dot navigation | `{{req1.body}}` |
| Multi-segment path | `{{req1.body.users.name}}` |
| Array index | `{{req1.body.users[0]}}` |
| Nested index path | `{{req1.body.users[0].id}}` |
| Env var (uppercase, no dot) | `{{API_TOKEN}}` |

### Deferred to future versions

- Pipeline syntax `{{alias \| filter}}` — v2.0+
- Cross-document refs `[[note]]#alias.path` — v2.x

## Token kinds emitted

See [httui-lang/spec/token-kinds.md](../../spec/token-kinds.md) for the
canonical vocabulary. This grammar maps to:

- `delimiter` — `{{` and `}}`
- `punctuation` — `.`, `[`, `]`
- `httui.alias` — identifier in alias position (disambiguation in the
  consumer; the grammar emits raw `Identifier` tokens)
- `number` — array indices

Refinement (alias vs env var vs path segment) happens during the semantic
walk in the OCaml LSP server, not in this lexical grammar.

## Build

```bash
npm install
npm run build       # generates src/parser.js from refs.grammar, bundles dist/
npm test            # runs corpus tests
```

The generated `src/parser.js` is not committed; CI and `npm install`
regenerate it.

## License

MIT. See [LICENSE](../../LICENSE).
