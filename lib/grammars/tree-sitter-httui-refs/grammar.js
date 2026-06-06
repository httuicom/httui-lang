/**
 * Tree-sitter grammar for httui reference syntax.
 *
 * Recognizes {{alias.path[0].nested}} forms embedded in arbitrary text.
 * This grammar is canonical for semantic analysis: the OCaml language
 * layer (in httui-lang/lib) and the TUI client consume the concrete
 * syntax tree produced here.
 *
 * Coverage (Slice 1 minimal):
 *   {{alias}}
 *   {{alias.path}}
 *   {{alias.path.nested}}
 *   {{alias.path[0]}}
 *   {{ENV_VAR}}
 *
 * Sync contract: the Lezer counterpart in
 * grammars-lezer/lezer-httui-refs/ must emit equivalent token kinds
 * for the same inputs. Cross-grammar corpus tests enforce alignment.
 */

module.exports = grammar({
  name: "httui_refs",

  rules: {
    source_file: ($) => repeat(choice($.ref, $.text)),

    ref: ($) => seq("{{", optional($.ref_body), "}}"),

    ref_body: ($) => seq($.identifier, optional($.dot_path)),

    dot_path: ($) => repeat1(seq(".", $.path_segment)),

    path_segment: ($) => seq($.identifier, optional($.index_access)),

    index_access: ($) => seq("[", $.number, "]"),

    identifier: ($) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    number: ($) => /[0-9]+/,

    // Any run of characters that does not open a ref. A single `{` not
    // followed by `{` stays inside text; `{{` is the only ref opener.
    // The lower precedence keeps `{{` winning over text when both could
    // start at the same position.
    text: ($) => token(prec(-1, /([^{]|\{[^{])+/)),
  },
});
