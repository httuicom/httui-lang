# Token kinds vocabulary

Canonical token kind vocabulary emitted by every httui grammar (tree-sitter
canonical + Lezer rendering). Both grammar engines map their internal node
kinds to these names; clients (CM6, ratatui, external editors via LSP
semantic tokens) consume only these names.

The LSP server declares them in `SemanticTokensLegend` at `initialize`.
Fallback is a **server-side downgrade**: token types are unique per range
and clients silently ignore types outside their announced capabilities, so
the server compares the `httui.*` kinds with the client's capabilities at
`initialize` and, for clients without support, emits the LSP-standard
fallback kind (second column) in both the legend and the token stream.
In VS Code, the extension registers the custom types via the
`semanticTokenTypes` contribution with `superType` pointing at the
fallback — VS Code's native degradation mechanism, aligned with this
table.

## Standard kinds (LSP 3.17 SemanticTokenTypes)

| Kind | When applied |
|---|---|
| `keyword` | Reserved words (`SELECT`, `GET`, `POST`, `if`, `for`) |
| `operator` | `=`, `+`, `\|\|`, `&&`, `\|` (pipe — reserved for v2.0+) |
| `string` | String literals `"..."`, `'...'`, raw strings |
| `number` | Numeric literals (int, float, hex) |
| `boolean` | `true`, `false`, `TRUE`, `NULL` (SQL) |
| `comment` | `//`, `--`, `#`, `/* */` |
| `function` | Function names at call sites |
| `variable` | Variable identifiers |
| `parameter` | Function or named parameters |
| `property` | Field accesses (`.body`, `.users`) |
| `type` | Type names |
| `namespace` | Namespace or schema prefixes (`public.users`) |
| `punctuation` | `,`, `;`, `()`, `{}`, `[]` |
| `delimiter` | Block opening/closing (`{{`, `}}`, ` ``` `) |

## httui-specific kinds (with LSP fallback)

| httui kind | LSP fallback | When applied |
|---|---|---|
| `httui.alias` | `variable` | Block alias identifier (`req1` in `{{req1.body}}` or `alias=req1`) |
| `httui.env_var` | `variable` | Env var name (`API_TOKEN` in `{{API_TOKEN}}`) |
| `httui.ref_path` | `property` | Path navigation inside a ref (`body.users[0].id`) |
| `httui.http_method` | `keyword` | HTTP method — visual specialization: GET green, POST yellow, DELETE red |
| `httui.http_header_name` | `property` | HTTP header name |
| `httui.http_header_value` | `string` | HTTP header value |
| `httui.fence_lang` | `keyword` | Language identifier in info string (`http`, `db-postgres`) |
| `httui.fence_info` | `parameter` | Info string tokens beyond lang (`alias=...`, `timeout=...`) |

**Fallback enforcement:** every `httui.*` kind must declare a fallback.
A PR that adds a new `httui.*` kind without a fallback is rejected.

## Modifiers

### LSP standard (10)

| Modifier | Applied when |
|---|---|
| `declaration` | Site where a symbol is declared (e.g. `alias=req1` in fence info string) |
| `definition` | Same as `declaration` for simple languages; LSP separates for languages with forward declarations |
| `readonly` | Read-only symbol |
| `static` | Static member (reserved) |
| `deprecated` | Symbol marked deprecated (reserved) |
| `abstract` | Reserved |
| `async` | Reserved |
| `modification` | Site where a symbol is modified |
| `documentation` | Within documentation strings |
| `defaultLibrary` | Built-in vs user-defined |

### httui-specific (3)

| Modifier | Applied when |
|---|---|
| `secret` | Env var with `is_secret=true` (renders obfuscated or in warning color) |
| `unresolved` | Ref does not resolve (alias unknown, env var missing) — clients use this for squiggle |
| `inferred` | Type was inferred (vs explicit) |

## Application rules

1. **More specific wins.** `httui.http_method` overrides `keyword` even
   though `GET` is also a keyword in the HTTP grammar.
2. **Modifiers stack.** `httui.env_var` with `secret + unresolved` is valid.
3. **Theme is free within the vocab.** A user theme can assign color X to
   `httui.alias` in Tokyo Night and color Y in Solarized; the vocab
   guarantees the assignment is unique.
4. **Grammars don't invent kinds.** A new kind goes through a PR adding it
   to this spec; grammars don't ship kinds outside this list.
5. **Fallback mandatory for every `httui.*`.** Without it, an external
   editor with no extension renders the token uncolored.
6. **`secret` implies value masking.** No surface (hover, `inlineValue`,
   completion detail, server logs) shows the real value of a secret env
   var — only a masked form. The modifier governs token rendering; the
   masking is a server invariant (the server has no keychain access by
   design).

## Theming integration

User palette in `user.toml` extends with:

```toml
[theme.tokens]
keyword = "purple"
"httui.alias" = "cyan"
"httui.http_method" = "method_color"   # special: per-method (GET/POST/...)
"httui.env_var" = { mod_secret = "warning", default = "cyan" }
```

Clients honor the palette per kind + modifier. No hardcoded colors in
renderers.

## SemanticTokensLegend

The OCaml LSP server declares the full vocab in `initialize` response:

```ocaml
let legend = {
  token_types = [
    "keyword"; "operator"; "string"; "number"; "boolean";
    "comment"; "function"; "variable"; "parameter"; "property";
    "type"; "namespace"; "punctuation"; "delimiter";
    "httui.alias"; "httui.env_var"; "httui.ref_path";
    "httui.http_method"; "httui.http_header_name"; "httui.http_header_value";
    "httui.fence_lang"; "httui.fence_info";
  ];
  token_modifiers = [
    "declaration"; "definition"; "readonly"; "static"; "deprecated";
    "abstract"; "async"; "modification"; "documentation"; "defaultLibrary";
    "secret"; "unresolved"; "inferred";
  ];
}
```

Clients announce which subsets they support via `ClientCapabilities`.
The legend above is the **full** vocab; the legend actually registered is
computed per client — `httui.*` kinds the client did not announce are
replaced by their fallback before registration, so no token ever reaches
a client as an unknown (silently dropped) kind.
