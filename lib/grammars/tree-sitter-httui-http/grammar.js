/**
 * Tree-sitter grammar for the httui HTTP fence dialect.
 *
 * Parses the body of ```http fenced blocks:
 *
 *   GET https://api.example.com/users?page=1
 *   &limit=10
 *   # desc: auth for staging
 *   Authorization: Bearer {{TOKEN}}
 *   # X-Disabled: value
 *
 *   {"name":"alice"}
 *
 * Line structure:
 *   - request line: `METHOD URL` (URL may carry an inline query)
 *   - `?seg` / `&seg` lines are query continuations
 *   - `# desc: text` (exact prefix, one space) describes the next line
 *   - `# ` + query/header is a disabled row; any other `#` line is a
 *     free-form comment
 *   - headers run until the first blank line; everything after is body
 *
 * `{{...}}` references are plain text here — the refs grammar overlays
 * them in every consumer.
 *
 * Newlines are significant: content tokens never cross lines, and the
 * headers/body boundary is the `_blank` token (two or more consecutive
 * newlines), which wins over `_newline` by maximal munch.
 *
 * The grammar is lenient on purpose: METHOD is any uppercase run and
 * "query before the first header" is not enforced — those are semantic
 * checks for the analysis layer, never parse errors.
 *
 * Sync contract: the Lezer counterpart in
 * grammars-lezer/lezer-httui-http/ emits a lexical coarsening of these
 * tokens (every Lezer token maps to a span here with an equal or more
 * generic kind). Cross-grammar corpus tests enforce alignment.
 */

module.exports = grammar({
  name: "httui_http",

  extras: ($) => [/[ \t]/],

  rules: {
    source_file: ($) =>
      seq(
        repeat(choice($.comment_line, $.desc_line, $._newline)),
        optional(
          seq(
            $.request_line,
            repeat(
              seq(
                $._newline,
                optional(
                  choice(
                    $.query_line,
                    $.header_line,
                    $.desc_line,
                    $.comment_line,
                    $.disabled_query_line,
                    $.disabled_header_line,
                  ),
                ),
              ),
            ),
            optional(seq($._blank, optional($.body))),
          ),
        ),
      ),

    request_line: ($) => seq($.method, optional($.url)),

    method: ($) => token(/[A-Z]+/),

    url: ($) => token(/[^ \t\r\n][^\r\n]*/),

    query_line: ($) => token(/[?&][^\r\n]*/),

    header_line: ($) => seq($.header_name, ":", optional($.header_value)),

    header_name: ($) => token(/[^:?&#\s][^:\r\n]*/),

    header_value: ($) => token(/[^\r\n]+/),

    desc_line: ($) => token(prec(3, /# desc: [^\r\n]*/)),

    disabled_query_line: ($) => token(prec(2, /# [?&][^\r\n]*/)),

    disabled_header_line: ($) =>
      token(prec(2, /# [^:?&\r\n][^:\r\n]*:[^\r\n]*/)),

    comment_line: ($) => token(prec(1, /#[^\r\n]*/)),

    body: ($) => repeat1(choice($.body_line, $._newline)),

    body_line: ($) => token(prec(-1, /[^\r\n]+/)),

    _newline: ($) => /\r?\n/,

    _blank: ($) => token(/\r?\n([ \t]*\r?\n)+/),
  },
});
