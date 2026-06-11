# @httui/lezer-http

[Lezer](https://lezer.codemirror.net/) grammar for the httui HTTP fence
dialect — the body of ```` ```http ```` fenced blocks.

This grammar is consumed by the CodeMirror 6 client in the httui desktop
app for fast lexical first-paint highlighting. Semantic enrichment comes
from the LSP server, which uses the canonical
[tree-sitter-httui-http](../../lib/grammars/tree-sitter-httui-http)
grammar.

## Dialect coverage

```http
GET https://api.example.com/users?page=1
&limit=10
# desc: auth for staging
Authorization: Bearer {{TOKEN}}
# X-Disabled: value

{"name":"alice"}
```

- Request line: `METHOD URL` — known methods (`GET`, `POST`, `PUT`,
  `PATCH`, `DELETE`, `HEAD`, `OPTIONS`) are specialized nodes so each
  can carry its own color; unknown uppercase runs stay a generic
  `Method` node.
- `?seg` / `&seg` lines are query continuations.
- `# desc: text` describes the next line; `# ` + query/header is a
  disabled row; any other `#` line is a free-form comment.
- Headers run until the first blank line; everything after is an opaque
  body.
- `{{...}}` references are plain text here — the
  [@httui/lezer-refs](../lezer-httui-refs) grammar overlays them.

## Highlight tags

`httpTags` exports one [`@lezer/highlight`](https://lezer.codemirror.net/docs/ref/#highlight)
tag per construct (and per method). Every tag derives from a standard
tag, so themes that only know the standard set still get sensible
colors. See [httui-lang/spec/token-kinds.md](../../spec/token-kinds.md)
for the canonical vocabulary.

## Build

```bash
npm install
npm run build       # generates src/parser.js from http.grammar, bundles dist/
npm test            # runs corpus tests
```

The generated `src/parser.js` is not committed; CI and `npm install`
regenerate it.

## License

MIT. See [LICENSE](../../LICENSE).
